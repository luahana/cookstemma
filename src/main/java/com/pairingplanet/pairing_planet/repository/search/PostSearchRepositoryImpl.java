package com.pairingplanet.pairing_planet.repository.search;

import com.pairingplanet.pairing_planet.domain.entity.food.FoodMaster;
import com.pairingplanet.pairing_planet.domain.entity.food.QFoodMaster;
import com.pairingplanet.pairing_planet.domain.entity.context.QContextTag;

import com.pairingplanet.pairing_planet.dto.search.PairingSearchRequestDto;
import com.pairingplanet.pairing_planet.dto.search.PostSearchResultDto;
import com.pairingplanet.pairing_planet.dto.search.SearchCursorDto;
import com.querydsl.core.BooleanBuilder;
import com.querydsl.core.Tuple;
import com.querydsl.jpa.impl.JPAQueryFactory;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.Collections;
import java.util.List;
import java.util.Map;

import static com.pairingplanet.pairing_planet.domain.entity.post.QPost.post;
import static com.pairingplanet.pairing_planet.domain.entity.pairing.QPairingMap.pairingMap;
import static com.pairingplanet.pairing_planet.domain.entity.user.QUser.user;

@Repository
@RequiredArgsConstructor
public class PostSearchRepositoryImpl implements PostSearchRepositoryCustom {

    private final JPAQueryFactory queryFactory;

    // Q-Class 정의 (Join용)
    private static final QFoodMaster f1 = new QFoodMaster("f1");
    private static final QFoodMaster f2 = new QFoodMaster("f2");
    private static final QContextTag ctxWhen = new QContextTag("ctxWhen");
    private static final QContextTag ctxDiet = new QContextTag("ctxDiet");

    @Override
    public List<PostSearchResultDto> searchPosts(PairingSearchRequestDto request, SearchCursorDto cursor, int limit) {
        return executeSearch(request, cursor, limit, false);
    }

    @Override
    public List<PostSearchResultDto> searchPostsFallback(PairingSearchRequestDto request, SearchCursorDto cursor, int limit) {
        return executeSearch(request, cursor, limit, true);
    }

    private List<PostSearchResultDto> executeSearch(PairingSearchRequestDto request, SearchCursorDto cursor, int limit, boolean ignoreWhenTag) {

        // 1. 결과 조회 (Tuple로 조회하여 필요한 Entity들만 가져옴)
        List<Tuple> results = queryFactory
                .select(post, user, f1, f2, ctxWhen, ctxDiet)
                .from(post)
                .join(post.pairing, pairingMap) // Post -> PairingMap
                .join(post.creator, user)          // Post -> User
                .join(pairingMap.food1, f1)  // PairingMap -> Food1
                .leftJoin(pairingMap.food2, f2) // PairingMap -> Food2 (Optional)
                .leftJoin(pairingMap.whenContext, ctxWhen)
                .leftJoin(pairingMap.dietaryContext, ctxDiet)
                .where(
                        post.isDeleted.isFalse(),
                        post.isPrivate.isFalse(),
                        buildFilterConditions(request, ignoreWhenTag), // 필터 조건
                        buildCursorCondition(cursor)                   // 커서 조건
                )
                .orderBy(post.popularityScore.desc(), post.id.desc()) // 정렬 (Score -> ID)
                .limit(limit)
                .fetch();

        // 2. DTO 변환
        return results.stream()
                .map(tuple -> convertToDto(tuple, request.locale(), ignoreWhenTag))
                .toList();
    }

    // --- 조건 빌더 (BooleanBuilder) ---

    private BooleanBuilder buildFilterConditions(PairingSearchRequestDto request, boolean ignoreWhenTag) {
        BooleanBuilder builder = new BooleanBuilder();

        // FR-80: Food Tags Search (교차 검증)
        if (request.foodIds() != null && !request.foodIds().isEmpty()) {
            List<Long> foods = request.foodIds();
            if (foods.size() == 1) {
                Long id = foods.get(0);
                // (Food1 == id OR Food2 == id)
                builder.and(pairingMap.food1.id.eq(id).or(pairingMap.food2.id.eq(id)));
            } else if (foods.size() >= 2) {
                Long id1 = foods.get(0);
                Long id2 = foods.get(1);
                // (F1=id1 AND F2=id2) OR (F1=id2 AND F2=id1)
                builder.and(
                        (pairingMap.food1.id.eq(id1).and(pairingMap.food2.id.eq(id2)))
                                .or(pairingMap.food1.id.eq(id2).and(pairingMap.food2.id.eq(id1)))
                );
            }
        }

        // FR-83: Dietary Tag (Hard Filter)
        if (request.dietaryContextId() != null) {
            builder.and(pairingMap.dietaryContext.id.eq(request.dietaryContextId()));
        }

        // FR-84: When Tag (Soft Filter)
        if (!ignoreWhenTag && request.whenContextId() != null) {
            builder.and(pairingMap.whenContext.id.eq(request.whenContextId()));
        }

        return builder;
    }

    // 커서 조건: (score < lastScore) OR (score = lastScore AND id < lastId)
    private BooleanBuilder buildCursorCondition(SearchCursorDto cursor) {
        if (cursor == null || cursor.lastScore() == null) return new BooleanBuilder();

        BooleanBuilder builder = new BooleanBuilder();
        builder.and(
                post.popularityScore.lt(cursor.lastScore())
                        .or(post.popularityScore.eq(cursor.lastScore()).and(post.id.lt(cursor.lastId())))
        );
        return builder;
    }

    // --- DTO 매핑 헬퍼 ---

    private PostSearchResultDto convertToDto(Tuple tuple, String locale, boolean isFallback) {
        var p = tuple.get(post);
        var u = tuple.get(user);
        var food1 = tuple.get(f1);
        var food2 = tuple.get(f2);
        var when = tuple.get(ctxWhen);
        var diet = tuple.get(ctxDiet);

        return new PostSearchResultDto(
                p.getId(),
                p.getPublicId(),
                p.getContent(),
                p.getImageUrls() != null ? p.getImageUrls() : Collections.emptyList(),
                p.getCreatedAt(),

                u.getUsername(), // or getNickname
                u.getPublicId(),

                getLocalizedName(food1, locale),
                food1.getPublicId(),
                getLocalizedName(food2, locale),
                food2 != null ? food2.getPublicId() : null,

                when != null ? when.getDisplayName() : null, // DisplayName은 보통 단일값이거나 Locale 처리 필요
                diet != null ? diet.getDisplayName() : null,

                p.getGeniusCount(),
                p.getDaringCount(),
                p.getPickyCount(),
                p.getCommentCount(),
                p.getSavedCount(),
                p.getPopularityScore(),
                isFallback
        );
    }

    // JSON 형태의 이름에서 로케일 추출 (Entity 메서드나 JSON 파싱 로직 활용)
    private String getLocalizedName(FoodMaster food, String locale) {
        // 1. 방어 로직 (Null Check)
        if (food == null || food.getName() == null || food.getName().isEmpty()) {
            return "Unknown Food"; // 혹은 null
        }

        // 2. Map 가져오기
        Map<String, String> names = food.getName();

        // 3. 우선순위 로직
        // Case A: 요청한 로케일(예: "ko")이 있으면 반환
        if (names.containsKey(locale)) {
            return names.get(locale);
        }

        // Case B: 없으면 영어("en") 반환 (Fallback)
        if (names.containsKey("en")) {
            return names.get("en");
        }

        // Case C: 영어도 없으면 맵에 있는 것 중 아무거나 첫 번째 반환
        return names.values().stream().findFirst().orElse("Unknown Food");
    }
}