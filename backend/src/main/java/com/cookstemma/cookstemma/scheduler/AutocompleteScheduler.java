package com.cookstemma.cookstemma.scheduler;

import com.cookstemma.cookstemma.domain.entity.autocomplete.AutocompleteItem;
import com.cookstemma.cookstemma.repository.autocomplete.AutocompleteItemRepository;
import com.cookstemma.cookstemma.service.AutocompleteService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Profile;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Slf4j
@Component
@Profile("!aws")
@RequiredArgsConstructor
public class AutocompleteScheduler {

    private final AutocompleteItemRepository autocompleteItemRepository;
    private final AutocompleteService autocompleteService;

    // Supported locales - 7 languages
    private static final List<String> SUPPORTED_LOCALES = List.of(
            "en-US", "ko-KR", "ja-JP", "fr-FR", "zh-CN", "es-ES", "it-IT"
    );

    @Scheduled(fixedRate = 3600000) // 1 hour
    @Transactional(readOnly = true)
    public void syncAutocompleteData() {
        log.info("Starting Autocomplete Sync to Redis...");

        // 1. Clear Redis for all locales
        for (String locale : SUPPORTED_LOCALES) {
            autocompleteService.clear(locale);
        }

        // 2. Sync autocomplete items
        List<AutocompleteItem> items = autocompleteItemRepository.findAll();
        for (AutocompleteItem item : items) {
            processAutocompleteItem(item);
        }

        log.info("Autocomplete Sync Completed. Synced {} items.", items.size());
    }

    private void processAutocompleteItem(AutocompleteItem item) {
        String type = item.getType().name();
        Double score = item.getScore() != null ? item.getScore() : 50.0;

        Map<String, String> names = item.getName();
        if (names == null) return;

        names.forEach((locale, name) -> {
            if (SUPPORTED_LOCALES.contains(locale)) {
                autocompleteService.add(locale, name, type, item.getPublicId(), score);
            }
        });
    }
}
