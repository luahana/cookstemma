import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pairing_planet2_frontend/core/theme/app_colors.dart';
import 'package:pairing_planet2_frontend/domain/entities/autocomplete/autocomplete_result.dart';
import '../../../../core/providers/autocomplete_providers.dart';
import '../../../../core/providers/locale_provider.dart';
import 'minimal_header.dart';

class IngredientSection extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> ingredients;
  final Function(String) onAddIngredient;
  final Function(int) onRemoveIngredient;
  final Function(int) onRestoreIngredient;

  const IngredientSection({
    super.key,
    required this.ingredients,
    required this.onAddIngredient,
    required this.onRemoveIngredient,
    required this.onRestoreIngredient,
  });

  @override
  ConsumerState<IngredientSection> createState() => _IngredientSectionState();
}

class _IngredientSectionState extends ConsumerState<IngredientSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategorySection(
          'recipe.ingredients.main'.tr(),
          "MAIN",
          Icons.set_meal_outlined,
        ),
        const SizedBox(height: 32),
        _buildCategorySection(
          'recipe.ingredients.secondary'.tr(),
          "SECONDARY",
          Icons.bakery_dining_outlined,
        ),
        const SizedBox(height: 32),
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
    IconData icon,
  ) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MinimalHeader(icon: icon, title: title),
        const SizedBox(height: 12),
        ...activeItems.map((e) => _buildIngredientRow(e.key)),
        TextButton.icon(
          onPressed: () => widget.onAddIngredient(type),
          icon: const Icon(Icons.add, size: 18),
          label: Text(
            'recipe.ingredient.add'.tr(namedArgs: {'type': title}),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
        if (deletedItems.isNotEmpty) _buildDeletedSection(deletedItems),
      ],
    );
  }

  Widget _buildIngredientRow(int index) {
    final ingredient = widget.ingredients[index];
    final currentLocale = ref.watch(localeProvider);
    // 💡 기존 재료인지 확인 (수정 불가 제약용)
    final bool isOriginal = ingredient['isOriginal'] ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Autocomplete<AutocompleteResult>(
              displayStringForOption: (option) => option.name,
              // 💡 기존 재료인 경우 자동완성 작동 중지
              optionsBuilder: (TextEditingValue textEditingValue) async {
                if (isOriginal || textEditingValue.text.isEmpty)
                  return const Iterable.empty();
                final result = await ref
                    .read(getAutocompleteUseCaseProvider)
                    .execute(textEditingValue.text, currentLocale);
                return result.fold(
                  (_) => const Iterable.empty(),
                  (list) => list,
                );
              },
              onSelected: (selection) =>
                  setState(() => ingredient["name"] = selection.name),
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                    if (controller.text != ingredient["name"]) {
                      controller.text = ingredient["name"] ?? "";
                    }
                    return _smallField(
                      'recipe.ingredient.name'.tr(),
                      (v) => ingredient["name"] = v,
                      controller,
                      focusNode,
                      enabled: !isOriginal, // 💡 기존 재료는 텍스트 필드 비활성화
                    );
                  },
              optionsViewBuilder: (context, onSelected, options) =>
                  _buildOptionsView(onSelected, options),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: _smallField(
              'recipe.ingredient.amount'.tr(),
              (v) => ingredient["amount"] = v,
              TextEditingController(text: ingredient["amount"])
                ..selection = TextSelection.collapsed(
                  offset: (ingredient["amount"] ?? "").length,
                ),
              null,
              enabled: !isOriginal, // 💡 기존 재료의 양 수정 불가
            ),
          ),
          const SizedBox(width: 4),
          // 💡 삭제 버튼은 기존 재료라도 항상 활성화 (빼는 기능)
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey, size: 18),
            onPressed: () => widget.onRemoveIngredient(index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _smallField(
    String hint,
    Function(String) onChanged,
    TextEditingController controller,
    FocusNode? focusNode, {
    bool enabled = true, // 💡 활성화 여부 파라미터 추가
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        // 💡 비활성 상태일 때 시각적으로 다르게 표시
        color: enabled ? Colors.grey[50] : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? Colors.transparent : Colors.grey[300]!,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        enabled: enabled, // 💡 TextField 비활성화 적용
        style: TextStyle(
          fontSize: 13,
          color: enabled ? Colors.black : Colors.grey[600], // 💡 글자색 변경
        ),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
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
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 220,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options.elementAt(index);
              return ListTile(
                title: Text(option.name, style: const TextStyle(fontSize: 13)),
                onTap: () => onSelected(option),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDeletedSection(List<MapEntry<int, Map<String, dynamic>>> items) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'recipe.ingredient.deleted'.tr(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((e) => _buildDeletedRow(e.key, e.value)),
        ],
      ),
    );
  }

  Widget _buildDeletedRow(int index, Map<String, dynamic> ingredient) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "${ingredient['name']} ${ingredient['amount']}",
              style: TextStyle(
                decoration: TextDecoration.lineThrough,
                color: Colors.grey[500],
                fontSize: 13,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => widget.onRestoreIngredient(index),
            icon: const Icon(Icons.undo, size: 16),
            label: Text('recipe.ingredient.restore'.tr(), style: const TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
