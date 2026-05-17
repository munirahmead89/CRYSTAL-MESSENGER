# Crystal Messenger - Complete Setup Guide

## Overview
This guide will walk you through setting up Crystal Messenger for production deployment. Follow these steps to get your app running smoothly on all platforms.

---

## Prerequisites

### Required Software
- **Flutter SDK**: 3.3.0 or higher
- **Dart SDK**: 3.3.0 or higher (included with Flutter)
- **Android Studio**: For Android development
- **Xcode**: For iOS development (macOS only)
- **Git**: For version control
- **Node.js**: For Supabase CLI (optional but recommended)

### Required Accounts
- **Supabase Account**: Free tier available at [supabase.com](https://supabase.com)
- **Google AdMob Account**: For monetization (optional)
- **Google Play Console**: For Android distribution (optional)
- **Apple Developer Account**: For iOS distribution (optional, $99/year)

---

## Step 1: Clone and Install Dependencies

### Clone Repository
```bash
git clone <your-repository-url>
cd crystal messenger
```

### Install Flutter Dependencies
```bash
flutter pub get
```

### Verify Flutter Installation
```bash
flutter doctor
```
Ensure all checks pass (except optional tools).

---

## Step 2: Set Up Supabase Backend

### Option A: Using Supabase Dashboard (Recommended for Quick Start)

1. **Create Supabase Project**
   - Go to [https://supabase.com](https://supabase.com)
   - Click "Start your project"
   - Sign in with GitHub or email
   - Click "New Project"
   - Enter project name: `crystal-messenger`
   - Choose database password (save it securely)
   - Select region closest to your users
   - Click "Create new project"
   - Wait 2-3 minutes for project to be ready

2. **Get API Credentials**
   - Navigate to Project Settings → API
   - Copy **Project URL** (format: `https://xxxxxxxx.supabase.co`)
   - Copy **anon public key** (starts with `eyJ...`)
   - Copy **service_role key** (starts with `eyJ...`)

3. **Run Database Schema**
   - Navigate to SQL Editor in Supabase dashboard
   - Click "New Query"
   - Copy contents of `supabase/schema.sql`
   - Paste into SQL Editor
   - Click "Run"
   - Verify all tables are created successfully

4. **Enable Realtime**
   - Navigate to Database → Replication
   - Enable Realtime for: `messages`, `profiles`, `rooms`, `participants`, `typing_indicators`, `call_sessions`
   - Click "Save"

5. **Create Storage Bucket**
   - Navigate to Storage
   - Click "New Bucket"
   - Name: `media`
   - Public bucket: Yes
   - Click "Create Bucket"

6. **Configure Storage Policies**
   - Navigate to Storage → Policies
   - Add policy for `media` bucket:
     - Name: `Public Access`
     - Allowed operations: `SELECT`, `INSERT`
     - Target role: `anon`
     - Using check: `bucket_id = 'media'`

### Option B: Using Supabase CLI (Recommended for Development)

1. **Install Supabase CLI**
   ```bash
   npm install -g supabase
   ```

2. **Login to Supabase**
   ```bash
   supabase login
   ```

3. **Link Project**
   ```bash
   supabase link --project-ref your-project-id
   ```

4. **Push Schema**
   ```bash
   supabase db push
   ```

---

## Step 3: Configure Environment Variables

### Create .env File
```bash
cp .env.template .env
```

### Edit .env File
Open `.env` and replace placeholder values:

```env
# ── SUPABASE BACKEND (Required) ────────────────────────────────────────────────
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# ── TWILIO SMS (Optional - for SMS bridge feature) ────────────────────────────
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_PHONE_NUMBER=

# ── WEBRTC STUN/TURN SERVERS (For P2P calls) ───────────────────────────────────
STUN_SERVER=stun:stun.l.google.com:19302
TURN_SERVER_URL=
TURN_USERNAME=
TURN_CREDENTIAL=

# ── AGORA (Optional - fallback calling service) ────────────────────────────────
AGORA_APP_ID=

# ── APP ENVIRONMENT ───────────────────────────────────────────────────────────
APP_ENV=production
API_BASE_URL=https://your-project-id.supabase.co
```

**Important**: Never commit `.env` file to version control. It's already in `.gitignore`.

---

## Step 4: Configure Google Authentication (Optional but Recommended)

### Enable Google Auth in Supabase
1. Navigate to Authentication → Providers
2. Click on Google
3. Enable Google provider
4. Add your Google OAuth credentials:
   - Get from [Google Cloud Console](https://console.cloud.google.com)
   - Create OAuth 2.0 credentials
   - Authorized redirect URI: `https://your-project-id.supabase.co/auth/v1/callback`
5. Save configuration

### Configure Android Deep Links
1. Open `android/app/src/main/AndroidManifest.xml`
2. Add deep link intent filter:
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="io.supabase.crystalmessenger" />
</intent-filter>
```

### Configure iOS Deep Links
1. Open `ios/Runner/Info.plist`
2. Add URL scheme:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>io.supabase.crystalmessenger</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>io.supabase.crystalmessenger</string>
        </array>
    </dict>
</array>
```

---

## Step 5: Configure AdMob (For Monetization)

See [ADMOB_REVENUE_GUIDE.md](ADMOB_REVENUE_GUIDE.md) for detailed instructions.

### Quick Setup
1. Create AdMob account at [admob.google.com](https://admob.google.com)
2. Create app and ad units
3. Replace test IDs in `lib/core/services/admob_service.dart` with production IDs
4. Update AndroidManifest.xml with AdMob App ID
5. Update Info.plist with AdMob App ID

---

## Step 6: Platform-Specific Setup

### Android Setup

1. **Update Android Version**
   - Open `android/app/build.gradle.kts`
   - Verify `compileSdk = 35` and `targetSdk = 35`

2. **Configure Signing (For Release)**
   ```bash
   keytool -genkey -v -keystore crystal-messenger.keystore -alias crystal -keyalg RSA -keysize 2048 -validity 10000
   ```
   - Move keystore to `android/app/`
   - Create `android/key.properties`:
   ```properties
   storePassword=your-store-password
   keyPassword=your-key-password
   keyAlias=crystal
   storeFile=crystal-messenger.keystore
   ```
   - Add `key.properties` to `.gitignore`

3. **Update build.gradle.kts**
   - Add signing config reading from key.properties
   - See comments in `android/app/build.gradle.kts`

4. **Update Package Name**
   - Current: `com.crystalmessenger.app`
   - Change if needed in `android/app/build.gradle.kts`

### iOS Setup

1. **Open in Xcode**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Configure Bundle Identifier**
   - Select Runner target
   - General tab → Bundle Identifier
   - Set to your unique identifier (e.g., `com.yourcompany.crystalmessenger`)

3. **Configure Signing**
   - Select your development team
   - Enable automatic signing
   - For production, use distribution certificate

4. **Update Info.plist**
   - Add required permissions (Camera, Microphone, Contacts)
   - Add AdMob configuration
   - Add deep link configuration

### Web Setup

1. **Build for Web**
   ```bash
   flutter build web
   ```

2. **Deploy**
   - Upload `build/web` folder to your hosting provider
   - Or use Firebase Hosting, Vercel, Netlify, etc.

### Desktop Setup (Windows, macOS, Linux)

1. **Build for Desktop**
   ```bash
   # Windows
   flutter build windows

   # macOS
   flutter build macos

   # Linux
   flutter build linux
   ```

2. **Distribute**
   - Create installers using platform-specific tools
   - Or distribute as standalone executables

---

## Step 7: Run the App

### Development Mode

#### Android
```bash
flutter run
```

#### iOS
```bash
flutter run
```

#### Web
```bash
flutter run -d chrome
```

#### Windows
```bash
flutter run -d windows
```

#### macOS
```bash
flutter run -d macos
```

#### Linux
```bash
flutter run -d linux
```

### Production Build

#### Android
```bash
# APK
flutter build apk --release

# App Bundle (Recommended for Play Store)
flutter build appbundle --release
```

#### iOS
```bash
flutter build ios --release
```

#### Web
```bash
flutter build web --release
```

#### Desktop
```bash
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

---

## Step 8: Test the App

### Testing Checklist

- [ ] **Authentication**: Sign up with email/password
- [ ] **Google OAuth**: Sign in with Google (if configured)
- [ ] **Profile Setup**: Complete profile creation
- [ ] **Contact Sync**: Sync device contacts
- [ ] **Create Chat**: Start a conversation
- [ ] **Send Messages**: Send text messages
- [ ] **Send Images**: Send image attachments
- [ ] **Send Documents**: Send document files
- [ ] **Voice Notes**: Record and send voice notes
- [ ] **Voice Playback**: Play received voice notes
- [ ] **Typing Indicators**: Verify typing status shows
- [ ] **Online Status**: Verify online/offline status
- [ ] **Audio Call**: Test audio calling
- [ ] **Video Call**: Test video calling
- [ ] **Banner Ads**: Verify banner ads display
- [ ] **Interstitial Ads**: Verify interstitial ads show
- [ ] **Offline Cache**: Test offline functionality
- [ ] **Settings**: Navigate settings screen
- [ ] **Sign Out**: Test sign out functionality

### Debugging

#### View Logs
```bash
flutter logs
```

#### Check Network Requests
- Use Supabase dashboard to monitor API calls
- Check browser DevTools for web
- Use Android Studio Logcat for Android
- Use Xcode Console for iOS

---

## Step 9: Deploy to Production

### Android (Google Play Store)

1. **Create Google Play Console Account**
   - Go to [play.google.com/console](https://play.google.com/console)
   - Pay $25 one-time fee
   - Create app listing

2. **Generate Signed Bundle**
   ```bash
   flutter build appbundle --release
   ```

3. **Upload to Play Console**
   - Upload `build/app/outputs/bundle/release/app-release.aab`
   - Complete store listing
   - Add screenshots
   - Provide privacy policy URL
   - Submit for review

### iOS (App Store)

1. **Create App Store Connect Account**
   - Requires Apple Developer Program ($99/year)
   - Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)

2. **Configure App in App Store Connect**
   - Create new app
   - Configure app information
   - Add screenshots
   - Provide privacy policy URL

3. **Build and Upload**
   ```bash
   flutter build ios --release
   ```
   - Open in Xcode
   - Archive and upload to App Store Connect
   - Submit for review

### Web Deployment

#### Firebase Hosting
```bash
npm install -g firebase-tools
firebase login
firebase init
firebase deploy
```

#### Vercel
```bash
npm install -g vercel
vercel
```

#### Netlify
```bash
npm install -g netlify-cli
netlify deploy --prod
```

### Desktop Distribution

#### Windows
- Use Inno Setup or NSIS to create installer
- Or distribute as portable executable

#### macOS
- Create .dmg or .pkg installer
- Code sign for distribution

#### Linux
- Create .deb, .rpm, or AppImage
- Or distribute as tarball

---

## Step 10: Monitor and Maintain

### Supabase Monitoring
- **Dashboard**: Monitor database usage, API calls, storage
- **Logs**: View database logs and error logs
- **Performance**: Monitor query performance
- **Backups**: Automatic backups enabled by default

### AdMob Monitoring
- **Revenue**: Track daily/weekly/monthly earnings
- **Performance**: Monitor fill rate, CPM, impressions
- **Reports**: Generate performance reports

### App Analytics
- **Firebase Analytics**: Optional integration for user analytics
- **Crashlytics**: Optional integration for crash reporting
- **Performance Monitoring**: Optional integration for performance tracking

---

## Troubleshooting

### Common Issues

#### Supabase Connection Failed
- **Check .env**: Verify SUPABASE_URL and keys are correct
- **Check Network**: Ensure internet connection is stable
- **Check RLS**: Verify Row Level Security policies allow access
- **Check Realtime**: Ensure Realtime is enabled for required tables

#### AdMob Not Showing Ads
- **Check Ad Unit IDs**: Verify correct Ad Unit IDs
- **Check Test Mode**: Ensure not using test IDs in production
- **Check Fill Rate**: Low fill rate may cause no ads
- **Check Logs**: Review debug logs for AdMob errors

#### Build Errors
- **Flutter Doctor**: Run `flutter doctor` to check for issues
- **Clean Build**: Run `flutter clean` then `flutter pub get`
- **Update Dependencies**: Run `flutter pub upgrade`
- **Check SDK Versions**: Ensure compatible Flutter and Dart versions

#### Permission Errors
- **Android**: Check AndroidManifest.xml for required permissions
- **iOS**: Check Info.plist for required permissions
- **Runtime**: Ensure permissions are requested at runtime

#### WebRTC Call Issues
- **Check STUN/TURN**: Verify STUN server is accessible
- **Check Firewall**: Ensure firewall allows WebRTC traffic
- **Check Permissions**: Verify camera/microphone permissions granted
- **Check Network**: Ensure stable internet connection

---

## Security Best Practices

### Environment Variables
- Never commit `.env` file
- Use different keys for development and production
- Rotate keys periodically
- Use strong passwords for database

### API Keys
- Use Supabase anon key for client-side
- Never expose service_role key in client code
- Implement rate limiting if needed
- Monitor API usage for anomalies

### Data Security
- Enable Row Level Security (RLS)
- Use HTTPS for all communications
- Encrypt sensitive data at rest
- Implement proper authentication flows

### User Privacy
- Comply with GDPR, CCPA regulations
- Provide privacy policy
- Implement consent dialogs
- Allow data deletion requests

---

## Performance Optimization

### App Performance
- Use const widgets where possible
- Implement lazy loading for lists
- Optimize image sizes
- Use efficient state management
- Profile with Flutter DevTools

### Database Performance
- Add indexes to frequently queried columns
- Optimize complex queries
- Use connection pooling
- Monitor query performance
- Implement caching strategies

### Network Performance
- Implement request batching
- Use compression for large payloads
- Optimize image loading
- Implement retry logic
- Monitor API response times

---

## Scaling Considerations

### User Growth
- Supabase auto-scales database
- Monitor resource usage
- Upgrade plan if needed
- Implement caching for high-traffic features
- Consider CDN for static assets

### Cost Management
- Start with Supabase free tier
- Monitor usage metrics
- Upgrade to Pro tier when needed
- Optimize database queries
- Implement efficient caching

### Geographic Distribution
- Choose Supabase region closest to users
- Consider multi-region deployment
- Implement CDN for static assets
- Optimize for low-bandwidth connections

---

## Support and Resources

### Documentation
- [Flutter Documentation](https://flutter.dev/docs)
- [Supabase Documentation](https://supabase.com/docs)
- [AdMob Documentation](https://developers.google.com/admob)
- [Dart Documentation](https://dart.dev/guides)

### Community
- [Flutter Community](https://flutter.dev/community)
- [Supabase Discord](https://supabase.com/discord)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
- [GitHub Issues](https://github.com/supabase/supabase/issues)

### App-Specific Resources
- APP_CAPABILITIES.md - Complete feature list
- ADMOB_REVENUE_GUIDE.md - Monetization guide
- supabase/schema.sql - Database schema
- .env.template - Environment configuration

---

## Quick Reference

### Essential Commands
```bash
# Install dependencies
flutter pub get

# Run app
flutter run

# Build for production
flutter build apk --release
flutter build appbundle --release
flutter build ios --release
flutter build web --release

# Clean build
flutter clean

# Check Flutter installation
flutter doctor

# View logs
flutter logs

# Upgrade dependencies
flutter pub upgrade
```

### Important Files
- `.env` - Environment variables (create from .env.template)
- `lib/core/services/supabase_service.dart` - Supabase integration
- `lib/core/services/admob_service.dart` - AdMob integration
- `android/app/build.gradle.kts` - Android configuration
- `ios/Runner/Info.plist` - iOS configuration
- `supabase/schema.sql` - Database schema

### Key URLs
- Supabase Dashboard: https://supabase.com/dashboard
- AdMob Dashboard: https://admob.google.com/home
- Flutter Docs: https://flutter.dev/docs
- Supabase Docs: https://supabase.com/docs

---

## Next Steps

1. ✅ Complete Supabase setup
2. ✅ Configure environment variables
3. ✅ Test all features
4. ✅ Configure AdMob (optional)
5. ✅ Build for production
6. ✅ Deploy to app stores
7. ✅ Monitor performance
8. ✅ Gather user feedback
9. ✅ Iterate and improve

---

## Conclusion

Crystal Messenger is now ready for production deployment. The app includes:

- ✅ Complete authentication system
- ✅ Real-time messaging
- ✅ Voice and video calling
- ✅ Contact synchronization
- ✅ AdMob monetization
- ✅ Cross-platform support
- ✅ Offline caching
- ✅ Modern UI
- ✅ Comprehensive error handling
- ✅ Secure backend

Follow this guide to deploy your app and start building your user base. The app is designed to scale automatically with Supabase's infrastructure, so you can focus on growing your user community.

---

**Built by Munir Waheed - Founder of Crystal Messenger**
**Version**: 1.1.0+2
**Last Updated**: May 2026
