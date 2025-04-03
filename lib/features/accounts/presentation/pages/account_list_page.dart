// lib/features/accounts/presentation/pages/account_list_page.dart
// MODIFIED FILE

// ... (Imports remain the same) ...
import 'package:expense_tracker/core/common/generic_list_page.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_card.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:expense_tracker/core/assets/app_assets.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';
// Import necessary types for ItemWidgetBuilder callbacks (no longer needed here)
// import 'package:expense_tracker/features/categories/domain/entities/category.dart';

class AccountListPage extends StatelessWidget {
  const AccountListPage({super.key});

  // Helper to navigate to the edit page for an account
  void _navigateToEditAccount(BuildContext context, AssetAccount account) {
    log.info("[AccountListPage] Navigating to Edit Account ID: ${account.id}");
    context.pushNamed(RouteNames.editAccount,
        pathParameters: {RouteNames.paramId: account.id}, extra: account);
  }

  // --- Specific Builders for Accounts ---

  // CORRECTED: Simpler signature, takes only what it needs + the edit callback
  Widget _buildAccountItem(
    BuildContext context,
    AssetAccount item,
    VoidCallback onEditTap, // Receive the specific action callback
  ) {
    // Pass the received onEditTap directly to AccountCard's onTap
    return AccountCard(account: item, onTap: onEditTap);
  }

  Widget _buildEmptyState(BuildContext context, bool filtersApplied) {
    // ... (empty state logic remains the same) ...
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;
    String illustrationKey = AssetKeys.illuEmptyWallet;
    String defaultIllustration = AppAssets.elIlluEmptyWallet;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
                modeTheme?.assets.getIllustration(illustrationKey,
                        defaultPath: defaultIllustration) ??
                    defaultIllustration,
                height: 100,
                colorFilter: ColorFilter.mode(
                    theme.colorScheme.secondary, BlendMode.srcIn)),
            const SizedBox(height: 16),
            Text('No accounts yet.',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: theme.colorScheme.secondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Tap "+" to add your first account.',
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add First Account'),
              onPressed: () => context.pushNamed(RouteNames.addAccount),
            )
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmAccountDeletion(
      BuildContext context, AssetAccount item) async {
    // ... (confirmation logic remains the same) ...
    return await AppDialogs.showConfirmation(
          context,
          title: "Confirm Deletion",
          content:
              'Are you sure you want to delete the account "${item.name}"?\n\nThis might fail if transactions are linked.',
          confirmText: "Delete",
          confirmColor: Theme.of(context).colorScheme.error,
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AccountListBloc>(
      create: (_) => sl<AccountListBloc>()..add(const LoadAccounts()),
      child: Builder(builder: (innerContext) {
        // Use innerContext which has AccountListBloc
        return GenericListPage<AssetAccount, AccountListBloc, AccountListEvent,
            AccountListState>(
          pageTitle: 'Accounts',
          addRouteName: RouteNames.addAccount,
          editRouteName:
              RouteNames.editAccount, // Still needed for _navigateToEditAccount
          itemHeroTagPrefix: 'account',
          fabHeroTag: 'fab_accounts',
          // --- CORRECTED itemBuilder wiring ---
          // Provide a lambda matching the SIMPLIFIED ItemWidgetBuilder signature
          itemBuilder: (
            BuildContext itemBuilderContext,
            AssetAccount accountItem,
            bool isSelected, // Provided by GenericListPage (unused here)
          ) {
            // Call our local _buildAccountItem helper.
            // We pass the specific action (_navigateToEditAccount) needed by this item.
            return _buildAccountItem(
              itemBuilderContext,
              accountItem,
              // Pass the navigation function bound to the current context and item
              () => _navigateToEditAccount(innerContext, accountItem),
            );
          },
          // --- END CORRECTION ---
          tableBuilder: null,
          emptyStateBuilder: _buildEmptyState,
          filterDialogBuilder: null,
          deleteConfirmationBuilder: (dialogContext, item) =>
              _confirmAccountDeletion(dialogContext, item),
          deleteEventBuilder: (id) => DeleteAccountRequested(id),
          loadEventBuilder: ({bool forceReload = false}) =>
              LoadAccounts(forceReload: forceReload),
          showSummaryCard: false,
        );
      }),
    );
  }
}
