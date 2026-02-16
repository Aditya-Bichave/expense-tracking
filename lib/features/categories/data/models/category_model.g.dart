// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CategoryModelAdapter extends TypeAdapter<CategoryModel> {
  @override
  final typeId = 3;

  @override
  CategoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoryModel(
      id: fields[0] as String,
      name: fields[1] as String,
      iconName: fields[2] as String,
      colorHex: fields[3] as String,
      isCustom: fields[4] as bool,
      parentCategoryId: fields[5] as String?,
      typeIndex: (fields[6] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, CategoryModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.iconName)
      ..writeByte(3)
      ..write(obj.colorHex)
      ..writeByte(4)
      ..write(obj.isCustom)
      ..writeByte(5)
      ..write(obj.parentCategoryId)
      ..writeByte(6)
      ..write(obj.typeIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryModel _$CategoryModelFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'id',
      'name',
      'iconName',
      'colorHex',
      'isCustom',
      'typeIndex',
    ],
  );
  return CategoryModel(
    id: json['id'] as String,
    name: json['name'] as String,
    iconName: json['iconName'] as String,
    colorHex: json['colorHex'] as String,
    isCustom: json['isCustom'] as bool,
    parentCategoryId: json['parentCategoryId'] as String?,
    typeIndex: (json['typeIndex'] as num?)?.toInt() ?? 0,
  );
}

Map<String, dynamic> _$CategoryModelToJson(CategoryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'iconName': instance.iconName,
      'colorHex': instance.colorHex,
      'isCustom': instance.isCustom,
      'parentCategoryId': ?instance.parentCategoryId,
      'typeIndex': instance.typeIndex,
    };
