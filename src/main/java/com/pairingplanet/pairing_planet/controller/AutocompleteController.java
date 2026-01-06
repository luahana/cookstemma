package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.dto.autocomplete.AutocompleteDto;
import com.pairingplanet.pairing_planet.service.AutocompleteService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/autocomplete")
@RequiredArgsConstructor
public class AutocompleteController {

    private final AutocompleteService autocompleteService;

    @GetMapping
    public List<AutocompleteDto> autocomplete(
            @RequestParam(name = "keyword") String keyword,
            @RequestParam(name = "locale", defaultValue = "ko-KR") String locale
    ) {
        return autocompleteService.search(keyword, locale);
    }
}
