// lib/features/accounts/presentation/pages/accounts_tab_page.dart
import 'package:expense_tracker/core/common/base_list_state.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/widgets/placeholder_screen.dart';
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_card.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/main.dart';
import 'package:toggle_switch/toggle_switch.dart'; // Import ToggleSwitch

enum AccountViewType { assets, liabilities }

class AccountsTabPage extends StatefulWidget {
  const AccountsTabPage({super.key});

  @override
  State<AccountsTabPage> createState() => _AccountsTabPageState();
}

class _AccountsTabPageState extends State<AccountsTabPage> {
  AccountViewType _selectedView = AccountViewType.assets;

  void _navigateToAccountDetail(BuildContext context, AssetAccount account) {
    log.info(
        "[AccountsTabPage] Navigating to Edit Account for ID: ${account.id}");
    context.pushNamed(RouteNames.editAccount,
        pathParameters: {RouteNames.paramAccountId: account.id},
        extra: account);
  }

  void _showLiabilityComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content:
            const Text("Liability account features are under development."),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        duration: const Duration(seconds: 2),
      ));
    // IMPORTANT: Reset toggle back to Assets immediately AFTER showing snackbar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _selectedView = AccountViewType.assets;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;

    // Define gradient lists
    final assetGradientList = [
      theme.colorScheme.primaryContainer,
      theme.colorScheme.primaryContainer.withOpacity(0.7)
    ];
    final liabilityGradientList = [
      theme.colorScheme.errorContainer.withOpacity(0.7),
      theme.colorScheme.errorContainer
    ];

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          context
              .read<AccountListBloc>()
              .add(const LoadAccounts(forceReload: true));
          await context.read<AccountListBloc>().stream.firstWhere(
              (state) => state is! AccountListLoading || !state.isReloading);
        },
        child: ListView(
          padding: modeTheme?.pagePadding.copyWith(top: 8, bottom: 80) ??
              const EdgeInsets.only(top: 8.0, bottom: 80.0),
          children: [
            // Add ToggleSwitch
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Center(
                child: ToggleSwitch(
                  minWidth: 120.0,
                  cornerRadius: 20.0,
                  // --- FIX: Use activeBgColors ---
                  activeBgColors: [assetGradientList, liabilityGradientList],
                  // --- END FIX ---
                  activeBgColor: null, // Must be null when using activeBgColors
                  activeFgColor: _selectedView == AccountViewType.assets
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onErrorContainer,
                  inactiveBgColor: theme.colorScheme.surfaceContainerHighest,
                  inactiveFgColor: theme.colorScheme.onSurfaceVariant,
                  initialLabelIndex:
                      _selectedView == AccountViewType.assets ? 0 : 1,
                  totalSwitches: 2,
                  labels: const ['Assets', 'Liabilities'],
                  radiusStyle: true,
                  onToggle: (index) {
                    if (index != null) {
                      final newView = index == 0
                          ? AccountViewType.assets
                          : AccountViewType.liabilities;
                      if (_selectedView != newView) {
                        if (newView == AccountViewType.liabilities) {
                          _showLiabilityComingSoon(
                              context); // Show message and revert
                        } else {
                          setState(() {
                            _selectedView = newView;
                          }); // Update state for Assets
                        }
                      }
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Conditionally Show Asset/Liability Content
            if (_selectedView == AccountViewType.assets)
              _buildAssetContent(context, theme, modeTheme)
            else
              _buildLiabilityPlaceholder(context, theme),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_account_fab_sub', // Unique tag
        child: const Icon(Icons.add),
        tooltip: _selectedView == AccountViewType.assets
            ? 'Add Asset Account'
            : 'Add Liability Account',
        onPressed: () {
          if (_selectedView == AccountViewType.assets) {
            context.pushNamed(RouteNames.addAccount);
          } else {
            _showLiabilityComingSoon(
                context); // Show coming soon if trying to add liability
          }
        },
      ),
    );
  }

  Widget _buildAssetContent(
      BuildContext context, ThemeData theme, AppModeTheme? modeTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Assets'),
        BlocBuilder<AccountListBloc, AccountListState>(
          builder: (context, state) {
            if (state is AccountListLoading && !state.isReloading) {
              return const Center(
                  child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator()));
            }
            if (state is AccountListError) {
              return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                      child: Text('Error loading accounts: ${state.message}',
                          style: TextStyle(color: theme.colorScheme.error))));
            }
            if (state is AccountListLoaded ||
                (state is AccountListLoading && state.isReloading)) {
              final accounts = (state is AccountListLoaded)
                  ? state.items
                  : (context.read<AccountListBloc>().state is AccountListLoaded)
                      ? (context.read<AccountListBloc>().state
                              as AccountListLoaded)
                          .items
                      : <AssetAccount>[];
              final double totalAssets =
                  accounts.fold(0.0, (sum, acc) => sum + acc.currentBalance);
              final settingsState = context.watch<SettingsBloc>().state;
              final currencySymbol = settingsState.currencySymbol;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  if (accounts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 24.0),
                      child: Center(
                        child: Text(
                          'No asset accounts added yet.\nTap the "+" button below to add one.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: accounts.length,
                      itemBuilder: (ctx, index) {
                        final account = accounts[index];
                        return AccountCard(
                            account: account,
                            onTap: () =>
                                _navigateToAccountDetail(context, account));
                      },
                    ),
                  // --- ADDED: Add Asset Account Button ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Add Asset Account'),
                      onPressed: () => context.pushNamed(RouteNames.addAccount),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: theme.textTheme.labelLarge,
                        side:
                            BorderSide(color: theme.colorScheme.outlineVariant),
                        minimumSize: const Size.fromHeight(
                            45), // Make button full width like liability one
                      ),
                    ),
                  ),
                  // --- END ADD ---
                ],
              );
            }
            // Fallback for Initial state
            return const Center(
                child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator()));
          },
        ),
      ],
    );
  }

  Widget _buildLiabilityPlaceholder(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Liabilities'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Liabilities:',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.disabledColor)),
              Text('N/A',
                  style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold, color: theme.disabledColor)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Center(
              child: Text(
                  'Liability accounts (Credit Cards, Loans) coming soon!',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center)),
        ),
        Padding(
          // Button remains the same, but is effectively disabled by FAB logic now
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: OutlinedButton.icon(
            icon: Icon(Icons.add_circle_outline, color: theme.disabledColor),
            label: Text('Add Liability Account',
                style: TextStyle(color: theme.disabledColor)),
            onPressed: () => _showLiabilityComingSoon(
                context), // Show message on button press too
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: theme.textTheme.labelLarge,
              side: BorderSide(color: theme.disabledColor.withOpacity(0.5)),
              minimumSize: const Size.fromHeight(45),
            ),
          ),
        ),
      ],
    );
  }
}
