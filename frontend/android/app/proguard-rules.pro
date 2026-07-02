# Keep all classes from Google ML Kit
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep text recognition classes
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }

# Keep all classes from google_ml_kit
-keep class com.google_mlkit_vision.** { *; }
-keep class com.google_mlkit_commons.** { *; }

# Keep Google Play Core classes
-keep class com.google.android.play.** { *; }
-dontwarn com.google.android.play.**

# Don't obfuscate any ML Kit classes
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep your app classes
-keep class com.example.frontend.** { *; }

# Keep serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep all classes from your dependencies
-keep class * extends androidx.** { *; }
-keep class * extends android.** { *; }

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}