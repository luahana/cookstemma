import Foundation

// MARK: - Measurement Unit

enum MeasurementUnit: String, CaseIterable {
    // Volume units
    case ml = "ML"
    case liter = "L"
    case tsp = "TSP"
    case tbsp = "TBSP"
    case cup = "CUP"
    case flOz = "FL_OZ"
    case pint = "PINT"
    case quart = "QUART"

    // Weight units
    case gram = "G"
    case kg = "KG"
    case oz = "OZ"
    case lb = "LB"

    // Non-convertible units
    case piece = "PIECE"
    case pinch = "PINCH"
    case dash = "DASH"
    case toTaste = "TO_TASTE"
    case clove = "CLOVE"
    case bunch = "BUNCH"
    case can = "CAN"
    case package = "PACKAGE"

    var displayName: String {
        switch self {
        case .ml: return "ml"
        case .liter: return "L"
        case .tsp: return "tsp"
        case .tbsp: return "tbsp"
        case .cup: return "cup"
        case .flOz: return "fl oz"
        case .pint: return "pt"
        case .quart: return "qt"
        case .gram: return "g"
        case .kg: return "kg"
        case .oz: return "oz"
        case .lb: return "lb"
        case .piece: return "piece"
        case .pinch: return "pinch"
        case .dash: return "dash"
        case .toTaste: return "to taste"
        case .clove: return "clove"
        case .bunch: return "bunch"
        case .can: return "can"
        case .package: return "pkg"
        }
    }

    var isVolumeUnit: Bool {
        switch self {
        case .ml, .liter, .tsp, .tbsp, .cup, .flOz, .pint, .quart:
            return true
        default:
            return false
        }
    }

    var isWeightUnit: Bool {
        switch self {
        case .gram, .kg, .oz, .lb:
            return true
        default:
            return false
        }
    }

    var isConvertible: Bool {
        switch self {
        case .piece, .pinch, .dash, .toTaste, .clove, .bunch, .can, .package:
            return false
        default:
            return true
        }
    }

    var isMetric: Bool {
        switch self {
        case .ml, .liter, .gram, .kg:
            return true
        default:
            return false
        }
    }

    var isUS: Bool {
        switch self {
        case .tsp, .tbsp, .cup, .flOz, .pint, .quart, .oz, .lb:
            return true
        default:
            return false
        }
    }
}

// MARK: - Conversion Result

struct ConversionResult {
    let quantity: Double
    let unit: MeasurementUnit
    let displayString: String
}

// MARK: - Measurement Converter

enum MeasurementConverter {
    // Conversion factors to base units (ML for volume, G for weight)
    private static let volumeToML: [MeasurementUnit: Double] = [
        .ml: 1,
        .liter: 1000,
        .tsp: 5,
        .tbsp: 15,
        .cup: 240,
        .flOz: 30,
        .pint: 473,
        .quart: 946
    ]

    private static let weightToG: [MeasurementUnit: Double] = [
        .gram: 1,
        .kg: 1000,
        .oz: 28.35,
        .lb: 453.59
    ]

    // MARK: - Public API

    /// Convert a measurement to the user's preferred unit system
    static func convert(
        quantity: Double?,
        unitString: String?,
        preference: MeasurementPreference
    ) -> ConversionResult? {
        guard let quantity = quantity, let unitString = unitString else {
            return nil
        }

        let unit = MeasurementUnit(rawValue: unitString) ?? .piece

        // If original, just return as-is
        if preference == .original {
            return ConversionResult(
                quantity: smartRound(quantity),
                unit: unit,
                displayString: formatQuantity(smartRound(quantity), unit: unit)
            )
        }

        // Non-convertible units stay as-is
        guard unit.isConvertible else {
            return ConversionResult(
                quantity: smartRound(quantity),
                unit: unit,
                displayString: formatQuantity(smartRound(quantity), unit: unit)
            )
        }

        let targetUnit = getTargetUnit(unit, preference: preference)

        // If already in target unit system, return normalized
        if unit == targetUnit {
            let normalized = normalizeUnit(quantity: quantity, unit: unit)
            return ConversionResult(
                quantity: normalized.quantity,
                unit: normalized.unit,
                displayString: formatQuantity(normalized.quantity, unit: normalized.unit)
            )
        }

        // Perform conversion
        var convertedQuantity: Double

        if unit.isVolumeUnit && targetUnit.isVolumeUnit {
            // Convert through ML as base
            let inML = quantity * (volumeToML[unit] ?? 1)
            convertedQuantity = inML / (volumeToML[targetUnit] ?? 1)
        } else if unit.isWeightUnit && targetUnit.isWeightUnit {
            // Convert through G as base
            let inG = quantity * (weightToG[unit] ?? 1)
            convertedQuantity = inG / (weightToG[targetUnit] ?? 1)
        } else {
            // Cannot convert between volume and weight
            return ConversionResult(
                quantity: smartRound(quantity),
                unit: unit,
                displayString: formatQuantity(smartRound(quantity), unit: unit)
            )
        }

        // Normalize to better unit if needed (e.g., 1000ml -> 1L)
        let normalized = normalizeUnit(quantity: convertedQuantity, unit: targetUnit)

        return ConversionResult(
            quantity: normalized.quantity,
            unit: normalized.unit,
            displayString: formatQuantity(normalized.quantity, unit: normalized.unit)
        )
    }

    // MARK: - Private Helpers

    private static func getTargetUnit(_ sourceUnit: MeasurementUnit, preference: MeasurementPreference) -> MeasurementUnit {
        if preference == .original {
            return sourceUnit
        }

        guard sourceUnit.isConvertible else {
            return sourceUnit
        }

        let targetIsMetric = preference == .metric

        if sourceUnit.isVolumeUnit {
            return targetIsMetric ? .ml : .cup
        }

        if sourceUnit.isWeightUnit {
            return targetIsMetric ? .gram : .oz
        }

        return sourceUnit
    }

    /// Round to reasonable precision based on value
    private static func smartRound(_ value: Double) -> Double {
        if value >= 100 {
            return (value).rounded()
        } else if value >= 10 {
            return (value * 10).rounded() / 10
        } else if value >= 1 {
            return (value * 100).rounded() / 100
        } else {
            // For very small values, show more precision
            return (value * 1000).rounded() / 1000
        }
    }

    /// Convert and potentially upgrade unit for better readability
    /// e.g., 1000ml -> 1L, 1000g -> 1kg
    private static func normalizeUnit(quantity: Double, unit: MeasurementUnit) -> (quantity: Double, unit: MeasurementUnit) {
        // Upgrade ML to L if >= 1000ml
        if unit == .ml && quantity >= 1000 {
            return (smartRound(quantity / 1000), .liter)
        }

        // Upgrade G to KG if >= 1000g
        if unit == .gram && quantity >= 1000 {
            return (smartRound(quantity / 1000), .kg)
        }

        // Upgrade OZ to LB if >= 16oz
        if unit == .oz && quantity >= 16 {
            return (smartRound(quantity / 16), .lb)
        }

        // Upgrade CUP to QUART if >= 4 cups
        if unit == .cup && quantity >= 4 {
            return (smartRound(quantity / 4), .quart)
        }

        return (smartRound(quantity), unit)
    }

    private static func formatQuantity(_ quantity: Double, unit: MeasurementUnit) -> String {
        // Handle "to taste" specially - no quantity
        if unit == .toTaste {
            return unit.displayName
        }

        // Format quantity - remove trailing zeros
        let formattedQty: String
        if quantity.truncatingRemainder(dividingBy: 1) == 0 {
            formattedQty = String(format: "%.0f", quantity)
        } else if quantity < 1 {
            formattedQty = String(format: "%.2f", quantity).replacingOccurrences(of: "\\.?0+$", with: "", options: .regularExpression)
        } else {
            formattedQty = String(format: "%.1f", quantity).replacingOccurrences(of: "\\.?0+$", with: "", options: .regularExpression)
        }

        return "\(formattedQty) \(unit.displayName)"
    }
}
