cat << 'INNER_EOF' > /tmp/group_balances3.patch
--- lib/features/groups/presentation/widgets/stitch/group_balances_tab.dart
+++ lib/features/groups/presentation/widgets/stitch/group_balances_tab.dart
@@ -62,7 +62,7 @@
                     .firstWhere(
                       (s) =>
                           s is GroupBalancesLoaded &&
-                              !(s as GroupBalancesLoaded).isRefreshing ||
+                              !s.isRefreshing ||
                           s is GroupBalancesError,
                     )
                     .timeout(const Duration(seconds: 3));
INNER_EOF
patch lib/features/groups/presentation/widgets/stitch/group_balances_tab.dart < /tmp/group_balances3.patch
