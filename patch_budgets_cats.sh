cat << 'INNER_EOF' > /tmp/budgets_cats.patch
--- lib/features/budgets_cats/presentation/pages/budgets_sub_tab.dart
+++ lib/features/budgets_cats/presentation/pages/budgets_sub_tab.dart
@@ -124,9 +124,13 @@
               final bloc = context.read<BudgetListBloc>();
               bloc.add(const LoadBudgets(forceReload: true));
               // Wait until the loading state completes
-              await bloc.stream.firstWhere(
-                (s) => s.status != BudgetListStatus.loading,
-              );
+              try {
+                await bloc.stream.firstWhere(
+                  (s) => s.status != BudgetListStatus.loading,
+                ).timeout(const Duration(seconds: 3));
+              } catch (_) {
+                // Prevent unhandled errors or timeouts
+              }
             },
             child: content,
           );
INNER_EOF
patch lib/features/budgets_cats/presentation/pages/budgets_sub_tab.dart < /tmp/budgets_cats.patch
