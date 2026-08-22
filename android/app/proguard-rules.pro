# Flutter Wrapper ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Play Services
-dontwarn com.google.android.gms.**
-keep class com.google.android.gms.** { *; }

# Mappls SDK
-dontwarn com.mappls.**
-keep class com.mappls.** { *; }
-keep interface com.mappls.** { *; }
