package com.pairingplanet.pairing_planet.domain.entity.log_post;

import com.pairingplanet.pairing_planet.domain.entity.common.BaseEntity;
import com.pairingplanet.pairing_planet.domain.entity.hashtag.Hashtag;
import com.pairingplanet.pairing_planet.domain.entity.image.Image;
import com.pairingplanet.pairing_planet.domain.entity.recipe.RecipeLog;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.*;

@Entity
@Table(name = "log_posts")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@SuperBuilder
public class LogPost extends BaseEntity {
    private String locale;

    @Column(columnDefinition = "TEXT")
    private String title;

    @Column(columnDefinition = "TEXT")
    private String content;

    private Long creatorId;

    // Translation fields for multilingual content
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "title_translations", columnDefinition = "jsonb")
    @Builder.Default
    private Map<String, String> titleTranslations = new HashMap<>();

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "content_translations", columnDefinition = "jsonb")
    @Builder.Default
    private Map<String, String> contentTranslations = new HashMap<>();

    @Builder.Default
    private Boolean isPrivate = false;

    // Soft delete (standardized pattern - NULL means active, timestamp means deleted)
    @Column(name = "deleted_at")
    private Instant deletedAt;

    // Audit: who last updated this log post
    @Column(name = "updated_by_id")
    private Long updatedById;

    @OneToOne(mappedBy = "logPost", cascade = CascadeType.ALL)
    private RecipeLog recipeLog;

    @Builder.Default
    @OneToMany(mappedBy = "logPost", cascade = CascadeType.ALL)
    @OrderBy("displayOrder ASC")
    private List<Image> images = new ArrayList<>();

    @Builder.Default
    @ManyToMany
    @JoinTable(name = "log_post_hashtag_map",
            joinColumns = @JoinColumn(name = "log_post_id"),
            inverseJoinColumns = @JoinColumn(name = "hashtag_id"))
    private Set<Hashtag> hashtags = new HashSet<>();

    // Bookmark counter
    @Builder.Default
    @Column(name = "saved_count")
    private Integer savedCount = 0;

    public void incrementSavedCount() {
        this.savedCount = (this.savedCount == null ? 0 : this.savedCount) + 1;
    }

    public void decrementSavedCount() {
        this.savedCount = Math.max(0, (this.savedCount == null ? 0 : this.savedCount) - 1);
    }

    public boolean isDeleted() {
        return deletedAt != null;
    }

    public void softDelete() {
        this.deletedAt = Instant.now();
    }
}