# ============================================================
# Flutter Core
# ============================================================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# ============================================================
# Google Play Services / Guava / Play Core
# ============================================================
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keep class com.google.common.** { *; }
-dontwarn com.google.common.**
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# ============================================================
# just_audio / audio_service
# ============================================================
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.** { *; }
-dontwarn com.ryanheise.**

# ExoPlayer (used by just_audio)
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**

# ============================================================
# on_audio_query
# ============================================================
-keep class com.lucasjosino.on_audio_query.** { *; }
-dontwarn com.lucasjosino.on_audio_query.**

# ============================================================
# permission_handler
# ============================================================
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# ============================================================
# sqflite
# ============================================================
-keep class com.tekartik.sqflite.** { *; }
-dontwarn com.tekartik.sqflite.**

# ============================================================
# path_provider
# ============================================================
-keep class io.flutter.plugins.pathprovider.** { *; }
-dontwarn io.flutter.plugins.pathprovider.**

# ============================================================
# shared_preferences
# ============================================================
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-dontwarn io.flutter.plugins.sharedpreferences.**

# ============================================================
# file_picker
# ============================================================
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-dontwarn com.mr.flutter.plugin.filepicker.**

# ============================================================
# audiotags (JNI / native bridge)
# ============================================================
-keep class com.kyant.taglib.** { *; }
-dontwarn com.kyant.taglib.**
# Keep all JNI-registered native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# ============================================================
# palette_generator
# ============================================================
-keep class androidx.palette.** { *; }
-dontwarn androidx.palette.**

# ============================================================
# flutter_svg / xml parsing
# ============================================================
-keep class org.xmlpull.** { *; }
-dontwarn org.xmlpull.**

# ============================================================
# Kotlin coroutines
# ============================================================
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# ============================================================
# AndroidX / Jetpack
# ============================================================
-keep class androidx.lifecycle.** { *; }
-dontwarn androidx.lifecycle.**
-keep class androidx.core.** { *; }
-dontwarn androidx.core.**

# ============================================================
# General safety rules
# ============================================================
# Keep all Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep enum values (used by Riverpod / Dart enums compiled to Java)
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Suppress common warnings from third-party libraries
-dontwarn javax.annotation.**
-dontwarn sun.misc.**
-dontwarn java.lang.invoke.**
