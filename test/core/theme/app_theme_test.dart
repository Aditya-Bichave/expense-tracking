import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    // Override the asset bundle to prevent Google Fonts from throwing async errors
    // Since Google Fonts tries to load .ttf files which we don't have in tests
    // Actually, setting allowRuntimeFetching = false causes it to throw if font not found.
    // Setting it to true might cause a network request in test which also fails.
    // Let's use GoogleFonts.config.allowRuntimeFetching = false but we need to supply dummy font files
    // or just catch the async errors. We can use a custom FontLoader.
  });

  setUpAll(() {
    final fontLoader = FontLoader('Inter');
    fontLoader.addFont(Future.value(ByteData(0)));
    fontLoader.load();

    final fontLoader2 = FontLoader('Roboto Mono');
    fontLoader2.addFont(Future.value(ByteData(0)));
    fontLoader2.load();

    final fontLoader3 = FontLoader('Quicksand');
    fontLoader3.addFont(Future.value(ByteData(0)));
    fontLoader3.load();
  });

  group('AppTheme Tests', () {
    testWidgets('buildTheme creates expected ThemeData for Elemental', (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false; // Just in case
      final pair = AppTheme.buildTheme(UIMode.elemental, AppTheme.elementalPalette1);
      expect(pair, isNotNull);
      expect(pair.light.brightness, Brightness.light);
      expect(pair.dark.brightness, Brightness.dark);

      final extLight = pair.light.extension<AppModeTheme>();
      expect(extLight, isNotNull);
      final extDark = pair.dark.extension<AppModeTheme>();
      expect(extDark, isNotNull);
    });

    testWidgets('buildTheme creates expected ThemeData for Quantum', (tester) async {
      final pair = AppTheme.buildTheme(UIMode.quantum, AppTheme.quantumPalette1);
      expect(pair.light.brightness, Brightness.light);
      expect(pair.dark.brightness, Brightness.dark);
    });

    testWidgets('buildTheme creates expected ThemeData for Aether', (tester) async {
      final pair = AppTheme.buildTheme(UIMode.aether, AppTheme.aetherPalette1);
      expect(pair.light.brightness, Brightness.light);
      expect(pair.dark.brightness, Brightness.dark);
    });

    testWidgets('buildTheme creates expected ThemeData for Stitch', (tester) async {
      final pair = AppTheme.buildTheme(UIMode.stitch, AppTheme.stitchPalette1);
      expect(pair.light.brightness, Brightness.light);
      expect(pair.dark.brightness, Brightness.dark);
    });
  });
}
