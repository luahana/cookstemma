import 'package:pairing_planet2_frontend/domain/entities/ingredient.dart';

class IngredientDto {
  final String name;
  final String amount;
  final String type; // IngredientType Enum을 String으로 처리

  IngredientDto({required this.name, required this.amount, required this.type});

  factory IngredientDto.fromJson(Map<String, dynamic> json) => IngredientDto(
    name: json['name'],
    amount: json['amount'],
    type: json['type'],
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'amount': amount,
    'type': type,
  };

  Ingredient toEntity() => Ingredient(name: name, amount: amount, type: type);
}
