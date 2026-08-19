import 'package:expense_tracker/core/constants/app_constants.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/ui_bridge/bridge_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shows what build the user is actually running, plus the open-source licences
/// of the packages this app ships.
///
/// The version comes from [SettingsBloc], which reads it from PackageInfo at
/// startup; this page renders whatever that load produced, including its failure
/// state, rather than loading it again.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BridgeScaffold(
      appBar: AppBar(title: const Text('About')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              AppConstants.appName,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            BlocBuilder<SettingsBloc, SettingsState>(
              buildWhen: (a, b) =>
                  a.appVersion != b.appVersion ||
                  a.packageInfoStatus != b.packageInfoStatus ||
                  a.packageInfoError != b.packageInfoError,
              builder: (context, state) => Text(
                _versionLabel(state),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Open source licences'),
              subtitle: const Text('Licences of the packages this app uses'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLicences(context),
            ),
            const Divider(height: 1),
          ],
        ),
      ),
    );
  }

  String _versionLabel(SettingsState state) {
    return switch (state.packageInfoStatus) {
      PackageInfoStatus.loading => 'Loading version...',
      PackageInfoStatus.error =>
        state.packageInfoError ?? 'Could not load version',
      _ => 'Version ${state.appVersion ?? 'unknown'}',
    };
  }

  /// Flutter's built-in licence registry, so the list stays correct as
  /// dependencies change instead of being maintained by hand.
  void _showLicences(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: AppConstants.appName,
      applicationIcon: const Padding(
        padding: EdgeInsets.all(8),
        child: Icon(Icons.account_balance_wallet_outlined, size: 48),
      ),
    );
  }
}
