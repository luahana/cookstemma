package com.pairingplanet.pairing_planet.domain.entity.log_post;

import com.pairingplanet.pairing_planet.domain.entity.common.BaseEntity;
import com.pairingplanet.pairing_planet.domain.entity.hashtag.Hashtag;
import com.pairingplanet.pairing_planet.domain.entity.image.Image;
import com.pairingplanet.pairing_planet.domain.entity.recipe.RecipeLog;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;

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
    private String title;
    private String content;
    private Long creatorId;

    // [추가] 레포지토리에서 필터링을 위해 필요한 필드들입니다.
    @Builder.Default
    private Boolean isPrivate = false;

    @Builder.Default
    private Boolean isDeleted = false;

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
}