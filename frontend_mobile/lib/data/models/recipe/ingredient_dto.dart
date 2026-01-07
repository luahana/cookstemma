import 'package:json_annotation/json_annotation.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/ingredient.dart';

part 'ingredient_dto.g.dart'; // 💡 반드시 파일명과 일치해야 함

enum IngredientType { MAIN, SECONDARY, SEASONING }

@JsonSerializable()
class IngredientDto {
  final String name;
  final String? amount;
  final IngredientType type; // 💡 String 대신 Enum 사용 권장

  IngredientDto({required this.name, required this.amount, required this.type});

  factory IngredientDto.fromJson(Map<String, dynamic> json) =>
      _$IngredientDtoFromJson(json);
  Map<String, dynamic> toJson() => _$IngredientDtoToJson(this);

  Ingredient toEntity() => Ingredient(
    name: name,
    amount: amount,
    type: type.name, // Entity에는 문자열로 전달
  );

  factory IngredientDto.fromEntity(Ingredient ingredient) {
    return IngredientDto(
      name: ingredient.name,
      amount: ingredient.amount,
      type: IngredientType.values.firstWhere(
        (e) => e.name == ingredient.type,
        orElse: () => IngredientType.MAIN,
      ),
    );
  }
}
