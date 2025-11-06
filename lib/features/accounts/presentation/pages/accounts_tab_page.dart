// lib/features/accounts/presentation/pages/accounts_tab_page.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/entities/liability.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_card.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/liability_card.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/main.dart';

class AccountsTabPage extends StatefulWidget {
  const AccountsTabPage({super.key});

  @override
  State<AccountsTabPage> createState() => _AccountsTabPageState();
}

class _AccountsTabPageState extends State<AccountsTabPage> {
  void _navigateToAccountDetail(BuildContext context, AssetAccount account) {
    log.info(
        "[AccountsTabPage] Navigating to Edit Account for ID: ${account.id}");
    context.pushNamed(RouteNames.editAccount,
        pathParameters: {RouteNames.paramAccountId: account.id},
        extra: account);
  }

  void _navigateToAddLiability(BuildContext context) {
    context.pushNamed(RouteNames.addLiability);
  }

  void _navigateToEditLiability(BuildContext context, Liability liability) {
    // TODO: Implement navigation to Add/Edit Liability page
  }

  void _showAddAccountOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: const Text('Add Asset Account'),
              onTap: () {
                Navigator.of(ctx).pop();
                context.pushNamed(RouteNames.addAccount);
              },
            ),
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('Add Credit/Loan'),
              onTap: () {
                Navigator.of(ctx).pop();
                _navigateToAddLiability(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          context
              .read<AccountListBloc>()
              .add(const LoadAccounts(forceReload: true));
          await context.read<AccountListBloc>().stream.firstWhere(
              (state) => state is! AccountListLoading || !state.isReloading);
        },
        child: BlocBuilder<AccountListBloc, AccountListState>(
          builder: (context, state) {
            if (state is AccountListLoading && !state.isReloading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AccountListError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            if (state is AccountListLoaded) {
              final assets = state.accounts;
              final liabilities = state.liabilities;
              final double totalAssets =
                  assets.fold(0.0, (sum, acc) => sum + acc.currentBalance);
              final double totalLiabilities = liabilities.fold(
                  0.0, (sum, acc) => sum + acc.currentBalance);
              final settingsState = context.watch<SettingsBloc>().state;
              final currencySymbol = settingsState.currencySymbol;

              return ListView(
                padding:
                    modeTheme?.pagePadding.copyWith(top: 8, bottom: 80) ??
                        const EdgeInsets.only(top: 8.0, bottom: 80.0),
                children: [
                  const SectionHeader(title: 'Assets'),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Assets:',
                            style: theme.textTheme.titleMedium),
                        Text(
                          CurrencyFormatter.format(totalAssets, currencySymbol),
                          style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (assets.isEmpty)
                    const Center(child: Text('No asset accounts yet.'))
                  else
                    ...assets.map((account) => AccountCard(
                        account: account,
                        onTap: () =>
                            _navigateToAccountDetail(context, account))),
                  const SizedBox(height: 16),
                  const SectionHeader(title: 'Credit & Loans'),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Liabilities:',
                            style: theme.textTheme.titleMedium),
                        Text(
                          CurrencyFormatter.format(
                              totalLiabilities, currencySymbol),
                          style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (liabilities.isEmpty)
                    const Center(child: Text('No liability accounts yet.'))
                  else
                    ...liabilities.map((liability) => LiabilityCard(
                          liability: liability,
                          onTap: () =>
                              _navigateToEditLiability(context, liability),
                        )),
                ],
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_account_fab',
        tooltip: 'Add Account',
        onPressed: () => _showAddAccountOptions(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
