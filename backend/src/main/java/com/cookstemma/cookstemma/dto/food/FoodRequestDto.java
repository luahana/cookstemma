package com.cookstemma.cookstemma.dto.food;

import com.fasterxml.jackson.annotation.JsonCreator;

import java.util.UUID;

public record FoodRequestDto(
        UUID id,
        String name,
        String localeCode // 신규 음식일 경우 필요
) {
    // [수정] mode = JsonCreator.Mode.DELEGATING 을 추가해야
    // "qwer" 같은 단일 문자열을 객체로 변환할 수 있습니다.
    @JsonCreator(mode = JsonCreator.Mode.DELEGATING)
    public static FoodRequestDto fromString(String name) {
        return new FoodRequestDto(null, name, "ko-KR");
    }
}