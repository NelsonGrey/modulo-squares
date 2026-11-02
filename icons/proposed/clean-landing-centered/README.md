# Modulo Squares Proposed Icon Set - Clean Landing Centered

This folder contains the source and generated set for the clean-landing-centered
concept. The set was promoted to production on 2026-07-07; this directory remains
the reproducible source/reference copy.

## Concept

Pale blue-grey game field with a subtle grid, an indigo falling tile marked
`15`, and three bottom buckets labeled `3`, `5`, and `6`. The center `5`
bucket is highlighted with pale green fill and an orange active outline.

## Source

- `master/generated-source.png` - generated source image
- `master/icon-modulo-squares-clean-landing-1024.png` - normalized 1024px RGB master
- `master/icon-modulo-squares-clean-landing-960.png` - normalized 960px master
- `preview/icon-preview-sheet.png` - quick review sheet for common sizes

## Output Sets

- `ios/AppIcon.appiconset/` mirrors:
  `packages/mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- `android/res/` mirrors:
  `packages/mobile/android/app/src/main/res/`
- `web/public/` mirrors:
  `packages/web/public/`
- `mobile-web/` mirrors:
  `packages/mobile/web/`

The iOS 1024px marketing icon is RGB/no-alpha and sized for App Store review.

## Replacement Targets

These were the production replacement targets used after approval:

- `ios/AppIcon.appiconset/*` -> `packages/mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- `android/res/*` -> `packages/mobile/android/app/src/main/res/`
- `web/public/*` -> `packages/web/public/`
- `mobile-web/*` -> `packages/mobile/web/`

## Prompt

Create one single square app icon for Modulo Squares. Use a pale blue-grey
rounded game field with a subtle square grid, one indigo falling rounded square
tile marked 15, centered directly above the middle bucket, with exactly three
numbered buckets across the bottom labeled 3, 5, 6. The middle bucket labeled 5
is the active correct target, filled pale green with an orange outline. Use a
small dotted drop path and simple down arrow. No words, no slogans, no watermark,
no formula text, no labels outside the icon.
