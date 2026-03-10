# Android Google Play Deployment Guide

Complete guide for deploying DrawkcaB Flutter app to the Google Play Store.

---

## Quick Start

**Already set up?** Jump to [Build & Deploy](#build--deploy).

**First time?** Follow the [Prerequisites](#prerequisites) and [Setup](#setup) sections below.

**Need templates?** See [PLAYSTORE_METADATA.md](PLAYSTORE_METADATA.md) for app description, keywords, and store listing copy.

**Need icons/screenshots?** See [ASSETS_GUIDE.md](ASSETS_GUIDE.md) for detailed asset creation instructions.

---

## What's Already Configured

✅ Application ID: `chat.drawback.flutter`  
✅ App display name: "DrawkcaB"  
✅ Deep linking configured: `drawback://` scheme  
✅ Universal links configured: `https://drawback.chat`  
✅ Target SDK: Auto (latest via Flutter)  
✅ Automated build script: `make archive-android`  
✅ Release signing configuration (requires key.properties)

---

## Prerequisites

### Google Play Developer Account
- [ ] Google Play Console account ($25 one-time registration fee)
- [ ] Access to [Google Play Console](https://play.google.com/console)
- [ ] Payment profile set up (for paid apps or in-app purchases)

### Development Environment
- [ ] Java Development Kit (JDK) 17 or later installed
- [ ] Android SDK installed (via Android Studio or command-line tools)
- [ ] Flutter SDK installed and configured
- [ ] Run `flutter doctor -v` to verify setup
- [ ] Keystore file created for release signing (see [Setup](#setup))

### App Assets (REQUIRED before first build)
- [ ] **Adaptive app icon created** — 432x432 PNG foreground + background layers
- [ ] **Feature graphic created** — 1024x500 PNG/JPEG for Play Store listing
- [ ] **Screenshots prepared** — See [ASSETS_GUIDE.md](ASSETS_GUIDE.md) for required sizes
- [ ] **Marketing copy ready** — See [PLAYSTORE_METADATA.md](PLAYSTORE_METADATA.md) for templates

---

## Setup

### 1. Create Release Keystore

**⚠️ CRITICAL: Keep your keystore file secure and backed up. You cannot update your app without it!**

Generate a new upload keystore (one-time setup):

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

During the process, you'll be prompted for:
- **Keystore password** — Store securely (you'll need this for every build)
- **Key password** — Can be the same as keystore password
- **Name/Organization** — Your details (not shown to users)

**Backup your keystore:**
```bash
# Copy to a secure location (NOT the project directory)
cp ~/upload-keystore.jks ~/Dropbox/secure/upload-keystore.jks
# Or upload to a secure cloud storage
```

### 2. Configure Signing Properties

Create `android/key.properties` file (this file is gitignored):

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/Users/YOUR_USERNAME/upload-keystore.jks
```

**Replace:**
- `YOUR_KEYSTORE_PASSWORD` — Password from step 1
- `YOUR_KEY_PASSWORD` — Key password from step 1  
- `YOUR_USERNAME` — Your actual macOS username
- Or use relative path: `storeFile=../../../upload-keystore.jks`

**Security checklist:**
- [x] `key.properties` is listed in `.gitignore` (already configured)
- [x] Keystore file is NOT in project directory
- [x] Keystore file is backed up to secure location
- [x] Passwords are stored in password manager

### 3. Verify Signing Configuration

The app is already configured to read signing properties from `key.properties`. Verify:

- [x] `android/key.properties` file exists with correct paths
- [x] Keystore file path in `key.properties` is accessible
- [x] Run `make build-android-prod` to verify signing works

If signing fails, the build will automatically fall back to debug signing (for development only).

### 4. Create App in Google Play Console

- [ ] Go to [Google Play Console](https://play.google.com/console)
- [ ] Click **Create app**
- [ ] Configure:
  - **App name:** DrawkcaB
  - **Default language:** English (United States)
  - **App or game:** App
  - **Free or paid:** Free
  - **Declarations:** Accept all required declarations

### 5. Configure App Information

#### App Details
- [ ] **App name:** DrawkcaB (30 characters max)
- [ ] **Short description:** See [PLAYSTORE_METADATA.md](PLAYSTORE_METADATA.md) for template (80 characters max)
- [ ] **Full description:** See [PLAYSTORE_METADATA.md](PLAYSTORE_METADATA.md) for template (4000 characters max)
- [ ] **App icon:** 512x512 PNG, 32-bit with alpha (adaptive icon layers)
- [ ] **Feature graphic:** 1024x500 PNG/JPEG (REQUIRED)

#### Categorization
- [ ] **Category:** Social
- [ ] **Tags:** drawing, chat, social, creative (optional)

#### Store Listing Assets
- [ ] **App icon:** Upload 512x512 PNG adaptive icon
- [ ] **Feature graphic:** 1024x500 PNG/JPEG
- [ ] **Phone screenshots:** 2-8 screenshots, 1080x1920 recommended (16:9 or 9:16)
- [ ] **7-inch tablet screenshots:** 2-8 screenshots, 1024x1600 (optional)
- [ ] **10-inch tablet screenshots:** 2-8 screenshots, 1920x1200 (optional)

#### Contact Details
- [ ] **Email:** support@drawback.chat
- [ ] **Phone:** (optional)
- [ ] **Website:** https://drawback.chat
- [ ] **Privacy policy URL:** https://drawback.chat/privacy (REQUIRED)

### 6. Configure App Content

#### Privacy Policy
- [ ] Upload privacy policy URL: `https://drawback.chat/privacy`
- [ ] Complete **Data safety** form:
  - **Data collected:** Email address, User ID, User content (drawings)
  - **Data sharing:** None with third parties
  - **Data usage:** App functionality only
  - **Data security:** Encrypted in transit, can request deletion

#### Content Rating
- [ ] Complete content rating questionnaire:
  - No violence, sexual content, or substance abuse
  - Contains user-generated content (UGC)
  - Chat functionality available
  - Target audience: 13+ recommended due to UGC

#### Target Audience
- [ ] **Target age:** 13+ (or as determined by content rating)
- [ ] **Appeals to children:** No

#### News Apps (Skip)
- [ ] Not a news app

### 7. Configure App Access

- [ ] **Test account required:** Yes
- [ ] Provide test credentials in [PLAYSTORE_METADATA.md](PLAYSTORE_METADATA.md) format:
  - Email: demo@drawback.chat (or create test account)
  - Password: [Secure password for review team]
  - Instructions: Register, confirm email (bypass in test), search for other users, send chat request

### 8. Configure Ads Declaration

- [ ] **Contains ads:** No (select "No" if you're not showing ads)

### 9. Set Up Countries/Regions

- [ ] **Countries:** All countries (or customize)
- [ ] **Pricing:** Free

### 10. Configure App Signing (Play App Signing)

Google Play requires App Signing for new apps:

- [ ] Go to **Release** → **Setup** → **App integrity**
- [ ] Choose **Use Google Play App Signing** (recommended)
- [ ] Upload your first App Bundle (.aab) — Google will generate optimized APKs
- [ ] Download and securely store the **upload certificate** (for CI/CD)

**Note:** After enabling Play App Signing, you upload signed AABs with your upload key, and Google re-signs with their key for distribution.

---

## Build & Deploy

### Pre-Build Checklist

- [ ] All assets created (icons, screenshots, feature graphic)
- [ ] Store listing filled out in Play Console
- [ ] Data safety form completed
- [ ] Content rating completed
- [ ] `key.properties` file configured with valid keystore path
- [ ] Keystore file backed up to secure location
- [ ] App version updated in `pubspec.yaml` (if releasing new version)

### Build the App Bundle

**Automated script (recommended):**

```bash
make archive-android
```

This runs `./scripts/deploy-android.sh` which:
1. Validates prerequisites (Flutter, JDK, signing config)
2. Cleans previous builds
3. Runs tests: `flutter test`
4. Runs analyzer: `flutter analyze`
5. Builds App Bundle: `flutter build appbundle --dart-define=BACKEND_URL=https://drawback.chat/api`

**Manual build:**

```bash
# Build App Bundle for production
flutter build appbundle --dart-define=BACKEND_URL=https://drawback.chat/api

# Output location
# build/app/outputs/bundle/release/app-release.aab
```

**For testing only (APK):**

```bash
# APKs are not accepted by Play Store for new apps
make build-android-apk-prod
```

### Verify App Bundle (Optional)

Test the App Bundle locally before uploading:

```bash
# Install bundletool
brew install bundletool

# Generate APKs from bundle for testing
bundletool build-apks \
  --bundle=build/app/outputs/bundle/release/app-release.aab \
  --output=build/app.apks \
  --ks=~/upload-keystore.jks \
  --ks-key-alias=upload

# Install on connected device
bundletool install-apks --apks=build/app.apks
```

### Upload to Google Play Console

#### Internal Testing Track (First Release)

1. Go to **Release** → **Testing** → **Internal testing**
2. Click **Create new release**
3. Upload `build/app/outputs/bundle/release/app-release.aab`
4. **Release name:** e.g., "0.1.0 (1)" (auto-suggested)
5. **Release notes:** What's new in this version
6. Add internal testers (email addresses)
7. Click **Review release** → **Start rollout to Internal testing**

#### Production Release

Only after successful internal testing:

1. Go to **Release** → **Production**
2. Click **Create new release**
3. Upload `build/app/outputs/bundle/release/app-release.aab`
4. **Release name:** e.g., "0.1.0 (1)"
5. **Release notes:** See [PLAYSTORE_METADATA.md](PLAYSTORE_METADATA.md) for template
6. **Rollout percentage:** 100% (or staged rollout: 5%, 10%, 25%, 50%, 100%)
7. Click **Review release** → **Start rollout to Production**

---

## Submit for Review

### Pre-Submission Checklist

- [ ] All store listing fields completed
- [ ] Feature graphic and screenshots uploaded
- [ ] Privacy policy URL accessible
- [ ] Data safety form complete
- [ ] Content rating certificate received
- [ ] App signed and uploaded to production track
- [ ] Test account credentials provided (if app requires sign-in)
- [ ] App tested on multiple device sizes (phone/tablet)

### Submission Process

1. Go to **Publishing overview** in Play Console
2. Review all sections — any incomplete items will block submission
3. Click **Send for review** (appears after all requirements met)
4. Review typically takes 1-7 days (average 2-3 days)
5. Monitor email for approval or rejection notifications

### Common Rejection Reasons

- **Privacy policy missing or non-compliant**
- **Data safety form incomplete**
- **App crashes on launch** — Test thoroughly before submitting
- **Restricted content without proper disclosure**
- **Permissions not justified** — Ensure Info.plist descriptions are clear
- **Misleading screenshots/description** — Must accurately represent app

---

## Subsequent Releases

### Update Version

Edit `pubspec.yaml`:

```yaml
version: 0.2.0+2  # version_name+build_number
```

- Increment **version name** for user-facing updates: `0.1.0` → `0.2.0`
- Increment **build number** for every upload: `1` → `2`

### Build & Upload

```bash
# Automated
make archive-android

# Upload new AAB to Play Console
# Go to Production → Create new release → Upload AAB
```

### Release Notes

See [PLAYSTORE_METADATA.md](PLAYSTORE_METADATA.md) for "What's New" template.

Keep release notes concise:
- **What's new:** New features
- **Improvements:** Performance, UI tweaks
- **Bug fixes:** Issues resolved

Max 500 characters per language.

---

## Troubleshooting

### Build Errors

**Error: `key.properties` not found**
- Ensure file exists at `android/key.properties`
- Check file path is relative to `android/` directory
- Verify filename is exactly `key.properties` (case-sensitive on Linux)

**Error: Keystore file not found**
- Check `storeFile` path in `key.properties`
- Use absolute path: `/Users/username/upload-keystore.jks`
- Or relative path: `../../../upload-keystore.jks`

**Error: Invalid keystore format**
- Ensure you created a `.jks` file with `keytool`
- Re-generate if corrupted: see [Setup](#1-create-release-keystore)

**Error: Wrong keystore password**
- Verify password in `key.properties` matches keystore password
- Passwords are case-sensitive

### Signing Errors

**App signed with debug key in production**
- Verify `key.properties` exists and is readable
- Check console output for "Using debug signing" warning
- Ensure `storeFile` path points to valid keystore

**Different signing key error when updating**
- You must use the **same keystore** for all updates
- If keystore is lost, you cannot update the app — must create new app listing
- Always keep keystore backed up!

### Deep Link Verification

**Deep links not working on Android**
- Go to Play Console → **Advanced settings** → **App signing**
- Download SHA-256 certificate fingerprint
- Add to `https://drawback.chat/.well-known/assetlinks.json`:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "chat.drawback.flutter",
    "sha256_cert_fingerprints": ["YOUR_CERTIFICATE_FINGERPRINT"]
  }
}]
```

- Verify at: https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://drawback.chat&relation=delegate_permission/common.handle_all_urls

### Package Name Issues

**Package name already exists**
- Package names are globally unique
- You cannot change package name after first upload
- If blocked, must choose different package name (e.g., `chat.drawback.flutter.v2`)

**Package name mismatch**
- Ensure `applicationId` in `build.gradle.kts` matches Play Console
- Current package: `chat.drawback.flutter`
- Check `AndroidManifest.xml` package attribute matches

### Upload Issues

**Upload failed: Version code must be higher**
- Increment build number in `pubspec.yaml`: `version: 0.1.0+2`
- Build numbers must always increase, never reuse

**APK not accepted**
- Play Store requires **App Bundles (AAB)** for new apps
- Use `flutter build appbundle`, not `flutter build apk`
- APKs are only for testing outside Play Store

---

## App Updates & Maintenance

### Release Cadence Recommendations

- **Bug fixes:** As needed (high priority)
- **Minor features:** Every 2-4 weeks
- **Major features:** Every 2-3 months
- **Security updates:** Immediately

### Staged Rollouts

For major updates, use staged rollouts to minimize risk:

1. Upload new release to Production
2. Set rollout to **5%** of users initially
3. Monitor crash reports and reviews for 24-48 hours
4. If stable, increase to **25%**, then **50%**, then **100%**
5. If issues found, halt rollout and upload fixed version

### Monitoring Post-Launch

- [ ] **Crashes:** Play Console → **Quality** → **Android vitals**
- [ ] **ANRs (App Not Responding):** Same section
- [ ] **User reviews:** Respond to reviews, especially negative ones
- [ ] **Install metrics:** Monitor installs, uninstalls, retention

---

## Emergency Procedures

### Critical Bug in Production

1. **Don't panic** — you can upload a fixed version immediately
2. Build and test fix thoroughly
3. Increment version code: `0.1.0+1` → `0.1.1+2`
4. Upload to Production track (no additional review needed after first approval)
5. Play Store will push update to users within hours

### Remove App from Store (Unpublish)

1. Go to **Publishing overview**
2. Click **Unpublish app**
3. App removed from store (existing users keep access)
4. Can re-publish anytime

### Keystore Lost/Compromised

**If keystore is lost:**
- Cannot update existing app
- Must create entirely new app listing with new package name
- Existing users cannot receive updates — must download new app

**If keystore is compromised:**
1. Contact Google Play support immediately
2. May be able to rotate signing key (if using Play App Signing)
3. Upload new version with new certificate

---

## Quick Reference

### Commands

```bash
# Build App Bundle (production)
make archive-android

# Build App Bundle (manual)
flutter build appbundle --dart-define=BACKEND_URL=https://drawback.chat/api

# Build APK for testing
make build-android-apk-prod

# Run tests
flutter test

# Run analyzer
flutter analyze

# Clean builds
flutter clean
```

### File Paths

- App Bundle: `build/app/outputs/bundle/release/app-release.aab`
- APK output: `build/app/outputs/flutter-apk/app-release.apk`
- Signing config: `android/key.properties` (gitignored)
- Build config: `android/app/build.gradle.kts`
- Manifest: `android/app/src/main/AndroidManifest.xml`

### Important Links

- [Google Play Console](https://play.google.com/console)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [Play Console Help](https://support.google.com/googleplay/android-developer)
- [Digital Asset Links Validator](https://developers.google.com/digital-asset-links/tools/generator)

### Support

- Google Play Support: https://support.google.com/googleplay/android-developer/
- Flutter Publishing Docs: https://docs.flutter.dev/deployment/android
- DrawkcaB Backend: https://drawback.chat/api

---

**Last updated:** March 2026  
**App Version:** 0.1.0+1  
**Package Name:** chat.drawback.flutter  
**Target SDK:** Auto (via Flutter)
