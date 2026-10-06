# Flutter Core Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**

# Flutter Plugins
-keep class io.flutter.plugins.** { *; }

# SQLite (sqflite)
-keep class com.tekartik.sqflite.** { *; }

# Image Compression & File Pickers
-keep class com.fluttercandies.image_compress.** { *; }
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Quick Actions & Sharing
-keep class io.flutter.plugins.quickactions.** { *; }
-keep class dev.fluttercommunity.plus.share.** { *; }

# Printing & PDF
-keep class net.nfet.flutter.printing.** { *; }

# Desugaring & Java 8+ APIs
-dontwarn com.google.errorprone.annotations.**
-dontwarn java.lang.invoke.**
