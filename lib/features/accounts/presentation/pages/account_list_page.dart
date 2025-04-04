import 'package:expense_tracker/core/common/generic_list_page.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_card.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Keep for potential future use (e.g., currency in empty state)
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:expense_tracker/core/assets/app_assets.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';

// This widget might be deprecated soon in favor of AccountsTabPage,
// but we'll keep it functional for now based on the provided code.
class AccountListPage extends StatelessWidget {
  const AccountListPage({super.key});

  // Helper to navigate to the edit page for an account
  // It uses pushNamed, assuming 'edit_account' is defined appropriately in the router,
  // potentially pushed onto the root navigator.
  void _navigateToEditAccount(BuildContext context, AssetAccount account) {
    log.info("[AccountListPage] Navigating to Edit Account ID: ${account.id}");
    context.pushNamed(RouteNames.editAccount,
        // Use the correct parameter name as defined in your router
        pathParameters: {
          RouteNames.paramAccountId: account.id
        }, // Assuming param name is 'accountId'
        extra: account // Pass the account data for pre-filling the form
        );
  }

  // --- Specific Builders for Accounts ---

  // Builds the widget for a single account item in the list.
  Widget _buildAccountItem(
    BuildContext context,
    AssetAccount item,
    VoidCallback onEditTap, // Callback triggered when the item should be edited
  ) {
    // AccountCard handles the visual representation. Pass the edit callback to its onTap.
    return AccountCard(account: item, onTap: onEditTap);
  }

  // Builds the widget displayed when the account list is empty.
  Widget _buildEmptyState(BuildContext context, bool filtersApplied) {
    // filtersApplied is provided by GenericListPage but currently unused here as filtering isn't implemented for accounts list.
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;
    // Define asset keys for illustration based on theme potentially
    String illustrationKey =
        AssetKeys.illuEmptyWallet; // Default illustration key
    String defaultIllustration =
        AppAssets.elIlluEmptyWallet; // Default asset path

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0), // Increased padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              // Get illustration path from theme or use default
              modeTheme?.assets.getIllustration(illustrationKey,
                      defaultPath: defaultIllustration) ??
                  defaultIllustration,
              height: 120, // Slightly larger illustration
              colorFilter: ColorFilter.mode(
                  theme.colorScheme.secondary.withOpacity(0.8),
                  BlendMode.srcIn), // Use theme color
            ),
            const SizedBox(height: 24),
            Text(
              'No accounts yet!',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(color: theme.colorScheme.secondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Tap the "+" button below to add your first bank account, cash wallet, or other assets.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add First Account'),
              onPressed: () => context.pushNamed(
                  RouteNames.addAccount), // Navigate using route name
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Builds and shows the confirmation dialog before deleting an account.
  Future<bool> _confirmAccountDeletion(
      BuildContext context, AssetAccount item) async {
    return await AppDialogs.showConfirmation(
          context,
          title: "Confirm Deletion",
          content:
              'Are you sure you want to delete the account "${item.name}"?\n\nThis action might fail if there are existing transactions linked to this account.',
          confirmText: "Delete",
          confirmColor: Theme.of(context)
              .colorScheme
              .error, // Use error color for destructive action
        ) ??
        false; // Return false if dialog is dismissed
  }

  @override
  Widget build(BuildContext context) {
    // Provide the AccountListBloc to this widget tree.
    // Load accounts immediately if the Bloc is created here.
    return BlocProvider<AccountListBloc>(
      create: (_) => sl<AccountListBloc>()..add(const LoadAccounts()),
      child: Builder(// Use Builder to get context with the Bloc
          builder: (innerContext) {
        return GenericListPage<AssetAccount, AccountListBloc, AccountListEvent,
            AccountListState>(
          pageTitle: 'Accounts', // Title for the AppBar
          addRouteName:
              RouteNames.addAccount, // Route for the default FAB action
          // editRouteName parameter removed
          itemHeroTagPrefix: 'account', // Prefix for potential Hero animations
          fabHeroTag: 'fab_accounts', // Hero tag for the default FAB
          showSummaryCard: false, // Don't show the analytics summary card here

          // Provide the builder for individual list items
          itemBuilder: (
            BuildContext
                itemBuilderContext, // Context specific to the item builder
            AssetAccount accountItem, // The data for the current item
            bool isSelected, // Selection state (unused in this implementation)
          ) {
            // Call the local helper to build the AccountCard, passing the edit action
            return _buildAccountItem(
              itemBuilderContext,
              accountItem,
              // Lambda function to navigate to edit screen when the card is tapped
              () => _navigateToEditAccount(innerContext, accountItem),
            );
          },

          tableBuilder:
              null, // No table view implementation for accounts currently
          emptyStateBuilder:
              _buildEmptyState, // Provide the empty state builder
          filterDialogBuilder:
              null, // No filtering implemented for accounts currently

          // Provide the delete confirmation dialog builder
          deleteConfirmationBuilder: (dialogContext, item) =>
              _confirmAccountDeletion(dialogContext, item),
          // Provide the function to create the delete event for the Bloc
          deleteEventBuilder: (id) => DeleteAccountRequested(id),
          // Provide the function to create the load event for the Bloc
          loadEventBuilder: ({bool forceReload = false}) =>
              LoadAccounts(forceReload: forceReload),

          // No custom FAB or AppBar actions needed for this basic list
          appBarActions: null,
          floatingActionButton: null, // Use default FAB from GenericListPage
        );
      }),
    );
  }
}
