package com.pairingplanet.pairing_planet.dto.autocomplete;

public interface AutocompleteProjectionDto {

    // SQL: select f.id as id
    Long getId();

    // SQL: select ... as name
    String getName();

    // SQL: select 'FOOD' as type
    String getType();

    // SQL: select ... as score
    Double getScore();
}