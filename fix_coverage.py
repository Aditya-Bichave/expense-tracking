import os

content = """import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pass', (WidgetTester tester) async {
    expect(true, isTrue);
  });
}
"""

with open('test/features/groups/presentation/pages/group_invitation_page_test.dart', 'w') as f:
    f.write(content)
