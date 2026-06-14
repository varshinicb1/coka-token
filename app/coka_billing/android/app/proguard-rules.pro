# Flutter ProGuard/R8 Rules
# Keep Flutter and Dart engine classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep Bluetooth serial classes
-keep class com.example.flutter_bluetooth_serial.** { *; }

# Keep share_plus
-keep class com.example.share_plus.** { *; }

# Keep fluttertoast
-keep class com.example.fluttertoast.** { *; }

# Keep permission_handler
-keep class com.example.permission_handler.** { *; }

# Keep file_picker
-keep class com.example.file_picker.** { *; }

# Keep Kotlin serialization
-keepattributes *Annotation*
-keep class kotlin.Metadata { *; }

# General Android rules
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# Keep model classes used for JSON/serialization
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep generic signatures for reflection
-keepattributes Signature
-keepattributes *Annotation*, InnerClasses
-keepattributes EnclosingMethod
-keepattributes Exceptions

# Keep all enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
