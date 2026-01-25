package com.cookstemma.cookstemma.domain.entity.food;

import com.cookstemma.cookstemma.domain.entity.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.HashMap;
import java.util.Map;

@Entity
@Table(name = "foods_master")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@SuperBuilder
public class FoodMaster extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id", nullable = true)
    private FoodCategory category;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb", nullable = false)
    @Builder.Default
    private Map<String, String> name = new HashMap<>();

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb")
    @Builder.Default
    private Map<String, String> description = new HashMap<>();

    @Column(name = "food_score")
    @Builder.Default
    private Double foodScore = 0.0;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "search_keywords", columnDefinition = "jsonb")
    @Builder.Default
    private Map<String, String> searchKeywords = new HashMap<>();

    @Column(name = "is_verified", nullable = false)
    @Builder.Default
    private Boolean isVerified = true;

    public String getNameByLocale(String locale) {
        if (name == null || name.isEmpty()) {
            return "Unknown Food";
        }

        // 1. Try exact key match: "ko-KR", "zh-CN", etc.
        if (name.containsKey(locale)) {
            return name.get(locale);
        }

        // 2. Extract language code and try matching
        String langCode = locale.contains("-") ? locale.split("-")[0] : locale;

        // 3. Try to find a key that starts with the language code
        for (Map.Entry<String, String> entry : name.entrySet()) {
            String key = entry.getKey();
            String keyLang = key.contains("-") ? key.split("-")[0] : key;
            if (keyLang.equalsIgnoreCase(langCode)) {
                return entry.getValue();
            }
        }

        // 4. Try "en-US" fallback
        if (name.containsKey("en-US")) {
            return name.get("en-US");
        }

        // 5. Try "en" fallback (any English variant)
        for (Map.Entry<String, String> entry : name.entrySet()) {
            String key = entry.getKey();
            if (key.startsWith("en")) {
                return entry.getValue();
            }
        }

        // 6. Return first available translation
        return name.values().iterator().next();
    }

    public void addNameTranslation(String locale, String translatedName) {
        if (this.name == null) {
            this.name = new HashMap<>();
        }
        this.name.put(locale, translatedName);
    }

    public void addDescriptionTranslation(String locale, String translatedDescription) {
        if (this.description == null) {
            this.description = new HashMap<>();
        }
        this.description.put(locale, translatedDescription);
    }


    public void addSearchKeywords(String locale, String keywords) {
        if (this.searchKeywords == null) {
            this.searchKeywords = new HashMap<>();
        }
        this.searchKeywords.put(locale, keywords);
    }
}