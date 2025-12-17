package com.pairingplanet.pairing_planet.repository.context;

import com.pairingplanet.pairing_planet.domain.entity.context.ContextDimension;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface ContextDimensionRepository extends JpaRepository<ContextDimension, Integer> {
    Optional<ContextDimension> findByName(String name);
}