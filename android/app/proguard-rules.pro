-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class androidx.lifecycle.DefaultLifecycleObserver { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.ads.** { *; }
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-dontwarn com.google.android.gms.**
-dontwarn com.google.ads.**
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepnames class kotlin.Metadata { *; }
-keep class kotlin.coroutines.jvm.internal.** { *; }
-keepclassmembers class kotlin.coroutines.jvm.internal.** {
    <fields>;
    <methods>;
}