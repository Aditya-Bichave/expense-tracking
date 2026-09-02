import 'dart:io';

void main() {
  final file = File(
    'lib/features/transactions/presentation/bloc/transaction_list_bloc.dart',
  );
  var content = file.readAsStringSync();

  content = content.replaceAll(
    '''
        final validSelection = state.isInBatchEditMode
            ? state.selectedTransactionIds
                  .where((id) => transactionIds.contains(id))
                  .toSet()
            : <String>{};''',
    '''
        // ⚡ Bolt Performance Optimization
        // Problem: `where(...).toSet()` iterates the collection to create a new Set.
        // Solution: Use `.intersection(transactionIds)` directly on the Set.
        // Impact: O(min(N, M)) set intersection is significantly faster and allocates less memory.
        final validSelection = state.isInBatchEditMode
            ? state.selectedTransactionIds.intersection(transactionIds)
            : <String>{};''',
  );

  file.writeAsStringSync(content);
  print('done');
}
