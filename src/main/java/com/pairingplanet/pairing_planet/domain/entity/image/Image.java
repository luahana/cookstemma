package com.pairingplanet.pairing_planet.domain.entity.image;

import com.pairingplanet.pairing_planet.domain.entity.common.BaseEntity;
import com.pairingplanet.pairing_planet.domain.entity.log_post.LogPost;
import com.pairingplanet.pairing_planet.domain.entity.recipe.Recipe;
import com.pairingplanet.pairing_planet.domain.enums.ImageStatus;
import com.pairingplanet.pairing_planet.domain.enums.ImageType;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

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
}