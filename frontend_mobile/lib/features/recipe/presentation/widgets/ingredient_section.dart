import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/data/models/recipe/ingredient_dto.dart';
import 'package:pairing_planet2_frontend/domain/entities/autocomplete/autocomplete_result.dart';
import '../../../../core/providers/autocomplete_providers.dart';
import '../../../../core/providers/locale_provider.dart';
import 'minimal_header.dart';

class IngredientSection extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> ingredients;
  final Function(String) onAddIngredient;
  final Function(int) onRemoveIngredient;
  final Function(int) onRestoreIngredient;
  final VoidCallback onStateChanged;

  const IngredientSection({
    super.key,
    required this.ingredients,
    required this.onAddIngredient,
    required this.onRemoveIngredient,
    required this.onRestoreIngredient,
    required this.onStateChanged,
  });

  @override
  ConsumerState<IngredientSection> createState() => _IngredientSectionState();
}

class _IngredientSectionState extends ConsumerState<IngredientSection> {
  static const int _maxMain = 5;
  static const int _maxSecondary = 8;
  static const int _maxSeasoning = 10;

  final Map<int, TextEditingController> _quantityControllers = {};

  @override
  void dispose() {
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getQuantityController(int index, dynamic quantity) {
    if (!_quantityControllers.containsKey(index)) {
      _quantityControllers[index] = TextEditingController(
        text: quantity != null ? _formatQuantity(quantity) : '',
      );
    }
    return _quantityControllers[index]!;
  }

  int _getMaxForType(String type) {
    switch (type) {
      case 'MAIN':
        return _maxMain;
      case 'SECONDARY':
        return _maxSecondary;
      case 'SEASONING':
        return _maxSeasoning;
      default:
        return 10;
    }
  }

  String _getMaxInfoKey(String type) {
    switch (type) {
      case 'MAIN':
        return 'recipe.ingredients.maxMain';
      case 'SECONDARY':
        return 'recipe.ingredients.maxSecondary';
      case 'SEASONING':
        return 'recipe.ingredients.maxSeasoning';
      default:
        return 'recipe.ingredients.maxMain';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategorySection(
          'recipe.ingredients.main'.tr(),
          "MAIN",
          Icons.set_meal_outlined,
          isRequired: true,
        ),
        SizedBox(height: 32.h),
        _buildCategorySection(
          'recipe.ingredients.secondary'.tr(),
          "SECONDARY",
          Icons.bakery_dining_outlined,
        ),
        SizedBox(height: 32.h),
        _buildCategorySection(
          'recipe.ingredients.seasoning'.tr(),
          "SEASONING",
          Icons.opacity_outlined,
        ),
      ],
    );
  }

  Widget _buildCategorySection(
    String title,
    String type,
    IconData icon, {
    bool isRequired = false,
  }) {
    final activeItems = widget.ingredients
        .asMap()
        .entries
        .where((e) => e.value["type"] == type && e.value["isDeleted"] != true)
        .toList();

    final deletedItems = widget.ingredients
        .asMap()
        .entries
        .where((e) => e.value["type"] == type && e.value["isDeleted"] == true)
        .toList();

    final maxForType = _getMaxForType(type);
    final isAtMax = activeItems.length >= maxForType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MinimalHeader(icon: icon, title: title, isRequired: isRequired),
        SizedBox(height: 12.h),
        ...activeItems.map((e) => _buildIngredientRow(e.key)),
        GestureDetector(
          onTap: isAtMax ? null : () => widget.onAddIngredient(type),
          child: Opacity(
            opacity: isAtMax ? 0.5 : 1.0,
            child: Row(
              children: [
                Icon(Icons.add, size: 18.sp, color: AppColors.primary),
                SizedBox(width: 4.w),
                Text(
                  'recipe.ingredient.add'.tr(namedArgs: {'type': title}),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          _getMaxInfoKey(type).tr(),
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[500],
          ),
        ),
        if (deletedItems.isNotEmpty) _buildDeletedSection(deletedItems, isAtMax: isAtMax),
      ],
    );
  }

  Widget _buildIngredientRow(int index) {
    final ingredient = widget.ingredients[index];
    final currentLocale = ref.watch(localeProvider);
    // 💡 기존 재료인지 확인 (수정 불가 제약용)
    final bool isOriginal = ingredient['isOriginal'] ?? false;
    // Get ingredient type for autocomplete filtering
    final String ingredientType = ingredient['type'] ?? 'MAIN';

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          // Name field with autocomplete
          Expanded(
            flex: 3,
            child: Autocomplete<AutocompleteResult>(
              displayStringForOption: (option) => option.name,
              // 💡 기존 재료인 경우 자동완성 작동 중지
              optionsBuilder: (TextEditingValue textEditingValue) async {
                if (isOriginal || textEditingValue.text.isEmpty) {
                  return const Iterable.empty();
                }
                final result = await ref
                    .read(getAutocompleteUseCaseProvider)
                    .execute(textEditingValue.text, currentLocale, type: ingredientType);
                return result.fold(
                  (_) => const Iterable.empty(),
                  (list) => list,
                );
              },
              onSelected: (selection) {
                setState(() => ingredient["name"] = selection.name);
                widget.onStateChanged();
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                    if (controller.text != ingredient["name"]) {
                      controller.text = ingredient["name"] ?? "";
                    }
                    return Focus(
                      onFocusChange: (hasFocus) {
                        if (!hasFocus) {
                          widget.onStateChanged(); // Only notify parent on focus lost
                        }
                      },
                      child: _smallField(
                        'recipe.ingredient.name'.tr(),
                        (v) {
                          ingredient["name"] = v; // Update immediately for autocomplete
                        },
                        controller,
                        focusNode,
                        enabled: !isOriginal,
                      ),
                    );
                  },
              optionsViewBuilder: (context, onSelected, options) =>
                  _buildOptionsView(onSelected, options),
            ),
          ),
          SizedBox(width: 4.w),
          // Quantity field (number input)
          SizedBox(
            width: 60.w,
            child: _quantityField(
              index,
              ingredient,
              enabled: !isOriginal,
            ),
          ),
          SizedBox(width: 4.w),
          // Unit dropdown
          SizedBox(
            width: 60.w,
            child: _unitDropdown(
              ingredient,
              enabled: !isOriginal,
            ),
          ),
          SizedBox(width: 2.w),
          // 💡 삭제 버튼은 기존 재료라도 항상 활성화 (빼는 기능)
          // Orange color highlights it as interactive even when fields are disabled
          IconButton(
            icon: Icon(
              Icons.close,
              color: isOriginal ? AppColors.inheritedInteractive : Colors.grey,
              size: 18.sp,
            ),
            onPressed: () => widget.onRemoveIngredient(index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _quantityField(int index, Map<String, dynamic> ingredient, {bool enabled = true}) {
    final quantity = ingredient['quantity'];
    final controller = _getQuantityController(index, quantity);
    // Sync text if quantity changed externally
    final expectedText = quantity != null ? _formatQuantity(quantity) : '';
    if (controller.text != expectedText && !controller.text.endsWith('.')) {
      controller.text = expectedText;
    }

    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus) {
          // Save when focus is lost
          final v = controller.text;
          if (v.isEmpty) {
            ingredient['quantity'] = null;
          } else {
            ingredient['quantity'] = double.tryParse(v);
          }
          widget.onStateChanged();
        }
      },
      child: Container(
        height: 44.h,
        decoration: BoxDecoration(
          color: enabled ? AppColors.editableBackground : Colors.grey[200],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: enabled ? AppColors.editableBorder : Colors.grey[300]!),
        ),
        child: TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            LengthLimitingTextInputFormatter(4),
          ],
          style: TextStyle(
            fontSize: 13.sp,
            color: enabled ? Colors.black : Colors.grey[600],
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: 'units.quantity'.tr(),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 6.w),
            hintStyle: TextStyle(fontSize: 11.sp, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  String _formatQuantity(dynamic quantity) {
    if (quantity == null) return '';
    if (quantity is int) return quantity.toString();
    if (quantity is double) {
      // Remove trailing zeros
      if (quantity % 1 == 0) {
        return quantity.toInt().toString();
      }
      return quantity.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return quantity.toString();
  }

  Widget _unitDropdown(Map<String, dynamic> ingredient, {bool enabled = true}) {
    final currentUnit = ingredient['unit'] as String?;

    return Container(
      height: 44.h,
      decoration: BoxDecoration(
        // Orange background for editable fields, grey for inherited
        color: enabled ? AppColors.editableBackground : Colors.grey[200],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: enabled ? AppColors.editableBorder : Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentUnit,
          isExpanded: true,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'units.selectUnit'.tr(),
              style: TextStyle(fontSize: 11.sp, color: Colors.grey),
            ),
          ),
          icon: Icon(
            Icons.arrow_drop_down,
            color: enabled ? Colors.grey[600] : Colors.grey[400],
            size: 18.sp,
          ),
          style: TextStyle(
            fontSize: 12.sp,
            color: enabled ? Colors.black : Colors.grey[600],
          ),
          onChanged: enabled
              ? (value) {
                  setState(() => ingredient['unit'] = value);
                  widget.onStateChanged();
                }
              : null,
          items: _buildUnitDropdownItems(),
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildUnitDropdownItems() {
    // Common units for cooking - grouped logically
    final units = <MeasurementUnit>[
      // Volume - Common
      MeasurementUnit.cup,
      MeasurementUnit.tbsp,
      MeasurementUnit.tsp,
      MeasurementUnit.ml,
      MeasurementUnit.l,
      // Weight
      MeasurementUnit.g,
      MeasurementUnit.kg,
      MeasurementUnit.oz,
      MeasurementUnit.lb,
      // Count/Other
      MeasurementUnit.piece,
      MeasurementUnit.clove,
      MeasurementUnit.bunch,
      MeasurementUnit.can,
      MeasurementUnit.package,
      // Subjective
      MeasurementUnit.pinch,
      MeasurementUnit.dash,
      MeasurementUnit.toTaste,
    ];

    return units.map((unit) {
      return DropdownMenuItem<String>(
        value: unit.name,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'units.${unit.name}'.tr(),
            style: TextStyle(fontSize: 12.sp),
          ),
        ),
      );
    }).toList();
  }

  Widget _smallField(
    String hint,
    Function(String) onChanged,
    TextEditingController controller,
    FocusNode? focusNode, {
    bool enabled = true, // 💡 활성화 여부 파라미터 추가
  }) {
    return Container(
      height: 44.h,
      decoration: BoxDecoration(
        // Orange background for editable fields, grey for inherited
        color: enabled ? AppColors.editableBackground : Colors.grey[200],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: enabled ? AppColors.editableBorder : Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        enabled: enabled, // 💡 TextField 비활성화 적용
        style: TextStyle(
          fontSize: 13.sp,
          color: enabled ? Colors.black : Colors.grey[600], // 💡 글자색 변경
        ),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
          hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildOptionsView(
    Function(AutocompleteResult) onSelected,
    Iterable<AutocompleteResult> options,
  ) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8.r),
        child: SizedBox(
          width: 220.w,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options.elementAt(index);
              return ListTile(
                title: Text(option.name, style: TextStyle(fontSize: 13.sp)),
                onTap: () => onSelected(option),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDeletedSection(List<MapEntry<int, Map<String, dynamic>>> items, {required bool isAtMax}) {
    return Container(
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'recipe.ingredient.deleted'.tr(),
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          ...items.take(5).map((e) => _buildDeletedRow(e.key, e.value, isAtMax: isAtMax)),
        ],
      ),
    );
  }

  Widget _buildDeletedRow(int index, Map<String, dynamic> ingredient, {required bool isAtMax}) {
    // Build display text: prefer quantity + unit, fallback to amount
    final name = ingredient['name'] ?? '';
    final quantity = ingredient['quantity'];
    final unit = ingredient['unit'] as String?;
    final amount = ingredient['amount'] as String?;

    String displayAmount;
    if (quantity != null && unit != null) {
      displayAmount = '${_formatQuantity(quantity)} ${'units.$unit'.tr()}';
    } else {
      displayAmount = amount ?? '';
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "$name $displayAmount",
              style: TextStyle(
                decoration: TextDecoration.lineThrough,
                color: Colors.grey[500],
                fontSize: 13.sp,
              ),
            ),
          ),
          Opacity(
            opacity: isAtMax ? 0.5 : 1.0,
            child: TextButton.icon(
              onPressed: isAtMax ? null : () => widget.onRestoreIngredient(index),
              icon: Icon(Icons.undo, size: 16.sp),
              label: Text('recipe.ingredient.restore'.tr(), style: TextStyle(fontSize: 12.sp)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
