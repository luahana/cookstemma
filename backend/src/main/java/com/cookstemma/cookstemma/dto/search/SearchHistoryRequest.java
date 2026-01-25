package com.cookstemma.cookstemma.dto.search;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record SearchHistoryRequest(
        @NotBlank(message = "Query cannot be blank")
        @Size(max = 500, message = "Query cannot exceed 500 characters")
        String query
) {
}
