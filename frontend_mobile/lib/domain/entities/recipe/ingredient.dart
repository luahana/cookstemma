class Ingredient {
  final String name;

  /// Legacy amount field - free-text like "2 cups" or "a pinch".
  final String? amount;

  /// Numeric quantity for structured measurements (e.g., 2.5).
  final double? quantity;

  /// Standardized unit name for structured measurements.
  final String? unit;

  final String type;

  Ingredient({
    required this.name,
    this.amount,
    this.quantity,
    this.unit,
    required this.type,
  });

  /// Check if this ingredient uses structured measurements.
  bool get hasStructuredMeasurement => quantity != null && unit != null;

  /// Get display amount - prefers structured if available.
  String get displayAmount {
    if (hasStructuredMeasurement) {
      // Format quantity nicely (remove trailing zeros)
      final qtyStr = quantity! % 1 == 0
          ? quantity!.toInt().toString()
          : quantity!.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      return '$qtyStr ${_formatUnit(unit!)}';
    }
    return amount ?? '';
  }

  String _formatUnit(String unit) {
    // Convert enum name to display format
    switch (unit.toLowerCase()) {
      case 'ml':
        return 'ml';
      case 'l':
        return 'L';
      case 'tsp':
        return 'tsp';
      case 'tbsp':
        return 'tbsp';
      case 'cup':
        return 'cup';
      case 'floz':
        return 'fl oz';
      case 'pint':
        return 'pint';
      case 'quart':
        return 'quart';
      case 'g':
        return 'g';
      case 'kg':
        return 'kg';
      case 'oz':
        return 'oz';
      case 'lb':
        return 'lb';
      case 'piece':
        return 'pc';
      case 'pinch':
        return 'pinch';
      case 'dash':
        return 'dash';
      case 'totaste':
        return 'to taste';
      case 'clove':
        return 'clove';
      case 'bunch':
        return 'bunch';
      case 'can':
        return 'can';
      case 'package':
        return 'pkg';
      default:
        return unit;
    }
  }
}
