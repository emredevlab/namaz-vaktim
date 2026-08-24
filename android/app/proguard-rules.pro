# Namaz Vaktim - release R8 kurallari.
#
# NOT: Flutter varsayilan kurallari flutter-gradle-plugin tarafindan minify
# acikken otomatik olarak eklenir (-keep class io.flutter.** vb.). Buraya
# sadece plugin consumer kurallarinin kapsamadigi keep/dontwarn kurallari
# eklenir. Konservatif yaklasim: derleme/runtime kirilirsa kural ekle.
#
# Plugin consumer kurallari AAR'larla gelir:
#   google_mobile_ads, flutter_local_notifications, geolocator,
#   permission_handler, flutter_secure_storage

# KRİTİK: flutter_local_notifications planlanan bildirimleri Gson TypeToken
# ile saklar. R8 generic imzaları sildiğinde şu hata atılır:
#   "TypeToken must be created with a type argument ... generic signatures
#    are preserved" (loadScheduledNotifications/saveScheduledNotification)
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepattributes Signature

