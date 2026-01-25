package com.cookstemma.cookstemma.dto.block;

import java.util.List;

public record BlockedUsersListResponse(
        List<BlockedUserDto> content,
        boolean hasNext,
        int page,
        int size,
        long totalElements
) {}
