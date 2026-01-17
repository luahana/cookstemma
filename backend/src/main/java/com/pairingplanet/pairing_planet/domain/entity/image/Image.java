package com.pairingplanet.pairing_planet.domain.entity.image;

import com.pairingplanet.pairing_planet.domain.entity.common.BaseEntity;
import com.pairingplanet.pairing_planet.domain.entity.log_post.LogPost;
import com.pairingplanet.pairing_planet.domain.entity.recipe.Recipe;
import com.pairingplanet.pairing_planet.domain.enums.ImageStatus;
import com.pairingplanet.pairing_planet.domain.enums.ImageType;
import com.pairingplanet.pairing_planet.domain.enums.ImageVariant;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;


@Entity
@Table(name = "images")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor
@SuperBuilder
public class Image extends BaseEntity {
    private String storedFilename;
    private String originalFilename;

    @Builder.Default
    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    private ImageStatus status = ImageStatus.PROCESSING;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    private ImageType type;

    @Builder.Default
    private Integer displayOrder = 0;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "log_post_id")
    private LogPost logPost;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recipe_id")
    private Recipe recipe;

    private Long uploaderId;

    // Variant-related fields
    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(name = "variant_type")
    private ImageVariant variantType;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "original_image_id")
    private Image originalImage;

    @OneToMany(mappedBy = "originalImage", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<Image> variants = new ArrayList<>();

    private Integer width;
    private Integer height;
    private Long fileSize;
    private String format;

    // Soft delete fields
    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Column(name = "delete_scheduled_at")
    private Instant deleteScheduledAt;

    // Audit: who last updated this image
    @Column(name = "updated_by_id")
    private Long updatedById;

    public boolean isOriginal() {
        return originalImage == null;
    }

    public boolean hasVariants() {
        return variants != null && !variants.isEmpty();
    }

    public boolean isDeleted() {
        return deletedAt != null;
    }
}