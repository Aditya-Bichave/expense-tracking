import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart'; // Import enum
import 'package:expense_tracker/main.dart'; // Logger

part 'category_model.g.dart';

@JsonSerializable()
@HiveType(typeId: 3) // Keep existing typeId
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
  // --- ADDED Field for Type ---
  @HiveField(6) // New field index
  @JsonKey(required: true, defaultValue: 0) // Default to expense (index 0)
  final int typeIndex; // Store enum index

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorHex,
    required this.isCustom,
    this.parentCategoryId,
    required this.typeIndex, // Added to constructor
  });

  factory CategoryModel.fromEntity(Category entity) {
    return CategoryModel(
      id: entity.id,
      name: entity.name,
      iconName: entity.iconName,
      colorHex: entity.colorHex,
      isCustom: entity.isCustom,
      parentCategoryId: entity.parentCategoryId,
      typeIndex: entity.type.index, // Get index from entity type
    );
  }

  Category toEntity() {
    CategoryType type;
    if (typeIndex >= 0 && typeIndex < CategoryType.values.length) {
      type = CategoryType.values[typeIndex];
    } else {
      log.warning(
        "[CategoryModel] Invalid typeIndex '$typeIndex' for category '$id'. Defaulting to expense.",
      );
      type = CategoryType.expense;
    }
    return Category(
      id: id,
      name: name,
      iconName: iconName,
      colorHex: colorHex,
      isCustom: isCustom,
      parentCategoryId: parentCategoryId,
      type: type,
    );
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryModelToJson(this);
}
