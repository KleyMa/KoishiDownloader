# Proguard rules for youtubedl-android and FFmpeg
-keep class com.yausername.youtubedl_android.** { *; }
-keep class com.yausername.ffmpeg.** { *; }
-keep class com.yausername.aria2c.** { *; }

# Jackson (used by youtubedl-android for JSON parsing)
-keep class com.fasterxml.jackson.** { *; }
-keepnames class com.fasterxml.jackson.** { *; }
-dontwarn com.fasterxml.jackson.**

# Keep Flutter wrapper (just in case)
-keep class com.example.music_downloader.** { *; }

# Chaquopy (Python for Android, used by youtubedl-android)
-keep class com.chaquo.python.** { *; }
-keep class com.chaquo.python.android.** { *; }

# Apache Commons (used by youtubedl-android for zip extraction)
-keep class org.apache.commons.compress.archivers.zip.** { *; }
