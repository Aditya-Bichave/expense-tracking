import 'dart:io';

import 'package:expense_tracker/core/services/secure_storage_service.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/ui_bridge/bridge_circular_progress_indicator.dart';
import 'package:expense_tracker/ui_bridge/bridge_elevated_button.dart';
import 'package:expense_tracker/ui_bridge/bridge_scaffold.dart';
import 'package:expense_tracker/ui_bridge/bridge_text_style.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Last-resort UI shown when [AppInitializer] fails, in place of the real app.
///
/// This runs *outside* the service locator and the normal widget tree — nothing
/// it needs may come from `sl` or a bloc, because the failure it reports may be
/// that those were never built.
///
/// [theme] exists so tests can inject a plain [ThemeData] and avoid runtime
/// font fetching.
class InitializationErrorApp extends StatefulWidget {
  const InitializationErrorApp({super.key, required this.error, this.theme});

  final Object error;
  final ThemeData? theme;

  @override
  State<InitializationErrorApp> createState() => _InitializationErrorAppState();
}

class _InitializationErrorAppState extends State<InitializationErrorApp> {
  bool _isResetting = false;

  /// Clears the encryption key and the on-disk Hive files so the next launch
  /// starts from a clean slate. Destroys all local data — offered because the
  /// alternative, for a corrupted key, is an app that can never start.
  Future<void> _resetApp() async {
    setState(() => _isResetting = true);
    try {
      await SecureStorageService().clearAll();
      await _deleteLocalDatabaseFiles();
      _showMessage(
        'Data reset successfully. Please restart the app manually.',
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      _showMessage('Reset failed: $e');
    } finally {
      if (mounted) setState(() => _isResetting = false);
    }
  }

  Future<void> _deleteLocalDatabaseFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final entries = await dir.list().toList();
    await Future.wait(entries.map(_deleteIfDatabaseFile));
  }

  /// A file that cannot be deleted is logged and skipped: the reset should
  /// remove everything it can rather than abort on the first locked file.
  Future<void> _deleteIfDatabaseFile(FileSystemEntity entry) async {
    final path = entry.path;
    if (!path.endsWith('.hive') && !path.endsWith('.lock')) return;
    try {
      await entry.delete();
    } catch (e, s) {
      log.severe('Failed to delete $path during reset: $e\n$s');
    }
  }

  void _showMessage(String message, {Duration? duration}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only build the real theme when no test theme was injected — constructing
    // it pulls in font loading, which tests deliberately avoid.
    final fallback = widget.theme == null
        ? AppTheme.buildTheme(
            SettingsState.defaultUIMode,
            SettingsState.defaultPaletteIdentifier,
          )
        : null;

    return MaterialApp(
      theme: widget.theme ?? fallback!.light,
      darkTheme: widget.theme ?? fallback!.dark,
      themeMode: SettingsState.defaultThemeMode,
      home: BridgeScaffold(
        body: Builder(
          builder: (context) => Center(
            child: Padding(
              padding: context.space.allXxl,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade700,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  _title(),
                  const SizedBox(height: 12),
                  _details(),
                  const SizedBox(height: 24),
                  _resetSection(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _title() => Text(
    'Application Initialization Failed',
    textAlign: TextAlign.center,
    style: BridgeTextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.red.shade900,
    ),
  );

  Widget _details() => Text(
    'A critical error occurred during startup:\n\n${widget.error}\n\n'
    'Please restart the app. If the problem persists, contact support or '
    'check logs.',
    textAlign: TextAlign.center,
    style: const BridgeTextStyle(fontSize: 14),
  );

  Widget _resetSection(BuildContext context) => Column(
    children: [
      const Text(
        'Your encryption key appears to be corrupted. You can reset the app '
        'data to recover, but all local data will be lost.',
        textAlign: TextAlign.center,
        style: BridgeTextStyle(color: Color(0xFFD32F2F)),
      ),
      const SizedBox(height: 16),
      if (_isResetting)
        const BridgeCircularProgressIndicator()
      else
        BridgeElevatedButton(
          onPressed: _resetApp,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.kit.colors.danger,
            foregroundColor: context.kit.colors.surface,
          ),
          child: const Text('Reset App Data'),
        ),
    ],
  );
}
