package com.pairingplanet.pairing_planet.dto.feed;

import com.pairingplanet.pairing_planet.dto.post.PostDto;
import lombok.Builder;
import java.util.List;

@Builder
public record FeedResponseDto(
        List<PostDto> posts,
        String nextCursor,
        boolean hasNext
) {}