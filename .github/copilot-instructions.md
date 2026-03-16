## DrawkcaB Flutter Copilot Instructions

Use this file as the default behavior guide when assisting in this repository.

## Project Context

- This is a Flutter client for DrawkcaB.
- Current implemented scope centers on auth and core navigation flows.
- Backend API base URL is provided through `--dart-define=BACKEND_URL=...`.
- App identifiers:
  - Android package/application id: `chat.drawback.flutter`
  - iOS bundle id: `chat.drawback.flutter`
  - iOS team id: `QLNTY3GVPQ`

## Core Working Style

- Prefer simple, direct control flow over excessive abstraction.
- Keep changes minimal and scoped to the request.
- Preserve existing architecture and naming unless migration/refactor is explicitly requested.
- Do not add new dependencies unless clearly necessary.
- Follow existing lint settings from `analysis_options.yaml`, including `avoid_print`.

## Flutter/Dart Coding Rules

- Keep widgets small and readable, but avoid unnecessary helper-method indirection.
- Use `const` constructors/widgets where possible.
- Handle async states explicitly (loading, success, error).
- Avoid silent failure paths; surface user-safe error messages and actionable logs.
- Prefer null-safe patterns over force unwraps.
- Keep platform conditionals localized and documented.

## Platform-Specific Constraints

### Android Billing

- Real Google Play Billing product queries require a Play Console uploaded build installed from a testing track.
- Local `flutter run` installs may return empty `productDetails` with `error == null`.
- Current product id in code: `discovery_premium`.

### Android Passkeys

- RP validation depends on `assetlinks.json` containing both relations:
  - `delegate_permission/common.get_login_creds`
  - `delegate_permission/common.handle_all_urls`
- Missing `common.handle_all_urls` can cause `RP ID cannot be validated` failures.

### iOS Passkeys

- Associated Domains capability must be configured.
- Entitlements include `webcredentials:drawback.chat` in `ios/Runner/Runner.entitlements`.
- Backend must serve `/.well-known/apple-app-site-association` over HTTPS as `application/json`.
- Expected app id in AASA: `QLNTY3GVPQ.chat.drawback.flutter`.

## Testing and Validation Expectations

When making code changes, validate with the smallest relevant checks first.

- Run formatter for touched Dart files.
- Run static analysis:

```bash
flutter analyze
```

- Run targeted tests when possible (unit/widget/integration related to changed area).
- If behavior affects auth, purchase, or passkeys, call that out explicitly in validation notes.

## Common Commands

```bash
flutter pub get
flutter analyze
flutter test
make archive-android
make archive-ios
```

## File and Documentation Hygiene

- Update docs when behavior, setup, or deployment steps change.
- Keep user-facing strings consistent with current product language.
- Do not check in secrets or local signing credentials (for example `android/key.properties` values).

## Change Review Checklist

Before finishing a task, verify:

- The change matches the user request exactly.
- No unrelated files were modified.
- Lints and tests relevant to the change are addressed or explicitly reported.
- Any platform-specific impacts (Android/iOS/Web) are noted.
