# Code Coverage Guide

Track and maintain 80% code coverage for DrawkcaB Flutter.

## 🚀 Quick Commands

| Command | Purpose |
|---------|---------|
| `flutter test --coverage` | Generate LCOV coverage report |
| `./scripts/coverage.sh --view` | Generate & open HTML report in browser |
| `./scripts/coverage.sh --check` | Check if coverage meets 80% threshold |
| `./scripts/coverage.sh --check --threshold 85` | Check against custom threshold |
| `./scripts/coverage.sh --clean` | Clean coverage files |

## 📊 Current Status

- **Unit Tests**: ~40% coverage ✅ (APIs, controllers)
- **Widget Tests**: 0% coverage ❌ (to be added)
- **Integration Tests**: 0% coverage ❌ (to be added)
- **Target**: 80% overall coverage

## Setup

### Prerequisites
- Flutter SDK
- Dart SDK  
- `lcov` (installed automatically on macOS with Homebrew, or manually: `sudo apt-get install lcov`)

### Configuration Files

- **`coverage.yaml`** - Coverage configuration with thresholds and targets
- **`.coverage-exclude`** - File patterns to exclude from coverage reports
- **`scripts/coverage.sh`** - Bash script for coverage operations

## Coverage Commands

### Generate LCOV Report
```bash
./scripts/coverage.sh
# or
flutter test --coverage
```
Generates `coverage/lcov.info` with raw coverage data.

### Generate HTML Report
```bash
./scripts/coverage.sh --view
```
Generates `coverage/html/index.html` and opens it in your browser.

### Check Against Threshold
```bash
./scripts/coverage.sh --check
./scripts/coverage.sh --check --threshold 85
```
Verifies coverage percentage meets minimum (default 80%).

### Clean Coverage Files
```bash
./scripts/coverage.sh --clean
```

## Understanding Coverage Reports

### HTML Report Structure
When you run `--view`, an interactive HTML report is generated showing:

- **Overview**: Total coverage percentage
- **File List**: Coverage by file (green = high, red = low)
- **Line Details**: Which lines are executed vs. skipped
- **Branch Coverage**: If branch coverage is tracked

### Coverage Metrics

- **LF (Lines Found)**: Total lines of code
- **LH (Lines Hit)**: Lines executed during tests
- **Coverage %**: (`LH / LF`) × 100

## Target Coverage

### Project Goal: 80% Overall Coverage

| Module | Target | Current |
|--------|--------|---------|
| `lib/core/**` | 85% | TBD |
| `lib/features/**` | 80% | TBD |
| **Overall** | 80% | TBD |

## Test Types and Coverage Contribution

### Unit Tests
- **Best for**: Business logic, APIs, validators, state management
- **Coverage**: ~50% with full unit test coverage
- **Files**: `lib/core/**`, `lib/features/**/data/**`, `lib/features/**/presentation/controllers/**`

### Widget Tests
- **Best for**: UI components, buttons, forms, navigation
- **Coverage**: ~25% in addition to unit tests
- **Files**: `lib/features/**/presentation/{screens,widgets}/**`

### Integration Tests
- **Best for**: End-to-end user flows
- **Coverage**: ~5% additional (app-level flows)
- **Files**: `lib/app.dart`, `lib/main.dart`

## Excluded Files

The following are automatically excluded from coverage:

- `*.g.dart` - Generated Freezed files
- `*.freezed.dart` - Freezed models
- `lib/main.dart` - Entry point (covered by integration tests)
- `lib/app.dart` - App configuration (covered by widget tests)
- `**/test/**` - Test files themselves

## GitHub Actions Integration (CI/CD)

Add to your CI/CD pipeline:

```yaml
- name: Run tests with coverage
  run: flutter test --coverage

- name: Check coverage threshold
  run: ./scripts/coverage.sh --check --threshold 75
```

## Best Practices

### 1. Run Locally Before Committing
```bash
./scripts/coverage.sh --check
```

### 2. Review HTML Report
```bash
./scripts/coverage.sh --view
```

### 3. Add Tests for Untested Code
If coverage drops below 80%:
1. Run `--view` to identify untested files
2. Add unit/widget/integration tests
3. Verify with `--check` again

### 4. Keep Thresholds Achievable
- Start with 70%, gradually increase to 80%+
- Don't aim for 100% (often not practical for UI-heavy code)
- Focus on critical paths (auth, data layer)

## Troubleshooting

### "lcov command not found"
**macOS:**
```bash
brew install lcov
```

**Linux:**
```bash
sudo apt-get install lcov
```

### "Coverage report not found"
Run:
```bash
flutter test --coverage
```

### "HTML report won't open"
Manual path: `coverage/html/index.html`
Open in your browser directly.

### Low Coverage Detection
Check:
1. Are all tests running? (`flutter test`)
2. Are mocks properly configured?
3. Is untested code in excluded patterns?

## Next Steps

1. **Generate baseline**: `./scripts/coverage.sh --view`
2. **Identify gaps**: Review HTML report for red files
3. **Add widget tests**: (See WIDGET_TESTS.md - to be created)
4. **Add integration tests**: (See INTEGRATION_TESTS.md - to be created)
5. **Monitor**: Run `--check` regularly to ensure 80%+

## Resources

- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [LCOV Documentation](http://ltp.sourceforge.net/coverage/lcov.php)
- [Dart Code Coverage](https://github.com/google/coverage.dart)
