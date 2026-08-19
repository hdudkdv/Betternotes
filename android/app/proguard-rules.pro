# MediaPipe / flutter_gemma (optional AutoValue + proto classes not on the compile classpath)
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**
-dontwarn com.google.auto.value.extension.memoized.Memoized
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# ML Kit: latin is shipped; other scripts are referenced but not depended on.
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
