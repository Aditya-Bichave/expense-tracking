// lib/features/settings/presentation/widgets/about_settings_section.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/settings_list_tile.dart'; // Updated import
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AboutSettingsSection extends StatelessWidget {
  final SettingsState state;
  final bool isLoading;

  const AboutSettingsSection({
    super.key,
    required this.state,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'About'),
        SettingsListTile(
          enabled: !isLoading,
          leadingIcon: Icons.info_outline_rounded,
          title: 'About App',
          subtitle: state.packageInfoStatus == PackageInfoStatus.loading
              ? 'Loading...'
              : state.packageInfoStatus == PackageInfoStatus.error
                  ? state.packageInfoError ?? 'Error'
                  : state.appVersion ?? 'N/A',
          trailing: Icon(Icons.chevron_right,
              color: isLoading
                  ? theme.disabledColor
                  : theme.colorScheme.onSurfaceVariant),
          onTap: isLoading
              ? null
              : () => context.pushNamed(RouteNames.settingsAbout),
        ),
        // Optional Logout
        SettingsListTile(
          enabled: !isLoading, // Enable when auth is implemented
          leadingIcon: Icons.logout_rounded,
          title: 'Logout',
          onTap: isLoading
              ? null
              : () {
                  log.warning("Logout functionality not implemented.");
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Logout (Not Implemented)")));
                },
        ),
      ],
    );
  }
}
