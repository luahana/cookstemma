# Technical Specification - Pairing Planet

## Project Overview

**Pairing Planet** is a full-stack application (Flutter mobile + Spring Boot backend) that treats recipes as an **evolving knowledge graph** rather than static content. The app documents how recipes survive, evolve, and branch through user experimentation.

### Core Philosophy
> "This app is not a place to consume recipes—it's a system that records the process of recipes staying alive."

### Key Principles
1. **Recipes as Living Knowledge**: Recipes evolve through variations (original → modified versions)
2. **Logs Keep Recipes Alive**: Cooking logs (photos, reviews, ratings) give recipes vitality
3. **Progressive Authentication**: Login is NOT forced—only prompted when users create value
4. **Mobile-Only**: No web version; designed exclusively for mobile experience

---

# Table of Contents
- [Content Model](#content-model)
- [Backend Architecture](#backend-architecture)
- [Frontend Architecture](#frontend-architecture)
- [API Contracts](#api-contracts)
- [Authentication & UX Philosophy](#authentication--ux-philosophy)
- [Feed Strategy](#feed-strategy)
- [Performance Considerations](#performance-considerations)
- [Production-Ready Enhancements](#production-ready-enhancements)
- [Planned Features](#planned-features)
- [Dependencies](#dependencies)

---

# Content Model

## Core Entities

### Recipe
Represents a dish—either an **original recipe** or a **variation** of an existing recipe.

**Structure**:
- `publicId`: Unique identifier (UUID)
- `title`: Recipe name
- `description`: Recipe overview
- `ingredients[]`: List of ingredients with amounts and types (MAIN, SECONDARY, SEASONING)
- `steps[]`: Cooking instructions with optional step images
- `imagePublicIds[]`: Recipe thumbnail photos
- `parentPublicId`: Reference to parent recipe (if this is a variation; null for originals)
- `rootPublicId`: Reference to original recipe (root of variation tree; null for originals)
- `changeCategory`: Type of modification made (e.g., "ingredient swap", "technique change", "seasoning")

**Variation Tree**:
```
Original Recipe (root)
├── Variation A (parentId → Original, rootId → Original)
│   └── Variation A1 (parentId → A, rootId → Original)
└── Variation B (parentId → Original, rootId → Original)
```

**Business Rules**:
- Original recipes have `parentPublicId = null` and `rootPublicId = null`
- Variations must reference both parent and root for tree navigation
- "Inspired by" relationship is explicitly tracked
- ✅ **Soft delete only**—recipes are never hard-deleted (preservation philosophy)

**Graph Traversal Queries**:
```dart
// Get all variations of a recipe (entire tree)
Future<List<Recipe>> getAllVariations(String recipeId) async {
  return await db.recipes
    .where('rootPublicId', isEqualTo: recipeId)
    .where('deletedAt', isNull: true)
    .get();
}

// Get direct children only
Future<List<Recipe>> getDirectChildren(String recipeId) async {
  return await db.recipes
    .where('parentPublicId', isEqualTo: recipeId)
    .where('deletedAt', isNull: true)
    .get();
}

// Get ancestry path (traverse up to root)
Future<List<Recipe>> getAncestryPath(String recipeId) async {
  List<Recipe> path = [];
  String? currentId = recipeId;

  while (currentId != null) {
    final recipe = await db.recipes.doc(currentId).get();
    path.insert(0, recipe);
    currentId = recipe.parentPublicId;
  }

  return path;
}
```

### Log Post
A cooking attempt record: photos, review, rating, and commentary.

**Structure**:
- `publicId`: Unique identifier (UUID)
- `recipePublicId`: Reference to the recipe that was cooked (**foreign key**, not embedded)
- `title`: Optional log title
- `content`: Cooking notes, review, commentary
- `rating`: 1-5 stars (integer)
- `imagePublicIds[]`: Photos of the cooking attempt
- `creatorName`: User who created the log
- `createdAt`: Timestamp

**Business Rules**:
- Logs are **separate entities** from recipes (NOT embedded documents)
- Multiple logs can reference the same recipe
- Logs give recipes "vitality"—recipes with many logs rank higher in feed
- ✅ **Soft delete only**—logs are preserved even if parent recipe is deleted

### Image
Media files associated with recipes or logs, served via CDN.

**Structure**:
- `imagePublicId`: UUID identifier
- `imageUrl`: CDN URL for accessing the image
- `originalFilename`: Original file name
- `type`: "THUMBNAIL" (recipe photos) or "LOG_POST" (log photos)
- `uploadedAt`: Timestamp

**Upload Flow (Current)**:
1. Client selects image (camera/gallery)
2. Client uploads to backend API
3. Backend stores in cloud storage and returns `imagePublicId` + `imageUrl`
4. Client stores publicId reference

**Upload Flow (Planned - Presigned URLs)**:
1. Client requests presigned URL from backend
2. Backend generates presigned URL, returns to client
3. Client uploads directly to CDN
4. Client notifies backend of completion
5. Backend stores metadata

### Hashtag (Planned Feature)
Weak classification system for discovery and context.

**Structure**:
- `tag`: Hashtag text (e.g., "vegetarian", "quick-meal", "spicy")
- `usageCount`: Number of recipes using this tag
- `trending`: Boolean flag for trending tags

**Purpose**:
- Enable exploration and search
- Provide contextual connections between recipes
- NOT a strict categorization—recipes can have 0-5 hashtags
- User-generated, organic discovery

## Relationships

```
Recipe (Original)
  ↓ (1:N)
Recipe (Variations) ← parentPublicId, rootPublicId
  ↓ (1:N)
LogPost ← recipePublicId
  ↓ (1:N)
Image ← imagePublicIds[]
```

**Key Design Decision**: Recipe and Log are **separate entities** to:
- Avoid write hotspots (logs are more frequently created than recipes)
- Enable independent scaling (read-heavy recipe queries vs write-heavy log creation)
- Preserve content integrity (orphaned logs kept if recipe deleted)

---

# Backend Architecture

## Technology Stack

- **Framework**: Spring Boot 3.5.8
- **Language**: Java 21
- **Database**: PostgreSQL 16
- **Cache**: Redis (Alpine)
- **Storage**: AWS S3 / MinIO (S3-compatible)
- **Authentication**: Firebase Admin SDK 9.2.0 + JWT (jjwt 0.12.3)
- **ORM**: Spring Data JPA with Hibernate
- **Query DSL**: QueryDSL 5.1.0 (type-safe queries)
- **Migrations**: Flyway
- **Testing**: JUnit 5, TestContainers
- **Build Tool**: Gradle with Spring Boot Plugin

## Spring Boot Layer Architecture

```
src/main/java/com/pairingplanet/pairing_planet/
├── controller/          # REST API endpoints (@RestController)
│   ├── AuthController.java
│   ├── RecipeController.java
│   ├── LogPostController.java
│   ├── ImageController.java
│   ├── AnalyticsController.java
│   └── HomeController.java
│
├── service/             # Business logic layer
│   ├── AuthService.java
│   ├── RecipeService.java
│   ├── LogPostService.java
│   ├── ImageService.java
│   └── AnalyticsService.java
│
├── repository/          # Data access layer (Spring Data JPA)
│   ├── UserRepository.java
│   ├── RecipeRepository.java
│   ├── LogPostRepository.java
│   └── ImageRepository.java
│
├── domain/              # JPA entities (@Entity)
│   ├── User.java
│   ├── Recipe.java (posts table)
│   ├── LogPost.java
│   ├── Image.java
│   └── SocialAccount.java
│
├── dto/                 # Request/Response DTOs
│   ├── recipe/
│   ├── log_post/
│   ├── auth/
│   └── image/
│
├── config/              # Configuration classes
│   ├── SecurityConfig.java
│   ├── FirebaseConfig.java
│   ├── S3Config.java / MinioConfig.java
│   ├── RedisConfig.java
│   ├── QueryDslConfig.java
│   └── WebConfig.java (CORS, interceptors)
│
├── security/            # Authentication & authorization
│   ├── JwtTokenProvider.java
│   ├── FirebaseTokenValidator.java
│   ├── UserPrincipal.java
│   └── JwtAuthenticationFilter.java
│
├── exception/           # Custom exceptions & error handlers
│   ├── GlobalExceptionHandler.java
│   ├── RecipeNotFoundException.java
│   └── UnauthorizedException.java
│
├── scheduler/           # Scheduled tasks (@Scheduled)
│   └── FeedRankingScheduler.java
│
└── util/                # Utility classes
    └── S3Util.java
```

## Database Schema Overview

**Migration Tool**: Flyway
**Location**: `src/main/resources/db/migration/`

**Core Tables**:

### users
```sql
CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),

    username VARCHAR(50) NOT NULL UNIQUE,
    profile_image_url TEXT,
    email VARCHAR(255),

    gender VARCHAR(10) CHECK (gender IN ('MALE', 'FEMALE', 'OTHER')),
    birth_date DATE,
    locale VARCHAR(10) NOT NULL,

    role VARCHAR(20) DEFAULT 'USER' CHECK (role IN ('USER', 'ADMIN', 'CREATOR')),
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'BANNED', 'DELETED')),

    app_refresh_token VARCHAR(512),

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
```

### social_accounts
```sql
CREATE TABLE social_accounts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),

    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    provider VARCHAR(20) NOT NULL CHECK (provider IN ('GOOGLE', 'NAVER', 'KAKAO', 'APPLE')),
    provider_user_id VARCHAR(255) NOT NULL,

    email VARCHAR(255),
    access_token TEXT,
    refresh_token TEXT,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    UNIQUE(provider, provider_user_id)
);
```

### posts (Recipes)
```sql
CREATE TABLE posts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),

    title VARCHAR(255) NOT NULL,
    description TEXT,

    ingredients JSONB NOT NULL DEFAULT '[]',
    steps JSONB NOT NULL DEFAULT '[]',
    image_public_ids TEXT[] DEFAULT '{}',

    parent_public_id UUID REFERENCES posts(public_id),
    root_public_id UUID REFERENCES posts(public_id),
    change_category VARCHAR(50),

    creator_id BIGINT NOT NULL REFERENCES users(id),
    locale VARCHAR(10) NOT NULL,

    ranking_score DOUBLE PRECISION DEFAULT 0.0,

    deleted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_posts_parent ON posts(parent_public_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_posts_root ON posts(root_public_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_posts_ranking ON posts(ranking_score DESC, created_at DESC) WHERE deleted_at IS NULL;
```

### log_posts
```sql
CREATE TABLE log_posts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),

    recipe_public_id UUID NOT NULL REFERENCES posts(public_id),

    title VARCHAR(255),
    content TEXT,
    rating INT CHECK (rating BETWEEN 1 AND 5),

    image_public_ids TEXT[] DEFAULT '{}',

    creator_id BIGINT NOT NULL REFERENCES users(id),

    deleted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_log_posts_recipe ON log_posts(recipe_public_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_log_posts_creator ON log_posts(creator_id) WHERE deleted_at IS NULL;
```

### images
```sql
CREATE TABLE images (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),

    image_url TEXT NOT NULL,
    original_filename VARCHAR(255),

    image_type VARCHAR(20) CHECK (image_type IN ('THUMBNAIL', 'LOG_POST', 'STEP')),

    uploader_id BIGINT REFERENCES users(id),

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
```

**Schema Conventions**:
- Primary key: `id BIGINT` (internal, never exposed)
- Public ID: `public_id UUID` (external-facing)
- Soft delete: `deleted_at TIMESTAMP WITH TIME ZONE`
- Timestamps: `created_at`, `updated_at` (both `TIMESTAMP WITH TIME ZONE`)
- JSONB for structured data (ingredients, steps)
- Arrays for simple lists (image_public_ids)

## Security & Authentication

### Firebase → JWT Flow

**Step 1: Client Login (Frontend)**
1. User signs in with Google via Firebase Auth
2. Firebase returns ID token
3. Client sends ID token to backend

**Step 2: Backend Token Validation**
```java
POST /api/v1/auth/social-login
{
  "provider": "GOOGLE",
  "idToken": "eyJhbG...",
  "locale": "ko-KR"
}
```

**Step 3: Backend Processing**
1. Validate Firebase ID token with Firebase Admin SDK
2. Extract user info (email, name, uid)
3. Find or create user in database
4. Generate JWT access + refresh tokens
5. Store refresh token in database
6. Return tokens to client

**Step 4: Client Token Storage**
- Access token: In-memory or secure storage
- Refresh token: Secure storage (flutter_secure_storage)

**Step 5: Authenticated Requests**
```
GET /api/v1/recipes/{id}
Authorization: Bearer {accessToken}
```

**Step 6: Token Refresh**
```java
POST /api/v1/auth/reissue
{
  "refreshToken": "..."
}

Response:
{
  "accessToken": "new-access-token",
  "refreshToken": "new-refresh-token"
}
```

### JWT Token Structure

**Access Token** (1 hour expiration):
```json
{
  "sub": "user-uuid",
  "email": "user@example.com",
  "role": "USER",
  "iat": 1234567890,
  "exp": 1234571490
}
```

**Refresh Token** (30 days expiration):
- Stored in database (`users.app_refresh_token`)
- Single-use (invalidated on refresh)
- Linked to user account

### Spring Security Configuration

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) {
        http
            .csrf(csrf -> csrf.disable())
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .sessionManagement(session -> session.sessionCreationPolicy(STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/v1/auth/**").permitAll()
                .requestMatchers("/actuator/health").permitAll()
                .requestMatchers("/api/v1/**").authenticated()
            )
            .addFilterBefore(jwtAuthenticationFilter(), UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }
}
```

**Endpoints**:
- **Public**: `/auth/**`, `/actuator/health`
- **Authenticated**: All other `/api/v1/**` endpoints

## S3/MinIO Image Storage

### Configuration

**AWS S3** (Production):
```yaml
cloud:
  aws:
    s3:
      bucket: pairing-planet-images
    credentials:
      access-key: ${AWS_ACCESS_KEY}
      secret-key: ${AWS_SECRET_KEY}
    region:
      static: ap-northeast-2
```

**MinIO** (Local Development):
```yaml
minio:
  endpoint: http://localhost:9000
  access-key: minioadmin
  secret-key: minioadmin
  bucket: pairing-planet-images
```

### Image Upload Flow

**Current Implementation**:
1. Client: `POST /api/v1/images/upload` (multipart/form-data)
2. Backend receives file
3. Backend uploads to S3/MinIO with UUID filename
4. Backend saves metadata to `images` table
5. Backend returns:
   ```json
   {
     "imagePublicId": "550e8400-e29b-41d4-a716-446655440000",
     "imageUrl": "https://cdn.pairingplanet.com/images/550e8400..."
   }
   ```

**Planned: Presigned URL Upload**:
1. Client: `POST /api/v1/images/presigned-url` → Get presigned URL
2. Client: Upload directly to S3 via presigned URL
3. Client: `POST /api/v1/images/confirm` → Notify backend of completion
4. Backend: Save metadata

**Benefits**: Reduces backend bandwidth, faster uploads

## Redis Caching Strategy

### Use Cases

1. **User Sessions (Refresh Tokens)**
   - Key: `refresh_token:{token}`
   - Value: User ID
   - TTL: 30 days

2. **Feed Ranking Scores**
   - Key: `feed:ranking`
   - Type: Sorted Set (ZADD)
   - Value: Recipe public IDs sorted by score

3. **Rate Limiting**
   - Key: `rate_limit:{userId}:{endpoint}`
   - Type: Counter with TTL
   - TTL: 1 hour

4. **Autocomplete Cache**
   - Key: `autocomplete:{query}`
   - Type: List
   - TTL: 1 hour

### Spring Cache Configuration

```java
@Configuration
@EnableCaching
public class RedisConfig {
    @Bean
    public CacheManager cacheManager(RedisConnectionFactory factory) {
        RedisCacheConfiguration config = RedisCacheConfiguration.defaultCacheConfig()
            .entryTtl(Duration.ofMinutes(10))
            .serializeValuesWith(/* Jackson serializer */);

        return RedisCacheManager.builder(factory)
            .cacheDefaults(config)
            .build();
    }
}
```

**Usage**:
```java
@Cacheable(value = "recipes", key = "#publicId")
public RecipeDetailResponseDto getRecipeDetail(UUID publicId) {
    // Cached for 10 minutes
}

@CacheEvict(value = "recipes", key = "#publicId")
public void updateRecipe(UUID publicId, UpdateRecipeRequestDto dto) {
    // Invalidate cache on update
}
```

## QueryDSL for Complex Queries

### Type-Safe Query Example

```java
public Slice<Recipe> findRecipesByFilters(
    String locale,
    boolean onlyRoot,
    Pageable pageable
) {
    QRecipe recipe = QRecipe.recipe;

    BooleanBuilder builder = new BooleanBuilder();
    builder.and(recipe.deletedAt.isNull());

    if (locale != null) {
        builder.and(recipe.locale.eq(locale));
    }

    if (onlyRoot) {
        builder.and(recipe.parentPublicId.isNull());
    }

    List<Recipe> content = queryFactory
        .selectFrom(recipe)
        .where(builder)
        .orderBy(recipe.rankingScore.desc(), recipe.createdAt.desc())
        .offset(pageable.getOffset())
        .limit(pageable.getPageSize() + 1)
        .fetch();

    boolean hasNext = content.size() > pageable.getPageSize();
    if (hasNext) {
        content.remove(content.size() - 1);
    }

    return new SliceImpl<>(content, pageable, hasNext);
}
```

**Benefits**:
- Compile-time query validation
- IDE autocomplete
- Refactoring-safe
- Complex WHERE clauses without string concatenation

## Data Preservation & Soft Delete

### Soft Delete Philosophy

**✅ Soft Delete Everywhere**
- ALL deletions are soft deletes (set `deleted_at` timestamp, don't remove row)
- Entities have `deletedAt: LocalDateTime` field
- Deleted content excluded from queries but preserved in database
- **Rationale**: Content preservation is a core value—recipes and logs are community knowledge

**❌ NO Cascade Deletes**
- If a recipe is deleted, logs remain (orphaned but preserved)
- If a user is deleted, their content remains (anonymized: "Deleted User")
- **Rationale**: Recipes and logs have value independent of creator

### JPA Entity Pattern

```java
@Entity
@Table(name = "posts")
@Where(clause = "deleted_at IS NULL")  // Auto-filter soft-deleted
public class Recipe extends BaseEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private UUID publicId = UUID.randomUUID();

    private String title;

    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;

    // Soft delete method
    public void softDelete() {
        this.deletedAt = LocalDateTime.now();
    }

    public boolean isDeleted() {
        return deletedAt != null;
    }
}
```

### Repository Query Pattern

```java
public interface RecipeRepository extends JpaRepository<Recipe, Long> {
    // @Where clause automatically filters deleted_at IS NULL
    Optional<Recipe> findByPublicId(UUID publicId);

    // Explicit filter for clarity
    @Query("SELECT r FROM Recipe r WHERE r.deletedAt IS NULL AND r.locale = :locale")
    List<Recipe> findByLocale(@Param("locale") String locale);

    // Include soft-deleted items (admin use)
    @Query("SELECT r FROM Recipe r WHERE r.publicId = :publicId")
    Optional<Recipe> findByPublicIdIncludingDeleted(@Param("publicId") UUID publicId);
}
```

---

# Frontend Architecture

## Technology Stack (Flutter)

- **Language**: Dart (3.10.4+)
- **Framework**: Flutter
- **State Management**: flutter_riverpod ^2.5.1
- **Routing**: go_router ^17.0.1
- **HTTP Client**: dio ^5.4.0
- **Local Storage**: hive ^2.2.3, isar ^3.1.0+1
- **Firebase**: firebase_core, firebase_auth, firebase_analytics
- **Image**: cached_network_image, image_picker, flutter_image_compress
- **Code Generation**: json_serializable, build_runner, isar_generator
- **Functional Programming**: dartz ^0.10.1
- **Logging**: talker_flutter, talker_dio_logger

## Clean Architecture Layers

```
lib/
├── core/                 # Shared utilities and configurations
│   ├── router/
│   ├── network/
│   ├── constants/
│   ├── providers/
│   └── workers/
│
├── domain/              # Business logic layer (entities, repositories, use cases)
│   ├── entities/
│   ├── repositories/
│   └── usecases/
│
├── data/                # Data layer (DTOs, data sources, repository implementations)
│   ├── models/
│   ├── datasources/
│   └── repositories/
│
├── features/            # Feature modules (presentation layer)
│   ├── recipe/
│   ├── log_post/
│   ├── auth/
│   └── home/
│
└── shared/              # Shared models and utilities
```

### Layer Responsibilities

**Domain Layer**:
- **Entities**: Pure Dart classes representing business objects
- **Repositories**: Abstract interfaces defining data operations
- **Use Cases**: Single-responsibility business logic operations
- **Rule**: ❌ **NO dependencies on Data or Presentation layers**

**Data Layer**:
- **DTOs**: Data Transfer Objects with JSON serialization
- **Data Sources**: Remote (API calls via Dio), Local (Isar/Hive)
- **Repository Implementations**: Implements domain repository interfaces

**Presentation Layer**:
- **State Management**: Riverpod 2.x
- **UI Components**: Flutter widgets organized by feature
- **Routing**: GoRouter for declarative navigation

For complete frontend architecture details, see the original TECHSPEC.md Content Model and Architecture sections.

## Variation Creation Form UX

### Soft Delete with Restore Pattern

When creating a recipe variation, users can accidentally delete inherited ingredients or steps. The form implements a **soft delete pattern** allowing users to restore deleted items.

**Data Model**:
```dart
// Ingredient/Step map structure
{
  'name': '닭고기',
  'amount': '600g',
  'type': 'MAIN',        // MAIN, SECONDARY, SEASONING
  'isOriginal': true,    // Inherited from parent recipe
  'isDeleted': false,    // Soft delete flag
}
```

**UI Behavior**:
1. Tap [X] → Item marked as deleted, moves to "삭제됨" section
2. Tap [복원] → Item restored to active list
3. On submit → Deleted items filtered out (not sent to backend)

**Visual Design**:
```
━━━ 주재료 ━━━
[닭고기 600g]        [X]
[감자 2개]           [X]
[+ 주재료 추가]

── 삭제됨 ──
~~양파 1개~~        [↩️ 복원]
~~당근 1개~~        [↩️ 복원]
```

**Key Files**:
- `lib/features/recipe/presentation/screens/recipe_create_screen.dart`
- `lib/features/recipe/presentation/widgets/ingredient_section.dart`
- `lib/features/recipe/presentation/widgets/step_section.dart`

---

# API Contracts

## Authentication Endpoints

### POST /api/v1/auth/social-login
**Purpose**: Login or register user with Firebase ID token

**Request**:
```json
{
  "provider": "GOOGLE",
  "idToken": "eyJhbGciOiJSUzI1NiIs...",
  "locale": "ko-KR"
}
```

**Response** (200 OK):
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": "550e8400-e29b-41d4-a716-446655440000",
  "user": {
    "publicId": "user-uuid",
    "username": "johndoe",
    "email": "john@example.com",
    "profileImageUrl": "https://...",
    "locale": "ko-KR"
  }
}
```

### POST /api/v1/auth/reissue
**Purpose**: Refresh access token using refresh token

**Request**:
```json
{
  "refreshToken": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response** (200 OK):
```json
{
  "accessToken": "new-access-token",
  "refreshToken": "new-refresh-token"
}
```

## Recipe Endpoints

### GET /api/v1/recipes
**Purpose**: Get paginated list of recipes

**Query Parameters**:
- `locale` (optional): Filter by locale (e.g., "ko-KR", "en-US")
- `onlyRoot` (optional, default: false): Show only original recipes (no variations)
- `page` (default: 0): Page number
- `size` (default: 20): Page size
- `sort` (default: "rankingScore,desc"): Sort order

**Response** (200 OK) - Spring Slice:
```json
{
  "content": [
    {
      "publicId": "recipe-uuid",
      "title": "Original Carbonara",
      "description": "Classic Italian pasta",
      "thumbnailUrl": "https://...",
      "creatorName": "Chef Mario",
      "createdAt": "2026-01-05T10:00:00Z",
      "logCount": 42,
      "variationCount": 5
    }
  ],
  "number": 0,
  "size": 20,
  "first": true,
  "last": false,
  "hasNext": true
}
```

### GET /api/v1/recipes/{publicId}
**Purpose**: Get recipe detail with variations and logs

**Response** (200 OK):
```json
{
  "publicId": "recipe-uuid",
  "title": "Vegan Carbonara",
  "description": "Plant-based version",
  "ingredients": [
    {
      "name": "Tofu",
      "amount": "200g",
      "type": "MAIN"
    }
  ],
  "steps": [
    {
      "stepNumber": 1,
      "instruction": "Dice the tofu",
      "imageUrl": null
    }
  ],
  "imagePublicIds": ["img-uuid-1", "img-uuid-2"],
  "parentInfo": {
    "publicId": "parent-recipe-uuid",
    "title": "Original Carbonara"
  },
  "rootInfo": {
    "publicId": "root-recipe-uuid",
    "title": "Original Carbonara"
  },
  "changeCategory": "protein_change",
  "variants": [
    {
      "publicId": "variant-uuid",
      "title": "Spicy Vegan Carbonara",
      "thumbnailUrl": "https://..."
    }
  ],
  "recentLogs": [
    {
      "publicId": "log-uuid",
      "title": "Tried it today!",
      "rating": 5,
      "thumbnailUrl": "https://...",
      "creatorName": "Jane",
      "createdAt": "2026-01-04T15:30:00Z"
    }
  ],
  "creatorName": "Chef Mario",
  "locale": "ko-KR",
  "createdAt": "2026-01-01T10:00:00Z",
  "updatedAt": "2026-01-01T10:00:00Z"
}
```

### POST /api/v1/recipes
**Purpose**: Create new recipe (original or variation)

**Request**:
```json
{
  "title": "My Recipe",
  "description": "Delicious dish",
  "ingredients": [
    {
      "name": "Ingredient 1",
      "amount": "100g",
      "type": "MAIN"
    }
  ],
  "steps": [
    {
      "stepNumber": 1,
      "instruction": "Do something",
      "imagePublicId": null
    }
  ],
  "imagePublicIds": ["img-uuid-1"],
  "parentPublicId": null,
  "rootPublicId": null,
  "changeCategory": null,
  "locale": "ko-KR"
}
```

**Response** (201 Created): Same as GET recipe detail

## Log Post Endpoints

### GET /api/v1/log-posts
**Purpose**: Get paginated list of log posts

**Query Parameters**:
- `recipePublicId` (optional): Filter by recipe
- `page`, `size`, `sort`: Pagination

**Response** (200 OK) - Spring Slice:
```json
{
  "content": [
    {
      "publicId": "log-uuid",
      "recipePublicId": "recipe-uuid",
      "title": "Cooked this today",
      "rating": 4,
      "thumbnailUrl": "https://...",
      "creatorName": "Jane",
      "createdAt": "2026-01-05T12:00:00Z"
    }
  ],
  "hasNext": true
}
```

### GET /api/v1/log-posts/{publicId}
**Purpose**: Get log post detail

**Response** (200 OK):
```json
{
  "publicId": "log-uuid",
  "recipePublicId": "recipe-uuid",
  "recipeTitle": "Original Carbonara",
  "title": "My cooking attempt",
  "content": "It was amazing! Here's what I learned...",
  "rating": 5,
  "imagePublicIds": ["img-1", "img-2", "img-3"],
  "creatorName": "Jane Doe",
  "createdAt": "2026-01-05T12:00:00Z"
}
```

### POST /api/v1/log-posts
**Purpose**: Create new log post

**Request**:
```json
{
  "recipePublicId": "recipe-uuid",
  "title": "Tried this recipe",
  "content": "Here's my experience...",
  "rating": 4,
  "imagePublicIds": ["img-uuid-1", "img-uuid-2"]
}
```

**Response** (201 Created): Same as GET log detail

## Image Endpoints

### POST /api/v1/images/upload
**Purpose**: Upload image to S3/MinIO

**Request**: `multipart/form-data`
- `file`: Image file (JPEG, PNG)
- `type`: "THUMBNAIL" | "LOG_POST" | "STEP"

**Response** (200 OK):
```json
{
  "imagePublicId": "550e8400-e29b-41d4-a716-446655440000",
  "imageUrl": "https://cdn.pairingplanet.com/images/550e8400..."
}
```

## Analytics Endpoints

### POST /api/v1/events
**Purpose**: Track single event (immediate priority)

**Request**:
```json
{
  "eventId": "event-uuid",
  "eventType": "logCreated",
  "userId": "user-uuid",
  "timestamp": "2026-01-05T10:30:00Z",
  "recipeId": "recipe-uuid",
  "logId": "log-uuid",
  "properties": {
    "rating": 4,
    "image_count": 3
  }
}
```

**Response**: 200 OK

### POST /api/v1/events/batch
**Purpose**: Track multiple events (batched priority)

**Request**:
```json
{
  "events": [
    {
      "eventId": "uuid-1",
      "eventType": "recipeViewed",
      "timestamp": "2026-01-05T10:30:00Z",
      "properties": {}
    }
  ]
}
```

**Response**: 200 OK

## Pagination Strategy

**Spring Slice** (Backend default):
- Used for infinite scroll
- Returns `hasNext` boolean (not total count)
- More efficient than Page (no COUNT query)

**Frontend Handling**:
```dart
class SliceResponseDto<T> {
  final List<T> content;  // Note: "content", not "items"
  final bool hasNext;

  factory SliceResponseDto.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return SliceResponseDto(
      content: (json['content'] as List)
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      hasNext: json['hasNext'] as bool,
    );
  }
}
```

## Error Responses

**Standard Error Format**:
```json
{
  "timestamp": "2026-01-05T10:30:00Z",
  "status": 404,
  "error": "Not Found",
  "message": "Recipe with ID 'abc-123' not found",
  "path": "/api/v1/recipes/abc-123"
}
```

**Common Status Codes**:
- 200 OK: Success
- 201 Created: Resource created
- 400 Bad Request: Invalid input
- 401 Unauthorized: Missing or invalid token
- 403 Forbidden: Insufficient permissions
- 404 Not Found: Resource doesn't exist
- 500 Internal Server Error: Backend error

---

# Authentication & UX Philosophy

## Progressive Authentication Strategy

**Core Principle**: ❌ **Never force login at app launch**

Users can browse, view recipes, and explore the app anonymously. Login is prompted **ONLY when users create value**:

**Login Trigger Points**:
- 💾 **Saving/bookmarking a recipe** (planned feature)
- 📝 **Creating a log post** (review/photo of cooking attempt)
- 🔀 **Creating a recipe variation** (modified version of existing recipe)
- ⭐ **Rating or reviewing** (any user-generated content)

**Implementation**:
- Use **bottom sheet** for login UI (non-intrusive, dismissable)
- Firebase Authentication with Google Sign-In
- Token stored in secure local storage (NOT HTTP-only cookies)
- Auto-refresh with Dio interceptors

**User Flow Example**:
```
User opens app → Browse home feed (NO login required ✅)
                ↓
User finds recipe → View recipe details (NO login required ✅)
                ↓
User wants to save recipe → 🔓 Bottom sheet login prompt
                            → After login: Recipe saved
                ↓
User creates log post → Already authenticated → Direct to creation screen
```

## Authentication State Management

```dart
// Auth state provider (lazy evaluation)
final authStateProvider = StreamProvider((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Check auth before protected actions
Future<void> saveRecipe(BuildContext context, WidgetRef ref, String recipeId) async {
  final authState = await ref.read(authStateProvider.future);

  if (authState == null) {
    // User not logged in - show bottom sheet
    final loggedIn = await showLoginBottomSheet(context);
    if (!loggedIn) return; // User cancelled login
  }

  // Proceed with save
  await ref.read(recipeRepositoryProvider).saveRecipe(recipeId);
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('레시피가 저장되었습니다!')),
  );
}
```

## User-Friendly Terminology

| Internal (Developer) | User-Facing (Korean) | User-Facing (English) | Notes |
|---------------------|---------------------|----------------------|-------|
| Variation | 내 버전 | My Version | Not "variation" - too technical |
| Log Post | 요리 기록 | Cooking Log | Action-oriented |
| Parent Recipe | 참고한 레시피 | Based On | Human relationship |
| Root Recipe | 원본 레시피 | Original Recipe | Clear origin |
| Success | 성공했어요 😊 | Success! 😊 | Emoji reinforces emotion |
| Partial | 반쯤 성공 😐 | Partial 😐 | Non-judgmental |
| Failed | 망했어요 😢 | Failed 😢 | Relatable, not clinical |
| Change Category | (hidden) | (hidden) | Auto-detected, never shown |

**Rule**: Backend uses English internally. Frontend handles localization via `assets/translations/`.

---

# Feed Strategy

## Home Feed Composition

The home feed is a **mixed feed** combining multiple content types to showcase recipe evolution and community activity:

**Content Types**:
1. **Popular Recipes**: High-engagement recipes based on ranking algorithm
2. **Recent Variations**: Newly created recipe variations showing how recipes evolve
3. **Photo-Centric Logs**: Recent cooking attempts with appealing photos (visual discovery)

**Feed Distribution** (approximate):
- 50% Popular recipes
- 30% Recent logs (photo-centric)
- 20% Recent variations

## Ranking Algorithm

Recipes are ranked using a **weighted score** combining multiple signals:

```java
score = (
  w1 * recency_score +
  w2 * log_count +
  w3 * save_count +       // Planned feature
  w4 * variation_count
)
```

**Factor Definitions**:

1. **Recency Score**: Time decay function
   ```java
   recency_score = Math.exp(-lambda * days_since_creation)
   // lambda = decay constant (e.g., 0.1 for 10-day half-life)
   ```
   - Recent recipes score higher
   - Exponential decay prevents old content from dominating

2. **Log Count**: Number of cooking attempts logged
   - Indicates recipe is **actually being cooked** (vitality signal)
   - Recipes with many logs are proven, trustworthy

3. **Save Count** (Planned): Number of users who bookmarked
   - Indicates recipe is worth revisiting
   - Social proof of value

4. **Variation Count**: Number of derivative recipes
   - Indicates recipe **inspires creativity**
   - High variation count suggests adaptable, interesting base recipe

**Implementation Notes**:
- Backend pre-computes scores periodically (e.g., hourly cron job)
- Scores cached in Redis for fast feed generation
- Feed results cached for 5-10 minutes per user
- Personalization layer can be added later (user preferences, follow graph)

## Feed Performance Requirements

**SLA Targets**:
- **P50 response time**: < 150ms
- **P95 response time**: < 300ms ⚠️ **Critical threshold**
- **P99 response time**: < 500ms

**Optimization Strategies**:
1. **Materialized View**: Pre-computed feed table with scores
2. **Redis Cache**: Hot content cached for instant serving
3. **CDN for Images**: Thumbnail URLs served from CDN, not origin server
4. **Lazy Loading**: Load 20 items per page, prefetch next page
5. **Database Indexing**: Composite indexes on (score DESC, createdAt DESC, deletedAt)

---

# Monetization Strategy (Future)

## Revenue Model Options

### Freemium Model (Recommended)
- **Free tier**: Full access to browse, create, and share
- **Premium tier**: Advanced features for power users
  - Analytics dashboard (see who cooked your recipes)
  - Advanced export (PDF recipe books)
  - Ad-free experience
  - Priority support

### Data Monetization (Ethical)
- **Aggregated cooking insights** (anonymized):
  - Which ingredient substitutions succeed most
  - Regional cooking trends
  - Seasonal recipe popularity
- **Partner API** for food brands (anonymized trends only)
- **NO individual data selling**

### Creator Economy (Phase 2)
- **Featured recipes** (creators pay for visibility)
- **Tips/donations** to recipe creators
- **Recipe book publishing** (creators sell curated collections)

## Current Priority
Focus on user growth first. Monetization deferred until:
- 10,000+ active users
- 50,000+ recipes
- Strong engagement metrics

---

# Performance Considerations

## Image Optimization & CDN

**✅ CDN is Mandatory** for all images:
- Images served from CDN URLs, NOT backend server
- Automatic image optimization at CDN layer
- Presigned URLs for uploads (planned improvement)

**Image Specs**:
- **Upload quality**: 70% JPEG compression
- **Max file size**: 5MB per image
- **Supported formats**: JPEG, PNG
- **Thumbnail generation**: Multiple sizes for different contexts
  - 300x300 (list thumbnails)
  - 600x600 (detail page thumbnails)
  - 1200x1200 (full-size display)

**CDN Configuration**:
```dart
class ImageConfig {
  static const String cdnBaseUrl = 'https://cdn.pairingplanet.com';

  static String getThumbnail(String imagePublicId, {int size = 300}) {
    return '$cdnBaseUrl/images/$imagePublicId?w=$size&h=$size&fit=cover';
  }

  static String getFullImage(String imagePublicId) {
    return '$cdnBaseUrl/images/$imagePublicId';
  }
}

// Usage in UI
CachedNetworkImage(
  imageUrl: ImageConfig.getThumbnail(recipe.imagePublicIds.first, size: 600),
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

## Backend Performance

**Database Query Optimization**:
- Indexes on frequently queried columns
- QueryDSL for type-safe, optimized queries
- Connection pooling (HikariCP)
- Read replicas for heavy read operations

**Caching Strategy**:
- Redis for session data, feed scores
- Spring Cache abstraction
- Cache invalidation on writes

**API Response Time**:
- Target: < 200ms for simple queries
- Pagination to limit result size
- Async processing for heavy operations

## N+1 Query Prevention

### JPA Entity Graph Pattern
```java
@EntityGraph(attributePaths = {"creator", "images", "logs"})
Optional<Recipe> findByPublicId(UUID publicId);
```

### BatchSize for Collections
```java
@Entity
public class Recipe {
    @BatchSize(size = 20)
    @OneToMany(mappedBy = "recipe")
    private List<LogPost> logs;
}
```

### QueryDSL Fetch Join
```java
public Recipe findWithRelations(UUID publicId) {
    QRecipe recipe = QRecipe.recipe;
    return queryFactory
        .selectFrom(recipe)
        .leftJoin(recipe.creator).fetchJoin()
        .leftJoin(recipe.logs).fetchJoin()
        .where(recipe.publicId.eq(publicId))
        .fetchOne();
}
```

### Monitoring Strategy
- Enable Hibernate SQL logging in dev: `spring.jpa.show-sql=true`
- Use p6spy or datasource-proxy to log query counts per request
- Alert if >5 queries per endpoint (indicates N+1)

## Rate Limiting Implementation

### Limits by Endpoint Type

| Endpoint Type | Limit | Window | Response |
|--------------|-------|--------|----------|
| Read (GET) | 100 | 1 min | 429 Too Many Requests |
| Write (POST/PUT) | 10 | 1 min | 429 + Retry-After header |
| Image Upload | 5 | 1 min | 429 + retry guidance |
| Auth | 5 | 5 min | 429 + lockout warning |

### Redis Implementation
```java
@Component
public class RateLimitInterceptor implements HandlerInterceptor {
    private final StringRedisTemplate redis;

    @Override
    public boolean preHandle(HttpServletRequest request,
                             HttpServletResponse response,
                             Object handler) {
        String key = "rate:" + getUserId() + ":" + getEndpointType(request);
        Long count = redis.opsForValue().increment(key);

        if (count == 1) {
            redis.expire(key, 1, TimeUnit.MINUTES);
        }

        if (count > getLimit(request)) {
            throw new RateLimitExceededException();
        }
        return true;
    }
}
```

### Response Headers
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1704456000
```

### Graceful Degradation
- Show "잠시 후 다시 시도해주세요" message
- Display countdown: "30초 후 재시도 가능"
- Queue write requests if possible (offline-first)

---

# Web Architecture (Planned - Long-Term)

## Overview

A Next.js web frontend for SEO and discoverability, with full feature parity to the mobile app.

**Purpose**:
- Enable recipe discovery via search engines (Google, Naver)
- Support social sharing with proper Open Graph meta tags
- Provide web access for users who prefer desktop

**Tech Stack**: Next.js 14+ (App Router) + TypeScript + Tailwind CSS + NextAuth.js

## Architecture

```
┌─────────────────────┐
│   CDN (Cloudflare)  │
└──────────┬──────────┘
           │
    ┌──────┴──────┐
    │             │
    ▼             ▼
┌────────┐  ┌────────────┐
│Next.js │  │Spring Boot │
│  Web   │  │    API     │
└────────┘  └─────┬──────┘
                  │
           ┌──────┴──────┐
           │             │
           ▼             ▼
      ┌────────┐   ┌────────┐
      │PostgreSQL  │  MinIO │
      │ + Redis│   │ Images │
      └────────┘   └────────┘
```

## Key Features

### SEO
- **SSR/SSG**: Server-side rendering for crawlers
- **ISR**: Incremental Static Regeneration for recipes (5 min revalidation)
- **Schema.org**: Recipe structured data for Google Rich Results
- **Open Graph**: Dynamic meta tags for social sharing
- **Sitemap**: Auto-generated sitemap.xml

### Authentication
- NextAuth.js with Google/Naver/Kakao/Apple providers
- Exchange OAuth tokens for backend JWT
- httpOnly cookies for secure token storage

### Backend Requirements
- CORS configuration for web origins
- `GET /api/v1/seo/recipes/{id}` - SEO metadata endpoint
- `GET /api/v1/recipes/public-ids` - For sitemap generation

## Deployment

**Target**: AWS (ECS Fargate) or GCP (Cloud Run)
- Serverless, auto-scaling
- Pay-per-use pricing

See [ROADMAP.md - Web Version](ROADMAP.md#long-term-12-months) for implementation timeline.

---

# Implementation Roadmap

For all production enhancement phases, planned features, and future improvements, see **[ROADMAP.md](ROADMAP.md)**.

**Quick Links**:
- [Phase 1: Event Tracking](ROADMAP.md#phase-1-event-tracking-infrastructure--completed-2026-01-05) ✅ Completed
- [Phase 2-6: Production Enhancements](ROADMAP.md#production-enhancement-phases) (Planned)
- [Phase 7: UX/UI Alignment](ROADMAP.md#phase-7-ux-spec-alignment-in-planning) (In Planning)
- [Feature Roadmap](ROADMAP.md#feature-roadmap) (Save, Hashtags, Search, etc.)
- [Future Improvements](ROADMAP.md#future-improvements) (Short/Medium/Long-term)

---

# Dependencies

## Backend (Spring Boot)

```gradle
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
    implementation 'org.springframework.boot:spring-boot-starter-data-redis'
    implementation 'org.springframework.boot:spring-boot-starter-security'

    implementation 'org.postgresql:postgresql'
    implementation 'org.flywaydb:flyway-core'

    implementation 'com.google.firebase:firebase-admin:9.2.0'
    implementation 'io.jsonwebtoken:jjwt-api:0.12.3'

    implementation 'com.querydsl:querydsl-jpa:5.1.0:jakarta'

    implementation 'io.awspring.cloud:spring-cloud-aws-starter-s3'
    // OR
    implementation 'io.minio:minio'

    testImplementation 'org.springframework.boot:spring-boot-starter-test'
    testImplementation 'org.testcontainers:postgresql'
}
```

## Frontend (Flutter)

```yaml
dependencies:
  # Core
  flutter_riverpod: ^2.5.1
  go_router: ^17.0.1
  dio: ^5.4.0
  dartz: ^0.10.1

  # Firebase
  firebase_core: latest
  firebase_auth: latest

  # Local Storage
  hive: ^2.2.3
  isar: ^3.1.0+1
  isar_flutter_libs: ^3.1.0+1

  # Image
  cached_network_image: latest
  image_picker: latest
  flutter_image_compress: ^2.1.0
  image: ^4.1.3

  # Utilities
  uuid: ^4.3.3
  talker_flutter: latest

dev_dependencies:
  build_runner: ^2.4.13
  json_serializable: ^6.8.0
  isar_generator: ^3.1.0+1
```

---

For implementation guidance, see [CLAUDE.md](CLAUDE.md).
For backend setup instructions, see [BACKEND_SETUP.md](BACKEND_SETUP.md).
For project changelog, see [CHANGELOG.md](CHANGELOG.md).
