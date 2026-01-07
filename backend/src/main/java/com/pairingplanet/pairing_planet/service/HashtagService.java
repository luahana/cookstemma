package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.hashtag.Hashtag;
import com.pairingplanet.pairing_planet.dto.hashtag.HashtagDto;
import com.pairingplanet.pairing_planet.repository.hashtag.HashtagRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class HashtagService {
    private final HashtagRepository hashtagRepository;

    /**
     * Get all hashtags
     */
    public List<HashtagDto> getAllHashtags() {
        return hashtagRepository.findAll().stream()
                .map(HashtagDto::from)
                .toList();
    }

    /**
     * Search hashtags by name prefix (for autocomplete)
     */
    public List<HashtagDto> searchHashtags(String query) {
        if (query == null || query.isBlank()) {
            return List.of();
        }
        String normalizedQuery = normalizeHashtagName(query);
        return hashtagRepository.findByNameContainingIgnoreCase(normalizedQuery).stream()
                .map(HashtagDto::from)
                .toList();
    }

    /**
     * Get or create hashtags from a list of names.
     * Returns a Set of Hashtag entities for association with recipes/log posts.
     */
    @Transactional
    public Set<Hashtag> getOrCreateHashtags(List<String> hashtagNames) {
        if (hashtagNames == null || hashtagNames.isEmpty()) {
            return new HashSet<>();
        }

        // Normalize hashtag names (remove # prefix if present, trim whitespace)
        List<String> normalizedNames = hashtagNames.stream()
                .map(this::normalizeHashtagName)
                .filter(name -> !name.isBlank())
                .distinct()
                .toList();

        if (normalizedNames.isEmpty()) {
            return new HashSet<>();
        }

        // Find existing hashtags
        List<Hashtag> existingHashtags = hashtagRepository.findByNameIn(normalizedNames);
        Set<String> existingNames = existingHashtags.stream()
                .map(Hashtag::getName)
                .collect(Collectors.toSet());

        // Create new hashtags for names that don't exist
        List<Hashtag> newHashtags = normalizedNames.stream()
                .filter(name -> !existingNames.contains(name))
                .map(name -> Hashtag.builder().name(name).build())
                .toList();

        if (!newHashtags.isEmpty()) {
            hashtagRepository.saveAll(newHashtags);
        }

        // Combine existing and new hashtags
        Set<Hashtag> allHashtags = new HashSet<>(existingHashtags);
        allHashtags.addAll(newHashtags);
        return allHashtags;
    }

    /**
     * Normalize hashtag name: remove # prefix, trim whitespace, convert to lowercase
     */
    private String normalizeHashtagName(String name) {
        if (name == null) {
            return "";
        }
        String trimmed = name.trim();
        if (trimmed.startsWith("#")) {
            trimmed = trimmed.substring(1);
        }
        return trimmed.toLowerCase();
    }
}
