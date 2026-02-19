import 'package:expense_tracker/features/groups/presentation/widgets/stitch/group_detail_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GroupDetailHeader renders correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: GroupDetailHeader())),
    );

    expect(find.text('GROUP SPEND'), findsOneWidget);
    expect(find.text('\$2,450.00'), findsOneWidget);
    expect(find.text('You are owed'), findsOneWidget);
    expect(find.text('Settle Up'), findsOneWidget);
  });
}
