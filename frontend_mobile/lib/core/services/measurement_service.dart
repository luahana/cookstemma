import 'package:pairing_planet2_frontend/data/models/recipe/ingredient_dto.dart';

/// Service for converting between measurement units.
/// Only supports same-type conversions (volume ↔ volume, weight ↔ weight).
/// Does NOT support volume ↔ weight conversion (requires ingredient density).
class MeasurementService {
  // Volume conversions to ML (base unit)
  static const Map<MeasurementUnit, double> _volumeToMl = {
    MeasurementUnit.ml: 1.0,
    MeasurementUnit.l: 1000.0,
    MeasurementUnit.tsp: 5.0,
    MeasurementUnit.tbsp: 15.0,
    MeasurementUnit.cup: 240.0,
    MeasurementUnit.flOz: 30.0,
    MeasurementUnit.pint: 473.0,
    MeasurementUnit.quart: 946.0,
  };

  // Weight conversions to G (base unit)
  static const Map<MeasurementUnit, double> _weightToG = {
    MeasurementUnit.g: 1.0,
    MeasurementUnit.kg: 1000.0,
    MeasurementUnit.oz: 28.35,
    MeasurementUnit.lb: 453.59,
  };

  /// Convert a quantity from one unit to another.
  /// Only same-type conversions are supported.
  /// Returns null if conversion is not possible.
  static double? convert(double? quantity, MeasurementUnit? fromUnit, MeasurementUnit? toUnit) {
    if (quantity == null || fromUnit == null || toUnit == null) {
      return null;
    }

    if (fromUnit == toUnit) {
      return quantity;
    }

    // Volume conversion
    if (_isVolume(fromUnit) && _isVolume(toUnit)) {
      final mlValue = quantity * _volumeToMl[fromUnit]!;
      return _round(mlValue / _volumeToMl[toUnit]!);
    }

    // Weight conversion
    if (_isWeight(fromUnit) && _isWeight(toUnit)) {
      final gValue = quantity * _weightToG[fromUnit]!;
      return _round(gValue / _weightToG[toUnit]!);
    }

    // Cannot convert between different types
    return null;
  }

  /// Get the target unit for a given unit and preference.
  static MeasurementUnit getTargetUnit(MeasurementUnit sourceUnit, MeasurementPreference preference) {
    if (preference == MeasurementPreference.original) {
      return sourceUnit;
    }

    if (_isCountOrOther(sourceUnit)) {
      return sourceUnit;
    }

    if (preference == MeasurementPreference.metric) {
      return _getMetricEquivalent(sourceUnit);
    } else if (preference == MeasurementPreference.us) {
      return _getUSEquivalent(sourceUnit);
    }

    return sourceUnit;
  }

  /// Convert quantity and unit based on user preference.
  static ConversionResult convertForPreference(
    double? quantity,
    MeasurementUnit? unit,
    MeasurementPreference preference,
  ) {
    if (quantity == null || unit == null || preference == MeasurementPreference.original) {
      return ConversionResult(quantity: quantity, unit: unit);
    }

    final targetUnit = getTargetUnit(unit, preference);
    if (targetUnit == unit) {
      return ConversionResult(quantity: quantity, unit: unit);
    }

    final convertedQuantity = convert(quantity, unit, targetUnit);
    return ConversionResult(quantity: convertedQuantity, unit: targetUnit);
  }

  static bool _isVolume(MeasurementUnit unit) {
    return _volumeToMl.containsKey(unit);
  }

  static bool _isWeight(MeasurementUnit unit) {
    return _weightToG.containsKey(unit);
  }

  static bool _isCountOrOther(MeasurementUnit unit) {
    return !_isVolume(unit) && !_isWeight(unit);
  }

  static MeasurementUnit _getMetricEquivalent(MeasurementUnit unit) {
    if (_isVolume(unit)) {
      return MeasurementUnit.ml;
    } else if (_isWeight(unit)) {
      return MeasurementUnit.g;
    }
    return unit;
  }

  static MeasurementUnit _getUSEquivalent(MeasurementUnit unit) {
    if (_isVolume(unit)) {
      if (unit == MeasurementUnit.ml || unit == MeasurementUnit.l) {
        return MeasurementUnit.cup;
      }
      return unit;
    } else if (_isWeight(unit)) {
      if (unit == MeasurementUnit.g || unit == MeasurementUnit.kg) {
        return MeasurementUnit.oz;
      }
      return unit;
    }
    return unit;
  }

  static double _round(double value) {
    return (value * 100).round() / 100;
  }

  /// Get display label for a unit.
  static String getUnitLabel(MeasurementUnit unit) {
    switch (unit) {
      case MeasurementUnit.ml:
        return 'ml';
      case MeasurementUnit.l:
        return 'L';
      case MeasurementUnit.tsp:
        return 'tsp';
      case MeasurementUnit.tbsp:
        return 'tbsp';
      case MeasurementUnit.cup:
        return 'cup';
      case MeasurementUnit.flOz:
        return 'fl oz';
      case MeasurementUnit.pint:
        return 'pint';
      case MeasurementUnit.quart:
        return 'quart';
      case MeasurementUnit.g:
        return 'g';
      case MeasurementUnit.kg:
        return 'kg';
      case MeasurementUnit.oz:
        return 'oz';
      case MeasurementUnit.lb:
        return 'lb';
      case MeasurementUnit.piece:
        return 'pc';
      case MeasurementUnit.pinch:
        return 'pinch';
      case MeasurementUnit.dash:
        return 'dash';
      case MeasurementUnit.toTaste:
        return 'to taste';
      case MeasurementUnit.clove:
        return 'clove';
      case MeasurementUnit.bunch:
        return 'bunch';
      case MeasurementUnit.can:
        return 'can';
      case MeasurementUnit.package:
        return 'pkg';
    }
  }

  /// Get all volume units.
  static List<MeasurementUnit> get volumeUnits => _volumeToMl.keys.toList();

  /// Get all weight units.
  static List<MeasurementUnit> get weightUnits => _weightToG.keys.toList();

  /// Get count/other units.
  static List<MeasurementUnit> get countUnits => [
    MeasurementUnit.piece,
    MeasurementUnit.pinch,
    MeasurementUnit.dash,
    MeasurementUnit.toTaste,
    MeasurementUnit.clove,
    MeasurementUnit.bunch,
    MeasurementUnit.can,
    MeasurementUnit.package,
  ];

  /// Get all units grouped by category.
  static Map<String, List<MeasurementUnit>> get groupedUnits => {
    'Volume': volumeUnits,
    'Weight': weightUnits,
    'Count': countUnits,
  };
}

/// Result of a unit conversion.
class ConversionResult {
  final double? quantity;
  final MeasurementUnit? unit;

  ConversionResult({this.quantity, this.unit});

  bool get isConverted => quantity != null && unit != null;

  /// Format the result for display.
  String format() {
    if (!isConverted) return '';
    final qtyStr = quantity! % 1 == 0
        ? quantity!.toInt().toString()
        : quantity!.toStringAsFixed(2)
            .replaceAll(RegExp(r'0+$'), '')
            .replaceAll(RegExp(r'\.$'), '');
    return '$qtyStr ${MeasurementService.getUnitLabel(unit!)}';
  }
}
