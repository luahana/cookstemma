package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.dto.admin.FoodMasterAdminDto;
import com.cookstemma.cookstemma.repository.food.FoodMasterRepository;
import jakarta.persistence.criteria.JoinType;
import jakarta.persistence.criteria.Predicate;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;

/**
 * Admin controller for viewing FoodMaster data.
 * All endpoints require ADMIN role.
 */
@RestController
@RequestMapping("/api/v1/admin/foods-master")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class FoodMasterAdminController {

    private final FoodMasterRepository foodMasterRepository;

    /**
     * Get paginated list of foods master with optional filters.
     *
     * GET /api/v1/admin/foods-master?page=0&size=20&name=...&isVerified=true&...
     */
    @GetMapping
    @Transactional(readOnly = true)
    public ResponseEntity<Page<FoodMasterAdminDto>> getFoodsMaster(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String name,
            @RequestParam(required = false) Boolean isVerified,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortOrder
    ) {
        // Map camelCase property names to snake_case column names for native queries
        String dbSortColumn = mapToColumnName(sortBy);
        Sort sort = "asc".equalsIgnoreCase(sortOrder)
                ? Sort.by(dbSortColumn).ascending()
                : Sort.by(dbSortColumn).descending();
        Pageable pageable = PageRequest.of(page, size, sort);

        Page<FoodMaster> foodsPage;

        // Use native queries for name search (JSONB text search)
        // Use Specification for other filters
        if (name != null && !name.isBlank()) {
            String namePattern = "%" + name + "%";
            if (isVerified != null) {
                foodsPage = foodMasterRepository.searchByNameContainingAndIsVerified(namePattern, isVerified, pageable);
            } else {
                foodsPage = foodMasterRepository.searchByNameContaining(namePattern, pageable);
            }
        } else {
            // No name filter - use Specification with JPA property names
            Sort jpaSort = "asc".equalsIgnoreCase(sortOrder)
                    ? Sort.by(sortBy).ascending()
                    : Sort.by(sortBy).descending();
            Pageable jpaPageable = PageRequest.of(page, size, jpaSort);
            Specification<FoodMaster> spec = buildSpecification(isVerified);
            foodsPage = foodMasterRepository.findAll(spec, jpaPageable);
        }

        Page<FoodMasterAdminDto> dtoPage = foodsPage.map(FoodMasterAdminDto::from);
        return ResponseEntity.ok(dtoPage);
    }

    private Specification<FoodMaster> buildSpecification(Boolean isVerified) {
        return (root, query, cb) -> {
            // Fetch category eagerly to avoid N+1 (only for actual entity queries, not count queries)
            if (query.getResultType() != Long.class && query.getResultType() != long.class) {
                root.fetch("category", JoinType.LEFT);
            }

            List<Predicate> predicates = new ArrayList<>();

            if (isVerified != null) {
                predicates.add(cb.equal(root.get("isVerified"), isVerified));
            }

            return predicates.isEmpty() ? null : cb.and(predicates.toArray(new Predicate[0]));
        };
    }

    /**
     * Map JPA camelCase property names to snake_case database column names for native queries.
     */
    private String mapToColumnName(String propertyName) {
        return switch (propertyName) {
            case "createdAt" -> "created_at";
            case "updatedAt" -> "updated_at";
            case "foodScore" -> "food_score";
            case "isVerified" -> "is_verified";
            case "searchKeywords" -> "search_keywords";
            case "publicId" -> "public_id";
            case "categoryId" -> "category_id";
            default -> propertyName;
        };
    }
}
