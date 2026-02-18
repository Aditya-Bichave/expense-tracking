import 'package:expense_tracker/features/settlements/data/models/settlement_model.dart';
import 'package:hive_ce/hive.dart';

abstract class SettlementsLocalDataSource {
  Future<void> cacheSettlements(List<SettlementModel> settlements);
  Future<void> addSettlement(SettlementModel settlement);
  List<SettlementModel> getSettlements(String groupId);
}

class SettlementsLocalDataSourceImpl implements SettlementsLocalDataSource {
  final Box<SettlementModel> _box;

  SettlementsLocalDataSourceImpl(this._box);

  @override
  Future<void> cacheSettlements(List<SettlementModel> settlements) async {
    final Map<String, SettlementModel> map = {
      for (var s in settlements) s.id: s,
    };
    await _box.putAll(map);
  }

  @override
  Future<void> addSettlement(SettlementModel settlement) async {
    await _box.put(settlement.id, settlement);
  }

  @override
  List<SettlementModel> getSettlements(String groupId) {
    return _box.values.where((s) => s.groupId == groupId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
