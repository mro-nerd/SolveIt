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
## These classes are referenced by google_mlkit_text_recognition but only
## needed when the corresponding language-specific packages are added.
## Keep them as "don't warn" so R8 does not abort the build.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

## --- TensorFlow Lite GPU Delegate ---
## ML Kit references TFLite GPU classes that may not be bundled.
## These are optional runtime dependencies for GPU acceleration.
-dontwarn org.tensorflow.lite.gpu.**
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.**
-keep class org.tensorflow.lite.** { *; }
