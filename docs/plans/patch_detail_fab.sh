sed -i "s|canAddExpense|canAddExpense \&\& group != null \&\& group.currency.isNotEmpty|g" lib/features/groups/presentation/pages/group_detail_page.dart
sed -i "s|group?.currency ?? 'USD'|group.currency|g" lib/features/groups/presentation/pages/group_detail_page.dart
