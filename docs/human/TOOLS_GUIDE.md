# Tool Replacements Guide

## What We Removed → What Replaces It

| Removed File | Replacement Tool | Auto with Claude Code? |
|--------------|------------------|------------------------|
| TESTS.md | `flutter test --coverage` | ✅ Yes |
| BUGS.md | GitHub Issues | ⚠️ Needs `gh` CLI |
| GLOSSARY.md | Merged into FEATURES.md | ✅ Yes |
| PROMPTS.md | Merged into CLAUDE.md | ✅ Yes |

---

## 1. Test Coverage (Replaces TESTS.md)

### Frontend (Flutter)
```bash
# Generate coverage report
flutter test --coverage

# Output file
coverage/lcov.info

# Generate HTML report (optional)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html    # View in browser
```

### Backend (Spring Boot + JaCoCo)
```bash
# Run tests with coverage
./gradlew test jacocoTestReport

# Output file
build/reports/jacoco/test/html/index.html

# View report
open build/reports/jacoco/test/html/index.html
```

**JaCoCo Setup (if not already in build.gradle):**
```groovy
plugins {
    id 'jacoco'
}

jacocoTestReport {
    dependsOn test
    reports {
        xml.required = true
        html.required = true
    }
}

test {
    finalizedBy jacocoTestReport
}
```

### Can Claude Code Use It?
**✅ Yes, automatically.** Claude Code can run:
```bash
# Frontend
flutter test --coverage

# Backend
./gradlew test jacocoTestReport
```
And read the results.

### What You Get
- Line-by-line coverage
- Which files have tests
- Coverage percentage
- No manual tracking needed

---

## 2. GitHub Issues (Replaces BUGS.md)

### Where to Find
**Web UI:** `https://github.com/YOUR_USERNAME/YOUR_REPO/issues`

**CLI:** Install GitHub CLI first:
```bash
# macOS
brew install gh

# Login
gh auth login
```

### Commands
```bash
# Create bug issue
gh issue create --title "Bug: description" --label "bug"

# List bugs
gh issue list --label "bug"

# View issue
gh issue view 123

# Close issue
gh issue close 123

# Create with body
gh issue create --title "Bug: crash on login" --body "Steps to reproduce..." --label "bug"
```

### Can Claude Code Use It?
**⚠️ Yes, but needs setup:**

1. Install `gh` CLI on your machine
2. Run `gh auth login` once
3. Then Claude Code can run `gh` commands

**Example Claude Code can do:**
```bash
gh issue create --title "Bug: null pointer in recipe detail" --label "bug"
gh issue list --label "bug"
```

### Benefits Over BUGS.md
- Searchable
- Assignable
- Link to PRs/commits
- Notifications
- Labels (bug, priority, etc.)
- Milestones

---

## 3. GitHub Projects (Optional - Replaces ROADMAP.md)

### Where to Find
**Web UI:** `https://github.com/YOUR_USERNAME/YOUR_REPO/projects`

### Can Claude Code Use It?
**❌ Not directly.** GitHub Projects API is complex.

**Recommendation:** Keep ROADMAP.md for simplicity. Claude Code can update it.

---

## 4. PR Templates (Replaces commit-time doc checks)

### Where to Create
Create file: `.github/PULL_REQUEST_TEMPLATE.md`

```markdown
## Description
Brief description of changes.

## Related
- Closes #123 (if fixing an issue)
- Feature: [FEAT-XXX]

## Checklist
- [ ] Tests added/updated
- [ ] FEATURES.md updated (if new feature)
- [ ] ROADMAP.md marked [x]
- [ ] No console.log / print statements left

## Screenshots (if UI change)
```

### Can Claude Code Use It?
**✅ Yes.** When creating PR via `gh pr create`, it uses the template.

```bash
gh pr create --title "feat: add follow system" --body "..."
```

---

## Summary: What Claude Code Can Auto-Use

| Tool | Auto? | How |
|------|-------|-----|
| `flutter test --coverage` | ✅ | Just runs it |
| `./gradlew test jacocoTestReport` | ✅ | Just runs it |
| `gh issue create` | ✅ | After `gh auth login` |
| `gh issue list` | ✅ | After `gh auth login` |
| `gh pr create` | ✅ | After `gh auth login` |
| GitHub Projects | ❌ | Too complex, keep ROADMAP.md |
| Coverage HTML (Flutter) | ✅ | `genhtml` + `open` |
| Coverage HTML (Backend) | ✅ | `./gradlew jacocoTestReport` + `open` |

---

## One-Time Setup

Run these once on your machine:

```bash
# 1. Install GitHub CLI
brew install gh              # macOS
# or: sudo apt install gh    # Ubuntu

# 2. Login to GitHub
gh auth login

# 3. Install coverage tools (optional, for HTML reports)
brew install lcov            # macOS
# or: sudo apt install lcov  # Ubuntu

# 4. Verify
gh --version
gh auth status
```

---

## How Claude Code Will Use These

**Before (with BUGS.md):**
```
Claude: "Should I add this bug to BUGS.md?"
You: "Yes"
Claude: *edits BUGS.md*
```

**After (with GitHub Issues):**
```
Claude: "Should I create a GitHub issue for this bug?"
You: "Yes"
Claude: gh issue create --title "Bug: token refresh race condition" --label "bug" --body "..."
```

**Benefits:**
- Bug is now in GitHub Issues
- Can be assigned, labeled, linked to PR
- Auto-closes when PR merged with "Closes #123"

---

## Recommended Labels for GitHub Issues

Create these labels in your repo:

| Label | Color | Use For |
|-------|-------|---------|
| `bug` | red | Bugs |
| `feature` | green | New features |
| `priority:high` | orange | Urgent |
| `priority:low` | gray | Can wait |
| `good first issue` | purple | Easy tasks |

```bash
# Create labels via CLI
gh label create "bug" --color "d73a4a"
gh label create "feature" --color "0e8a16"
gh label create "priority:high" --color "ff9800"
```
