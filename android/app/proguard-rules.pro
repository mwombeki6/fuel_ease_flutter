# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter Play Store split-install stubs — Flutter engine references these
# classes but they are only present when using dynamic feature modules.
# Tell R8 to ignore them rather than fail the build.
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Keep JSON model classes from being stripped
-keepattributes *Annotation*
-keepattributes Signature
-dontwarn sun.misc.**
