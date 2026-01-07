package com.pairingplanet.pairing_planet.domain.entity.recipe;

import com.pairingplanet.pairing_planet.domain.entity.log_post.LogPost;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "recipe_logs")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RecipeLog {
    @Id
    private Long logPostId;

    @OneToOne
    @MapsId
    @JoinColumn(name = "log_post_id")
    private LogPost logPost;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recipe_id")
    private Recipe recipe;

    private String outcome;  // SUCCESS, PARTIAL, FAILED
}