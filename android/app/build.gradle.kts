plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.crystal_messenger"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        // Enables java.time API via desugaring for minSdk < 26
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.crystal_messenger"
        // flutter_webrtc, google_mobile_ads, and flutter_contacts require minSdk 21
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        // AdMob App ID
        manifestPlaceholders["adMobAppId"] = "ca-app-pub-5375584696804538~8182284522"
    }

    buildTypes {
        release {
            // Production signing configuration
            // Create keystore with: keytool -genkey -v -keystore crystal-messenger.keystore -alias crystal -keyalg RSA -keysize 2048 -validity 10000
            // Place keystore in android/app/ directory and uncomment below:
            /*
            signingConfigs {
                create("release") {
                    storeFile = file("crystal-messenger.keystore")
                    storePassword = "your-keystore-password"
                    keyAlias = "crystal"
                    keyPassword = "your-key-password"
                }
            }
            signingConfig = signingConfigs.getByName("release")
            */
            // For now using debug signing (replace with production keystore for release)
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        debug {
            isDebuggable = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Java 8+ API desugaring (required for java.time in flutter_webrtc et al)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // MultiDex for large dependency sets
    implementation("androidx.multidex:multidex:2.0.1")
}
