import 'package:expense_tracker/features/groups/data/datasources/groups_local_data_source.dart';
import 'package:expense_tracker/features/groups/data/models/group_model.dart';
import 'package:expense_tracker/features/groups/data/models/group_member_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockBoxGroup extends Mock implements Box<GroupModel> {}

class MockBoxMember extends Mock implements Box<GroupMemberModel> {}

class FakeGroupModel extends Fake implements GroupModel {}

class FakeGroupMemberModel extends Fake implements GroupMemberModel {}

void main() {
  late GroupsLocalDataSourceImpl dataSource;
  late MockBoxGroup mockGroupBox;
  late MockBoxMember mockMemberBox;

  setUpAll(() {
    registerFallbackValue(FakeGroupModel());
    registerFallbackValue(FakeGroupMemberModel());
  });

  setUp(() {
    mockGroupBox = MockBoxGroup();
    mockMemberBox = MockBoxMember();
    dataSource = GroupsLocalDataSourceImpl(mockGroupBox, mockMemberBox);
  });

  final tDate = DateTime(2023, 1, 1);
  final tGroupModel = GroupModel(
    id: '1',
    name: 'Test Group',
    createdBy: 'user1',
    createdAt: tDate,
    updatedAt: tDate,
    typeValue: 'custom',
    currency: 'USD',
  );

  final tGroupMemberModel = GroupMemberModel(
    id: 'm1',
    groupId: '1',
    userId: 'user1',
    roleValue: 'owner',
    joinedAt: tDate,
    updatedAt: tDate,
  );

  group('GroupsLocalDataSource', () {
    test('saveGroup should put group in box', () async {
      when(() => mockGroupBox.put(any(), any())).thenAnswer((_) async {});
      await dataSource.saveGroup(tGroupModel);
      verify(() => mockGroupBox.put(tGroupModel.id, tGroupModel)).called(1);
    });

    test('saveGroups should put all groups in box', () async {
      // Use explicit type check to help mocktail
      when(() => mockGroupBox.putAll(any())).thenAnswer((_) async {});
      await dataSource.saveGroups([tGroupModel]);
      verify(
        () => mockGroupBox.putAll({tGroupModel.id: tGroupModel}),
      ).called(1);
    });

    test('getGroups should return values from box', () {
      when(() => mockGroupBox.values).thenReturn([tGroupModel]);
      final result = dataSource.getGroups();
      expect(result, equals([tGroupModel]));
    });

    test('saveGroupMembers should put all members in box', () async {
      when(() => mockMemberBox.putAll(any())).thenAnswer((_) async {});
      await dataSource.saveGroupMembers([tGroupMemberModel]);
      verify(
        () => mockMemberBox.putAll({tGroupMemberModel.id: tGroupMemberModel}),
      ).called(1);
    });

    test('getGroupMembers should return members for specific group', () {
      final otherMember = GroupMemberModel(
        id: 'm2',
        groupId: '2',
        userId: 'user2',
        roleValue: 'member',
        joinedAt: tDate,
        updatedAt: tDate,
      );
      when(
        () => mockMemberBox.values,
      ).thenReturn([tGroupMemberModel, otherMember]);

      final result = dataSource.getGroupMembers('1');
      expect(result, equals([tGroupMemberModel]));
      expect(result, isNot(contains(otherMember)));
    });
  });
}
