import 'package:expense_tracker/features/aether_themes/presentation/widgets/personal_constellation_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PersonalConstellationWidget renders placeholder text', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PersonalConstellationWidget()),
    );

    expect(
      find.text('Personal Constellation Dashboard\n(Coming Soon!)'),
      findsOneWidget,
    );
    expect(find.byType(Text), findsOneWidget);

    final textWidget = tester.widget<Text>(
      find.text('Personal Constellation Dashboard\n(Coming Soon!)'),
    );
    expect(textWidget.style?.color, Colors.blueAccent);
  });
}
