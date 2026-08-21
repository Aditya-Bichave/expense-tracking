import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/trash_bin/trash_bin_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/trash_bin/trash_bin_event.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/trash_bin/trash_bin_state.dart';
import 'package:expense_tracker/features/settings/presentation/pages/trash_bin_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTrashBinBloc extends Mock implements TrashBinBloc {}

void main() {
  late MockTrashBinBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(LoadTrash());
    registerFallbackValue(
      const PurgeItem(id: '1', type: TrashItemType.expense),
    );
    registerFallbackValue(
      const RestoreItem(id: '1', type: TrashItemType.expense),
    );
  });

  setUp(() {
    mockBloc = MockTrashBinBloc();
    when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockBloc.close()).thenAnswer((_) async {});
  });

  tearDown(() {
    sl.reset();
  });

  testWidgets('TrashBinPage creates and adds LoadTrash via ServiceLocator', (
    tester,
  ) async {
    when(() => mockBloc.state).thenReturn(TrashBinInitial());
    sl.registerSingleton<TrashBinBloc>(mockBloc);

    await tester.pumpWidget(const MaterialApp(home: TrashBinPage()));

    verify(() => mockBloc.add(any<LoadTrash>())).called(1);
  });

  testWidgets('TrashBinView renders error state correctly', (tester) async {
    when(
      () => mockBloc.state,
    ).thenReturn(const TrashBinError('Failed to load trash'));

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<TrashBinBloc>.value(
          value: mockBloc,
          child: const TrashBinView(),
        ),
      ),
    );

    expect(find.text('Failed to load trash'), findsOneWidget);
  });

  testWidgets('TrashBinView renders items and handles popup restore', (
    tester,
  ) async {
    final now = DateTime.now();
    final itemExpense = TrashItem(
      id: 'exp1',
      title: 'Coffee',
      amount: 4.50,
      date: now,
      deletedAt: now.subtract(const Duration(minutes: 5)),
      type: TrashItemType.expense,
    );

    when(() => mockBloc.state).thenReturn(TrashBinLoaded([itemExpense]));

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<TrashBinBloc>.value(
          value: mockBloc,
          child: const TrashBinView(),
        ),
      ),
    );

    expect(find.text('Coffee'), findsOneWidget);

    final popupButtons = find.byType(PopupMenuButton<String>);
    await tester.tap(popupButtons.first);
    await tester.pumpAndSettle();

    expect(find.text('Restore'), findsOneWidget);

    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    verify(
      () => mockBloc.add(
        const RestoreItem(id: 'exp1', type: TrashItemType.expense),
      ),
    ).called(1);
  });
}
