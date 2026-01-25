package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.bot.BotPersona;
import com.cookstemma.cookstemma.dto.bot.BotPersonaDto;
import com.cookstemma.cookstemma.repository.bot.BotPersonaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * Service for managing bot personas.
 * Personas define the personality and content generation style for bots.
 */
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(readOnly = true)
public class BotPersonaService {

    private final BotPersonaRepository botPersonaRepository;

    /**
     * Gets all active personas.
     */
    public List<BotPersonaDto> getAllActivePersonas() {
        return botPersonaRepository.findByIsActiveTrue()
                .stream()
                .map(BotPersonaDto::from)
                .toList();
    }

    /**
     * Gets all personas (including inactive).
     */
    public List<BotPersonaDto> getAllPersonas() {
        return botPersonaRepository.findAll()
                .stream()
                .map(BotPersonaDto::from)
                .toList();
    }

    /**
     * Gets personas by locale.
     */
    public List<BotPersonaDto> getPersonasByLocale(String locale) {
        return botPersonaRepository.findByLocaleAndIsActiveTrue(locale)
                .stream()
                .map(BotPersonaDto::from)
                .toList();
    }

    /**
     * Gets a persona by public ID.
     */
    public BotPersonaDto getPersona(UUID publicId) {
        BotPersona persona = botPersonaRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("Persona not found: " + publicId));

        return BotPersonaDto.from(persona);
    }

    /**
     * Gets a persona by name.
     */
    public BotPersonaDto getPersonaByName(String name) {
        BotPersona persona = botPersonaRepository.findByName(name)
                .orElseThrow(() -> new IllegalArgumentException("Persona not found: " + name));

        return BotPersonaDto.from(persona);
    }

    /**
     * Activates or deactivates a persona.
     */
    @Transactional
    public void setPersonaActive(UUID publicId, boolean active) {
        BotPersona persona = botPersonaRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("Persona not found: " + publicId));

        persona.setActive(active);

        log.info("Set persona active: name={}, active={}", persona.getName(), active);
    }

    /**
     * Gets the raw entity (for internal use by other services).
     */
    public BotPersona getPersonaEntity(UUID publicId) {
        return botPersonaRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("Persona not found: " + publicId));
    }
}
