# Keep ML Kit classes to prevent R8 from removing them
-keep class com.google.mlkit.vision.text.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options