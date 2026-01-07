package com.pairingplanet.pairing_planet.service;

import org.springframework.stereotype.Service;

import java.util.*;

/**
 * Service for automatically detecting change categories from recipe variation diffs.
 * Phase 7-2: Automatic Change Detection with Soft Delete
 *
 * Categories:
 * - INGREDIENT: Changes to ingredients (added, removed, modified)
 * - TECHNIQUE: Changes to cooking steps
 * - AMOUNT: Changes to quantities only
 * - SEASONING: Changes to seasoning ingredients
 */
@Service
public class RecipeCategoryDetectionService {

    // Korean seasoning keywords for auto-detection
    private static final Set<String> SEASONING_KEYWORDS = Set.of(
            // Basic seasonings
            "소금", "간장", "고추장", "된장", "설탕", "후추", "굵은소금",
            // Oils and vinegars
            "참기름", "들기름", "식용유", "올리브유", "식초", "발사믹",
            // Cooking wines
            "맛술", "미림", "청주", "소주", "와인",
            // Sauces
            "굴소스", "피시소스", "케첩", "마요네즈", "머스타드", "칠리소스",
            // Spices
            "고춧가루", "카레", "파프리카가루", "계피",
            // Aromatics
            "마늘", "생강", "파", "양파", "대파", "쪽파",
            // MSG and enhancers
            "다시다", "치킨스톡", "쇠고기다시다", "멸치액젓", "새우젓"
    );

    // English seasoning keywords
    private static final Set<String> SEASONING_KEYWORDS_EN = Set.of(
            "salt", "pepper", "soy sauce", "sugar", "vinegar", "oil",
            "sesame oil", "olive oil", "garlic", "ginger", "onion",
            "chili", "paprika", "curry", "ketchup", "mayonnaise",
            "mustard", "fish sauce", "oyster sauce"
    );

    /**
     * Detects change categories from a changeDiff structure.
     *
     * @param changeDiff The diff structure containing ingredients and steps changes
     * @return List of detected categories (INGREDIENT, TECHNIQUE, AMOUNT, SEASONING)
     */
    @SuppressWarnings("unchecked")
    public List<String> detectCategories(Map<String, Object> changeDiff) {
        if (changeDiff == null || changeDiff.isEmpty()) {
            return Collections.emptyList();
        }

        Set<String> categories = new LinkedHashSet<>(); // Preserve insertion order

        // Check ingredients changes
        Object ingredientsObj = changeDiff.get("ingredients");
        if (ingredientsObj instanceof Map) {
            Map<String, Object> ingredients = (Map<String, Object>) ingredientsObj;
            if (hasChanges(ingredients)) {
                categories.add("INGREDIENT");

                // Check if seasoning-related
                if (containsSeasoningKeywords(ingredients)) {
                    categories.add("SEASONING");
                }

                // Check if amount-only change
                if (isAmountOnlyChange(ingredients)) {
                    categories.add("AMOUNT");
                }
            }
        }

        // Check steps changes
        Object stepsObj = changeDiff.get("steps");
        if (stepsObj instanceof Map) {
            Map<String, Object> steps = (Map<String, Object>) stepsObj;
            if (hasChanges(steps)) {
                categories.add("TECHNIQUE");
            }
        }

        return new ArrayList<>(categories);
    }

    /**
     * Checks if a section (ingredients or steps) has any changes.
     */
    private boolean hasChanges(Map<String, Object> section) {
        if (section == null) return false;

        Object removed = section.get("removed");
        Object added = section.get("added");
        Object modified = section.get("modified");

        return isNonEmptyList(removed) || isNonEmptyList(added) || isNonEmptyList(modified);
    }

    private boolean isNonEmptyList(Object obj) {
        if (obj instanceof List) {
            return !((List<?>) obj).isEmpty();
        }
        return false;
    }

    /**
     * Checks if ingredient changes contain seasoning-related items.
     */
    private boolean containsSeasoningKeywords(Map<String, Object> ingredients) {
        Set<String> allIngredientTexts = new HashSet<>();

        // Collect all ingredient texts from removed, added, modified
        collectTexts(ingredients.get("removed"), allIngredientTexts);
        collectTexts(ingredients.get("added"), allIngredientTexts);
        collectModifiedTexts(ingredients.get("modified"), allIngredientTexts);

        // Check if any text contains seasoning keywords
        for (String text : allIngredientTexts) {
            String lowerText = text.toLowerCase();

            // Check Korean keywords
            for (String keyword : SEASONING_KEYWORDS) {
                if (lowerText.contains(keyword)) {
                    return true;
                }
            }

            // Check English keywords
            for (String keyword : SEASONING_KEYWORDS_EN) {
                if (lowerText.contains(keyword)) {
                    return true;
                }
            }
        }

        return false;
    }

    /**
     * Checks if the changes are amount-only (quantities changed, not ingredients themselves).
     * Amount-only: modified list has items, but removed/added are empty.
     */
    @SuppressWarnings("unchecked")
    private boolean isAmountOnlyChange(Map<String, Object> ingredients) {
        Object removed = ingredients.get("removed");
        Object added = ingredients.get("added");
        Object modified = ingredients.get("modified");

        // Amount-only if only modified has changes (no full additions or removals)
        boolean hasRemoved = isNonEmptyList(removed);
        boolean hasAdded = isNonEmptyList(added);
        boolean hasModified = isNonEmptyList(modified);

        if (hasModified && !hasRemoved && !hasAdded) {
            // Check if modifications are quantity-related
            List<Map<String, Object>> modifiedList = (List<Map<String, Object>>) modified;
            return modifiedList.stream().allMatch(this::isQuantityChange);
        }

        return false;
    }

    /**
     * Determines if a modification is likely a quantity change.
     * Compares 'from' and 'to' values to see if the ingredient name is the same
     * but only the quantity differs.
     */
    @SuppressWarnings("unchecked")
    private boolean isQuantityChange(Map<String, Object> modification) {
        String from = String.valueOf(modification.get("from"));
        String to = String.valueOf(modification.get("to"));

        if (from == null || to == null) return false;

        // Extract non-numeric parts (ingredient names)
        String fromName = extractIngredientName(from);
        String toName = extractIngredientName(to);

        // If the names are the same (ignoring quantities), it's an amount change
        return fromName.equalsIgnoreCase(toName) && !from.equals(to);
    }

    /**
     * Extracts the ingredient name by removing numeric/quantity parts.
     * Example: "닭 600g" -> "닭"
     *          "청양고추 3개" -> "청양고추"
     */
    private String extractIngredientName(String ingredientText) {
        // Remove common quantity patterns
        return ingredientText
                .replaceAll("\\d+(\\.\\d+)?\\s*(g|kg|ml|l|개|조각|큰술|작은술|컵|tbsp|tsp|cup|oz|lb)", "")
                .replaceAll("\\d+/\\d+", "") // fractions
                .replaceAll("\\d+", "")
                .trim();
    }

    private void collectTexts(Object listObj, Set<String> collection) {
        if (listObj instanceof List) {
            for (Object item : (List<?>) listObj) {
                if (item instanceof String) {
                    collection.add((String) item);
                }
            }
        }
    }

    @SuppressWarnings("unchecked")
    private void collectModifiedTexts(Object listObj, Set<String> collection) {
        if (listObj instanceof List) {
            for (Object item : (List<?>) listObj) {
                if (item instanceof Map) {
                    Map<String, Object> map = (Map<String, Object>) item;
                    Object from = map.get("from");
                    Object to = map.get("to");
                    if (from instanceof String) collection.add((String) from);
                    if (to instanceof String) collection.add((String) to);
                }
            }
        }
    }
}
