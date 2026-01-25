package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.Role;
import com.cookstemma.cookstemma.dto.admin.UserAdminDto;
import com.cookstemma.cookstemma.repository.specification.UserSpecification;
import com.cookstemma.cookstemma.repository.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AdminUserService {

    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public Page<UserAdminDto> getUsers(String username, String email, Role role,
                                        String sortBy, String sortOrder, int page, int size) {
        Sort.Direction direction = "asc".equalsIgnoreCase(sortOrder)
                ? Sort.Direction.ASC
                : Sort.Direction.DESC;

        String field = sortBy != null && !sortBy.isBlank() ? sortBy : "createdAt";
        Sort sort = Sort.by(direction, field);
        Pageable pageable = PageRequest.of(page, size, sort);

        return userRepository
                .findAll(UserSpecification.withFilters(username, email, role), pageable)
                .map(UserAdminDto::from);
    }

    @Transactional
    public UserAdminDto updateRole(UUID publicId, Role newRole, UUID currentUserPublicId) {
        // Prevent users from changing their own role
        if (publicId.equals(currentUserPublicId)) {
            throw new IllegalArgumentException("Cannot change your own role");
        }

        User user = userRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + publicId));

        user.setRole(newRole);
        return UserAdminDto.from(user);
    }
}
