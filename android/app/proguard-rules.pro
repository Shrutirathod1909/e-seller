# -------------------------------
# ML Kit Core
# -------------------------------
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.common.** { *; }

# -------------------------------
# Language-specific recognizers (VERY IMPORTANT)
# -------------------------------
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }

# -------------------------------
# Flutter ML Kit Plugin
# -------------------------------
-keep class com.google_mlkit.** { *; }

# -------------------------------
# Suppress warnings (optional but recommended)
# -------------------------------
-dontwarn com.google.mlkit.vision.text.**