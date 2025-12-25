package com.pairingplanet.pairing_planet.domain.entity.post;

import jakarta.persistence.Column;
import jakarta.persistence.DiscriminatorValue;
import jakarta.persistence.Entity;
import lombok.*;
import lombok.experimental.SuperBuilder;
import org.hibernate.annotations.ColumnDefault;

@Entity
@DiscriminatorValue("REVIEW")
@Getter
@Setter
@SuperBuilder // [핵심] 부모의 빌더를 확장하기 위해 필수
@NoArgsConstructor(access = AccessLevel.PROTECTED) // JPA 필수
@AllArgsConstructor
public class ReviewPost extends Post {
    @Column(name = "title")
    private String title;

    @Column(name = "verdict_enabled")
    private boolean verdictEnabled;

}