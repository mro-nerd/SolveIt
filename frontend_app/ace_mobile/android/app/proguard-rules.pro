## --- Flutter ---
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

## --- Firebase ---
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

## --- Google ML Kit Face Detection ---
-keep class com.google.mlkit.vision.face.** { *; }
-dontwarn com.google.mlkit.vision.face.**

## --- Google ML Kit text recognition optional language packs ---
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# TensorFlow Lite keep rules
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.**

## --- Environment Variables (flutter_dotenv) ---
-keep class com.flutter_dotenv.** { *; }
-dontwarn com.flutter_dotenv.**

## --- Supabase / GoTrue / Postgrest ---
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**
-keep class com.supabase.** { *; }
-dontwarn com.supabase.**
