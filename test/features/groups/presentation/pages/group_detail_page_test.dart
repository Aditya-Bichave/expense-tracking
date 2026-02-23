import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/group_expenses/domain/repositories/group_expenses_repository.dart';
import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_bloc.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/pages/group_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/pump_app.dart';

class MockGroupsBloc extends MockBloc<GroupsEvent, GroupsState>
    implements GroupsBloc {}

class MockGroupExpensesRepository extends Mock
    implements GroupExpensesRepository {}

class MockGroupsRepository extends Mock implements GroupsRepository {}

void main() {
  late MockGroupsBloc mockGroupsBloc;
  late MockGroupExpensesRepository mockGroupExpensesRepo;
  late MockGroupsRepository mockGroupsRepo;

  setUp(() {
    mockGroupsBloc = MockGroupsBloc();
    mockGroupExpensesRepo = MockGroupExpensesRepository();
    mockGroupsRepo = MockGroupsRepository();

    GetIt.I.reset();
    GetIt.I.registerLazySingleton<GroupExpensesRepository>(
      () => mockGroupExpensesRepo,
    );
    GetIt.I.registerLazySingleton<GroupsRepository>(() => mockGroupsRepo);

    when(
      () => mockGroupExpensesRepo.getExpenses(any()),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => mockGroupExpensesRepo.syncExpenses(any()),
    ).thenAnswer((_) async => const Right(null));
  });

  testWidgets('GroupDetailPage renders correctly', (tester) async {
    when(() => mockGroupsBloc.state).thenReturn(GroupsLoaded([]));

    await pumpWidgetWithProviders(
      tester: tester,
      widget: const GroupDetailPage(groupId: '1'),
      blocProviders: [BlocProvider<GroupsBloc>.value(value: mockGroupsBloc)],
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('No expenses yet.'), findsOneWidget);
  });
}
