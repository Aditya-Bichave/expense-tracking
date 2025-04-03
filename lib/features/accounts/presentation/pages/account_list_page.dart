// lib/features/accounts/presentation/pages/account_list_page.dart
import 'package:expense_tracker/core/common/generic_list_page.dart'; // Import Generic List Page
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart'; // Import AssetKeys
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_card.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // For theme access
import 'package:expense_tracker/main.dart'; // logger
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // For context.read
import 'package:flutter_svg/svg.dart';
import 'package:expense_tracker/core/assets/app_assets.dart';
import 'package:go_router/go_router.dart'; // Default assets
import 'package:expense_tracker/core/utils/app_dialogs.dart';

class AccountListPage extends StatelessWidget {
  const AccountListPage({super.key});

  // --- Specific Builders for Accounts ---

  Widget _buildAccountItem(
      BuildContext context, AssetAccount item, VoidCallback onTapEdit) {
    // AccountCard needs AccountListBloc provided higher up (GenericListPage does this)
    return AccountCard(account: item, onTap: onTapEdit);
  }

  Widget _buildEmptyState(BuildContext context, bool filtersApplied) {
    // filtersApplied will be false here since filtering isn't enabled
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;
    // Use appropriate illustration key
    String illustrationKey = AssetKeys.illuEmptyWallet;
    String defaultIllustration = AppAssets.elIlluEmptyWallet; // Example default

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
              // Button to add first account
              icon: const Icon(Icons.add),
              label: const Text('Add First Account'),
              // Navigate using the route name defined in GenericListPage constructor
              onPressed: () => context.pushNamed(RouteNames.addAccount),
            )
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmAccountDeletion(
      BuildContext context, AssetAccount item) async {
    // Reusing the generic confirmation dialog logic
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
    // Instantiate GenericListPage with Account-specific types and builders
    return GenericListPage<AssetAccount, AccountListBloc, AccountListEvent,
        AccountListState>(
      pageTitle: 'Accounts',
      addRouteName: RouteNames.addAccount,
      editRouteName: RouteNames.editAccount,
      itemHeroTagPrefix: 'account', // Prefix for keys
      fabHeroTag: 'fab_accounts', // Unique FAB tag
      // Provide the specific builders and event creators
      itemBuilder: _buildAccountItem,
      tableBuilder: null, // No table view for accounts
      emptyStateBuilder: _buildEmptyState,
      filterDialogBuilder: null, // No filtering for accounts
      deleteConfirmationBuilder: _confirmAccountDeletion,
      // Lambdas to create the correct event types
      deleteEventBuilder: (id) => DeleteAccountRequested(id),
      loadEventBuilder: ({bool forceReload = false}) =>
          LoadAccounts(forceReload: forceReload),
      showSummaryCard:
          false, // Accounts page doesn't need the expense summary card
    );
  }
}
