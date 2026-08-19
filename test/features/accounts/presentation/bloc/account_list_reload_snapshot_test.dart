import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/delete_asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/get_asset_accounts.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetAssetAccountsUseCase extends Mock
    implements GetAssetAccountsUseCase {}

class MockDeleteAssetAccountUseCase extends Mock
    implements DeleteAssetAccountUseCase {}

/// Regression tests for the rows the list keeps on screen while reloading.
///
/// `AccountListPage` renders `AccountListLoading.previousItems` during a
/// refresh so the list does not blank out. Anything that loses that snapshot
/// makes the accounts disappear mid-pull, which is what these tests guard.
/// Yields to the event loop until [condition] holds, bounded so a broken
/// expectation fails the test rather than hanging it.
Future<void> _until(bool Function() condition, {int maxTurns = 100}) async {
  for (var i = 0; i < maxTurns && !condition(); i++) {
    await Future<void>.delayed(Duration.zero);
  }
  if (!condition()) {
    throw StateError('condition never became true after $maxTurns turns');
  }
}

void main() {
  late MockGetAssetAccountsUseCase getAccounts;
  late MockDeleteAssetAccountUseCase deleteAccount;

  const bank = AssetAccount(
    id: '1',
    name: 'Bank',
    type: AssetType.bank,
    initialBalance: 1000,
    currentBalance: 1000,
  );
  const cash = AssetAccount(
    id: '2',
    name: 'Cash',
    type: AssetType.cash,
    initialBalance: 50,
    currentBalance: 50,
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const DeleteAssetAccountParams('1'));
  });

  setUp(() {
    getAccounts = MockGetAssetAccountsUseCase();
    deleteAccount = MockDeleteAssetAccountUseCase();
  });

  AccountListBloc buildBloc() => AccountListBloc(
    getAssetAccountsUseCase: getAccounts,
    deleteAssetAccountUseCase: deleteAccount,
    dataChangeStream: const Stream<DataChangedEvent>.empty(),
  );

  test('a first load carries no snapshot and is not a reload', () async {
    when(() => getAccounts(any())).thenAnswer((_) async => const Right([bank]));
    final bloc = buildBloc();
    addTearDown(bloc.close);

    final states = <AccountListState>[];
    final sub = bloc.stream.listen(states.add);
    bloc.add(const LoadAccounts());
    await bloc.stream.firstWhere((s) => s is AccountListLoaded);
    await sub.cancel();

    final loading = states.first as AccountListLoading;
    expect(loading.isReloading, isFalse);
    expect(loading.previousItems, isEmpty);
  });

  test('a forced reload keeps the loaded rows in the loading state', () async {
    when(
      () => getAccounts(any()),
    ).thenAnswer((_) async => const Right([bank, cash]));
    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(const LoadAccounts());
    await bloc.stream.firstWhere((s) => s is AccountListLoaded);

    final reloadStates = <AccountListState>[];
    final sub = bloc.stream.listen(reloadStates.add);
    bloc.add(const LoadAccounts(forceReload: true));
    await bloc.stream.firstWhere((s) => s is AccountListLoaded);
    await sub.cancel();

    final loading = reloadStates.whereType<AccountListLoading>().first;
    expect(loading.isReloading, isTrue);
    expect(loading.previousItems, [bank, cash]);
  });

  test(
    'a reload that overlaps an in-flight reload still keeps the rows',
    () async {
      // Bloc handlers run concurrently by default. The second LoadAccounts
      // observes AccountListLoading rather than AccountListLoaded, so deriving
      // the snapshot from "is it loaded?" alone would drop the rows and the
      // page would flash a full-screen spinner instead of holding the list.
      when(
        () => getAccounts(any()),
      ).thenAnswer((_) async => const Right([bank, cash]));
      final bloc = buildBloc();
      addTearDown(bloc.close);

      // Prime a loaded state.
      bloc.add(const LoadAccounts());
      await bloc.stream.firstWhere((s) => s is AccountListLoaded);

      // Now make the use case hang so both reloads are genuinely in flight at
      // once. Counting handler entries is what proves the overlap happened —
      // the bloc suppresses a second identical loading state, so counting
      // emissions would not.
      final slowGate = Completer<void>();
      var inFlight = 0;
      when(() => getAccounts(any())).thenAnswer((_) async {
        inFlight++;
        await slowGate.future;
        return const Right([bank, cash]);
      });

      final observed = <AccountListLoading>[];
      final sub = bloc.stream
          .where((s) => s is AccountListLoading)
          .cast<AccountListLoading>()
          .listen(observed.add);

      bloc.add(const LoadAccounts(forceReload: true));
      bloc.add(const LoadAccounts(forceReload: true));
      await _until(() => inFlight >= 2);

      // While both are in flight the visible state must still hold the rows.
      expect(
        bloc.state,
        isA<AccountListLoading>()
            .having((s) => s.previousItems, 'previousItems', [bank, cash])
            .having((s) => s.isReloading, 'isReloading', isTrue),
      );

      slowGate.complete();
      await bloc.stream.firstWhere((s) => s is AccountListLoaded);
      await sub.cancel();

      expect(observed, isNotEmpty);
      const expectedRows = [bank, cash];
      for (final loading in observed) {
        expect(
          loading.previousItems,
          expectedRows,
          reason: 'every reload state must keep the visible rows',
        );
        expect(loading.isReloading, isTrue);
      }
    },
  );

  blocTest<AccountListBloc, AccountListState>(
    'a reset clears the snapshot so the next load starts clean',
    build: () {
      when(
        () => getAccounts(any()),
      ).thenAnswer((_) async => const Right([bank]));
      return buildBloc();
    },
    seed: () => const AccountListLoaded(accounts: [bank]),
    act: (bloc) => bloc.add(const ResetState()),
    // A reset wipes the session, so the reload that follows must start from an
    // empty snapshot rather than carrying the old rows forward.
    expect: () => const [
      AccountListInitial(),
      AccountListLoading(isReloading: false, previousItems: []),
      AccountListLoaded(accounts: [bank]),
    ],
  );
}
