import 'package:expense_tracker/features/groups/presentation/widgets/stitch/group_invitation_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GroupInvitationCard renders correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: GroupInvitationCard())),
    );

    expect(find.text("YOU'RE INVITED"), findsOneWidget);
    expect(find.text('Europe Tour'), findsOneWidget);
    expect(find.text('Join Group'), findsOneWidget);
  });
}
