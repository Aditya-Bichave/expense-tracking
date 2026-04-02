cat << 'INNER_EOF' > /tmp/group_balances2.patch
--- lib/features/groups/presentation/widgets/stitch/group_balances_tab.dart
+++ lib/features/groups/presentation/widgets/stitch/group_balances_tab.dart
@@ -57,7 +57,7 @@
               bloc.add(RefreshBalances(widget.groupId));
               try {
                 await bloc.stream.firstWhere(
-                  (s) => s is GroupBalancesLoaded && !(s as GroupBalancesLoaded).isRefreshing || s is GroupBalancesError,
+                  (s) => s is GroupBalancesLoaded && !s.isRefreshing || s is GroupBalancesError,
                 ).timeout(const Duration(seconds: 3));
               } catch (_) {
                 // Prevent unhandled errors or timeouts
INNER_EOF
patch lib/features/groups/presentation/widgets/stitch/group_balances_tab.dart < /tmp/group_balances2.patch
