package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.domain.entity.food.FoodCategory;
import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.repository.food.FoodCategoryRepository;
import com.cookstemma.cookstemma.repository.food.FoodMasterRepository;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestJwtTokenProvider;
import com.cookstemma.cookstemma.support.TestUserFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.web.servlet.MockMvc;

import java.util.HashMap;
import java.util.Map;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class FoodMasterAdminControllerTest extends BaseIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private FoodMasterRepository foodMasterRepository;

    @Autowired
    private FoodCategoryRepository foodCategoryRepository;

    @Autowired
    private TestUserFactory testUserFactory;

    @Autowired
    private TestJwtTokenProvider testJwtTokenProvider;

    private User adminUser;
    private User regularUser;
    private String adminToken;
    private String userToken;
    private FoodMaster testFood;
    private FoodCategory testCategory;

    @BeforeEach
    void setUp() {
        adminUser = testUserFactory.createAdminUser();
        regularUser = testUserFactory.createTestUser();
        adminToken = testJwtTokenProvider.createAccessToken(adminUser.getPublicId(), "ADMIN");
        userToken = testJwtTokenProvider.createAccessToken(regularUser.getPublicId(), "USER");

        // Create a test category
        Map<String, String> categoryName = new HashMap<>();
        categoryName.put("en-US", "Test Category");
        categoryName.put("ko-KR", "테스트 카테고리");
        testCategory = FoodCategory.builder()
                .code("TEST_CATEGORY_" + System.currentTimeMillis())
                .name(categoryName)
                .depth(1)
                .build();
        foodCategoryRepository.saveAndFlush(testCategory);

        // Create a test food
        Map<String, String> foodName = new HashMap<>();
        foodName.put("en-US", "Test Food " + System.currentTimeMillis());
        foodName.put("ko-KR", "테스트 음식 " + System.currentTimeMillis());
        
        Map<String, String> foodDescription = new HashMap<>();
        foodDescription.put("en-US", "A test food description");
        foodDescription.put("ko-KR", "테스트 음식 설명");

        testFood = FoodMaster.builder()
                .name(foodName)
                .description(foodDescription)
                .category(testCategory)
                .foodScore(5.0)
                .isVerified(true)
                .searchKeywords(Map.of("en", "test, food"))
                .build();
        foodMasterRepository.saveAndFlush(testFood);
    }

    @Nested
    @DisplayName("GET /api/v1/admin/foods-master - List Foods Master")
    class ListFoodsMaster {

        @Test
        @DisplayName("Admin can get all foods master")
        void getFoodsMaster_AsAdmin_Success() throws Exception {
            mockMvc.perform(get("/api/v1/admin/foods-master")
                            .header("Authorization", "Bearer " + adminToken))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray())
                    .andExpect(jsonPath("$.content[0].publicId").exists())
                    .andExpect(jsonPath("$.content[0].name").exists())
                    .andExpect(jsonPath("$.content[0].isVerified").exists());
        }

        @Test
        @DisplayName("Admin can filter by name")
        void getFoodsMaster_FilterByName_Success() throws Exception {
            mockMvc.perform(get("/api/v1/admin/foods-master")
                            .header("Authorization", "Bearer " + adminToken)
                            .param("name", "Test Food"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray());
        }

        @Test
        @DisplayName("Admin can filter by isVerified true")
        void getFoodsMaster_FilterByVerifiedTrue_Success() throws Exception {
            mockMvc.perform(get("/api/v1/admin/foods-master")
                            .header("Authorization", "Bearer " + adminToken)
                            .param("isVerified", "true"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray());
        }

        @Test
        @DisplayName("Admin can filter by isVerified false")
        void getFoodsMaster_FilterByVerifiedFalse_Success() throws Exception {
            mockMvc.perform(get("/api/v1/admin/foods-master")
                            .header("Authorization", "Bearer " + adminToken)
                            .param("isVerified", "false"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray());
        }

        @Test
        @DisplayName("Admin can sort by foodScore ascending")
        void getFoodsMaster_SortByFoodScore_Success() throws Exception {
            mockMvc.perform(get("/api/v1/admin/foods-master")
                            .header("Authorization", "Bearer " + adminToken)
                            .param("sortBy", "foodScore")
                            .param("sortOrder", "asc"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray());
        }

        @Test
        @DisplayName("Admin can paginate results")
        void getFoodsMaster_Pagination_Success() throws Exception {
            mockMvc.perform(get("/api/v1/admin/foods-master")
                            .header("Authorization", "Bearer " + adminToken)
                            .param("page", "0")
                            .param("size", "10"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray())
                    .andExpect(jsonPath("$.totalElements").exists())
                    .andExpect(jsonPath("$.totalPages").exists())
                    .andExpect(jsonPath("$.size").value(10));
        }

        @Test
        @DisplayName("Response includes category name")
        void getFoodsMaster_IncludesCategoryName_Success() throws Exception {
            mockMvc.perform(get("/api/v1/admin/foods-master")
                            .header("Authorization", "Bearer " + adminToken))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content[0].categoryName").exists());
        }

        @Test
        @DisplayName("Non-admin cannot get foods master")
        void getFoodsMaster_AsUser_Forbidden() throws Exception {
            mockMvc.perform(get("/api/v1/admin/foods-master")
                            .header("Authorization", "Bearer " + userToken))
                    .andExpect(status().isForbidden());
        }

        @Test
        @DisplayName("Unauthenticated request returns 401")
        void getFoodsMaster_NoAuth_Unauthorized() throws Exception {
            mockMvc.perform(get("/api/v1/admin/foods-master"))
                    .andExpect(status().isUnauthorized());
        }
    }
}
