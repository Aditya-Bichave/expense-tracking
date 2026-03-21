sed -i "1s|^|import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_event.dart';\nimport 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_state.dart';\n|" lib/features/groups/presentation/pages/group_detail_page.dart
sed -i 's|groupCurrency:|currency:|g' lib/features/groups/presentation/pages/group_detail_page.dart
