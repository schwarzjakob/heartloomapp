# Heartloom (iOS SwiftUI)

Heartloom is a native SwiftUI app for families to collaboratively build a photo journal for their children. It supports multiple users per family, multi-photo entries with descriptions, timelines per child, basic AI-generated description suggestions, and PDF export.

## Features

- Multi-user flow: sign in (lightweight), create/join family via invite code
- Manage children within a family
- Add journal entries with multiple photos, descriptions, and tags
- AI: on-device suggestion stub (Vision) or fallback heuristic
- Timeline view for each child with photos and metadata
- Export timeline as PDF and share

## Project Structure

- `Heartloom.xcodeproj` – Xcode project
- `Heartloom/` – App sources
  - `Models/` – Data entities
  - `Services/` – Backend, image store, AI, PDF export
  - `ViewModels/` – MVVM state and actions
  - `Views/` – SwiftUI screens and components
  - `Assets.xcassets/` – App assets and app icon
  - `Info.plist` – App permissions and configuration

## Requirements

- Xcode 15+
- iOS 16.0+

## Run

1. Open `Heartloom.xcodeproj` in Xcode.
2. Set your Team in the target Signing settings (required for running on device).
3. Build and run on iOS 16+ simulator or device.

## Notes / Next Steps

- Backend is implemented as a local JSON store with a well-defined `BackendService` protocol. Swap in a real backend (e.g., Firebase/Firestore or CloudKit) by providing another implementation.
- AI suggestions currently use the built-in `Vision` image classifier when available; otherwise a simple heuristic. Replace `AISuggestionService` with a remote model if desired.
- PDF export is basic and intended as a starting point for future book-quality layouts.
- Permissions: App requests Camera and Photo Library access.

