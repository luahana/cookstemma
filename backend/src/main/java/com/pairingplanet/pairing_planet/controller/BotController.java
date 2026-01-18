package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.domain.entity.bot.BotCreatedFood;
import com.pairingplanet.pairing_planet.repository.bot.BotCreatedFoodRepository;
import com.pairingplanet.pairing_planet.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * API endpoints for bot-specific operations.
 */
@RestController
@RequestMapping("/api/v1/bot")
@RequiredArgsConstructor
public class BotController {

    private final BotCreatedFoodRepository botCreatedFoodRepository;

    /**
     * Get list of food names this bot has already created recipes for.
     * Uses username as the bot identifier.
     */
    @GetMapping("/created-foods")
    public ResponseEntity<List<String>> getCreatedFoods(
            @AuthenticationPrincipal UserPrincipal principal) {

        String botName = principal.getUsername();
        List<String> foods = botCreatedFoodRepository.findFoodNamesByPersonaName(botName);
        return ResponseEntity.ok(foods);
    }

    /**
     * Record that this bot created a recipe for a food.
     */
    @PostMapping("/created-foods")
    public ResponseEntity<Map<String, Object>> recordCreatedFood(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestBody RecordFoodRequest request) {

        String botName = principal.getUsername();

        // Check if already exists
        if (botCreatedFoodRepository.existsByPersonaNameAndFoodNameIgnoreCase(botName, request.foodName())) {
            return ResponseEntity.ok(Map.of(
                "recorded", false,
                "message", "Food already recorded"
            ));
        }

        // Record the new food
        BotCreatedFood record = BotCreatedFood.builder()
                .personaName(botName)
                .foodName(request.foodName())
                .recipePublicId(request.recipePublicId())
                .build();
        botCreatedFoodRepository.save(record);

        return ResponseEntity.ok(Map.of(
            "recorded", true,
            "foodName", request.foodName()
        ));
    }

    /**
     * Check if this bot has already created a recipe for a specific food.
     */
    @GetMapping("/created-foods/check")
    public ResponseEntity<Map<String, Boolean>> checkFoodExists(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam String foodName) {

        String botName = principal.getUsername();
        boolean exists = botCreatedFoodRepository.existsByPersonaNameAndFoodNameIgnoreCase(botName, foodName);
        return ResponseEntity.ok(Map.of("exists", exists));
    }

    record RecordFoodRequest(String foodName, UUID recipePublicId) {}
}
