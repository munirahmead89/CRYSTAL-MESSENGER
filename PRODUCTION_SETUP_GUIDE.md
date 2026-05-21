# Crystal Messenger - Production Setup Guide

## Prerequisites

- Flutter SDK (latest stable)
- Android SDK (API 35)
- iOS 12.0+
- Xcode (for iOS)
- Android Studio (for Android)
- Git

## Step 1: Create Production Supabase Project

1. Go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Click "New Project"
3. Configure:
   - Project name: Your app name
   - Database password: Generate strong password
   - Region: Choose closest to your users
4. Wait for project to initialize (2-3 minutes)
5. Get credentials from Settings > API > Project URL and anon key

## Step 2: Configure Environment

1. Update `.env` file:
   ```
   SUPABASE_URL=your-production-url
   SUPABASE_ANON_KEY=your-production-key
   ```

## Step 3: Build for Production

### Android

```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

### iOS

```bash
# Build for iOS
flutter build ios --release
```

Then in Xcode:
1. Open `ios/Runner.xcworkspace`
2. Select Product > Archive
3. Follow App Store submission steps

### Web

```bash
flutter build web --release
```

### Windows

```bash
flutter build windows --release
```

### macOS

```bash
flutter build macos --release
```

### Linux

```bash
flutter build linux --release
```

## Step 4: Testing

1. Run in debug mode:
   ```bash
   flutter run
   ```

2. Test all features:
   - Authentication
   - Profile setup
   - Messaging
   - Voice/video calls
   - Settings

## Step 5: Deployment

### Android Play Store

1. Create Google Play Developer account
2. Go to Google Play Console
3. Create new app
4. Upload APK/App Bundle
5. Fill app details and screenshots
6. Submit for review

### iOS App Store

1. Create Apple Developer account
2. Go to App Store Connect
3. Create new app
4. Upload build from Xcode archive
5. Fill app details and screenshots
6. Submit for review

### Web

1. Deploy to Firebase Hosting, Vercel, Netlify, etc.
2. Upload contents of `build/web` folder

## Monitoring

- Set up error tracking (Sentry, Crashlytics)
- Monitor user analytics
- Track performance metrics
- Set up alerts for critical errors
