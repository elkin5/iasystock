# ProGuard rules for iasy_stock_app
# Reglas para prevenir crashes de WebView y autenticación

## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

## WebView
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String, android.graphics.Bitmap);
    public boolean *(android.webkit.WebView, java.lang.String);
}
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, jav.lang.String);
}
-keep class android.webkit.** { *; }
-keepclassmembers class android.webkit.** { *; }

## flutter_appauth
-keep class net.openid.appauth.** { *; }
-dontwarn net.openid.appauth.**

## OkHttp (usado por flutter_appauth)
-dontwarn okhttp3.**
-dontwarn okio.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

## Gson (si se usa para serialización)
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.stream.** { *; }

## Kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

## Mantener clases de autenticación
-keep class com.co.kinsoft.app.iasy_stock_app.** { *; }

## Evitar warnings de bibliotecas de terceros
-dontwarn javax.annotation.**
-dontwarn javax.inject.**
-dontwarn sun.misc.**

