# Crystal Messenger (MVP)

## Overview
Crystal Messenger is a cross-platform Flutter app using Supabase for Auth, Realtime, and Storage. Uses flutter_riverpod architecture and follows a feature-first modular layout.

## Prereqs
- Flutter SDK >= stable channel
- Supabase project (create at https://supabase.com)
- AdMob account (optional for ads)

## Setup
1. Clone repo.
2. Copy `.env.example` to `.env` and fill SUPABASE_URL and SUPABASE_ANON_KEY and AdMob IDs.
3. Create Supabase buckets: `avatars` and `media`.
4. Run SQL in Supabase (supabase.sql).
5. Add Android/iOS platform keys (see README section).
6. Run:
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
7. Run app:
   flutter run -d <device>

## Build for release
- Android APK: `flutter build apk --release`
- iOS: open ios/Runner.xcworkspace in Xcode
- macOS: `flutter build macos`
- Windows: `flutter build windows`

## Notes
- Replace placeholder IDs before publishing.
- For reliable calling in production, set up a TURN server (coturn). Public STUN servers are free but may fail behind symmetric NATs.
- AdMob requires app registration and real Ad Unit IDs. For development you can use test IDs from AdMob docs.
- Supabase Realtime size: free tier supports some amount but monitor usage. The schema is designed to work with Postgres changes and Supabase Realtime.
- RLS (Row Level Security): implement policies to restrict access (e.g., profiles only viewable by the owner, self-only writes).
- Push Notifications: not included in this commit. Add FCM/APNs for background notifications.
