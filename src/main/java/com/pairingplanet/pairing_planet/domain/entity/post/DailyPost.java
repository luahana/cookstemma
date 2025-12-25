package com.pairingplanet.pairing_planet.domain.entity.post;

import jakarta.persistence.DiscriminatorValue;
import jakarta.persistence.Entity;
import lombok.AccessLevel;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;

@Entity
@DiscriminatorValue("DAILY")
@SuperBuilder
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class DailyPost extends Post {
}