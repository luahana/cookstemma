package com.cookstemma.cookstemma.domain.entity.autocomplete;

import com.cookstemma.cookstemma.domain.entity.common.BaseEntity;
import com.cookstemma.cookstemma.domain.enums.AutocompleteType;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.HashMap;
import java.util.Map;

@Entity
@Table(name = "autocomplete_items")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@SuperBuilder
public class AutocompleteItem extends BaseEntity {

    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false, length = 30)
    private AutocompleteType type;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb", nullable = false)
    @Builder.Default
    private Map<String, String> name = new HashMap<>();

    @Column(name = "score")
    @Builder.Default
    private Double score = 50.0;

    public String getNameByLocale(String locale) {
        if (name == null || name.isEmpty()) {
            return "Unknown";
        }

        if (name.containsKey(locale)) {
            return name.get(locale);
        }

        if (name.containsKey("en-US")) {
            return name.get("en-US");
        }

        return name.values().iterator().next();
    }
}
