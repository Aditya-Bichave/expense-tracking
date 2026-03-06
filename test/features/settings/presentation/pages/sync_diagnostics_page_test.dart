import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/sync/dead_letter_repository.dart';
import 'package:expense_tracker/core/sync/models/dead_letter_model.dart';
import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:expense_tracker/core/sync/sync_service.dart';
import 'package:expense_tracker/features/settings/presentation/pages/sync_diagnostics_page.dart';
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/pump_app.dart';
import 'package:mocktail/mocktail.dart';

class MockDeadLetterRepository extends Mock implements DeadLetterRepository {}

class MockOutboxRepository extends Mock implements OutboxRepository {}

class MockSyncService extends Mock implements SyncService {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      SyncMutationModel(
        id: '1',
        table: 'x',
        operation: OpType.create,
        payload: {},
        createdAt: DateTime.now(),
      ),
    );
  });

  late MockDeadLetterRepository mockDeadLetterRepository;
  late MockOutboxRepository mockOutboxRepository;
  late MockSyncService mockSyncService;

  setUp(() {
    mockDeadLetterRepository = MockDeadLetterRepository();
    mockOutboxRepository = MockOutboxRepository();
    mockSyncService = MockSyncService();

    if (sl.isRegistered<DeadLetterRepository>())
      sl.unregister<DeadLetterRepository>();
    if (sl.isRegistered<OutboxRepository>()) sl.unregister<OutboxRepository>();
    if (sl.isRegistered<SyncService>()) sl.unregister<SyncService>();

    sl.registerSingleton<DeadLetterRepository>(mockDeadLetterRepository);
    sl.registerSingleton<OutboxRepository>(mockOutboxRepository);
    sl.registerSingleton<SyncService>(mockSyncService);
  });

  group('SyncDiagnosticsPage', () {
    testWidgets('shows empty state when no items', (tester) async {
      when(() => mockDeadLetterRepository.getItems()).thenReturn([]);

      await pumpWidgetWithProviders(
        tester: tester,
        widget: const SyncDiagnosticsPage(),
      );

      expect(find.text('No failed sync items.'), findsOneWidget);
    });

    testWidgets('shows items and handles discard', (tester) async {
      final item = DeadLetterModel(
        id: '1',
        table: 'expenses',
        operation: OpType.create,
        payload: {},
        createdAt: DateTime.now(),
        failedAt: DateTime.now(),
        lastError: 'Test error',
        retryCount: 5,
      );

      when(() => mockDeadLetterRepository.getItems()).thenReturn([item]);
      when(
        () => mockDeadLetterRepository.deleteItem(item),
      ).thenAnswer((_) async {});

      await pumpWidgetWithProviders(
        tester: tester,
        widget: const SyncDiagnosticsPage(),
      );
      await tester.pumpAndSettle();

      expect(find.text('Table: expenses'), findsOneWidget);
      expect(find.text('Error: Test error'), findsOneWidget);

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      verify(() => mockDeadLetterRepository.deleteItem(item)).called(1);
    });

    testWidgets('handles retry', (tester) async {
      final item = DeadLetterModel(
        id: '1',
        table: 'expenses',
        operation: OpType.create,
        payload: {},
        createdAt: DateTime.now(),
        failedAt: DateTime.now(),
        lastError: 'Test error',
        retryCount: 5,
      );

      when(() => mockDeadLetterRepository.getItems()).thenReturn([item]);
      when(() => mockOutboxRepository.add(any())).thenAnswer((_) async {});
      when(
        () => mockDeadLetterRepository.deleteItem(item),
      ).thenAnswer((_) async {});
      when(() => mockSyncService.processOutbox()).thenAnswer((_) async {});

      await pumpWidgetWithProviders(
        tester: tester,
        widget: const SyncDiagnosticsPage(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      verify(() => mockOutboxRepository.add(any())).called(1);
      verify(() => mockDeadLetterRepository.deleteItem(item)).called(1);
      verify(() => mockSyncService.processOutbox()).called(1);
    });

    testWidgets('shows payload dialog', (tester) async {
      final item = DeadLetterModel(
        id: '1',
        table: 'expenses',
        operation: OpType.create,
        payload: {'test_key': 'test_value'},
        createdAt: DateTime.now(),
        failedAt: DateTime.now(),
        lastError: 'Test error',
        retryCount: 5,
      );

      when(() => mockDeadLetterRepository.getItems()).thenReturn([item]);

      await pumpWidgetWithProviders(
        tester: tester,
        widget: const SyncDiagnosticsPage(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Payload'));
      await tester.pumpAndSettle();

      expect(find.text('Payload Details'), findsOneWidget);
      expect(find.textContaining('test_key'), findsOneWidget);
    });
  });
}
