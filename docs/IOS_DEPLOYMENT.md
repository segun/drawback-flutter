# iOS App Store Deployment Guide

Complete guide for deploying DrawkcaB Flutter app to the Apple App Store.

---

## Quick Start

**Already set up?** Jump to [Build & Deploy](#build--deploy).

**First time?** Follow the [Prerequisites](#prerequisites) and [Setup](#setup) sections below.

**Need templates?** See [APPSTORE_METADATA.md](APPSTORE_METADATA.md) for app description, keywords, and marketing copy.

**Need icons/screenshots?** See [ASSETS_GUIDE.md](ASSETS_GUIDE.md) for detailed asset creation instructions.

---

## What's Already Configured

✅ Bundle identifier: `chat.drawback.flutter`  
✅ App display name: "DrawkcaB"  
✅ Team ID: `QLNTY3GVPQ`  
✅ Privacy descriptions in Info.plist  
✅ Export compliance configuration  
✅ Automated build script: `make archive-ios`  
✅ Export options for App Store distribution

---

## Prerequisites

### Apple Developer Account
- [ ] Active Apple Developer Program membership ($99/year)
- [ ] Access to [App Store Connect](https://appstoreconnect.apple.com)
- [ ] Access to [Apple Developer Portal](https://developer.apple.com)

### Development Environment
- [ ] macOS with Xcode installed (latest stable recommended)
- [ ] Flutter SDK installed and configured
- [ ] CocoaPods installed: `sudo gem install cocoapods`
- [ ] Valid code signing certificates in Keychain
- [ ] Run `flutter doctor -v` to verify setup

### App Assets (REQUIRED before first build)
- [ ] **App icon created** — Square 1024x1024 PNG, no transparency
- [ ] **All icon sizes generated** — Run `./scripts/generate-app-icons.sh`
- [ ] **Screenshots prepared** — See [ASSETS_GUIDE.md](ASSETS_GUIDE.md) for required sizes
- [ ] **Marketing copy ready** — See [APPSTORE_METADATA.md](APPSTORE_METADATA.md) for templates

---

## Setup

### 1. Create App in App Store Connect

- [ ] Go to [App Store Connect](https://appstoreconnect.apple.com)
- [ ] Click **My Apps** → **+** → **New App**
- [ ] Configure:
  - Platform: **iOS**
  - Name: **DrawkcaB**
  - Primary Language: **English (U.S.)**
  - Bundle ID: **chat.drawback.flutter** (create in Apple Developer Portal first if needed)
  - SKU: **drawback-flutter-ios**
  - User Access: **Full Access**

### 2. Configure App Information

- [ ] **App Privacy** — Configure data collection details:
  - Email Address (app functionality)
  - User ID (app functionality)
  - User Content/Drawings (app functionality)
  - No third-party tracking
- [ ] **Pricing & Availability** — Free, all countries (or customize)
- [ ] **App Category** — Social Networking (primary), Graphics & Design (secondary)
- [ ] **Age Rating** — Complete questionnaire (unrestricted web access, user-generated content)

### 3. Upload App Store Assets

- [ ] **App Icon** — 1024x1024 PNG uploaded to App Store Connect
- [ ] **Screenshots** uploaded for required device sizes:
  - iPhone 6.9" (1320 x 2868 px) — iPhone 16 Pro Max
  - iPhone 6.7" (1290 x 2796 px) — iPhone 14/15 Pro Max  
  - iPhone 6.5" (1242 x 2688 px) — iPhone 11 Pro Max/XS Max
  - iPad Pro 12.9" (2048 x 2732 px) — if supporting iPad
- [ ] **App description** — See [APPSTORE_METADATA.md](APPSTORE_METADATA.md) for template
- [ ] **Keywords** — Max 100 characters, comma-separated
- [ ] **Promotional text** — Max 170 characters (can be updated without new version)
- [ ] **Support URL** — `https://drawback.chat/support`
- [ ] **Privacy Policy URL** — `https://drawback.chat/privacy`
- [ ] **Marketing URL** — `https://drawback.chat` (optional)

### 4. Configure Code Signing

**Option A: Automatic Signing (Recommended)**
- [ ] Open `ios/Runner.xcworkspace` in Xcode
- [ ] Select **Runner** target → **Signing & Capabilities**
- [ ] Check **Automatically manage signing**
- [ ] Select your team: **QLNTY3GVPQ**

**Option B: Manual Signing**
- [ ] Create Distribution Certificate in Apple Developer Portal
- [ ] Create App Store Provisioning Profile
- [ ] Download and install in Xcode
- [ ] Configure in Xcode project settings

---

## Build & Deploy

### Pre-Build Checklist

- [ ] All unit tests passing: `make tests`
- [ ] Flutter analyzer clean: `make analyze` or `flutter analyze`
- [ ] App tested on physical iOS devices
- [ ] Tested on minimum iOS version (13.0+)
- [ ] Backend server stable at `https://drawback.chat/api`
- [ ] Version number updated in `pubspec.yaml`
- [ ] Build number incremented (required for each submission)

### Build the Archive

**Automated (Recommended):**
```bash
cd flutter
make archive-ios
```

This will:
- Clean previous builds
- Install dependencies  
- Run tests and analyzer
- Build release IPA
- Place IPA at: `build/ios/ipa/drawback_flutter.ipa`

**Manual:**
```bash
cd flutter
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter test
flutter analyze
flutter build ipa \
  --dart-define=BACKEND_URL=https://drawback.chat/api \
  --release \
  --export-options-plist=ios/ExportOptions.plist
```

### Validate the Build (Optional but Recommended)

```bash
xcrun altool --validate-app \
  -f build/ios/ipa/drawback_flutter.ipa \
  -t ios \
  --apiKey YOUR_API_KEY \
  --apiIssuer YOUR_ISSUER_ID
```

### Upload to App Store Connect

Choose one method:

**Option A: Xcode Organizer (Recommended for first time)**
1. Open Xcode: `open ios/Runner.xcworkspace`
2. Select **Any iOS Device (arm64)** as destination
3. **Product** → **Archive**
4. When complete, Organizer window opens automatically
5. Select your archive → **Distribute App**
6. Choose **App Store Connect** → Next
7. Choose **Upload** → Next
8. Select automatic signing → Next
9. Review information → **Upload**
10. Wait for processing (10-30 minutes)

**Option B: Command Line (requires App Store Connect API key)**
```bash
xcrun altool --upload-app \
  -f build/ios/ipa/drawback_flutter.ipa \
  -t ios \
  --apiKey YOUR_API_KEY \
  --apiIssuer YOUR_ISSUER_ID
```

**Option C: Transporter App**
1. Download Transporter from Mac App Store
2. Open IPA file in Transporter
3. Click **Deliver**

### TestFlight Beta Testing (Optional but Recommended)

- [ ] Build appears in **TestFlight** tab in App Store Connect
- [ ] Add internal testers (up to 100, no review needed)
- [ ] Fill in **Beta App Information**
- [ ] Add external testers (up to 10,000, requires Beta App Review)
- [ ] Collect and address feedback before production release

---

## Submit for App Review

### Prepare Submission

- [ ] Build status shows **Ready** in App Store Connect (processing complete)
- [ ] Go to **App Store** tab → Create new version or select version
- [ ] Select the build from the dropdown

### Fill Required Information

**Version Information:**
- [ ] **What's New in This Version** — Describe changes/features (v1.0.0: "Initial release")
- [ ] Version number matches build

**App Review Information:**
- [ ] **Sign-in required:** YES
- [ ] **Demo account** created and tested:
  - Username: `reviewer@drawback.chat`
  - Password: [Create secure password and save it]
- [ ] Demo credentials entered in App Store Connect
- [ ] **Notes for reviewer** — Instructions for testing:
  ```
  To test the app:
  1. Log in with the provided test account
  2. Search for users using @ symbol (e.g., @test_user)
  3. Send a chat request to another test user
  4. Draw on the canvas to test real-time collaboration
  
  Backend server: https://drawback.chat/api
  ```
- [ ] **Contact information** — Your name, phone, email

**Export Compliance:**
- [ ] Does your app use encryption? **YES**
- [ ] Is it exempt from U.S. encryption regulations? **YES**
  - Reason: Uses only standard HTTPS encryption
- [ ] Export compliance documentation: **Not required** (standard HTTPS only)

**Content Rights:**
- [ ] Third-party content: **None** (or list if applicable)
- [ ] Confirm rights to all content in app

**Advertising Identifier (IDFA):**
- [ ] Does this app use the Advertising Identifier? **NO** (unless using ad frameworks)

### Final Review

- [ ] All required fields have green checkmarks
- [ ] App icon displays correctly
- [ ] Screenshots render properly on all device sizes
- [ ] All URLs are accessible (test in browser)
- [ ] Metadata reviewed for typos and accuracy
- [ ] Privacy policy is live and accessible
- [ ] Support page exists and is functional

### Submit

- [ ] Click **Submit for Review**
- [ ] Confirmation email received
- [ ] App status: **Waiting for Review**

---

## Monitor & Respond

### During Review (1-3 days average)

- [ ] Check App Store Connect status daily
- [ ] Monitor email for questions from Apple Review Team
- [ ] Respond to any questions within 24 hours
- [ ] Keep backend server stable and accessible
- [ ] Ensure demo account remains functional

### If Approved ✅

Status changes to **Pending Developer Release** or **Ready for Sale**

Choose release option:
- [ ] **Automatic** — Releases immediately upon approval
- [ ] **Manual** — Click **Release This Version** when ready
- [ ] **Scheduled** — Set specific date/time for release

Post-launch:
- [ ] Announce on social media / website
- [ ] Monitor crash reports in App Store Connect
- [ ] Watch for user reviews
- [ ] Respond to user feedback

### If Rejected ❌

- [ ] Read rejection reason carefully in Resolution Center
- [ ] Fix issues identified by Apple
- [ ] Update code if necessary (increment build number)
- [ ] Update notes for reviewer with explanation
- [ ] Resubmit for review

Common rejection reasons:
- **2.1 App Completeness** — Demo account doesn't work, features broken
- **4.3 Design - Spam** — App needs unique value proposition
- **5.1.1 Privacy** — Missing privacy policy or incorrect data usage declarations

---

## Subsequent Releases

### Update Process

1. **Increment version** in `pubspec.yaml`:
   ```yaml
   # Patch (bug fixes): 1.0.0+1 → 1.0.1+2
   # Minor (new features): 1.0.0+1 → 1.1.0+2
   # Major (breaking changes): 1.0.0+1 → 2.0.0+2
   version: 1.0.1+2
   ```

2. **Build and upload:**
   ```bash
   make archive-ios
   ```
   Then upload using same method as initial release

3. **In App Store Connect:**
   - Create new version
   - Select new build
   - Update **What's New in This Version**
   - Submit for review

4. **Updates typically review faster** than initial submissions

---

## Troubleshooting

### Build Issues

**"No provisioning profile found"**
```bash
# Open Xcode → Settings → Accounts → Download Manual Profiles
# Or enable automatic signing in Xcode project settings
open ios/Runner.xcworkspace
```

**"Pod install failed"**
```bash
cd flutter
rm -rf ios/Pods ios/Podfile.lock
make clean-all
make install
```

**"No valid code signing certificates"**
- Open Xcode → Settings → Accounts
- Select Apple ID → Download Manual Profiles
- Or create Distribution Certificate in Apple Developer Portal

**Build size too large (>200MB)**
```bash
flutter build ipa \
  --split-debug-info=./debug_symbols \
  --obfuscate \
  --dart-define=BACKEND_URL=https://drawback.chat/api
```

### Upload Issues

**"exportArchive Error Downloading App Information"**
- App record must exist in App Store Connect first
- Or change `destination` in `ios/ExportOptions.plist` from `upload` to `export`

**"Missing compliance documentation"**
- Answer export compliance questions in App Store Connect
- For standard HTTPS: YES to encryption, YES to exemption

**"Invalid provisioning profile"**
```bash
cd flutter
rm -rf ios/Pods ios/Podfile.lock build
flutter clean
cd ios && pod install && cd ..
```

### Review Issues

**Demo account doesn't work**
- Test the exact credentials you provided to Apple
- Ensure account isn't deactivated or locked
- Backend must be accessible during review

**App crashes on launch**
- Test on physical device, not just simulator
- Check backend URL is correct production URL
- Review crash logs in App Store Connect

---

## Emergency Procedures

### Critical Bug Post-Launch

1. Fix bug immediately in code
2. Increment version and build number
3. Run full test suite
4. Build and submit new version
5. Request **Expedited Review** in App Store Connect
6. In notes, explain critical nature and impact

### Remove App from Sale

1. App Store Connect → Your App → **Pricing and Availability**
2. **Remove from all territories**
3. Status changes to **Developer Removed from Sale**
4. Can re-enable anytime

---

## Quick Reference

### Commands

```bash
# Full clean and reinstall
make clean-all && make install

# Run tests and analysis
make tests && make analyze

# Build and create IPA for App Store
make archive-ios

# Open in Xcode
open ios/Runner.xcworkspace

# Check Flutter environment
flutter doctor -v

# Check app size
du -sh build/ios/ipa/drawback_flutter.ipa
```

### Important Files

| File | Purpose |
|------|---------|
| `pubspec.yaml` | App version number |
| `ios/Runner.xcodeproj/project.pbxproj` | Bundle ID and team settings |
| `ios/Runner/Info.plist` | Privacy descriptions and metadata |
| `ios/ExportOptions.plist` | Archive export configuration |
| `scripts/deploy-ios.sh` | Automated deployment script |
| `Makefile` | Build commands |

### Resources

- **Content Templates:** [APPSTORE_METADATA.md](APPSTORE_METADATA.md)
- **Icon/Screenshot Guide:** [ASSETS_GUIDE.md](ASSETS_GUIDE.md)
- **App Store Connect:** https://appstoreconnect.apple.com
- **Apple Developer:** https://developer.apple.com
- **Review Guidelines:** https://developer.apple.com/app-store/review/guidelines/
- **Human Interface Guidelines:** https://developer.apple.com/design/human-interface-guidelines/
- **TestFlight Help:** https://developer.apple.com/testflight/
- **Flutter iOS Deployment:** https://docs.flutter.dev/deployment/ios

---

## Post-Launch Monitoring

### Week 1

- [ ] Monitor App Store reviews daily
- [ ] Check crash reports in App Store Connect
- [ ] Verify analytics (if implemented)
- [ ] Respond to user reviews
- [ ] Monitor backend for increased load
- [ ] Watch for critical bugs

### Ongoing

- [ ] Plan regular updates (features, bug fixes)
- [ ] Maintain TestFlight beta program
- [ ] Keep demo account functional for future reviews
- [ ] Monitor App Store Connect health metrics
- [ ] Track user feedback and feature requests
- [ ] Update screenshots when adding major features

---

**Ready to deploy?**

```bash
cd flutter
make archive-ios
```

Good luck with your App Store submission! 🚀

---

_Last updated: March 6, 2026_
