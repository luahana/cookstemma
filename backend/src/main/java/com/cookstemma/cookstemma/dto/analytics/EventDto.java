package com.cookstemma.cookstemma.dto.analytics;

import com.fasterxml.jackson.annotation.JsonFormat;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

public record EventDto(
        UUID eventId,

        String eventType,

        UUID userId,

        @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS", timezone = "UTC")
        Instant timestamp,

        UUID recipeId,

        UUID logId,

        Map<String, Object> properties
) {}

