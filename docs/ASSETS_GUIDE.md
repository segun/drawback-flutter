# App Store Assets Guide

This guide covers creating all required visual assets for iOS App Store and Google Play Store submission.

## Current Status

- ❌ **App Icons**: Currently using Flutter default placeholders
- ❌ **iOS App Store Icon**: Need 1024x1024 PNG for App Store Connect
- ❌ **Android Adaptive Icon**: Need 432x432 foreground + background layers
- ❌ **Play Store Feature Graphic**: Need 1024x500 PNG/JPEG
- ❌ **Screenshots**: Need to create for multiple device sizes (iOS & Android)
- ✅ **Source Logo**: Available at `public/images/logo/logo_main.png` (1536x672)

---

## 🎨 Part 1: App Icons

### Requirements

App icons must be:
- **Square** (1:1 aspect ratio)
- **No transparency** (fully opaque)
- **No alpha channel**
- **PNG format**
- **Different sizes** for different contexts

### Your Logo Issue

Your current logo (`logo_main.png`) is **1536 x 672** (not square). You need to create a square version for the app icon.

### Creating a Square Icon

**Option 1: Add background (Recommended for branding)**
1. Open your logo in a design tool (Figma, Sketch, Photoshop, etc.)
2. Create a 1536x1536 canvas
3. Add a background color (e.g., rose/pink to match your brand)
4. Center your logo on the background
5. Export as PNG at 1536x1536

**Option 2: Crop/Resize (Only if logo works when cropped)**
1. Crop the logo to include just the essential icon element
2. Resize to 1536x1536
3. Ensure it looks good when small

**Option 3: Create new icon mark**
- Design a simplified icon specifically for app icon use
- Square format from the start
- Should be recognizable even at 20x20 pixels

### Save Your Square Icon

Save it as: `flutter/assets/images/app_icon_1024.png` at 1024x1024 or larger

---

## 🔧 Generating All App Icon Sizes

### Automated Method (Recommended)

I've created a script for you. First, create your square icon, then:

```bash
cd flutter
./scripts/generate-app-icons.sh assets/images/app_icon_1024.png
```

This will generate all required sizes automatically.

### Manual Method

Use online tools:
- **[App Icon Generator](https://www.appicon.co/)** - Upload 1024x1024, download iOS set
- **[MakeAppIcon](https://makeappicon.com/)** - Free, generates all sizes
- **[App Icon Resizer](https://resizeappicon.com/)** - Simple and fast

### Manual Installation

After generating:
1. Download the iOS icon set
2. Replace all files in `flutter/ios/Runner/Assets.xcassets/AppIcon.appiconset/`
3. Keep the `Contents.json` file unchanged
4. Verify in Xcode that all icons show up

---

## 📱 Part 2: Screenshots

### Required Sizes for App Store

You **must** provide screenshots for these display sizes:

| Device | Resolution | Notes |
|--------|------------|-------|
| iPhone 6.9" | 1320 x 2868 px | iPhone 16 Pro Max, **Required** |
| iPhone 6.7" | 1290 x 2796 px | iPhone 14/15 Pro Max, **Required** |
| iPhone 6.5" | 1242 x 2688 px | iPhone 11 Pro Max/XS Max, **Required** |
| iPad Pro 12.9" | 2048 x 2732 px | 6th gen, Required if supporting iPad |

For each size, you need **3-10 screenshots** showing key features.

### Screenshots to Create

**Recommended 5 screenshots:**

1. **Login/Welcome Screen**
   - Shows the app branding
   - Clean, inviting first impression
   - Can include "Welcome to DrawkcaB" text overlay

2. **Registration Flow**
   - Shows how easy it is to sign up
   - Highlight the @displayname feature
   - "Get started in seconds" messaging

3. **User Search/Discovery**
   - Shows the search interface
   - Finding other users
   - "Connect with friends" messaging

4. **Chat Request Flow**
   - Sending/receiving chat requests
   - Shows the social aspect
   - "Start conversations easily"

5. **Feature overview/Coming Soon**
   - Preview of the drawing canvas (even if not fully implemented)
   - "Draw together in real-time" messaging
   - Build excitement for full features

### Creating Screenshots

#### Method 1: iOS Simulator (Easiest)

1. **Launch appropriate simulator:**
   ```bash
   # iPhone 16 Pro Max (6.9")
   flutter emulators --launch apple_ios_simulator
   # OR open specific device in Xcode: Xcode → Open Developer Tool → Simulator
   ```

2. **Run your app:**
   ```bash
   flutter run -d <simulator-id> --dart-define=BACKEND_URL=https://drawback.chat/api
   ```

3. **Navigate to each screen and capture:**
   - macOS: `Cmd + S` in Simulator saves screenshot to Desktop
   - Or: File → Save Screen

4. **Repeat for each device size:**
   - iPhone 16 Pro Max (6.9")
   - iPhone 14 Pro Max (6.7")
   - iPhone 11 Pro Max (6.5")

#### Method 2: Physical Device

1. Run app on physical device
2. Navigate to each screen
3. Take screenshots (Volume Up + Power button)
4. AirDrop to Mac
5. Verify resolution matches required size

#### Method 3: Screenshot Tool (Professional)

Use tools like:
- **[Screenshot Creator](https://www.appstorescreenshot.com/)** - Add device frames
- **[Previewed](https://previewed.app/)** - Professional mockups
- **[Figma](https://www.figma.com/)** - Design screenshots with overlays

### Screenshot Best Practices

✅ **Do:**
- Show actual app UI (no mockups unless adding device frame around real screenshot)
- Use real content (demo accounts with good data)
- Keep text legible
- Show key features clearly
- Use consistent branding/colors
- Add text overlays to explain features (optional but helpful)
- Ensure status bar looks clean (time = 9:41 AM, full battery, full signal)

❌ **Don't:**
- Include personal information
- Show empty states (use demo data)
- Use placeholder text like "Lorem ipsum"
- Include offensive content
- Show incorrect device in screenshot (6.5" screenshots must be from 6.5" device)
- Include promotional text in the UI itself (can add as overlay)

### Organizing Screenshots

Create this folder structure:

```
flutter/screenshots/
├── 6.9-inch/          # iPhone 16 Pro Max (1320 x 2868)
│   ├── 01-welcome.png
│   ├── 02-register.png
│   ├── 03-search.png
│   ├── 04-chat-request.png
│   └── 05-features.png
├── 6.7-inch/          # iPhone 14 Pro Max (1290 x 2796)
│   └── ...
├── 6.5-inch/          # iPhone 11 Pro Max (1242 x 2688)
│   └── ...
└── 12.9-inch-ipad/    # iPad Pro (2048 x 2732) - if supporting
    └── ...
```

---

## 📤 Part 3: Uploading to App Store Connect

### App Icons

1. The 1024x1024 icon goes in two places:
   - ✅ Xcode project (already done via icon generation)
   - App Store Connect → App Store tab → App Information → App Icon
   
2. Upload requirements:
   - Exactly 1024 x 1024 pixels
   - PNG format
   - No transparency
   - No rounded corners (Apple adds them)

### Screenshots

1. Go to App Store Connect → Your App → App Store tab

2. Under "App Previews and Screenshots":
   - Select device size (e.g., 6.9" Display)
   - Drag and drop screenshots in the order you want
   - Maximum 10 screenshots per device size
   - Minimum 3 screenshots

3. Screenshots can be in any order, but first one is most important (appears in search results)

4. You can optionally upload app preview videos (15-30 seconds)

---

## 🚀 Quick Start Workflow

### Step 1: Create Square App Icon (Manual)
1. Open `public/images/logo/logo_main.png` in design tool
2. Create 1536x1536 canvas with branded background
3. Center logo on background
4. Export as `flutter/assets/images/app_icon_1024.png`

### Step 2: Generate All Icon Sizes (Automated)
```bash
cd flutter
./scripts/generate-app-icons.sh assets/images/app_icon_1024.png
```

### Step 3: Create Screenshot Folders
```bash
cd flutter
mkdir -p screenshots/{6.9-inch,6.7-inch,6.5-inch}
```

### Step 4: Take Screenshots from Simulator
```bash
# Open iPhone 16 Pro Max simulator
open -a Simulator

# Run app
flutter run -d <simulator-name> --dart-define=BACKEND_URL=https://drawback.chat/api

# Navigate through app and press Cmd+S to save each screen
# Screenshots save to ~/Desktop by default
```

### Step 5: Organize Screenshots
Move from Desktop to appropriate folders:
```bash
mv ~/Desktop/Simulator\ Screen\ Shot*.png flutter/screenshots/6.9-inch/
# Rename to descriptive names
```

### Step 6: Upload to App Store Connect
1. App Icon → App Store Connect → App Information
2. Screenshots → App Store → Media Manager
3. Verify all images display correctly

---

## 🎨 Design Tips

### App Icon
- **Simple is better** - Should be recognizable at 20x20 pixels
- **No text** - Rarely works well in app icons
- **Bold shapes** - Clear, strong visual
- **Consistent with brand** - Use your brand colors
- **Test at small sizes** - View at 60x60 to see if it works

### Screenshots
- **Tell a story** - First screenshot to last should show user journey
- **Highlight unique features** - What makes DrawkcaB different?
- **Use text overlays** - Explain features in 3-5 words
- **Professional look** - Clean layouts, good typography
- **Localization** - Consider creating versions for other languages later

---

## 🛠️ Tools & Resources

### Icon Generation
- [App Icon Generator](https://www.appicon.co/) - Free, easy to use
- [MakeAppIcon](https://makeappicon.com/) - Generates all sizes
- Our script: `scripts/generate-app-icons.sh` (requires ImageMagick)

### Screenshot Tools
- **iOS Simulator** - Built into Xcode, free
- [Screenshot Creator](https://www.appstorescreenshot.com/) - Add frames
- [Figma](https://www.figma.com/) - Design overlays
- [Sketch](https://www.sketch.com/) - Design tool with iOS templates

### Image Editing
- **Preview** (macOS) - Basic resizing and cropping
- **GIMP** - Free Photoshop alternative
- **Photoshop** - Professional editing
- **Figma** - Browser-based design tool

### Verification Tools
- **Xcode** - Preview icons in Xcode's asset catalog
- `identify` command (ImageMagick) - Verify image dimensions
- Preview app - Quick look at dimensions in Get Info

---

## 🤖 Part 4: Android-Specific Assets

### Android Adaptive Icons

Android uses **adaptive icons** with separate foreground and background layers that the system combines. This allows for different shape masks (circle, squircle, rounded square) across different Android devices.

#### Icon Requirements

**Adaptive Icon Layers:**
- **Foreground layer:** 432 x 432 px PNG with transparency
- **Background layer:** 432 x 432 px PNG (solid color or pattern, no transparency)
- **Safe zone:** Keep important content within 66dp (264px) center circle
- **Full bleed:** Outer 36dp can be masked off on some devices

**Icon Sizes (Generated from adaptive icon):**
| Density | Size | Notes |
|---------|------|-------|
| mdpi | 48 x 48 px | Baseline density |
| hdpi | 72 x 72 px | ~1.5x |
| xhdpi | 96 x 96 px | ~2x |
| xxhdpi | 144 x 144 px | ~3x |
| xxxhdpi | 192 x 192 px | ~4x |

**Play Store Icon:**
- 512 x 512 px PNG with transparency
- 32-bit color with alpha channel
- Displayed in Play Store listing

#### Creating Adaptive Icons

**Option 1: Use Automated Script (Recommended)**

```bash
cd flutter
./scripts/generate-android-icons.sh assets/images/app_icon_1024.png
```

This generates all required Android icon sizes and formats.

**Option 2: Manual Creation**

1. **Create foreground layer:**
   - Open your logo in design tool
   - Create 432x432 canvas
   - Place logo centered within 264px safe zone circle
   - Export as PNG with transparency
   - Save as `android_icon_foreground.png`

2. **Create background layer:**
   - Create 432x432 canvas
   - Fill with brand color (e.g., rose-600: #E11D48)
   - Or use subtle pattern/gradient
   - Export as PNG
   - Save as `android_icon_background.png`

3. **Generate density variants:**
   - Use Android Studio's Asset Studio (File → New → Image Asset)
   - Or use online tool: [Android Asset Studio](https://romannurik.github.io/AndroidAssetStudio/)
   - Or use our script (recommended)

#### Installing Android Icons

Replace files in `flutter/android/app/src/main/res/`:

```
mipmap-mdpi/ic_launcher.png          (48x48)
mipmap-hdpi/ic_launcher.png          (72x72)
mipmap-xhdpi/ic_launcher.png         (96x96)
mipmap-xxhdpi/ic_launcher.png        (144x144)
mipmap-xxxhdpi/ic_launcher.png       (192x192)
```

### Play Store Feature Graphic

**REQUIRED** for Google Play Store listing. Displayed prominently at top of store page.

#### Requirements

- **Size:** 1024 x 500 px
- **Format:** PNG or JPEG
- **No transparency:** Must be fully opaque
- **File size:** Under 1MB
- **Aspect ratio:** Exactly 2.048:1

#### Design Guidelines

✅ **Do:**
- Include app name/logo
- Use brand colors (rose palette)
- Keep design clean and simple
- Make it eye-catching
- Test how it looks at different sizes
- Use high-quality graphics

❌ **Don't:**
- Include device frames
- Use too much text
- Make it look cluttered
- Use low-resolution images
- Include promotional text like "Download now"
- Use generic stock photos

#### Creating Feature Graphic

**Option 1: Design Tool (Figma/Photoshop)**

1. Create 1024 x 500 px canvas
2. Add branded background gradient or solid color
3. Place logo/app icon prominently
4. Add text: "DrawkcaB" or tagline
5. Keep it minimal and professional
6. Export as PNG or JPEG

**Template idea:**
```
- Background: Rose gradient (rose-400 to rose-600)
- Left side: App icon (200x200)
- Center: "DrawkcaB" text + "Draw Together" tagline
- Right side: Simple illustration or collaborative drawing preview
```

**Option 2: Simple Branded Version**

Minimum viable feature graphic:
1. Solid rose-600 background (#E11D48)
2. App icon centered
3. "DrawkcaB" text below in white
4. "Real-time collaborative drawing" subtitle

Save as: `flutter/assets/playstore/feature_graphic.png`

### Android Screenshots

Google Play requires screenshots for phones. Tablet screenshots are optional.

#### Phone Screenshots (Required)

**Resolution:** 1080 x 1920 px (recommended)  
**Aspect ratio:** 16:9 or 9:16  
**Format:** PNG or JPEG  
**Count:** Minimum 2, maximum 8  
**File size:** Max 8MB each

**Alternative resolutions:**
- 1080 x 1920 (Full HD, recommended)
- 720 x 1280 (HD)
- 1440 x 2560 (Quad HD)

#### 7-inch Tablet Screenshots (Optional)

**Resolution:** 1024 x 1600 px  
**Aspect ratio:** 16:10  
**Count:** Minimum 2, maximum 8

#### 10-inch Tablet Screenshots (Optional)

**Resolution:** 1920 x 1200 px (landscape) or 1200 x 1920 px (portrait)  
**Aspect ratio:** 16:10  
**Count:** Minimum 2, maximum 8

#### Taking Android Screenshots

**Method 1: Android Emulator**

```bash
# List available emulators
flutter emulators

# Launch Pixel-series emulator (or create one in Android Studio)
flutter emulators --launch <emulator-id>

# Run app
flutter run -d <emulator-id> --dart-define=BACKEND_URL=https://drawback.chat/api

# Take screenshot
# In emulator window: Click camera icon in toolbar
# Or: Cmd + S (macOS) / Ctrl + S (Windows/Linux)
```

Screenshots save to: `~/Desktop` or configurable location

**Method 2: Physical Android Device**

1. Enable USB debugging on device
2. Connect to computer
3. Run app: `flutter run -d <device-id> --dart-define=BACKEND_URL=https://drawback.chat/api`
4. Take screenshots: Power + Volume Down buttons
5. Transfer to computer via USB or cloud storage

**Recommended Screenshot Sizes:**

For Play Store, create 1080x1920 screenshots showing same content as iOS:
1. Login/Welcome screen
2. Registration flow
3. User search interface
4. Chat request screen
5. Drawing canvas (or preview)

### Organizing Android Assets

Recommended folder structure:

```
flutter/assets/playstore/
├── feature_graphic.png           # 1024 x 500
├── icon_foreground.png           # 432 x 432 (with transparency)
├── icon_background.png           # 432 x 432 (solid color)
└── icon_512.png                  # 512 x 512 (Play Store)

flutter/screenshots/android/
├── phone/                        # 1080 x 1920
│   ├── 01-welcome.png
│   ├── 02-register.png
│   ├── 03-search.png
│   ├── 04-chat-request.png
│   └── 05-features.png
├── 7-inch-tablet/                # 1024 x 1600 (optional)
│   └── ...
└── 10-inch-tablet/               # 1920 x 1200 (optional)
    └── ...
```

### Android Asset Checklist

Before Play Store submission:

- [ ] Adaptive icon foreground layer created (432x432 with transparency)
- [ ] Adaptive icon background layer created (432x432 solid)
- [ ] All density icon variants generated (mdpi through xxxhdpi)
- [ ] 512x512 Play Store icon exported
- [ ] Feature graphic created (1024x500)
- [ ] Phone screenshots created (2-8 at 1080x1920)
- [ ] Screenshots show actual app content (no placeholders)
- [ ] Assets organized in proper folders
- [ ] Icons tested on Android device/emulator
- [ ] Feature graphic previewed in Play Console

---

## ✅ Final Checklist

Before submitting to app stores:

### iOS App Icons
- [ ] Square source icon created (1024x1024 minimum)
- [ ] All iOS icon sizes generated
- [ ] Icons installed in Xcode project
- [ ] Icons appear correctly in Xcode asset catalog
- [ ] 1024x1024 icon uploaded to App Store Connect
- [ ] Icon has no transparency
- [ ] Icon looks good at small sizes (test on device)

### Android App Icons
- [ ] Adaptive icon foreground layer created (432x432 with transparency)
- [ ] Adaptive icon background layer created (432x432 solid)
- [ ] All density icon variants generated (mdpi through xxxhdpi)
- [ ] 512x512 Play Store icon exported
- [ ] Icons tested on Android device/emulator
- [ ] Icon safe zone respected (264px center circle)

### iOS Screenshots
- [ ] 6.9" iPhone: 3-10 screenshots at 1320 x 2868
- [ ] 6.7" iPhone: 3-10 screenshots at 1290 x 2796
- [ ] 6.5" iPhone: 3-10 screenshots at 1242 x 2688
- [ ] iPad (if supporting): 3-10 screenshots at 2048 x 2732
- [ ] Screenshots organized in folders
- [ ] No personal information visible
- [ ] Status bar looks clean
- [ ] Features clearly demonstrated
- [ ] First screenshot is most compelling
- [ ] Screenshots uploaded to App Store Connect

### Android Screenshots & Assets
- [ ] Feature graphic created (1024x500)
- [ ] Phone screenshots: 2-8 at 1080x1920
- [ ] Screenshots show actual app content (no placeholders)
- [ ] No personal information visible
- [ ] Features clearly demonstrated
- [ ] First screenshot is most compelling
- [ ] Assets uploaded to Play Console

### Quality Check (Both Platforms)
- [ ] Icons look sharp (not blurry) on device
- [ ] Screenshots match actual app UI
- [ ] All images meet Apple's requirements
- [ ] No placeholder content visible
- [ ] Brand consistency across all assets

---

## 📱 Quick Reference: Screenshot Sizes

```bash
# iPhone 16 Pro Max (6.9")
1320 x 2868 pixels

# iPhone 14/15 Pro Max (6.7") 
1290 x 2796 pixels

# iPhone 11 Pro Max / XS Max (6.5")
1242 x 2688 pixels

# iPad Pro 12.9" (6th gen)
2048 x 2732 pixels (portrait)
2732 x 2048 pixels (landscape)
```

---

**Need Help?**
- iOS script: [scripts/generate-app-icons.sh](../scripts/generate-app-icons.sh)
- Android script: [scripts/generate-android-icons.sh](../scripts/generate-android-icons.sh)
- Apple's guidelines: [App Store Screenshots](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- Google's guidelines: [Adaptive Icons](https://developer.android.com/develop/ui/views/launch/icon_design_adaptive)
- iOS deployment guide: [IOS_DEPLOYMENT.md](IOS_DEPLOYMENT.md)
- Android deployment guide: [ANDROID_DEPLOYMENT.md](ANDROID_DEPLOYMENT.md)

---

**Last Updated:** March 7, 2026
