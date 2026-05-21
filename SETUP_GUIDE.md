# Crystal Messenger - Setup Guide

## Step 1: Clone Repository

```bash
git clone https://github.com/munirahmead89/CRYSTAL-MESSENGER.git
cd CRYSTAL-MESSENGER
```

## Step 2: Install Dependencies

```bash
# Install Flutter dependencies
flutter pub get

# Generate code (for Hive, Riverpod, etc.)
flutter pub run build_runner build --delete-conflicting-outputs
```

## Step 3: Configure Supabase

1. Create Supabase account at [https://supabase.com](https://supabase.com)
2. Create a new project
3. Get your credentials from Settings > API
4. Copy `.env.example` to `.env`
5. Fill in:
   ```
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_ANON_KEY=your-anon-key-here
   ```

### Create Database Buckets

1. In Supabase dashboard, go to Storage
2. Create bucket: `avatars`
3. Create bucket: `media`

### Import Database Schema

1. In Supabase dashboard, go to SQL Editor
2. Create new query
3. Copy contents of `supabase.sql` into query
4. Execute

### Configure Android Deep Links

1. Open `android/app/build.gradle.kts`
2. Update `applicationId` to your package name
3. Update `namespace` to match

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

## Step 4: Platform-Specific Setup

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

3. **Update Package Name**
   - Current: `com.example.crystal_messenger`
   - Change in `android/app/build.gradle.kts`

### iOS Setup

1. **Open in Xcode**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Configure Bundle Identifier**
   - Select Runner target
   - General tab → Bundle Identifier
   - Set to your unique identifier

3. **Configure Signing**
   - Select your development team
   - Enable automatic signing

### Web Setup

1. **Build for Web**
   ```bash
   flutter build web
   ```

2. **Deploy**
   - Upload `build/web` folder to your hosting provider

### Desktop Setup

1. **Build for Desktop**
   ```bash
   # Windows
   flutter build windows

   # macOS
   flutter build macos

   # Linux
   flutter build linux
   ```
