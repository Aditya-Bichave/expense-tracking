sed -i "1s|^|import 'package:expense_tracker/features/group_expenses/presentation/pages/add_group_expense_page.dart';\n|" test/features/groups/presentation/pages/group_detail_page_test.dart
sed -i "s|expect(find.text('Edit expense coming soon'), findsOneWidget);|expect(find.byType(AddGroupExpensePage), findsOneWidget);|g" test/features/groups/presentation/pages/group_detail_page_test.dart
sed -i "s|tapping an expense shows the placeholder edit feedback for members|tapping an expense routes to AddGroupExpensePage|g" test/features/groups/presentation/pages/group_detail_page_test.dart
