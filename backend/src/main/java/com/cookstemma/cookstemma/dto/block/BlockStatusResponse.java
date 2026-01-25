package com.cookstemma.cookstemma.dto.block;

public record BlockStatusResponse(
        boolean isBlocked,  // Has the current user blocked the target user?
        boolean amBlocked   // Has the target user blocked the current user?
) {}
