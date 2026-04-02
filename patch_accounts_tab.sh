cat << 'INNER_EOF' > /tmp/accounts_tab.patch
--- lib/features/accounts/presentation/pages/accounts_tab_page.dart
+++ lib/features/accounts/presentation/pages/accounts_tab_page.dart
@@ -85,9 +85,13 @@
         onRefresh: () async {
           final bloc = context.read<AccountListBloc>();
           bloc.add(const LoadAccounts(forceReload: true));
-          await bloc.stream.firstWhere(
-            (state) => state is! AccountListLoading || !state.isReloading,
-          );
+          try {
+            await bloc.stream.firstWhere(
+              (state) => state is! AccountListLoading || !state.isReloading,
+            ).timeout(const Duration(seconds: 3));
+          } catch (_) {
+            // Prevent hanging on error
+          }
         },
         child: ListView(
           padding:
INNER_EOF
patch lib/features/accounts/presentation/pages/accounts_tab_page.dart < /tmp/accounts_tab.patch
