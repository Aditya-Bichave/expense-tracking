import 'dart:js_interop';

@JS('setFlutterReady')
external void _setFlutterReady();

void signalE2EReady() {
  try {
    _setFlutterReady();
  } catch (_) {
    // Ignore if function not found
  }
}
