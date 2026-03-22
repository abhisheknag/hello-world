# ScreenStash

**Smart Screenshot Organizer for iOS**

Your photo library is drowning in screenshots. ScreenStash uses on-device OCR to automatically organize, search, and clean them up — with zero data leaving your device.

## Features

- **Auto-Categorization** — Receipts, conversations, articles, social media, codes, maps, app screens, memes, and errors are automatically sorted into smart folders
- **Full-Text Search** — Find any screenshot by searching the text inside it
- **Duplicate Detection** — Perceptual hashing finds near-identical screenshots for easy cleanup
- **Bulk Delete** — Clean up by category or date range
- **Quick Actions** — Copy extracted text, open URLs, create contacts from screenshots
- **Widgets** — Home and Lock Screen widgets for quick access
- **100% Private** — All OCR processing happens on-device using Apple's Vision framework

## Pricing

| Tier | Price |
|------|-------|
| Free | 25 screenshots, 3 categories |
| Pro Annual | $11.99/year (3-day free trial) |
| Pro Lifetime | $29.99 one-time |

## Tech Stack

- Swift / SwiftUI
- SwiftData for persistence
- Vision framework for on-device OCR
- PhotosUI / PHPhotoLibrary
- StoreKit 2 for subscriptions
- WidgetKit
- iOS 17+ minimum

## Project Structure

```
ScreenStash/
├── Models/          # SwiftData models (Screenshot, Category)
├── Services/        # Business logic (OCR, import, classify, dedup, subscriptions)
├── Views/           # SwiftUI views organized by feature
│   ├── Library/     # Screenshot grid and detail views
│   ├── Categories/  # Smart folder views
│   ├── Search/      # Full-text search
│   ├── Cleanup/     # Duplicate detection and bulk delete
│   ├── Settings/    # Settings and paywall
│   └── Onboarding/  # First-launch permission flow
├── Widgets/         # WidgetKit extension
└── ScreenStashApp.swift
```

## Getting Started

1. Open `ScreenStash.xcodeproj` in Xcode 15+
2. Set your development team in Signing & Capabilities
3. Build and run on a device or simulator (iOS 17+)
4. Grant photo library access when prompted
5. Screenshots will be automatically imported and processed

## Privacy

ScreenStash processes all screenshots entirely on-device using Apple's Vision framework. No screenshot data, extracted text, or metadata is ever uploaded to any server. We don't track users and collect zero data.
