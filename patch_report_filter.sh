cat << 'INNER_EOF' > /tmp/report_filter.patch
--- lib/features/reports/presentation/widgets/report_filter_controls.dart
+++ lib/features/reports/presentation/widgets/report_filter_controls.dart
@@ -22,11 +22,15 @@
     if (filterBloc.state.optionsStatus != FilterOptionsStatus.loaded) {
       filterBloc.add(const LoadFilterOptions(forceReload: true));
       // Consider showing a loading indicator briefly or disabling button until loaded
-      await filterBloc.stream.firstWhere(
-        (state) =>
-            state.optionsStatus == FilterOptionsStatus.loaded ||
-            state.optionsStatus == FilterOptionsStatus.error,
-      );
+      try {
+        await filterBloc.stream.firstWhere(
+          (state) =>
+              state.optionsStatus == FilterOptionsStatus.loaded ||
+              state.optionsStatus == FilterOptionsStatus.error,
+        ).timeout(const Duration(seconds: 3));
+      } catch (_) {
+        // Prevent hanging if stream errors or times out
+      }
       if (!context.mounted ||
           filterBloc.state.optionsStatus != FilterOptionsStatus.loaded) {
         return; // Don't show sheet if loading failed or stream closed early
INNER_EOF
patch lib/features/reports/presentation/widgets/report_filter_controls.dart < /tmp/report_filter.patch
