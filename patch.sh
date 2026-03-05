sed -i '/<<<<<<< Updated upstream/d' lib/features/transactions/presentation/bloc/transaction_list_bloc.dart
sed -i '/=======/d' lib/features/transactions/presentation/bloc/transaction_list_bloc.dart
sed -i '/final currentTransactionsMap = {for (var t in state.transactions) t.id: t};/d' lib/features/transactions/presentation/bloc/transaction_list_bloc.dart
sed -i '/for (final id in state.selectedTransactionIds) {/d' lib/features/transactions/presentation/bloc/transaction_list_bloc.dart
sed -i '/final txn = currentTransactionsMap\[id\];/d' lib/features/transactions/presentation/bloc/transaction_list_bloc.dart
sed -i '/>>>>>>> Stashed changes/d' lib/features/transactions/presentation/bloc/transaction_list_bloc.dart
