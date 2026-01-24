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
    public ResponseEntity<Page<FoodMasterAdminDto>> getFoodsMaster(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String name,
            @RequestParam(required = false) Boolean isVerified,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortOrder
    ) {
        Sort sort = "asc".equalsIgnoreCase(sortOrder)
                ? Sort.by(sortBy).ascending()
                : Sort.by(sortBy).descending();
        Pageable pageable = PageRequest.of(page, size, sort);

        Specification<FoodMaster> spec = buildSpecification(name, isVerified);
        Page<FoodMaster> foodsPage = foodMasterRepository.findAll(spec, pageable);

        Page<FoodMasterAdminDto> dtoPage = foodsPage.map(FoodMasterAdminDto::from);
        return ResponseEntity.ok(dtoPage);
    }

    private Specification<FoodMaster> buildSpecification(String name, Boolean isVerified) {
        return (root, query, cb) -> {
            // Fetch category eagerly to avoid N+1 (only for actual entity queries, not count queries)
            if (query.getResultType() != Long.class && query.getResultType() != long.class) {
                root.fetch("category", JoinType.LEFT);
            }

            List<Predicate> predicates = new ArrayList<>();

            if (name != null && !name.isBlank()) {
                // Search in JSONB name field by casting to text
                // PostgreSQL: name::text ILIKE '%search%'
                String nameLower = "%" + name.toLowerCase() + "%";
                // Use native SQL function to cast JSONB to text for searching
                var nameAsText = cb.function("to_json", String.class, root.get("name")).as(String.class);
                predicates.add(cb.like(cb.lower(nameAsText), nameLower));
            }

            if (isVerified != null) {
                predicates.add(cb.equal(root.get("isVerified"), isVerified));
            }

            return predicates.isEmpty() ? null : cb.and(predicates.toArray(new Predicate[0]));
        };
    }
}
