package com.pairingplanet.pairing_planet.dto.search;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record PostSearchResultDto(
        // [Post 메타 정보]
        Long postId,
        UUID postPublicId,
        String content,              // 포스트 내용
        List<String> imageUrls,      // 이미지 URL 리스트
        Instant createdAt,     // 생성일 (최신순 정렬 시 참고)

        // [작성자 정보]
        String creatorName,
        UUID creatorPublicId,

        // [음식 정보 - Food2는 null일 수 있음]
        String food1Name,
        UUID food1PublicId,
        String food2Name,
        UUID food2PublicId,

        // [태그 정보]
        String whenTagName,          // 화면 표시용 (예: "점심")
        String dietaryTagName,       // 화면 표시용 (예: "비건")

        // [통계 및 랭킹 정보 (FR-88)]
        int geniusCount,
        int daringCount,
        int pickyCount,
        int commentCount,
        int savedCount,
        double popularityScore,      // 랭킹 점수

        // [검색 상태 정보]
        boolean isWhenFallback       // FR-84: When 조건이 결과가 없어 무시되었는지 여부
) {}