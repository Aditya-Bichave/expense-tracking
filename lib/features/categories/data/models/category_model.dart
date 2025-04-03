// lib/features/categories/data/models/category_model.dart
// MODIFIED FILE
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';

part 'category_model.g.dart'; // CORRECTED: Relative path

@JsonSerializable()
@HiveType(typeId: 3)
class CategoryModel extends HiveObject {
  @HiveField(0)
  @JsonKey(required: true)
  final String id;

  @HiveField(1)
  @JsonKey(required: true)
  final String name;

  @HiveField(2)
  @JsonKey(required: true)
  final String iconName;

  @HiveField(3)
  @JsonKey(required: true)
  final String colorHex;

  @HiveField(4)
  @JsonKey(required: true)
  final bool isCustom;

  @HiveField(5)
  @JsonKey(includeIfNull: false)
  final String? parentCategoryId;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorHex,
    required this.isCustom,
    this.parentCategoryId,
  });

  factory CategoryModel.fromEntity(Category entity) {
    return CategoryModel(
      id: entity.id,
      name: entity.name,
      iconName: entity.iconName,
      colorHex: entity.colorHex,
      isCustom: entity.isCustom,
      parentCategoryId: entity.parentCategoryId,
    );
  }

  Category toEntity() {
    return Category(
      id: id,
      name: name,
      iconName: iconName,
      colorHex: colorHex,
      isCustom: isCustom,
      parentCategoryId: parentCategoryId,
    );
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryModelToJson(this);
}
