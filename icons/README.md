# Icons Directory

**Updated**: 2026-07-20

This directory contains the canonical icon assets for the Modulo Squares project.

## Master Icons

- **`icon-modulo-squares.png`**: High-resolution master icon (1024x1024 or larger recommended)
- The current master is the clean-landing-centered 1024px RGB icon applied on 2026-07-07.

## Automated Icon Generation

To regenerate all app icons from the master PNG, run:

```bash
./scripts/apply-new-icon.sh icons/icon-modulo-squares.png
```

This script will automatically generate:
- **iOS App Icons**: All required sizes for AppIcon.appiconset (@1x, @2x, @3x variants)
- **Android Icons**: All mipmap densities (mdpi through xxxhdpi) + adaptive icons
- **Flutter Web/PWA**: Icon-192, Icon-512, maskable variants for progressive web app
- **React Web App**: favicon sizes, apple-touch-icon, android-chrome icons

## Manual Regeneration

If you need to regenerate specific icon sets:

### iOS Icons
Navigate to `packages/mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/` and replace PNG files.

### Android Icons
Navigate to `packages/mobile/android/app/src/main/res/mipmap-*/` directories.

### Web Icons
- **Flutter Web**: `packages/mobile/web/icons/`
- **React Web**: `packages/web/public/`

## Icon Design Guidelines

- **Size**: Source icon should be at least 1024x1024 pixels
- **Format**: PNG with transparency (for overlays), or solid background
- **Padding**: Include ~10% padding around main icon content for better visibility
- **Colors**: Match Modulo Squares brand colors (#4CAF50 green, #1a1a1a dark)
- **Style**: Geometric, modern, recognizable at small sizes

## Current Icon Design

The current icon shows a falling `15` tile above divisor buckets `3`, `5`, and `6`, with bucket `5` highlighted. The original production set is retained under `archive/2026-07-08-previous-icon`.

## Updating the Icon

1. Place new high-resolution PNG in this directory as `icon-modulo-squares.png`
2. Run `./scripts/apply-new-icon.sh icons/icon-modulo-squares.png`  
3. Review generated icons in all platforms
4. Commit the changes
5. Deploy to App Store and Google Play

## Resources

- iOS Icon Guidelines: https://developer.apple.com/design/human-interface-guidelines/app-icons
- Android Icon Guidelines: https://developer.android.com/guide/practices/ui_guidelines/icon_design_adaptive
- PWA Icon Guidelines: https://web.dev/add-manifest/
