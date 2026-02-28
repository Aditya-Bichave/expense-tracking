import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

void main() {
  group('SectionHeader', () {
    testWidgets('renders title in uppercase', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SectionHeader(title: 'My Title')),
        ),
      );

      expect(find.text('MY TITLE'), findsOneWidget);
    });

    testWidgets('applies custom padding', (tester) async {
      const padding = context.space.allXl;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(title: 'Title', padding: padding),
          ),
        ),
      );

      final paddingWidget = tester.widget<Padding>(find.byType(Padding));
      expect(paddingWidget.padding, padding);
    });

    testWidgets('applies correct styling from theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            textTheme: const TextTheme(labelMedium: TextStyle(fontSize: 12)),
          ),
          home: const Scaffold(body: SectionHeader(title: 'Title')),
        ),
      );

      final text = tester.widget<Text>(find.text('TITLE'));
      expect(text.style?.fontWeight, FontWeight.bold);
      expect(text.style?.letterSpacing, 0.8);
      // Colors are dependent on theme, but ensuring style is applied is good enough
    });
  });
}
