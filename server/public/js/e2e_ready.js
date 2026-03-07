window.E2E_FLUTTER_READY = false;
window.setFlutterReady = function() {
  window.E2E_FLUTTER_READY = true;
  console.log('[E2E] Flutter app signals ready state');
};
