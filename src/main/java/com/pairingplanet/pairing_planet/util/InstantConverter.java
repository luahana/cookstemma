package com.pairingplanet.pairing_planet.util; // 패키지 위치 확인

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.sql.Timestamp;
import java.time.Instant;

@Converter(autoApply = true) // [중요] 모든 Instant 필드에 자동 적용
public class InstantConverter implements AttributeConverter<Instant, Timestamp> {

    private static final Instant SAFE_MIN = Instant.parse("1970-01-01T00:00:00Z");

    @Override
    public Timestamp convertToDatabaseColumn(Instant attribute) {
        if (attribute == null) return null;
        // DB로 갈 때: 날짜가 너무 옛날이면 1970년으로 고침
        if (attribute.isBefore(SAFE_MIN)) {
            return Timestamp.from(SAFE_MIN);
        }
        return Timestamp.from(attribute);
    }

    @Override
    public Instant convertToEntityAttribute(Timestamp dbData) {
        if (dbData == null) return null;
        return dbData.toInstant();
    }
}