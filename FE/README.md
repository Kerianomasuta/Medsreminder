# meds_reminder

A new Flutter project.

## Run on web

Run Flutter normally. By default, the app calls the deployed API gateway at
`https://medsreminder.duckdns.org`.

```powershell
flutter run -d chrome
```

To target another backend for development, override the URL at build time:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
