import 'package:hive_ce/hive.dart';

/// An in-memory [BinaryWriter] that records the exact sequence of calls a
/// generated Hive adapter makes, without touching a real box or the disk.
///
/// Generated adapters only ever use `writeByte` (for the field count and each
/// field index) and `write` (for the value), so recording those two in order is
/// enough to replay them back through [FakeBinaryReader].
class FakeBinaryWriter implements BinaryWriter {
  final List<Object?> ops = <Object?>[];

  @override
  void writeByte(int byte) => ops.add(byte);

  @override
  void write<T>(T value, {bool withTypeId = true}) => ops.add(value);

  @override
  void noSuchMethod(Invocation invocation) {
    throw UnsupportedError(
      'FakeBinaryWriter does not implement ${invocation.memberName}. '
      'Generated adapters should only need writeByte() and write().',
    );
  }
}

/// Replays the calls recorded by [FakeBinaryWriter] back to an adapter's
/// `read`, so a model can be round-tripped without a real Hive box.
class FakeBinaryReader implements BinaryReader {
  FakeBinaryReader(this._ops);

  final List<Object?> _ops;
  int _cursor = 0;

  /// Number of recorded operations not yet consumed.
  int get remaining => _ops.length - _cursor;

  @override
  int readByte() => _ops[_cursor++]! as int;

  @override
  dynamic read([int? typeId]) => _ops[_cursor++];

  @override
  void noSuchMethod(Invocation invocation) {
    throw UnsupportedError(
      'FakeBinaryReader does not implement ${invocation.memberName}. '
      'Generated adapters should only need readByte() and read().',
    );
  }
}

/// Writes [value] through [adapter] and reads it straight back.
///
/// This exercises both halves of a generated adapter and, crucially, proves the
/// field indices written match the field indices read. A mismatched or reused
/// Hive field id — the pitfall called out in AGENTS.md — shows up here as a
/// wrong value or a type cast error rather than as silent data corruption in
/// production.
T roundTrip<T>(TypeAdapter<T> adapter, T value) {
  final writer = FakeBinaryWriter();
  adapter.write(writer, value);
  final reader = FakeBinaryReader(writer.ops);
  final result = adapter.read(reader);
  if (reader.remaining != 0) {
    throw StateError(
      'Adapter ${adapter.runtimeType} wrote ${writer.ops.length} operations '
      'but read only ${writer.ops.length - reader.remaining}. The write() and '
      'read() halves are out of sync.',
    );
  }
  return result;
}

/// The declared field count an adapter writes, i.e. the leading byte.
int declaredFieldCount<T>(TypeAdapter<T> adapter, T value) {
  final writer = FakeBinaryWriter();
  adapter.write(writer, value);
  return writer.ops.first! as int;
}

/// The field indices an adapter writes, in order.
List<int> writtenFieldIndices<T>(TypeAdapter<T> adapter, T value) {
  final writer = FakeBinaryWriter();
  adapter.write(writer, value);
  // Layout is: [count, index0, value0, index1, value1, ...]
  final indices = <int>[];
  for (var i = 1; i < writer.ops.length; i += 2) {
    indices.add(writer.ops[i]! as int);
  }
  return indices;
}
