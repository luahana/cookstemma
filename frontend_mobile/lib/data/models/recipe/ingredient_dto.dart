import 'package:json_annotation/json_annotation.dart';
import 'package:pairing_planet2_frontend/domain/entities/recipe/ingredient.dart';

part 'ingredient_dto.g.dart';

enum IngredientType {
  @JsonValue('MAIN')
  main,
  @JsonValue('SECONDARY')
  secondary,
  @JsonValue('SEASONING')
  seasoning,
}

/// Measurement units for recipe ingredients.
/// Must match backend MeasurementUnit enum.
enum MeasurementUnit {
  // Volume - Metric
  @JsonValue('ML')
  ml,
  @JsonValue('L')
  l,

  // Volume - US
  @JsonValue('TSP')
  tsp,
  @JsonValue('TBSP')
  tbsp,
  @JsonValue('CUP')
  cup,
  @JsonValue('FL_OZ')
  flOz,
  @JsonValue('PINT')
  pint,
  @JsonValue('QUART')
  quart,

  // Weight - Metric
  @JsonValue('G')
  g,
  @JsonValue('KG')
  kg,

  // Weight - Imperial
  @JsonValue('OZ')
  oz,
  @JsonValue('LB')
  lb,

  // Count/Other
  @JsonValue('PIECE')
  piece,
  @JsonValue('PINCH')
  pinch,
  @JsonValue('DASH')
  dash,
  @JsonValue('TO_TASTE')
  toTaste,
  @JsonValue('CLOVE')
  clove,
  @JsonValue('BUNCH')
  bunch,
  @JsonValue('CAN')
  can,
  @JsonValue('PACKAGE')
  package,
}

/// User preference for displaying measurement units.
enum MeasurementPreference {
  @JsonValue('METRIC')
  metric,
  @JsonValue('US')
  us,
  @JsonValue('ORIGINAL')
  original,
}

@JsonSerializable()
class IngredientDto {
  final String name;

  /// Legacy amount field - free-text like "2 cups" or "a pinch".
  /// For backward compatibility. New clients should use quantity + unit.
  final String? amount;

  /// Numeric quantity for structured measurements (e.g., 2.5).
  /// Optional - use with unit for structured input.
  final double? quantity;

  /// Standardized unit for structured measurements.
  /// Optional - use with quantity for structured input.
  final MeasurementUnit? unit;

  final IngredientType type;

  IngredientDto({
    required this.name,
    this.amount,
    this.quantity,
    this.unit,
    required this.type,
  });

  /// Check if this DTO uses structured measurements.
  bool get hasStructuredMeasurement => quantity != null && unit != null;

  factory IngredientDto.fromJson(Map<String, dynamic> json) =>
      _$IngredientDtoFromJson(json);
  Map<String, dynamic> toJson() => _$IngredientDtoToJson(this);

  Ingredient toEntity() => Ingredient(
    name: name,
    amount: amount,
    quantity: quantity,
    unit: unit?.name,
    type: type.name.toUpperCase(),
  );

  factory IngredientDto.fromEntity(Ingredient ingredient) {
    return IngredientDto(
      name: ingredient.name,
      amount: ingredient.amount,
      quantity: ingredient.quantity,
      unit: ingredient.unit != null
          ? MeasurementUnit.values.firstWhere(
              (e) => e.name == ingredient.unit,
              orElse: () => MeasurementUnit.piece,
            )
          : null,
      type: IngredientType.values.firstWhere(
        (e) => e.name.toUpperCase() == ingredient.type?.toUpperCase(),
        orElse: () => IngredientType.main,
      ),
    );
  }
}
