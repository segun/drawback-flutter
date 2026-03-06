# iOS Deployment - Quick Start

This is a quick reference guide for deploying DrawkcaB to the Apple App Store.

## What's Been Configured

✅ **Bundle Identifier:** Changed from `com.example.drawbackFlutter` to `chat.drawback.flutter`  
✅ **App Display Name:** Updated to "DrawkcaB"  
✅ **Team ID:** Set to `QLNTY3GVPQ`  
✅ **Privacy Descriptions:** Added required Info.plist entries  
✅ **Export Compliance:** Configured for standard HTTPS encryption  
✅ **Build Scripts:** Automated deployment script created  
✅ **Export Options:** Plist file configured for App Store distribution

## First Time Deployment

### 1. Prerequisites
- Active Apple Developer Program membership
- Xcode installed with command line tools
- Flutter SDK properly configured
- Access to App Store Connect
- **App icon and screenshots ready** (see below)

### 2. Create App Assets (IMPORTANT!)

Before building, you need app icons and screenshots:

**App Icon:**
```bash
# 1. Create square icon (1024x1024) from your logo
#    Save as: flutter/assets/images/app_icon_1024.png

# 2. Generate all icon sizes
cd flutter
./scripts/generate-app-icons.sh assets/images/app_icon_1024.png

# 3. Verify in Xcode
open ios/Runner.xcworkspace
# → Runner → Assets.xcassets → AppIcon (should show your icon)
```

**Screenshots:**
```bash
# 1. Setup screenshot folders
./scripts/setup-screenshots.sh

# 2. Take screenshots (see docs/ASSETS_GUIDE.md for details)
#    Required: 3-10 screenshots for each device size:
#    - 6.9" (1320 x 2868)
#    - 6.7" (1290 x 2796)  
#    - 6.5" (1242 x 2688)
```

See **[ASSETS_GUIDE.md](ASSETS_GUIDE.md)** for complete instructions.

### 3. Create App in App Store Connect
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click "My Apps" → "+" → "New App"
3. Fill in:
   - **Platform:** iOS
   - **Name:** DrawkcaB
   - **Primary Language:** English (U.S.)
   - **Bundle ID:** Select `chat.drawback.flutter` (or create it in Apple Developer Portal first)
   - **SKU:** `drawback-flutter-ios`
   - **User Access:** Full Access

### 3. Build and Archive

```bash
cd flutter
make archive-ios
```

This command will:
- Clean previous builds
- Install dependencies
- Run tests and analysis
- Create production IPA
- Show you the next steps

### 4. Upload to App Store Connect

**Easiest method (recommended for first time):**

1. Open Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Select "Any iOS Device (arm64)" as the destination

3. Product → Archive

4. When complete, the Organizer window opens automatically

5. Select your archive → "Distribute App"

6. Choose "App Store Connect" → Next

7. Choose "Upload" → Next

8. Select automatic signing → Next

9. Review the app, package, and signing information → Upload

10. Wait for processing (can take 10-30 minutes)

**Alternative: Command line upload**

```bash
xcrun altool --upload-app \
  -f build/ios/ipa/drawback_flutter.ipa \
  -t ios \
  --apiKey YOUR_API_KEY \
  --apiIssuer YOUR_ISSUER_ID
```

### 5. Configure App Store Listing

While the build processes:

1. In App Store Connect, go to your app

2. Fill in required information:
   - App Privacy details
   - App Description (see [APPSTORE_METADATA.md](APPSTORE_METADATA.md))
   - Keywords
   - Screenshots (required sizes listed in metadata doc)
   - Support URL: `https://drawback.chat/support`
   - Privacy Policy URL: `https://drawback.chat/privacy`

3. Create demo/test account:
   - Email: `reviewer@drawback.chat`
   - Set password and save it
   - Enter credentials in "App Review Information"

4. Add notes for reviewer explaining how to test

### 6. Submit for Review

1. Once build shows "Ready" in App Store Connect

2. Go to App Store tab → Select your build

3. Fill in "What's New in This Version"

4. Add demo account credentials

5. Answer export compliance questions:
   - Uses encryption? **YES**
   - Exempt from regulations? **YES** (standard HTTPS only)

6. Click "Submit for Review"

7. Status changes to "Waiting for Review"

### 7. Monitor Review Process

- Check App Store Connect daily
- Respond to any questions within 24 hours
- Average review time: 1-3 days
- Keep backend server stable during review

## Subsequent Releases

For updates after the initial release:

### 1. Update Version
Edit `pubspec.yaml`:
```yaml
version: 1.0.1+2  # Increment version and build number
```

### 2. Build and Submit
```bash
make archive-ios
```

Then upload using the same process as first time.

### 3. Update "What's New"
In App Store Connect, describe the changes in this version.

### 4. Submit
Updates typically review faster than initial submissions.

## Common Issues

### "No provisioning profile found"
**Solution:** Open Xcode, go to Settings → Accounts → Download Manual Profiles

### "Bundle identifier already exists"
**Solution:** Use `chat.drawback.flutter` (already configured) or register a new one in Apple Developer Portal

### "Missing compliance"
**Solution:** Answer the export compliance questions in App Store Connect. For standard HTTPS, select YES for encryption and YES for exemption.

### Build fails with pod errors
**Solution:**
```bash
cd flutter
make clean-all
make install
```

## Important Files

| File | Purpose |
|------|---------|
| `ios/Runner.xcodeproj/project.pbxproj` | Xcode project with bundle ID and team settings |
| `ios/Runner/Info.plist` | App metadata and privacy descriptions |
| `ios/ExportOptions.plist` | Archive export configuration |
| `scripts/deploy-ios.sh` | Automated build and deployment script |
| `Makefile` | Build commands (`make archive-ios`) |
| `docs/IOS_APPSTORE_DEPLOYMENT.md` | Complete deployment guide |
| `docs/APPSTORE_CHECKLIST.md` | Step-by-step submission checklist |
| `docs/APPSTORE_METADATA.md` | App Store listing content templates |

## Quick Commands

```bash
# Build for App Store
make archive-ios

# Clean everything and reinstall
make clean-all && make install

# Run tests
make tests

# Run analyzer
make analyze

# Open in Xcode
open ios/Runner.xcworkspace

# Check Flutter setup
flutter doctor -v
```

## Support Resources

- **Full Guide:** [docs/IOS_APPSTORE_DEPLOYMENT.md](IOS_APPSTORE_DEPLOYMENT.md)
- **Checklist:** [docs/APPSTORE_CHECKLIST.md](APPSTORE_CHECKLIST.md)
- **Metadata Templates:** [docs/APPSTORE_METADATA.md](APPSTORE_METADATA.md)
- **App Store Connect:** https://appstoreconnect.apple.com
- **Apple Developer:** https://developer.apple.com

## Need Help?

1. Check the full deployment guide: `docs/IOS_APPSTORE_DEPLOYMENT.md`
2. Review the step-by-step checklist: `docs/APPSTORE_CHECKLIST.md`
3. Consult [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
4. Run `flutter doctor -v` to check your development environment

---

**Ready to deploy?** Start with: `make archive-ios`

Good luck with your App Store submission! 🚀
