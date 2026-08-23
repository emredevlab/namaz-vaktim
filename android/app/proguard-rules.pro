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
