# Namaz Vaktim

KapadokyaBulut mobil platformu için namaz vakitleri uygulaması (Android).

- Flutter 3.44.8 / Dart 3.12.2 (workspace yerel kurulumu: `.tools\flutter`)
- Ortak çekirdek: [emredevlab/kapadokya-mobile-core](https://github.com/emredevlab/kapadokya-mobile-core) — `../kapadokya-mobile-core` path dependency
- Sürüm çıkış adımları: [RELEASE.md](RELEASE.md)

## CI

Proje, GitHub Actions ile sürekli entegrasyon kullanır (`.github/workflows/ci.yml`):

- **Tetikleyici:** `main` dalına yapılan her `push` ve `main` dalını hedefleyen her `pull_request`.
- **Ortam:** `ubuntu-latest` üzerinde Flutter **3.44.8** (stable) ve JDK **17**.
- **Akış:**
  1. Bu depo `namaz-vaktim` yoluna, kardeş paket [emredevlab/kapadokya-mobile-core](https://github.com/emredevlab/kapadokya-mobile-core) ise `kapadokya-mobile-core` yoluna checkout edilir. Uygulama, `../kapadokya-mobile-core` path dependency kullandığı için iki deponun yan yana bulunması gerekir.
  2. Önce core pakette, ardından uygulamada sırasıyla `flutter pub get`, `flutter analyze` ve `flutter test` çalıştırılır.
  3. APK derlemesi yapılmaz (imza gerektirir ve uzun sürer); kalite güvencesi analyze + test adımlarıyla sağlanır.

> **Not:** `emredevlab/kapadokya-mobile-core` deposu **private** olduğundan varsayılan `GITHUB_TOKEN` yetmez. Repo ayarlarından `CORE_REPO_TOKEN` secret'ı olarak `contents:read` yetkili bir Personal Access Token (PAT) ekleyin; secret yoksa workflow uyarıyla core adımlarını atlar.

Workflow çalıştırmalarını deponun **Actions** sekmesinden izleyebilirsiniz: <https://github.com/emredevlab/namaz-vaktim/actions>
