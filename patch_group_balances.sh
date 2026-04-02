cat << 'INNER_EOF' > /tmp/group_balances.patch
--- lib/features/groups/presentation/widgets/stitch/group_balances_tab.dart
+++ lib/features/groups/presentation/widgets/stitch/group_balances_tab.dart
@@ -53,9 +53,15 @@

           return RefreshIndicator(
             onRefresh: () async {
-              context.read<GroupBalancesBloc>().add(
-                RefreshBalances(widget.groupId),
-              );
+              final bloc = context.read<GroupBalancesBloc>();
+              bloc.add(RefreshBalances(widget.groupId));
+              try {
+                await bloc.stream.firstWhere(
+                  (s) => s is GroupBalancesLoaded && !(s as GroupBalancesLoaded).isRefreshing || s is GroupBalancesError,
+                ).timeout(const Duration(seconds: 3));
+              } catch (_) {
+                // Prevent unhandled errors or timeouts
+              }
             },
             child: ListView(
               padding: const EdgeInsets.all(16.0),
INNER_EOF
patch lib/features/groups/presentation/widgets/stitch/group_balances_tab.dart < /tmp/group_balances.patch
