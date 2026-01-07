package com.pairingplanet.pairing_planet.scheduler;

import com.pairingplanet.pairing_planet.domain.entity.food.FoodCategory;
import com.pairingplanet.pairing_planet.domain.entity.food.FoodMaster;
import com.pairingplanet.pairing_planet.repository.food.FoodCategoryRepository;
import com.pairingplanet.pairing_planet.repository.food.FoodMasterRepository;
import com.pairingplanet.pairing_planet.service.AutocompleteService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Profile;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Slf4j
@Component
@Profile("!aws")
@RequiredArgsConstructor
public class AutocompleteScheduler {

    private final FoodMasterRepository foodMasterRepository;
    private final FoodCategoryRepository foodCategoryRepository;
    private final AutocompleteService autocompleteService;

    // 지원하는 로케일 목록 (상수 관리 추천)
    private static final List<String> SUPPORTED_LOCALES = List.of("en-US", "ko-KR", "ja-JP");

    @Scheduled(fixedRate = 3600000) // 1시간
    @Transactional(readOnly = true)
    public void syncAutocompleteData() {
        log.info("Starting Autocomplete Sync to Redis...");

        // 1. Redis 초기화 (모든 로케일)
        for (String locale : SUPPORTED_LOCALES) {
            autocompleteService.clear(locale);
        }

        // 2. 카테고리 동기화
        // Repository 로직 반영: 이름(Name) + 코드(Code) 모두 검색 가능하게 저장
        List<FoodCategory> categories = foodCategoryRepository.findAll();
        for (FoodCategory c : categories) {
            processCategory(c);
        }

        // 3. 음식 마스터 동기화
        // Repository 로직 반영: 검증된(isVerified) 음식만 저장
        List<FoodMaster> foods = foodMasterRepository.findAllVerified();
        for (FoodMaster f : foods) {
            processFood(f);
        }

        log.info("Autocomplete Sync Completed.");
    }

    private void processCategory(FoodCategory c) {
        // 카테고리는 중요하므로 기본 점수 높게 부여
        double baseScore = 100.0;

        // 1) 이름으로 저장 (로케일별)
        Map<String, String> names = c.getName(); // JSONB -> Map
        if (names == null) return;
        else {
            names.forEach((locale, name) -> {
                if (SUPPORTED_LOCALES.contains(locale)) {
                    autocompleteService.add(locale, name, "CATEGORY", c.getPublicId(), baseScore);
                }
            });
        }

        // 2) 코드(Code)로 저장 (예: "NOODLE")
        // 코드는 영문인 경우가 많으므로 보통 'en' 로케일이나 전체 로케일에 추가
        if (c.getCode() != null) {
            for (String locale : SUPPORTED_LOCALES) {
                // "NOODLE"을 입력해도 검색되도록 추가.
                // 단, 화면에 보여질 이름(display name)이 필요하므로, 로케일별 이름을 매핑해야 함.
                String displayName = names.getOrDefault(locale, c.getCode());
                // 검색어는 Code, 표시는 Name
                // 하지만 현재 구조(add)는 검색어=표시이름 이므로,
                // 코드로 검색되게 하려면 별도 처리가 필요하지만,
                // 간단하게 "Code" 자체를 자동완성 리스트에 띄워줍니다.
                autocompleteService.add(locale, c.getCode(), "CATEGORY", c.getPublicId(), baseScore - 1.0);
            }
        }
    }

    private void processFood(FoodMaster f) {
        // 인기 점수 사용 (없으면 0.0)
        double score = (f.getFoodScore() != null) ? f.getFoodScore() : 0.0;

        Map<String, String> names = f.getName();
        if (names != null) {
            names.forEach((locale, name) -> {
                if (SUPPORTED_LOCALES.contains(locale)) {
                    autocompleteService.add(locale, name, "FOOD", f.getPublicId(), score);
                }
            });
        }

        // (선택) Search Keywords(유의어)도 추가하고 싶다면 여기서 처리
        // 예: "삼겹살"의 유의어 "Pork Belly"가 있다면 추가
    }
}