# AdMob Revenue Tracking Guide - Crystal Messenger

## Overview
Crystal Messenger integrates Google AdMob for monetization. This guide explains how to set up AdMob, track revenue, and optimize earnings.

---

## Step 1: Create AdMob Account

1. **Visit AdMob**: Go to [https://admob.google.com/home/](https://admob.google.com/home/)
2. **Sign Up**: Sign in with your Google account
3. **Create Account**: Fill in your business information
4. **Verify Email**: Verify your email address
5. **Add Payment Details**: Add your payment information for receiving payments

---

## Step 2: Create AdMob App

1. **Add App**: Click "Apps" → "Add App"
2. **App Type**: Choose "Android" or "iOS"
3. **App Name**: Enter "Crystal Messenger"
4. **Package Name/Bundle ID**:
   - Android: `com.crystalmessenger.app`
   - iOS: Your iOS Bundle ID
5. **Platform**: Select platform
6. **Create App**: Click "Add App"

---

## Step 3: Create Ad Units

### Banner Ad Unit
1. **Navigate**: Go to your app in AdMob dashboard
2. **Ad Units**: Click "Ad Units" → "Create Ad Unit"
3. **Ad Format**: Select "Banner"
4. **Ad Unit Name**: Enter "Crystal Messenger Banner"
5. **Ad Type**: Select "Text & Image" or "Video"
6. **Refresh Rate**: Set to 30-60 seconds
7. **Create**: Click "Create Ad Unit"
8. **Copy ID**: Copy the Ad Unit ID (format: `ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY`)

### Interstitial Ad Unit
1. **Create Another**: Click "Create Ad Unit" again
2. **Ad Format**: Select "Interstitial"
3. **Ad Unit Name**: Enter "Crystal Messenger Interstitial"
4. **Ad Type**: Select "Text & Image" or "Video"
5. **Create**: Click "Create Ad Unit"
6. **Copy ID**: Copy the Ad Unit ID

---

## Step 4: Update App Configuration

### Replace Test IDs with Production IDs

Open `lib/core/services/admob_service.dart` and replace the test IDs:

```dart
String get bannerAdUnitId {
  if (Platform.isAndroid) {
    // Replace with your actual Banner Ad Unit ID
    return 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY'; // Your Android Banner ID
  } else if (Platform.isIOS) {
    // Replace with your actual Banner Ad Unit ID
    return 'ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ'; // Your iOS Banner ID
  }
  return '';
}

String get interstitialAdUnitId {
  if (Platform.isAndroid) {
    // Replace with your actual Interstitial Ad Unit ID
    return 'ca-app-pub-XXXXXXXXXXXXXXXX/AAAAAAAAAA'; // Your Android Interstitial ID
  } else if (Platform.isIOS) {
    // Replace with your actual Interstitial Ad Unit ID
    return 'ca-app-pub-XXXXXXXXXXXXXXXX/BBBBBBBBBB'; // Your iOS Interstitial ID
  }
  return '';
}
```

---

## Step 5: Configure AdMob in Android

### Update AndroidManifest.xml

Open `android/app/src/main/AndroidManifest.xml` and add:

```xml
<manifest>
    <application>
        <!-- Add AdMob App ID -->
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
    </application>
    
    <!-- Add required permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
</manifest>
```

Replace `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY` with your AdMob App ID.

---

## Step 6: Configure AdMob in iOS

### Update Info.plist

Open `ios/Runner/Info.plist` and add:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY</string>
<key>SKAdNetworkItems</key>
<array>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cstr6suwn9.skadnetwork</string>
    </dict>
</array>
```

Replace with your AdMob App ID.

---

## Step 7: Test AdMob Integration

### Test Mode
Before going to production, test with test ads:

1. **Keep Test IDs**: The current test IDs in the code are Google's official test IDs
2. **Test Devices**: Add your device as a test device in AdMob dashboard
3. **Verify Ads**: Run the app and verify ads appear correctly
4. **Check Console**: Check debug logs for AdMob messages

### Enable Test Ads
To test with real ads but in test mode:

1. Go to AdMob dashboard
2. Navigate to your app
3. Click "Test Devices"
4. Add your device's advertising ID
5. Enable test mode for your device

---

## Step 8: Go to Production

### Switch to Production IDs
1. Replace test IDs with your production Ad Unit IDs in `admob_service.dart`
2. Update AndroidManifest.xml with production App ID
3. Update Info.plist with production App ID
4. Build release version of the app

### Release Build
```bash
# Android
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## Step 9: Track Revenue

### AdMob Dashboard
1. **Login**: Go to [https://admob.google.com/home/](https://admob.google.com/home/)
2. **Select App**: Choose Crystal Messenger
3. **View Reports**: Click "Reports" in the sidebar
4. **Revenue Metrics**: View:
   - Estimated earnings
   - Impressions
   - CPM (Cost Per Mille)
   - CPC (Cost Per Click)
   - Fill rate
   - Active users

### Revenue Reports
- **Daily Revenue**: View daily earnings
- **Weekly Revenue**: Weekly performance summary
- **Monthly Revenue**: Monthly earnings report
- **By Ad Unit**: Breakdown by Banner vs Interstitial
- **By Platform**: Android vs iOS performance
- **By Country**: Geographic performance

### Key Metrics to Monitor
1. **eCPM (Effective Cost Per Mille)**: Revenue per 1,000 impressions
2. **Fill Rate**: Percentage of ad requests that return ads
3. **Impressions**: Number of ads shown
4. **Clicks**: Number of ad clicks
5. **CTR (Click-Through Rate)**: Clicks ÷ Impressions
6. **Revenue**: Total earnings

---

## Step 10: Optimize Revenue

### Ad Placement Strategy
- **Banner Ads**: Show in chat list (already implemented)
- **Interstitial Ads**: Show when opening chats (already implemented)
- **Frequency**: Don't show interstitials too frequently (current: once per chat open)

### Best Practices
1. **Don't Overload**: Show interstitials sparingly to avoid user frustration
2. **Natural Placement**: Place banner ads where they don't interfere with UX
3. **Test Different Placements**: A/B test different ad positions
4. **Monitor Fill Rate**: Ensure high fill rate for maximum revenue
5. **Track User Behavior**: Monitor if ads affect user retention

### Revenue Optimization Tips
1. **Increase User Base**: More users = more impressions = more revenue
2. **Improve Retention**: Longer sessions = more ad opportunities
3. **Target High-CPM Regions**: Focus on users from high-value countries
4. **Optimize Ad Types**: Test different ad formats (text, image, video)
5. **Seasonal Campaigns**: Leverage holiday seasons for higher CPM

---

## Step 11: Payment Setup

### Payment Information
1. **Navigate**: AdMob dashboard → "Payments"
2. **Add Payment Method**: Add bank account or PayPal
3. **Tax Information**: Complete tax questionnaire
4. **Payment Threshold**: Set minimum payment amount (default: $100)
5. **Payment Schedule**: Payments are made monthly

### Payment Schedule
- **Payment Date**: Around the 21st of each month
- **Payment Threshold**: Minimum $100 (configurable)
- **Payment Methods**: Bank transfer, PayPal
- **Currency**: USD (or your local currency)

---

## Step 12: Analytics Integration (Optional)

### Google Analytics
For deeper insights, integrate Google Analytics:

1. **Create Property**: Go to Google Analytics
2. **Add Firebase**: Link AdMob with Firebase
3. **Track Events**: Track custom events (e.g., ad impressions, clicks)
4. **User Segments**: Analyze revenue by user segments
5. **Cohort Analysis**: Track user behavior over time

### Custom Events to Track
```dart
// Track ad impressions
FirebaseAnalytics.instance.logEvent(
  name: 'ad_impression',
  parameters: {
    'ad_type': 'banner',
    'screen': 'chat_list',
  },
);

// Track ad clicks
FirebaseAnalytics.instance.logEvent(
  name: 'ad_click',
  parameters: {
    'ad_type': 'interstitial',
    'screen': 'chat_detail',
  },
);
```

---

## Step 13: Compliance

### AdMob Policies
1. **Content Policy**: Ensure app content complies with AdMob policies
2. **Traffic Quality**: Avoid incentivized traffic or bot traffic
3. **Ad Placement**: Don't place ads near inappropriate content
4. **User Experience**: Don't interfere with app functionality
5. **Privacy**: Comply with privacy regulations (GDPR, CCPA)

### Privacy Policy
1. **Create Privacy Policy**: Create a privacy policy for your app
2. **Disclose Ad Use**: Inform users about ad serving
3. **Data Collection**: Disclose data collection practices
4. **User Consent**: Implement consent dialog for GDPR regions

### GDPR Compliance
```dart
// Show consent dialog for EU users
if (userInEU) {
  showConsentDialog();
}
```

---

## Step 14: Troubleshooting

### Common Issues

#### No Ads Showing
- **Check Ad Unit IDs**: Verify correct Ad Unit IDs
- **Check Internet**: Ensure device has internet connection
- **Check Fill Rate**: Low fill rate may cause no ads
- **Check Test Mode**: Ensure not in test mode for production
- **Check Logs**: Review debug logs for errors

#### Low Revenue
- **Low Impressions**: Increase user base and engagement
- **Low CPM**: Target high-value regions
- **Low Fill Rate**: Contact AdMob support
- **Ad Blocking**: Some users may use ad blockers

#### Payment Issues
- **Payment Threshold**: Ensure earnings exceed threshold
- **Payment Info**: Verify payment information is correct
- **Tax Info**: Complete tax questionnaire
- **Contact Support**: Contact AdMob support for issues

---

## Revenue Calculator

### Estimated Revenue Calculation

**Formula:**
```
Revenue = (Impressions / 1000) × eCPM
```

**Example:**
- Impressions: 10,000
- eCPM: $2.00
- Revenue = (10,000 / 1,000) × $2.00 = $20.00

### Projected Monthly Revenue

Based on user base and engagement:

| Daily Active Users | Avg. Sessions/Day | Impressions/Session | eCPM | Monthly Revenue |
|-------------------|-------------------|---------------------|------|-----------------|
| 1,000             | 5                 | 3                   | $1.50| $675           |
| 10,000            | 5                 | 3                   | $2.00| $9,000          |
| 100,000           | 5                 | 3                   | $2.50| $112,500        |

---

## Current Implementation in Crystal Messenger

### Banner Ads
- **Location**: Chat list screen bottom
- **Implementation**: `AdMobService.instance.getBannerAdWidget()`
- **Size**: Standard banner (320x50)
- **Refresh**: Automatic refresh by AdMob SDK

### Interstitial Ads
- **Trigger**: When opening a chat detail screen
- **Implementation**: `AdMobService.instance.showInterstitialAd()`
- **Frequency**: Once per chat open
- **Location**: `chat_detail_screen.dart` line 62

### Ad Service Location
- **File**: `lib/core/services/admob_service.dart`
- **Initialization**: `main.dart` line 34
- **Error Handling**: Graceful degradation if ads fail

---

## Next Steps

1. **Create AdMob Account**: Sign up for AdMob
2. **Create App & Ad Units**: Set up your app and ad units
3. **Update Configuration**: Replace test IDs with production IDs
4. **Test Integration**: Test ads in development
5. **Release to Production**: Build and release with production IDs
6. **Monitor Performance**: Track revenue in AdMob dashboard
7. **Optimize**: Continuously optimize for better revenue

---

## Support Resources

- **AdMob Help Center**: [https://support.google.com/admob](https://support.google.com/admob)
- **AdMob Policy Center**: [https://support.google.com/admob/answer/1620435](https://support.google.com/admob/answer/1620435)
- **Flutter AdMob Plugin**: [https://pub.dev/packages/google_mobile_ads](https://pub.dev/packages/google_mobile_ads)
- **AdMob YouTube Channel**: [https://www.youtube.com/c/AdMob](https://www.youtube.com/c/AdMob)

---

**Last Updated**: May 2026
**App Version**: 1.1.0+2
**Built by**: Munir Waheed - Founder of Crystal Messenger
