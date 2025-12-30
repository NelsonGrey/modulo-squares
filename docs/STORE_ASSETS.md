# Store Assets Preparation Guide

## App Icons

### Android Icons
Create the following icon sizes and place them in `android/app/src/main/res/`:
- `mipmap-mdpi/ic_launcher.png` (48x48)
- `mipmap-hdpi/ic_launcher.png` (72x72)
- `mipmap-xhdpi/ic_launcher.png` (96x96)
- `mipmap-xxhdpi/ic_launcher.png` (144x144)
- `mipmap-xxxhdpi/ic_launcher.png` (192x192)

### iOS Icons
Icons are generated automatically from `ios/Runner/Assets.xcassets/AppIcon.appiconset/` when you provide a 1024x1024 PNG.

### Web/Icon
- `web/icons/Icon-192.png` (192x192)
- `web/icons/Icon-512.png` (512x512)
- `web/icons/Icon-maskable-192.png` (192x192)
- `web/icons/Icon-maskable-512.png` (512x512)

## Screenshots

### Required Screenshots

#### Android (Google Play)
- **Phone**: 8 screenshots (1080x1920 or higher)
- **Tablet**: 2-3 screenshots (recommended)
- **TV**: Not required for mobile game

#### iOS (App Store)
- **iPhone 6.5"**: 3-5 screenshots (1242x2688)
- **iPhone 5.5"**: 3-5 screenshots (1080x1920)
- **iPad Pro**: 1-3 screenshots (2048x2732)

### Screenshot Guidelines
1. **Show Gameplay**: Demonstrate core mechanics (modulo operations, level progression)
2. **High Quality**: Clean, well-lit screenshots
3. **No UI Overlays**: Remove debug info, FPS counters
4. **Variety**: Show different levels, special tiles, leaderboard
5. **Branding**: Include app name/icon subtly if needed

## Store Listing Metadata

### App Information
- **Name**: Modulo Squares (30 chars max)
- **Short Description**: 80 characters max
- **Full Description**: 4000 characters max
- **Category**: Puzzle/Casual Games

### Keywords (App Store)
modulo, puzzle, math, numbers, brain, logic, strategy, free, ads

### Privacy Policy URL
Required for apps with ads/user data collection.

### Support Information
- **Website**: Your website URL
- **Email**: Support email address
- **Marketing URL**: Optional

## Feature Graphic (Google Play)
- **Size**: 1024x500 pixels
- **Shows**: On Play Store listing
- **Content**: App name, key features, gameplay preview

## Promotional Graphics (Optional)
- **Icon**: 512x512 PNG (for store promotions)
- **Banner**: 1200x627 (for social media)

## Implementation Steps

1. **Design App Icon**: Create a 1024x1024 PNG with your app icon
2. **Generate Screenshots**: Take high-quality screenshots of gameplay
3. **Write Descriptions**: Craft compelling store descriptions
4. **Test Assets**: Verify all assets display correctly
5. **Prepare Metadata**: Fill out all store listing information
6. **Create Privacy Policy**: If not already done

## File Organization

```
assets/
├── store/
│   ├── icons/
│   │   ├── app_icon_1024x1024.png
│   │   └── feature_graphic_1024x500.png
│   ├── screenshots/
│   │   ├── android/
│   │   │   ├── phone_01.png
│   │   │   ├── phone_02.png
│   │   │   └── ...
│   │   └── ios/
│   │       ├── iphone_01.png
│   │       ├── iphone_02.png
│   │       └── ...
│   └── metadata/
│       ├── description.txt
│       ├── short_description.txt
│       └── keywords.txt
```

## Tools & Resources

- **Icon Generation**: Use online tools like appicon.co or makeappicon.com
- **Screenshot Tools**: Android Studio, Xcode, or physical devices
- **Design Software**: Figma, Sketch, or Adobe Creative Suite
- **Guidelines**: Follow [Google Play](https://support.google.com/googleplay/android-developer/answer/1078870) and [App Store](https://developer.apple.com/app-store/product-page/) guidelines