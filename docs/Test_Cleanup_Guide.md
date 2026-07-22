# Test Artifact Cleanup Guide

> **Historical cleanup proposal (reviewed 2026-07-20):** Do not delete tests solely from this list. Legacy board-mode tests remain intentional coverage until the legacy code boundary is resolved; see [Testing](Testing.md).

**Status**: Implementation in progress  
**Priority**: High  
**Estimated Time**: 5-10 minutes

This guide identifies test files that should be removed or consolidated to reduce confusion and maintenance burden.

## Test Files to Remove

### Location: `packages/mobile/test/services/`

The following test files are duplicates and should be **DELETED**:

| File | Reason | Action |
|------|--------|--------|
| `leaderboard_service_final_test.dart` | Obsolete final version, merged into main test | DELETE |
| `leaderboard_service_final_test.mocks.dart` | Mock file for obsolete test | DELETE |
| `leaderboard_service_simple_test.dart` | Early simple version, covered by main test | DELETE |
| `leaderboard_service_test_new.dart` | Incomplete new version | DELETE |
| `leaderboard_service_test_new.mocks.dart` | Mock file for incomplete test version | DELETE |

### File to Keep

**Authoritative test file**: `leaderboard_service_test.dart`

This file contains the comprehensive test suite and should be the single source of truth for leaderboard service testing.

## Cleanup Steps

### Step 1: Review Current Test Coverage
```bash
cd /Users/marknelson/Circus/Repositories/modulo-squares
grep -l "leaderboard_service" packages/mobile/test/services/*test.dart
```

### Step 2: Verify Main Test File
Ensure `leaderboard_service_test.dart` contains all necessary test cases:
- [ ] Score submission tests
- [ ] Error handling tests
- [ ] Cache behavior tests
- [ ] Stream listener tests
- [ ] Data validation tests

### Step 3: Delete Obsolete Files
```bash
rm -f packages/mobile/test/services/leaderboard_service_final_test.dart
rm -f packages/mobile/test/services/leaderboard_service_final_test.mocks.dart
rm -f packages/mobile/test/services/leaderboard_service_simple_test.dart
rm -f packages/mobile/test/services/leaderboard_service_test_new.dart
rm -f packages/mobile/test/services/leaderboard_service_test_new.mocks.dart
```

### Step 4: Clean Git History (Optional)
To remove these files from git history:
```bash
git filter-branch --tree-filter 'rm -f packages/mobile/test/services/leaderboard_service_*_test*.dart' HEAD
```

### Step 5: Run Tests
Verify everything still works:
```bash
cd packages/mobile
flutter test test/services/leaderboard_service_test.dart -v
```

### Step 6: Update CI/CD Pipeline
Ensure `.github/workflows` references only:
- `packages/mobile/test/services/leaderboard_service_test.dart`

Verify no other obsolete test files are referenced in:
- `pubspec.yaml`
- Test running scripts
- CI/CD configuration

## Additional Cleanup Opportunities

### Test Mock Files
All `.mocks.dart` files are **auto-generated** by Mockito and should:
- [ ] Be regenerated with: `flutter pub run build_runner build`
- [ ] Be excluded from version control in `.gitignore`:
  ```gitignore
  **/*.mocks.dart
  ```
- [ ] Or be committed if they're part of your CI/CD strategy

## Naming Conventions for Future Tests

To prevent this situation in the future:

**DO:**
- ✅ `my_feature_test.dart` - Single authoritative test file
- ✅ `my_feature_integration_test.dart` - Integration tests, if separate

**DON'T:**
- ❌ `my_feature_test_new.dart` - Use descriptive names instead
- ❌ `my_feature_final_test.dart` - Implies previous versions exist
- ❌ `my_feature_simple_test.dart` - Use feature-based naming
- ❌ Multiple versions of same test - Consolidate into one file

## Impact Assessment

**Affected Components**:
- Test discovery and execution
- CI/CD pipeline clarity
- Developer onboarding time
- Repository size

**Benefits of Cleanup**:
- Reduced confusion about authoritative tests
- Faster test discovery and execution
- Clearer git history
- Reduced maintenance burden
- ~50KB savings in repository size

**Risk Level**: 🟢 LOW
- No production code changes
- All tests consolidated to single file
- Easy to verify with full test run

## Verification Checklist

After cleanup, verify:
- [ ] All tests still pass: `flutter test`
- [ ] No import errors in remaining test file
- [ ] CI/CD pipeline completes successfully
- [ ] Git status clean: `git status`
- [ ] Documentation updated with test file paths

## Timeline

- **Estimated Duration**: 10 minutes hands-on
- **Risk**: Very Low
- **Complexity**: Trivial
- **Recommended**: Execute immediately after code review

## Related Documentation

- See parent document: [Code_Quality_Analysis.md](./Code_Quality_Analysis.md) - Issue #5
- See [Testing.md](./Testing.md) - General testing guidelines

---

**Created**: 2024  
**Author**: Code Quality Analysis System  
**Status**: Ready for Implementation  
