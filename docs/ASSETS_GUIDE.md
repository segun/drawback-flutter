# App Store Assets Guide

This guide covers creating all required visual assets for App Store submission.

## Current Status

- ❌ **App Icons**: Currently using Flutter default placeholders
- ❌ **App Store Icon**: Need 1024x1024 PNG for App Store Connect  
- ❌ **Screenshots**: Need to create for multiple device sizes
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

## ✅ Final Checklist

Before submitting to App Store:

### App Icons
- [ ] Square source icon created (1024x1024 minimum)
- [ ] All iOS icon sizes generated
- [ ] Icons installed in Xcode project
- [ ] Icons appear correctly in Xcode asset catalog
- [ ] 1024x1024 icon uploaded to App Store Connect
- [ ] Icon has no transparency
- [ ] Icon looks good at small sizes (test on device)

### Screenshots
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

### Quality Check
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
- See the automated script: [scripts/generate-app-icons.sh](../scripts/generate-app-icons.sh)
- Check Apple's guidelines: [App Store Screenshots](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- Review deployment guide: [IOS_APPSTORE_DEPLOYMENT.md](IOS_APPSTORE_DEPLOYMENT.md)

---

**Last Updated:** March 6, 2026
