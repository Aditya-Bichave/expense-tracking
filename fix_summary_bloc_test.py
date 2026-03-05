with open('test/features/analytics/presentation/bloc/summary_bloc_test.dart', 'r') as f:
    content = f.read()

content = content.replace('''  tearDown(() {
    bloc.close();
    dataChangeController.close();
  });''', '''  tearDown(() async {
    await bloc.close();
    await dataChangeController.close();
  });''')

content = content.replace('''      bloc.add(const LoadSummary());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SummaryLoading>(),
          isA<SummaryLoaded>().having((s) => s.summary, 'summary', tSummary),
        ]),
      );''', '''      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SummaryLoading>(),
          isA<SummaryLoaded>().having((s) => s.summary, 'summary', tSummary),
        ]),
      );

      bloc.add(const LoadSummary());
      await future;''')

content = content.replace('''      bloc.add(const LoadSummary());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SummaryLoading>(),
          isA<SummaryError>().having(
            (s) => s.message,
            'message',
            'Could not load summary from local data. cache error',
          ),
        ]),
      );''', '''      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SummaryLoading>(),
          isA<SummaryError>().having(
            (s) => s.message,
            'message',
            'Could not load summary from local data. cache error',
          ),
        ]),
      );

      bloc.add(const LoadSummary());
      await future;''')

content = content.replace('''      bloc.add(const LoadSummary());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SummaryLoading>(),
          isA<SummaryError>().having(
            (s) => s.message,
            'message',
            'An unexpected error occurred loading the summary.',
          ),
        ]),
      );''', '''      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SummaryLoading>(),
          isA<SummaryError>().having(
            (s) => s.message,
            'message',
            'An unexpected error occurred loading the summary.',
          ),
        ]),
      );

      bloc.add(const LoadSummary());
      await future;''')

content = content.replace('''      bloc.add(const LoadSummary());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SummaryLoading>(),
          isA<SummaryError>().having(
            (s) => s.message,
            'message',
            contains(
              'An unexpected error occurred loading summary: Exception: crash',
            ),
          ),
        ]),
      );''', '''      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SummaryLoading>(),
          isA<SummaryError>().having(
            (s) => s.message,
            'message',
            contains(
              'An unexpected error occurred loading summary: Exception: crash',
            ),
          ),
        ]),
      );

      bloc.add(const LoadSummary());
      await future;''')

content = content.replace('''      dataChangeController.add(
        const DataChangedEvent(
          type: DataChangeType.system,
          reason: DataChangeReason.reset,
        ),
      );

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SummaryInitial>(),
          isA<SummaryLoading>(),
          isA<SummaryLoaded>(),
        ]),
      );''', '''      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SummaryInitial>(),
          isA<SummaryLoading>(),
          isA<SummaryLoaded>(),
        ]),
      );

      dataChangeController.add(
        const DataChangedEvent(
          type: DataChangeType.system,
          reason: DataChangeReason.reset,
        ),
      );

      await future;''')

content = content.replace('''      dataChangeController.add(
        const DataChangedEvent(
          type: DataChangeType.expense,
          reason: DataChangeReason.added,
        ),
      );

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SummaryLoading>(), // Forced reload
          isA<SummaryLoaded>(),
        ]),
      );''', '''      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SummaryLoading>(), // Forced reload
          isA<SummaryLoaded>(),
        ]),
      );

      dataChangeController.add(
        const DataChangedEvent(
          type: DataChangeType.expense,
          reason: DataChangeReason.added,
        ),
      );

      await future;''')

with open('test/features/analytics/presentation/bloc/summary_bloc_test.dart', 'w') as f:
    f.write(content)
