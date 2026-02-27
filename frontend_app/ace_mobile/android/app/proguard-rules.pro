## --- Google ML Kit text recognition optional language packs ---
## These classes are referenced by google_mlkit_text_recognition but only
## needed when the corresponding language-specific packages are added.
## Keep them as "don't warn" so R8 does not abort the build.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
