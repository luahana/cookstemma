package com.pairingplanet.pairing_planet.repository.bot;

import com.pairingplanet.pairing_planet.domain.entity.bot.BotPersona;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface BotPersonaRepository extends JpaRepository<BotPersona, Long> {

    Optional<BotPersona> findByPublicId(UUID publicId);

    Optional<BotPersona> findByName(String name);

    List<BotPersona> findByIsActiveTrue();

    List<BotPersona> findByLocaleAndIsActiveTrue(String locale);

    boolean existsByName(String name);
}
