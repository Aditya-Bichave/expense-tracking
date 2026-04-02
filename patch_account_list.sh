cat << 'INNER_EOF' > /tmp/account_list.patch
--- lib/features/accounts/presentation/pages/account_list_page.dart
+++ lib/features/accounts/presentation/pages/account_list_page.dart
@@ -167,9 +167,13 @@
                   onRefresh: () async {
                     final bloc = context.read<AccountListBloc>();
                     bloc.add(const LoadAccounts(forceReload: true));
-                    await bloc.stream.firstWhere(
-                      (s) => s is! AccountListLoading || !s.isReloading,
-                    );
+                    try {
+                      await bloc.stream.firstWhere(
+                        (s) => s is! AccountListLoading || !s.isReloading,
+                      ).timeout(const Duration(seconds: 3));
+                    } catch (_) {
+                      // Prevent hanging on error
+                    }
                   },
                   child: ListView.builder(
                     padding:
INNER_EOF
patch lib/features/accounts/presentation/pages/account_list_page.dart < /tmp/account_list.patch
