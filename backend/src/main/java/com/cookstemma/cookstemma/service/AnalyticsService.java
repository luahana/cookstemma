package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.analytics.AnalyticsEvent;
import com.cookstemma.cookstemma.dto.analytics.EventDto;
import com.cookstemma.cookstemma.repository.analytics.AnalyticsEventRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional
public class AnalyticsService {
    private final AnalyticsEventRepository eventRepository;

    public void saveEvent(EventDto dto) {
        // Idempotency: 이미 처리된 eventId인지 확인
        if (eventRepository.existsByEventId(dto.eventId())) return;

        eventRepository.save(convertToEntity(dto));
    }

    public void saveBatchEvents(List<EventDto> dtos) {
        // 기존에 없는 eventId만 필터링하여 일괄 저장
        List<AnalyticsEvent> newEvents = dtos.stream()
                .filter(dto -> !eventRepository.existsByEventId(dto.eventId()))
                .map(this::convertToEntity)
                .toList();

        eventRepository.saveAll(newEvents);
    }

    public void deleteUserEvents(UUID userId) { // GDPR 대응
        eventRepository.deleteByUserId(userId);
    }

    private AnalyticsEvent convertToEntity(EventDto dto) {
        return AnalyticsEvent.builder()
                .eventId(dto.eventId())
                .eventType(dto.eventType())
                .userId(dto.userId())
                .recipeId(dto.recipeId())
                .logId(dto.logId())
                .timestamp(dto.timestamp())
                .properties(dto.properties())
                .build();
    }
}