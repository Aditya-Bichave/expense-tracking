import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:go_router/go_router.dart';

class DeepLinkService {
  final AppLinks _appLinks;
  final GoRouter _router;
  StreamSubscription? _linkSubscription;

  DeepLinkService(this._router) : _appLinks = AppLinks();

  void initialize() {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        log.info("[DeepLinkService] Received link: $uri");
        // Handle custom scheme or path
        // GoRouter should handle it automatically if platform passes it.
        // But if we need to force navigation:
        _router.go(uri.path);
      },
      onError: (err) {
        log.severe("[DeepLinkService] Error: $err");
      },
    );
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
