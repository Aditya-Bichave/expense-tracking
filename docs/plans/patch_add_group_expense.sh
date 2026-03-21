sed -i "s|final name = isMe ? 'You' : member.userId.substring(0, 6); // Mock name|final name = isMe ? 'You' : member.userId;|g" lib/features/group_expenses/presentation/pages/add_group_expense_page.dart
sed -i "s|final name = isMe ? 'You' : member.userId.substring(0, 6);|final name = isMe ? 'You' : member.userId;|g" lib/features/group_expenses/presentation/pages/add_group_expense_page.dart
