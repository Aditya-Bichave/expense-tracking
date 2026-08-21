import 'package:expense_tracker/core/services/clock.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/auth/session_cubit.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/e2e_ready.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:expense_tracker/features/deep_link/presentation/bloc/deep_link_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// How long the app may sit in the background before the session is
/// re-validated on resume.
const _sessionRevalidateAfter = Duration(seconds: 60);

/// The routed [MaterialApp] and the app-level concerns that wrap it: theming
/// from [SettingsBloc], session re-validation on resume, and deep-link
/// navigation.
class RootApp extends StatefulWidget {
  final Clock? clock;
  const RootApp({super.key, this.clock});

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> with WidgetsBindingObserver {
  DateTime? _pausedAt;
  bool _signalledE2EReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _pausedAt =
            (widget.clock ??
                    (sl.isRegistered<Clock>() ? sl<Clock>() : SystemClock()))
                .now();
      case AppLifecycleState.resumed:
        _revalidateSessionIfStale();
      default:
        break;
    }
  }

  /// A short backgrounding (switching apps, answering a notification) should
  /// not cost the user a session check; only a long one is treated as stale.
  void _revalidateSessionIfStale() {
    final pausedAt = _pausedAt;
    _pausedAt = null;
    if (pausedAt == null) return;

    final now =
        (widget.clock ??
                (sl.isRegistered<Clock>() ? sl<Clock>() : SystemClock()))
            .now();
    final backgrounded = now.difference(pausedAt);
    if (backgrounded >= _sessionRevalidateAfter) {
      context.read<SessionCubit>().checkSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsBloc>().state;
    final themes = AppTheme.buildTheme(
      settings.uiMode,
      settings.paletteIdentifier,
    );

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: themes.light,
      darkTheme: themes.dark,
      themeMode: settings.themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
      builder: (context, child) {
        _scheduleE2EReadySignal();
        if (child == null) {
          log.severe('Error: child route is null.');
          return const Scaffold(
            body: Center(child: Text('Error: Route failed to build.')),
          );
        }
        return _DeepLinkListener(child: child);
      },
    );
  }

  /// The E2E harness waits for a single "app is ready" signal. `builder` runs on
  /// every rebuild, so this guards against re-signalling on each theme or
  /// settings change.
  void _scheduleE2EReadySignal() {
    if (_signalledE2EReady) return;
    _signalledE2EReady = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => signalE2EReady());
  }
}

/// Surfaces deep-link outcomes as snack bars and navigates into the joined
/// group on success.
class _DeepLinkListener extends StatelessWidget {
  const _DeepLinkListener({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeepLinkBloc, DeepLinkState>(
      listener: _onDeepLink,
      child: child,
    );
  }

  void _onDeepLink(BuildContext context, DeepLinkState state) {
    switch (state) {
      case DeepLinkSuccess(:final groupId, :final groupName):
        _showMessage(context, 'Joined ${groupName ?? 'group'}');
        AppRouter.router.go('${RouteNames.groups}/$groupId');
      case DeepLinkError(:final message):
        _showMessage(context, message);
      default:
        break;
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
