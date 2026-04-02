cat << 'INNER_EOF' > /tmp/group_list.patch
--- lib/features/groups/presentation/pages/group_list_page.dart
+++ lib/features/groups/presentation/pages/group_list_page.dart
@@ -102,7 +102,15 @@
             if (state.groups.isEmpty) {
               return RefreshIndicator(
                 onRefresh: () async {
-                  context.read<GroupsBloc>().add(const RefreshGroups());
+                  final bloc = context.read<GroupsBloc>();
+                  bloc.add(const RefreshGroups(showLoading: true));
+                  try {
+                    await bloc.stream.firstWhere(
+                      (s) => s is GroupsLoaded || s is GroupsError,
+                    ).timeout(const Duration(seconds: 3));
+                  } catch (_) {
+                    // Prevent unhandled errors or timeouts
+                  }
                 },
                 child: ListView(
                   physics: const AlwaysScrollableScrollPhysics(),
@@ -130,7 +138,15 @@
             }
             return RefreshIndicator(
               onRefresh: () async {
-                context.read<GroupsBloc>().add(const RefreshGroups());
+                final bloc = context.read<GroupsBloc>();
+                bloc.add(const RefreshGroups(showLoading: true));
+                try {
+                  await bloc.stream.firstWhere(
+                    (s) => s is GroupsLoaded || s is GroupsError,
+                  ).timeout(const Duration(seconds: 3));
+                } catch (_) {
+                  // Prevent unhandled errors or timeouts
+                }
               },
               child: ListView.builder(
                 itemCount: state.groups.length,
INNER_EOF
patch lib/features/groups/presentation/pages/group_list_page.dart < /tmp/group_list.patch
