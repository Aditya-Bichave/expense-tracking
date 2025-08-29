import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/features/categories/domain/usecases/get_categories.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/transactions/presentation/pages/transaction_list_page.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_filter_dialog.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_list_header.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_sort_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockTransactionListBloc
    extends MockBloc<TransactionListEvent, TransactionListState>
    implements TransactionListBloc {}

class MockCategoryManagementBloc
    extends MockBloc<CategoryManagementEvent, CategoryManagementState>
    implements CategoryManagementBloc {}

class FakeTransactionListEvent extends Fake implements TransactionListEvent {}

class FakeTransactionListState extends Fake implements TransactionListState {}

class FakeCategoryManagementEvent extends Fake
    implements CategoryManagementEvent {}

class FakeCategoryManagementState extends Fake
    implements CategoryManagementState {}

class MockGetCategoriesUseCase extends Mock implements GetCategoriesUseCase {}

void main() {
  late TransactionListBloc mockTransactionListBloc;
  late CategoryManagementBloc mockCategoryManagementBloc;
  late GetCategoriesUseCase mockGetCategoriesUseCase;

  setUpAll(() {
    registerFallbackValue(FakeTransactionListEvent());
    registerFallbackValue(FakeTransactionListState());
    registerFallbackValue(FakeCategoryManagementState());
    registerFallbackValue(FakeCategoryManagementEvent());
    registerFallbackValue(NoParams());
  });

  setUp(() {
    mockTransactionListBloc = MockTransactionListBloc();
    mockCategoryManagementBloc = MockCategoryManagementBloc();
    mockGetCategoriesUseCase = MockGetCategoriesUseCase();
    sl.registerSingleton<GetCategoriesUseCase>(mockGetCategoriesUseCase);
    when(() => mockGetCategoriesUseCase.call(any()))
        .thenAnswer((_) async => const Right(<Category>[]));
  });

  tearDown(() {
    if (sl.isRegistered<GetCategoriesUseCase>()) {
      sl.unregister<GetCategoriesUseCase>();
    }
  });

  Widget buildTestWidget() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TransactionListBloc>.value(value: mockTransactionListBloc),
        BlocProvider<CategoryManagementBloc>.value(
            value: mockCategoryManagementBloc),
      ],
      child: const TransactionListPage(),
    );
  }

  group('TransactionListPage', () {
    testWidgets('renders Header and ListView by default', (tester) async {
      when(() => mockTransactionListBloc.state)
          .thenReturn(const TransactionListState());
      when(() => mockCategoryManagementBloc.state)
          .thenReturn(const CategoryManagementState());

      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget());

      expect(find.byType(TransactionListHeader), findsOneWidget);
      expect(find.byKey(const ValueKey('list_view')), findsOneWidget);
      expect(find.byKey(const ValueKey('calendar_view')), findsNothing);
    });

    testWidgets('switches to CalendarView when toggle is tapped',
        (tester) async {
      when(() => mockTransactionListBloc.state)
          .thenReturn(const TransactionListState());
      when(() => mockCategoryManagementBloc.state)
          .thenReturn(const CategoryManagementState());

      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget());

      await tester.tap(find.byKey(const ValueKey('button_toggle_view')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('calendar_view')), findsOneWidget);
      expect(find.byKey(const ValueKey('list_view')), findsNothing);
    });

    testWidgets('shows FilterDialog when filter button is tapped',
        (tester) async {
      when(() => mockTransactionListBloc.state)
          .thenReturn(const TransactionListState());
      when(() => mockCategoryManagementBloc.state)
          .thenReturn(const CategoryManagementState());

      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget());

      await tester.tap(find.byKey(const ValueKey('button_show_filter')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(TransactionFilterDialog), findsOneWidget);
    });

    testWidgets('shows SortSheet when sort button is tapped', (tester) async {
      final binding = tester.binding;
      binding.window.physicalSizeTestValue = const Size(800, 1000);
      binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(() {
        binding.window.clearPhysicalSizeTestValue();
        binding.window.clearDevicePixelRatioTestValue();
      });

      when(() => mockTransactionListBloc.state)
          .thenReturn(const TransactionListState());
      when(() => mockCategoryManagementBloc.state)
          .thenReturn(const CategoryManagementState());

      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget());

      await tester.tap(find.byKey(const ValueKey('button_show_sort')));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionSortSheet), findsOneWidget);
    });

    testWidgets('shows batch FAB when in batch edit mode', (tester) async {
      when(() => mockTransactionListBloc.state)
          .thenReturn(const TransactionListState(isInBatchEditMode: true));
      when(() => mockCategoryManagementBloc.state)
          .thenReturn(const CategoryManagementState());

      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget());

      expect(find.byKey(const ValueKey('batch_fab')), findsOneWidget);
    });

    testWidgets('search input triggers SearchChanged event', (tester) async {
      when(() => mockTransactionListBloc.state)
          .thenReturn(const TransactionListState());
      when(() => mockCategoryManagementBloc.state)
          .thenReturn(const CategoryManagementState());

      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget());

      await tester.enterText(
          find.byKey(const ValueKey('textField_transactionSearch')), 'coffee');
      await tester.pump(const Duration(milliseconds: 501)); // Wait for debounce

      verify(() => mockTransactionListBloc
          .add(const SearchChanged(searchTerm: 'coffee'))).called(1);
    });
  });
}
