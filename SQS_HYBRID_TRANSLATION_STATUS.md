# SQS Hybrid Translation Status Report

## ✅ Summary

**Cooking Logs (LogPosts)** and **Comments** ARE using the hybrid SQS push architecture for translations.

---

## 🔍 Detailed Analysis

### Entities Using Hybrid SQS Push (Real-time ~1 min)

| Entity | Status | Code Location | SQS Push |
|--------|--------|---------------|----------|
| **Recipe (RECIPE_FULL)** | ✅ Hybrid | `RecipeService.java` → `queueRecipeTranslation()` | Line 176 |
| **LogPost (Cooking Logs)** | ✅ Hybrid | `LogPostService.java` line 96 → `queueLogPostTranslation()` | Line 252 |
| **Comment** | ✅ Hybrid | `CommentService.java` lines 75, 117 → `queueCommentTranslation()` | Line 293 |

### Entities Using Pull-Only (EventBridge ~5 min)

| Entity | Status | Reason |
|--------|--------|--------|
| RecipeStep (standalone) | ❌ Pull-only | Individual step editing not using SQS |
| RecipeIngredient (standalone) | ❌ Pull-only | Individual ingredient editing not using SQS |
| FoodMaster | ❌ Pull-only | Admin-managed, not time-sensitive |
| AutocompleteItem | ❌ Pull-only | Admin-managed, not time-sensitive |
| User Bio | ❌ Pull-only | Low priority, not time-sensitive |

---

## 📋 Code Evidence

### 1. Cooking Logs (LogPost) - ✅ HYBRID

**File**: `LogPostService.java`

```java
// Line 96 - When creating a log post
translationEventService.queueLogPostTranslation(logPost);
```

**File**: `TranslationEventService.java`

```java
// Lines 226-253 - queueLogPostTranslation method
@Transactional
public void queueLogPostTranslation(LogPost logPost) {
    // ... validation logic ...

    TranslationEvent event = TranslationEvent.builder()
            .entityType(TranslatableEntity.LOG_POST)
            .entityId(logPost.getId())
            .sourceLocale(sourceLocale)
            .targetLocales(targetLocales)
            .build();

    translationEventRepository.save(event);

    // ✅ PUSH TO SQS FOR IMMEDIATE PROCESSING
    sendToSqs(event);  // Line 252
}
```

### 2. Comments - ✅ HYBRID

**File**: `CommentService.java`

```java
// Line 75 - When creating a comment on a log
translationEventService.queueCommentTranslation(comment);

// Line 117 - When creating a reply to a comment
translationEventService.queueCommentTranslation(reply);
```

**File**: `TranslationEventService.java`

```java
// Lines 262-294 - queueCommentTranslation method
@Transactional
public void queueCommentTranslation(Comment comment) {
    // ... validation logic ...

    TranslationEvent event = TranslationEvent.builder()
            .entityType(TranslatableEntity.COMMENT)
            .entityId(comment.getId())
            .sourceLocale(sourceLocale)
            .targetLocales(targetLocales)
            .build();

    translationEventRepository.save(event);

    // ✅ PUSH TO SQS FOR IMMEDIATE PROCESSING
    sendToSqs(event);  // Line 293
}
```

### 3. Recipes - ✅ HYBRID (for reference)

**File**: `TranslationEventService.java`

```java
// Lines 147-177 - queueRecipeTranslation method
@Transactional
public void queueRecipeTranslation(Recipe recipe) {
    // ... validation logic ...

    TranslationEvent event = TranslationEvent.builder()
            .entityType(TranslatableEntity.RECIPE_FULL)
            .entityId(recipe.getId())
            .sourceLocale(sourceLocale)
            .targetLocales(targetLocales)
            .build();

    translationEventRepository.save(event);

    // ✅ PUSH TO SQS FOR IMMEDIATE PROCESSING
    sendToSqs(event);  // Line 176
}
```

---

## 🔧 sendToSqs() Implementation

**File**: `TranslationEventService.java` (Lines 95-135)

```java
private void sendToSqs(TranslationEvent event) {
    // Skip if SQS is disabled or not configured
    if (!sqsEnabled || sqsClient == null || translationQueueUrl == null || translationQueueUrl.isEmpty()) {
        log.debug("SQS disabled or not configured, event {} will be picked up by EventBridge", event.getId());
        return;
    }

    try {
        // Create SQS message body
        Map<String, Object> messageBody = new HashMap<>();
        messageBody.put("event_id", event.getId());
        messageBody.put("entity_type", event.getEntityType().name());
        messageBody.put("entity_id", event.getEntityId());

        String messageJson = objectMapper.writeValueAsString(messageBody);

        // Send to SQS
        SendMessageRequest request = SendMessageRequest.builder()
                .queueUrl(translationQueueUrl)
                .messageBody(messageJson)
                .build();

        sqsClient.sendMessage(request);

        log.info("Sent {} translation event {} to SQS for immediate processing",
                event.getEntityType(), event.getId());

    } catch (Exception e) {
        // Log but don't fail - EventBridge will pick it up
        log.warn("Failed to send event {} to SQS, will be picked up by EventBridge in ~5 minutes",
                event.getId(), e.getMessage());
    }
}
```

---

## ⚠️ Missing SQS Push on Edit Operations

### Issue: Edits Don't Trigger SQS Push

**LogPost Edit** (`LogPostService.java` line 496-536):
- Updates content but does NOT call `queueLogPostTranslation()`
- ❌ No SQS push on edit
- Will be picked up by EventBridge (~5 min latency)

**Comment Edit** (`CommentService.java` line 184-198):
- Updates content but does NOT call `queueCommentTranslation()`
- ❌ No SQS push on edit
- Will be picked up by EventBridge (~5 min latency)

### Recommendation

If you want edited content to translate immediately, add SQS push to edit operations:

```java
// In LogPostService.updateLog():
logPostRepository.save(logPost);
translationEventService.queueLogPostTranslation(logPost);  // ← Add this

// In CommentService.editComment():
commentRepository.save(comment);
translationEventService.queueCommentTranslation(comment);  // ← Add this
```

---

## 📊 Hybrid Architecture Flow

```
User Creates Content
       ↓
1. Save to Database (TranslationEvent)
       ↓
2. Push to SQS ────────────┐
       ↓ (fails?)           │
       ↓                    │ (success - immediate)
3. EventBridge Backup      │ ← ~1 min processing
       ↓ (~5 min)          │
       └──→ Lambda Processor ←┘
              ↓
        Translation Completed
```

---

## ✅ Conclusion

**Cooking Logs (LogPosts)** and **Comments** are **CONFIRMED** to be using the hybrid SQS push architecture:

1. ✅ Events saved to database (source of truth)
2. ✅ Pushed to SQS for immediate processing (~1 min latency)
3. ✅ EventBridge backup if SQS fails (~5 min latency)

**Only missing**: Edit operations don't push to SQS (but still work via EventBridge backup).
