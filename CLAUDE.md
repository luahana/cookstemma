# CLAUDE.md — Cookstemma

> Flutter + Spring Boot recipe sharing app. Offline-first architecture.
> **This file is auto-read by Claude Code from project root.**

---

## 📂 FILE LOCATIONS

```
project-root/
├── CLAUDE.md                    ← THIS FILE (auto-read by Claude Code)
└── backend/
```

---

## 🚀 SESSION START

```
1. Claude Code auto-reads this file (CLAUDE.md)
2. Check: git branch --show-current
3. Check: git status
5. Wait for user to request a feature or ask what to work on
```

---

## ⚙️ SETUP

```bash
claude --dangerously-skip-permissions --model opus
```

---

## 🔴 CRITICAL RULES

0. **Model** → Use opus with extended thinking
2. **Plan with ultrathink** → Research best practices before implementing
4. **Feature = Code + Tests** → A feature is NOT complete until unit tests and integration tests are written and passing. No PR without tests.
5. **Before commit** → Run pre-commit checklist
10. **Buttons** → Debounce 300ms, check state before API call
12. **After await** → Check `if (!context.mounted) return;`
13. **API IDs** → Use `publicId` (UUID), never internal `id`
14. **Providers in callbacks** → `ref.read()`, not `ref.watch()`
17. **Error handling** → Return `Either<Failure, T>`, never throw
19. **DRY** → Code used 2+ times? Extract to shared location. No copy-paste.
20. **File size** → Max 300 lines per file. Split by responsibility if exceeded.
21. **Function size** → Max 50 lines per function. Extract helpers if exceeded.

---

## 🧠 PLANNING WITH ULTRATHINK

**Before implementing ANY feature:**

```
1. UNDERSTAND: What, why, edge cases?
2. RESEARCH: How do Instagram/Twitter/etc do this?
3. DESIGN: Models, APIs, UI flow
4. PLAN: Implementation steps
5. TEST PLAN: What tests will prove this works?
   - List test cases for happy path
   - List test cases for error cases
   - List edge cases to cover
```

---

## 🔍 BEST PRACTICES RESEARCH

| Feature Type | Research These Apps |
|--------------|---------------------|
| Follow system | Instagram, Twitter, TikTok |
| Notifications | Slack, Discord, WhatsApp |
| Search | Pinterest, Spotify, YouTube |
| Feed/List | Instagram, Reddit, TikTok |
| Profile | Instagram, LinkedIn |
| Image upload | Instagram, WhatsApp |

---

## 🧹 CODE QUALITY RULES

### DRY: Don't Repeat Yourself
**If code appears 2+ times → Extract to shared function/widget**

```dart
// ❌ BAD: Same padding used in 3 places
Padding(padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h))
Padding(padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h))
Padding(padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h))

// ✅ GOOD: Extract to constant or widget
// In lib/core/constants/app_spacing.dart
class AppSpacing {
  static EdgeInsets get cardPadding => EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h);
}

// Usage
Padding(padding: AppSpacing.cardPadding)
```

### File Size Limits
| Metric | Limit | Action When Exceeded |
|--------|-------|----------------------|
| Lines per file | **300 max** | Split by responsibility |
| Lines per function/method | **50 max** | Extract helper methods |
| Lines per widget build() | **100 max** | Extract sub-widgets |
| Parameters per function | **5 max** | Use object/class |

### When to Split Files
```
// File too long? Ask:
1. Does this file have multiple responsibilities? → Split by responsibility
2. Is one class doing too much? → Extract classes
3. Are there reusable widgets? → Move to widgets/ folder
4. Are there utility functions? → Move to utils/
```

---

## 🧪 TESTING (REQUIRED)

**A feature without unit tests and integration tests is not a feature. It's a liability.**

### What Needs Tests
| Change Type | Required Tests |
|-------------|----------------|
| New API endpoint | Unit test for controller + service |
| New repository method | Unit test with mock |
| New UI widget | Widget test |
| Business logic | Unit test |
| Bug fix | Regression test (proves bug is fixed) |

---

## ✅ PRE-COMMIT CHECKLIST

```
□ flutter analyze                    → No errors
□ flutter test                       → All pass
□ ./gradlew test (if backend)        → All pass
□ No print() or console.log
□ No hardcoded UI strings (use .tr)
□ No hardcoded pixels (run these checks):
  grep -rn "width: [0-9]" --include="*.dart" lib/ | grep -v "\\.w" | grep -v "\\.r"
  grep -rn "height: [0-9]" --include="*.dart" lib/ | grep -v "\\.h" | grep -v "\\.r"
  grep -rn "fontSize: [0-9]" --include="*.dart" lib/ | grep -v "\\.sp"
  grep -rn "circular([0-9]" --include="*.dart" lib/ | grep -v "\\.r"
  grep -rn "size: [0-9]" --include="*.dart" lib/ | grep -v "\\.sp" | grep -v "\\.w" | grep -v "\\.h"
  → ALL should return empty (no matches)
□ New text in BOTH en.json AND ko.json
□ Buttons debounced
□ Code quality checks:
  - No code repeated 2+ times (extract if found)
  - No file > 300 lines (split if found)
  - No function > 50 lines (extract helpers)
  - No nesting > 3 levels (use early returns)
  - No magic numbers (use constants)
  - Added const where possible
```

---

## 🔀 GIT

**Branch strategy:**
```
main ← staging ← dev
                    
```

**PR targets:**
| From | To |
|------|----|
| dev | staging |
| staging | main |

**Commands:**
```bash
git fetch origin
git push origin HEAD
gh pr create --base dev
```

---

## 🔥 FIREBASE ENVIRONMENTS

| Env | Project | Flavor |
|-----|---------|--------|
| Dev | cookstemma-dev | dev |
| Staging | cookstemma-stg | staging |
| Prod | cookstemma-prod | prod |

---

## 🛠️ COMMANDS

```bash
# Run backend
./gradlew bootRun

# Docker
docker-compose up -d
```


---

## 🌍 TRANSLATIONS

---

## 🌐 API

**Base URL:** `http://localhost:4000/api/v1`
**Auth:** `Authorization: Bearer $accessToken`

---

## ✅ WORKFLOW SUMMARY

```
1. git fetch origin
3. Plan with ultrathink (include test cases in plan)
4. Implement:
   a. Write feature code
   b. Write tests (unit + widget/integration as needed)
   c. Run tests → Must pass
   d. Fix until green
5. Refactor:
   a. Any code repeated 2+ times? → Extract
   b. Any file > 300 lines? → Split
   c. Any function > 50 lines? → Extract helpers
6. Run pre-commit checklist
7. git push origin HEAD
8. gh pr create --base dev
```

---

## 🛑 STOP AND CHECK

**Before starting feature:**
- [ ] Test cases planned?

**Before committing:**
- [ ] Tests written?
- [ ] Tests pass? (`./gradlew test`)
- [ ] No hardcoded strings?
- [ ] No hardcoded pixels? (run grep commands)
- [ ] No repeated code? (extract if 2+ times)
- [ ] No large files? (split if > 300 lines)
- [ ] No large functions? (extract if > 50 lines)
