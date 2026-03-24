# ─────────────────────────────────────────────────────────────
# ClassMate — ProGuard / R8 Rules
# ─────────────────────────────────────────────────────────────
# Applied for release builds only (configured in build.gradle).
# Debug builds do NOT use ProGuard.
# ─────────────────────────────────────────────────────────────

# ── Flutter ──────────────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ── Firebase Core ─────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ── Firebase Firestore ────────────────────────────────────────
-keep class com.google.firebase.firestore.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# ── Firebase Auth ─────────────────────────────────────────────
-keep class com.google.firebase.auth.** { *; }

# ── Firebase Storage ──────────────────────────────────────────
-keep class com.google.firebase.storage.** { *; }

# ── Firebase Messaging (FCM) ──────────────────────────────────
-keep class com.google.firebase.messaging.** { *; }

# ── Firebase Remote Config ────────────────────────────────────
-keep class com.google.firebase.remoteconfig.** { *; }

# ── Dio (HTTP client for FCM HTTP v1 API calls) ───────────────
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# ── Gson (used by Firebase SDKs) ──────────────────────────────
-keepattributes Signature
-keepattributes EnclosingMethod
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }

# ── flutter_secure_storage ────────────────────────────────────
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# ── flutter_local_notifications ───────────────────────────────
-keep class com.dexterous.** { *; }

# ── flutter_jailbreak_detection ───────────────────────────────
-keep class com.alexmisiulia.** { *; }

# ── image_picker / file_picker ────────────────────────────────
-keep class io.flutter.plugins.imagepicker.** { *; }

# ── General Android / Kotlin ──────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# ── Suppress common warnings ──────────────────────────────────
-dontwarn javax.annotation.**
-dontwarn org.codehaus.mojo.animal_sniffer.**

# ── Prevent stripping enums ───────────────────────────────────
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ── Keep Parcelable implementations ───────────────────────────
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# ── Keep Serializable classes ─────────────────────────────────
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
