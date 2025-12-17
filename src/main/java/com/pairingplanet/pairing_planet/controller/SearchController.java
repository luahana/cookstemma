package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.dto.search.PairingSearchRequestDto;
import com.pairingplanet.pairing_planet.dto.search.PostSearchResultDto;
import com.pairingplanet.pairing_planet.dto.search.SearchResponseDto;
import com.pairingplanet.pairing_planet.service.SearchService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/search")
@RequiredArgsConstructor
public class SearchController {

    private final SearchService searchService;

    @PostMapping("/posts")
    // [변경됨] 반환 타입 List<...> -> SearchResponseDto
    public ResponseEntity<SearchResponseDto> searchPosts(
            @RequestBody PairingSearchRequestDto request) {
        return ResponseEntity.ok(searchService.searchPosts(request));
    }
}