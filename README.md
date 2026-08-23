# namaz_vaktim

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## CI

Proje, GitHub Actions ile sürekli entegrasyon kullanır (`.github/workflows/ci.yml`):

- **Tetikleyici:** `main` dalına yapılan her `push` ve `main` dalını hedefleyen her `pull_request`.
- **Ortam:** `ubuntu-latest` üzerinde Flutter **3.44.8** (stable) ve JDK **17**.
- **Akış:**
  1. Bu depo `namaz-vaktim` yoluna, kardeş paket [emredevlab/kapadokya-mobile-core](https://github.com/emredevlab/kapadokya-mobile-core) ise `kapadokya-mobile-core` yoluna checkout edilir. Uygulama, `../kapadokya-mobile-core` path dependency kullandığı için iki deponun yan yana bulunması gerekir.
  2. Önce core pakette, ardından uygulamada sırasıyla `flutter pub get`, `flutter analyze` ve `flutter test` çalıştırılır.
  3. APK derlemesi yapılmaz (imza gerektirir ve uzun sürer); kalite güvencesi analyze + test adımlarıyla sağlanır.

> **Not:** `emredevlab/kapadokya-mobile-core` deposunun GitHub hesabınızda mevcut olması gerekir. Depo henüz pushlanmamışsa workflow bunu tolere eder: ilgili checkout ve sonraki adımlar atlanır, uyarıyla yeşil tamamlanır. Depo **private** ise varsayılan `GITHUB_TOKEN` yetmez; bir Personal Access Token (PAT) tanımlamanız gerekir.

Workflow çalıştırmalarını deponun **Actions** sekmesinden izleyebilirsiniz: <https://github.com/emredevlab/namaz-vaktim/actions>
