import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/trash_bin/trash_bin_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/trash_bin/trash_bin_event.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/trash_bin/trash_bin_state.dart';
import 'package:expense_tracker/features/settings/presentation/pages/trash_bin_page.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/tokens/app_colors.dart';
import 'package:expense_tracker/ui_kit/tokens/app_typography.dart';
import 'package:expense_tracker/ui_kit/tokens/app_spacing.dart';
import 'package:expense_tracker/ui_kit/tokens/app_radii.dart';
import 'package:expense_tracker/ui_kit/tokens/app_motion.dart';
import 'package:expense_tracker/ui_kit/tokens/app_shadows.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockIncomeRepository extends Mock implements IncomeRepository {}

void main() {
  late MockExpenseRepository mockExpenseRepository;
  late MockIncomeRepository mockIncomeRepository;

  setUp(() {
    sl.reset();
    mockExpenseRepository = MockExpenseRepository();
    mockIncomeRepository = MockIncomeRepository();

    sl.registerFactory<TrashBinBloc>(
      () => TrashBinBloc(
        expenseRepository: mockExpenseRepository,
        incomeRepository: mockIncomeRepository,
      ),
    );
  });

  tearDown(() {
    sl.reset();
  });

  final tItem = TrashItem(
    id: 'exp1',
    title: 'Deleted Grocery',
    amount: 45.0,
    date: DateTime(2026, 4, 1),
    deletedAt: DateTime(2026, 4, 2, 10, 0),
    type: TrashItemType.expense,
  );

  Widget createWidgetUnderTest({required TrashBinBloc bloc}) {
    final theme = ThemeData.light().copyWith(
      extensions: [
        AppKitTheme(
          colors: AppColors(ColorScheme.fromSeed(seedColor: Colors.blue)),
          typography: AppTypography(Typography.material2021().englishLike),
          spacing: const AppSpacing(),
          radii: const AppRadii(),
          motion: const AppMotion(),
          shadows: const AppShadows(),
        ),
      ],
    );
    return MaterialApp(
      theme: theme,
      home: BlocProvider<TrashBinBloc>.value(
        value: bloc,
        child: const TrashBinView(),
      ),
    );
  }

  testWidgets('TrashBinView renders empty state when trash is empty', (
    tester,
  ) async {
    final bloc = TrashBinBloc(
      expenseRepository: mockExpenseRepository,
      incomeRepository: mockIncomeRepository,
    );

    when(() => mockExpenseRepository.listDeletedExpenses()).thenAnswer(
      (_) async => Right<Failure, List<ExpenseModel>>(<ExpenseModel>[]),
    );
    when(() => mockIncomeRepository.listDeletedIncomes()).thenAnswer(
      (_) async => Right<Failure, List<IncomeModel>>(<IncomeModel>[]),
    );

    await tester.pumpWidget(createWidgetUnderTest(bloc: bloc));
    bloc.add(LoadTrash());
    await tester.pumpAndSettle();

    expect(find.text('Nothing in the trash'), findsOneWidget);
    expect(
      find.text('Items in the trash are removed automatically after 30 days.'),
      findsOneWidget,
    );
    bloc.close();
  });

  testWidgets(
    'TrashBinView renders loaded items and handles purge confirmation',
    (tester) async {
      final bloc = TrashBinBloc(
        expenseRepository: mockExpenseRepository,
        incomeRepository: mockIncomeRepository,
      );

      when(
        () => mockExpenseRepository.listDeletedExpenses(),
      ).thenAnswer((_) async => Right<Failure, List<ExpenseModel>>([]));
      when(
        () => mockIncomeRepository.listDeletedIncomes(),
      ).thenAnswer((_) async => Right<Failure, List<IncomeModel>>([]));
      when(
        () => mockExpenseRepository.purgeExpense('exp1'),
      ).thenAnswer((_) async => const Right(null));

      await tester.pumpWidget(createWidgetUnderTest(bloc: bloc));

      // Manually emit loaded state for immediate testing
      bloc.emit(TrashBinLoaded([tItem]));
      await tester.pump();

      expect(find.text('Deleted Grocery'), findsOneWidget);

      // Open popup menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsWidgets);

      // Tap Delete
      await tester.tap(find.text('Delete').first);
      await tester.pumpAndSettle();

      // Confirmation dialog check
      expect(
        find.text(
          'Are you sure you want to permanently delete "Deleted Grocery"? This action cannot be undone.',
        ),
        findsOneWidget,
      );

      // Confirm dialog
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      verify(() => mockExpenseRepository.purgeExpense('exp1')).called(1);
      bloc.close();
    },
  );
}
