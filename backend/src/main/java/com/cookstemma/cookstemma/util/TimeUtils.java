package com.cookstemma.cookstemma.util;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;

public class TimeUtils {
    // PostgreSQL TIMESTAMP 범위 내의 안전한 최소값 (예: 서기 1000년)
    public static final Instant SAFE_MIN_INSTANT = Instant.parse("1970-01-01T00:00:00Z");

    // 필요하다면 LocalDateTime 버전도 정의
    public static final LocalDateTime SAFE_MIN_DATE_TIME = LocalDateTime.of(1000, 1, 1, 0, 0, 0);
}