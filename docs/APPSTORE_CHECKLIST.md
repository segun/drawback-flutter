# iOS App Store Deployment Checklist

Use this checklist to ensure all steps are completed before and during App Store submission.

## Pre-Deployment Setup

### Apple Developer Account
- [ ] Active Apple Developer Program membership
- [ ] Development Team ID verified: `QLNTY3GVPQ`
- [ ] App Store Connect access confirmed
- [ ] Tax and banking information completed (for paid app/IAP)

### App Configuration
- [x] Bundle identifier updated to `chat.drawback.flutter`
- [x] App display name set to "DrawkcaB"
- [x] Version number set in `pubspec.yaml`
- [x] Privacy descriptions added to Info.plist
- [x] Export compliance flag set
- [ ] **App icon created** (square 1024x1024+, no transparency)
- [ ] **All app icon sizes generated** (run `./scripts/generate-app-icons.sh`)
- [ ] **App icons verified in Xcode** (Assets.xcassets → AppIcon)
- [ ] **Screenshots taken for all device sizes** (see Assets Guide)
- [ ] Backend URL set to production: `https://drawback.chat/api`

### Code Quality
- [ ] All tests passing: `make tests`
- [ ] Flutter analyzer clean: `flutter analyze`
- [ ] No TODO or FIXME in production code
- [ ] All console.log/print statements removed or commented
- [ ] Error handling tested with poor network
- [ ] App tested on physical iOS devices
- [ ] Tested on minimum iOS version (iOS 13.0)
- [ ] Memory leaks checked with Instruments
- [ ] No crashes during extended testing

## App Store Connect Setup

### Create App
- [ ] New app created in App Store Connect
- [ ] Bundle ID: `chat.drawback.flutter` selected
- [ ] App Name: "DrawkcaB" reserved
- [ ] Primary Language: English (U.S.)
- [ ] SKU: `drawback-flutter-ios` set
- [ ] Primary Category: Social Networking
- [ ] Secondary Category: Graphics & Design (optional)

### App Information
- [ ] Subtitle written (30 chars max)
- [ ] Privacy Policy URL: `https://drawback.chat/privacy`
- [ ] Support URL: `https://drawback.chat/support`
- [ ] Marketing URL: `https://drawback.chat` (optional)
- [ ] Copyright text: "Copyright © 2026 DrawkcaB. All rights reserved."
- [ ] App icon uploaded (1024x1024 PNG, no transparency)

### Pricing & Availability
- [ ] Price: Free (or set pricing)
- [ ] Availability: All countries (or select specific)
- [ ] Pre-order setup (if applicable)

## Content Preparation

### Screenshots
- [ ] iPhone 6.9" (1320 x 2868): 3-10 screenshots
- [ ] iPhone 6.7" (1290 x 2796): 3-10 screenshots
- [ ] iPhone 6.5" (1242 x 2688): 3-10 screenshots
- [ ] iPad Pro 12.9" (2048 x 2732): 3-10 screenshots (if supporting iPad)
- [ ] Screenshots show actual app UI
- [ ] No mockup frames or hardware images
- [ ] Text is readable and not cut off

### App Description
- [ ] Full description written (max 4000 chars)
- [ ] Promotional text written (max 170 chars)
- [ ] Keywords selected (max 100 chars, comma-separated)
- [ ] Description highlights key features
- [ ] "What's New" section ready for v1.0.0

### Age Rating
- [ ] Age Rating Questionnaire completed
- [ ] Appropriate for user-generated content
- [ ] Unrestricted web access declared

### App Privacy
- [ ] Privacy details configured in App Store Connect
- [ ] Data types collected listed:
  - [ ] Email Address (app functionality)
  - [ ] User ID (app functionality)
  - [ ] Drawings/User Content (app functionality)
- [ ] Data usage purposes explained
- [ ] Third-party data sharing: None
- [ ] Third-party tracking: No

## Build & Submit

### Build Preparation
- [ ] Clean build environment: `make clean-all`
- [ ] Dependencies installed: `make install`
- [ ] Tests run successfully: `make tests`
- [ ] Analyzer passes: `make analyze`
- [ ] Version incremented in `pubspec.yaml`

### Create Archive
- [ ] Run deployment script: `make archive-ios`
  - OR build IPA: `flutter build ipa --dart-define=BACKEND_URL=https://drawback.chat/api --export-options-plist=ios/ExportOptions.plist`
- [ ] IPA file created successfully
- [ ] IPA size checked (should be under 200MB for initial download)

### Validate Build (Optional but Recommended)
- [ ] IPA validated with altool or Xcode
- [ ] No validation errors
- [ ] Warnings reviewed and addressed

### Upload to App Store Connect
Choose one method:
- [ ] **Option A:** Uploaded via Xcode Organizer
- [ ] **Option B:** Uploaded via altool command line
- [ ] **Option C:** Uploaded via Transporter app
- [ ] Upload completed successfully
- [ ] Build shows "Processing" then "Ready" in App Store Connect

### TestFlight (Recommended)
- [ ] Build available in TestFlight tab
- [ ] Internal testers added
- [ ] TestFlight beta information filled
- [ ] Beta tester feedback received
- [ ] Critical bugs fixed before production

## App Review Submission

### Version Information
- [ ] Build selected from list
- [ ] Version number matches build
- [ ] "What's New" text added

### Test Account
- [ ] Demo account created with email: `reviewer@drawback.chat`
- [ ] Demo account password set and saved
- [ ] Demo account tested and working
- [ ] Demo account credentials entered in App Store Connect

### App Review Information
- [ ] Sign-in required: YES
- [ ] Demo account username provided
- [ ] Demo account password provided
- [ ] Notes for reviewer added (testing instructions)
- [ ] Contact information filled:
  - [ ] First name
  - [ ] Last name
  - [ ] Phone number
  - [ ] Email address

### Export Compliance
- [ ] "Does your app use encryption?" → YES
- [ ] "Is it exempt from U.S. encryption regulations?" → YES
  - Standard HTTPS encryption only
- [ ] Export compliance documentation NOT required for standard HTTPS

### Content Rights
- [ ] Third-party content: None (or list if applicable)
- [ ] Rights to use all content in app verified

### Advertising Identifier (IDFA)
- [ ] "Does this app use the Advertising Identifier?" → NO
  - (select YES only if using ad frameworks)

### Final Checks
- [ ] All required fields filled with green checkmarks
- [ ] App icon appears correctly
- [ ] Screenshots display properly
- [ ] Metadata reviewed for typos
- [ ] URLs are accessible and correct
- [ ] Privacy policy is live and accessible

### Submit
- [ ] **Submit for Review** button clicked
- [ ] Confirmation email received
- [ ] App status: "Waiting for Review"

## After Submission

### During Review
- [ ] Monitor App Store Connect status (check daily)
- [ ] Watch email for questions from Apple Review
- [ ] Respond to review questions within 24 hours
- [ ] Server uptime monitored and stable
- [ ] Demo account remains active and functional

### If Rejected
- [ ] Read rejection reason carefully
- [ ] Fix issues identified by Apple
- [ ] Update notes for reviewer if needed
- [ ] Increment build number if new build needed
- [ ] Resubmit with explanations

### Upon Approval
- [ ] App status: "Pending Developer Release" or "Ready for Sale"
- [ ] Choose release option:
  - [ ] Release immediately
  - [ ] Schedule for specific date/time
  - [ ] Manual release
- [ ] Announce launch on social media / website
- [ ] Monitor crash reports in App Store Connect
- [ ] Prepare customer support channels

## Post-Launch

### Week 1
- [ ] Monitor App Store reviews
- [ ] Check crash reports daily
- [ ] Verify analytics (if implemented)
- [ ] Respond to user reviews
- [ ] Watch for critical bugs
- [ ] Backend monitoring for increased load

### Ongoing
- [ ] Plan regular updates (bug fixes, features)
- [ ] Maintain TestFlight beta testing
- [ ] Keep demo account functional for future reviews
- [ ] Monitor App Store Connect health metrics
- [ ] Respond to user feedback
- [ ] Update screenshots for new features

## Emergency Procedures

### Critical Bug Found Post-Launch
1. [ ] Fix bug immediately
2. [ ] Increment version and build number
3. [ ] Run full test suite
4. [ ] Build and submit expedited review
5. [ ] Request expedited review with explanation
6. [ ] In notes, explain critical nature of fix

### Take Down App (if needed)
1. [ ] App Store Connect → App → Pricing and Availability
2. [ ] Remove from all territories
3. [ ] Status will change to "Developer Removed from Sale"

---

## Quick Commands Reference

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

# Update version (edit pubspec.yaml)
# version: 1.0.0+1  → 1.0.1+2
```

---

## Resources

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Connect](https://appstoreconnect.apple.com)
- [Apple Developer Portal](https://developer.apple.com)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [TestFlight Documentation](https://developer.apple.com/testflight/)

---

**Last Updated:** March 6, 2026  
**Version:** 1.0.0+1
