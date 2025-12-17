package com.pairingplanet.pairing_planet.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.pairingplanet.pairing_planet.dto.food.FoodRequestDto;
import com.pairingplanet.pairing_planet.dto.post.CreatePostRequestDto;
import com.pairingplanet.pairing_planet.dto.post.PostResponseDto;
import com.pairingplanet.pairing_planet.service.PostService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(PostController.class)
class PostControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockitoBean
    private PostService postService;

    @Test
    @DisplayName("정상적인 포스트 생성 요청 시 200 OK를 반환해야 한다")
    void createPost_success() throws Exception {
        // given
        FoodRequestDto food1 = new FoodRequestDto(1L, "Pizza", "en");
        CreatePostRequestDto request = new CreatePostRequestDto(
                food1, null, null, null, null, "Yummy!",false,  true
        );

        PostResponseDto response = new PostResponseDto(
                100L, "Pizza", null, List.of(), "Yummy!", true, true, false
        );

        given(postService.createPost(eq(1L), any())).willReturn(response);

        // when & then
        mockMvc.perform(post("/api/v1/posts")
                        .header("X-User-Id", "1") // 헤더 시뮬레이션
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.postId").value(100L))
                .andExpect(jsonPath("$.food1Name").value("Pizza"));
    }

    @Test
    @DisplayName("Food1이 누락되면 400 Bad Request가 발생해야 한다 (Validation)")
    void createPost_validation_fail() throws Exception {
        // given
        // Food1 = null (필수값 누락)
        CreatePostRequestDto request = new CreatePostRequestDto(
                null, null, null, null, null, "Fail content", false, true
        );

        // when & then
        mockMvc.perform(post("/api/v1/posts")
                        .header("X-User-Id", "1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest()); // 400 에러 확인
    }
}