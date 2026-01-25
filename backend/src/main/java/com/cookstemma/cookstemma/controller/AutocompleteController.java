package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.dto.autocomplete.AutocompleteDto;
import com.cookstemma.cookstemma.service.AutocompleteService;
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
            @RequestParam(name = "locale", defaultValue = "ko-KR") String locale,
            @RequestParam(name = "type", required = false) String type
    ) {
        return autocompleteService.search(keyword, locale, type);
    }
}
