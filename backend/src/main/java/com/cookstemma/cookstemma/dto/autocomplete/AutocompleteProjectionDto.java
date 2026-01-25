package com.cookstemma.cookstemma.dto.autocomplete;

import java.util.UUID;

public interface AutocompleteProjectionDto {

    UUID getPublicId();

    // SQL: select ... as name
    String getName();

    // SQL: select 'FOOD' as type
    String getType();

    // SQL: select ... as score
    Double getScore();
}