// ... other imports ...
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_card.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:expense_tracker/core/assets/app_assets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';

class AccountListPage extends StatelessWidget {
  const AccountListPage({super.key});

  void _navigateToEditAccount(BuildContext context, AssetAccount account) {
    log.info("[AccountListPage] Navigating to Edit Account ID: ${account.id}");
    context.pushNamed(
      RouteNames.editAccount,
      pathParameters: {RouteNames.paramAccountId: account.id},
      extra: account,
    );
  }

  // --- CORRECTED: Return Future<bool> ---
  Future<bool> _handleDelete(BuildContext context, AssetAccount item) async {
    final confirmed = await AppDialogs.showConfirmation(
      context,
      title: AppLocalizations.of(context)!.confirmDeletion,
      content: AppLocalizations.of(
        context,
      )!.deleteAccountConfirmation(item.name),
      confirmText: AppLocalizations.of(context)!.delete,
      confirmColor: Theme.of(context).colorScheme.error,
    );
    // Return the result (true if confirmed, false or null otherwise)
    // Default to false if dialog is dismissed without selection
    if (confirmed == true && context.mounted) {
      context.read<AccountListBloc>().add(DeleteAccountRequested(item.id));
      return true; // Indicate dismissal should proceed
    }
    return false; // Indicate dismissal should not proceed
  }
  // --- END CORRECTION ---

  Widget _buildEmptyState(BuildContext context) {
    // ... empty state implementation (no changes needed) ...
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;
    String illustrationKey = AssetKeys.illuEmptyWallet;
    String defaultIllustration = AppAssets.elIlluEmptyWallet;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              modeTheme?.assets.getIllustration(
                    illustrationKey,
                    defaultPath: defaultIllustration,
                  ) ??
                  defaultIllustration,
              height: 120,
              colorFilter: ColorFilter.mode(
                theme.colorScheme.secondary.withOpacity(0.8),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.noAccountsYet,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.addAccountEmptyDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.addFirstAccount),
              onPressed: () => context.pushNamed(RouteNames.addAccount),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
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

    return BlocProvider<AccountListBloc>(
      create: (_) => sl<AccountListBloc>()..add(const LoadAccounts()),
      child: Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.accounts)),
        body: BlocConsumer<AccountListBloc, AccountListState>(
          listener: (context, state) {
            if (state is AccountListError) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
            }
          },
          builder: (context, state) {
            Widget bodyContent;

            // --- CORRECTED: Access 'items' only on AccountListLoaded state ---
            if (state is AccountListLoading && !state.isReloading) {
              bodyContent = const Center(child: CircularProgressIndicator());
            } else if (state is AccountListLoaded ||
                (state is AccountListLoading && state.isReloading)) {
              // Determine the list to display (current or previous if reloading)
              List<AssetAccount> accounts = [];
              if (state is AccountListLoaded) {
                accounts =
                    state.items; // Access items directly from loaded state
              } else if (state is AccountListLoading && state.isReloading) {
                // Try to get previous state data if available
                final previousState = context.read<AccountListBloc>().state;
                if (previousState is AccountListLoaded) {
                  accounts = previousState.items;
                }
              }

              if (accounts.isEmpty &&
                  !(state is AccountListLoading && state.isReloading)) {
                // Avoid showing empty state during reload flicker
                bodyContent = _buildEmptyState(context);
              } else {
                bodyContent = RefreshIndicator(
                  onRefresh: () async {
                    context.read<AccountListBloc>().add(
                      const LoadAccounts(forceReload: true),
                    );
                    await context.read<AccountListBloc>().stream.firstWhere(
                      (s) => s is! AccountListLoading || !s.isReloading,
                    );
                  },
                  child: ListView.builder(
                    padding:
                        modeTheme?.pagePadding.copyWith(top: 8, bottom: 80) ??
                        const EdgeInsets.only(top: 8.0, bottom: 80.0),
                    itemCount: accounts.length,
                    itemBuilder: (ctx, index) {
                      final account = accounts[index];
                      return Dismissible(
                        key: Key('account_dismiss_${account.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          /* ... background ... */
                          color: theme.colorScheme.errorContainer,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.delete,
                                style: TextStyle(
                                  color: theme.colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.delete_sweep_outlined,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ],
                          ),
                        ),
                        // --- CORRECTED: Pass the Future<bool> function ---
                        confirmDismiss: (_) => _handleDelete(context, account),
                        // --- END CORRECTION ---
                        child:
                            AccountCard(
                                  account: account,
                                  onTap: () =>
                                      _navigateToEditAccount(context, account),
                                )
                                .animate(delay: (50 * index).ms)
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.2, curve: Curves.easeOut),
                      );
                    },
                  ),
                );
              }
            } else if (state is AccountListError) {
              bodyContent = Center(
                /* ... error display ... */
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.error,
                        size: 50,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.errorLoadingAccounts,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: Text(AppLocalizations.of(context)!.retry),
                        onPressed: () => context.read<AccountListBloc>().add(
                          const LoadAccounts(forceReload: true),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              bodyContent = const Center(child: CircularProgressIndicator());
            }

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: KeyedSubtree(
                // --- CORRECTED: Use concrete state type for key ---
                key: ValueKey(
                  state.runtimeType.toString() +
                      (state is AccountListLoaded
                          ? state.items.length.toString()
                          : ''),
                ),
                // --- END CORRECTION ---
                child: bodyContent,
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab_accounts',
          onPressed: () => context.pushNamed(RouteNames.addAccount),
          tooltip: AppLocalizations.of(context)!.addAccount,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
