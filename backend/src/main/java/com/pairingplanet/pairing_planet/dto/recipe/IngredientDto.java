package com.pairingplanet.pairing_planet.dto.recipe;

import com.pairingplanet.pairing_planet.domain.enums.IngredientType;

public record IngredientDto(String name, String amount, IngredientType type) {}