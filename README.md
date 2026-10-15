# soul

Flutter client for SOUL. Release builds require HTTPS for API and image requests.

## Configure the API

Pass the Laravel API base URL at build/run time. The URL may include the `/api`
path; if omitted, the app adds it.

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com
flutter test --dart-define=API_BASE_URL=https://api.example.com
```

For a phone connected to the same network as the development machine, use the
machine's LAN IP address, not `localhost` (which points back to the phone).
HTTP is permitted only in debug builds and only for localhost, emulator
loopback, or a private-network IP. Release builds require HTTPS. Android
cleartext traffic is enabled only by the debug manifest.

## Dark mode

Dark mode follows the device theme by default. Change it from **Profil & Pengaturan
> Akun & Keamanan > Mode gelap**; the selection is saved on the device.
The app theme follows Laravel's shared colors: blue `#2563EB`, dark blue
`#1D4ED8`, yellow `#FACC15`, dark ink `#0F172A`, and light background `#F8FAFC`.
In dark mode, the page background is `#171717`, cards and inputs use `#262626`,
and borders use `#404040`; text and muted text use neutral gray tones for
contrast.

## Flutter resources

For Flutter development documentation:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
