import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/di/service_configurations/sync_dependencies.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/sync/dead_letter_repository.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:expense_tracker/core/sync/models/dead_letter_model.dart';
import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:expense_tracker/features/groups/data/models/group_member_model.dart';
import 'package:expense_tracker/features/groups/data/models/group_model.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockBox<T> extends Mock implements Box<T> {}

void main() {
  test('SyncDependencies registers dependencies correctly', () {
    sl.reset();

    final mockOutboxBox = MockBox<SyncMutationModel>();
    final mockDeadLetterBox = MockBox<DeadLetterModel>();
    final mockGroupBox = MockBox<GroupModel>();
    final mockGroupMemberBox = MockBox<GroupMemberModel>();

    sl.registerSingleton<Box<SyncMutationModel>>(mockOutboxBox);
    sl.registerSingleton<Box<DeadLetterModel>>(mockDeadLetterBox);
    sl.registerSingleton<Box<GroupModel>>(mockGroupBox);
    sl.registerSingleton<Box<GroupMemberModel>>(mockGroupMemberBox);

    SyncDependencies.register();

    expect(sl.isRegistered<OutboxRepository>(), isTrue);
    expect(sl.isRegistered<DeadLetterRepository>(), isTrue);

    sl.reset();
  });
}
