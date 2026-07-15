# Sinhala Sign Language — Flutter App

Two-tab mobile app:

- **Sign → Sinhala:** streams phone camera frames to the WebSocket recognizer.
- **Sinhala → sign:** sends Sinhala text to the HTTP translator and plays the
  returned sign videos.

## Prerequisites

- Flutter SDK installed (`flutter doctor` all green for Android).
- The **server** running and reachable (see `../server/README.md`).
- A physical Android phone (camera streaming needs a real device, not an emulator).

## 1. Generate platform scaffolding

This folder ships only `pubspec.yaml` + `lib/`. Generate the `android/` (and
`ios/`) projects **in place** (this keeps our `pubspec.yaml` and `lib/`):

```powershell
cd C:\Users\MSI\Desktop\SignRecognision\app
flutter create --org com.example --project-name sign_app .
flutter pub get
```

## 2. Android configuration (required)

Edit **`android/app/src/main/AndroidManifest.xml`**:

- Add these lines just **above** the `<application` tag:
  ```xml
  <uses-permission android:name="android.permission.CAMERA"/>
  <uses-permission android:name="android.permission.INTERNET"/>
  ```
- Add this attribute **inside** the `<application ...>` tag. Without it, Android
  9+ blocks the plaintext `ws://` connection to your PC's LAN IP:
  ```xml
  android:usesCleartextTraffic="true"
  ```

Camera needs `minSdkVersion 21`. Flutter's default is already ≥21, so usually no
change is needed. If a build error mentions minSdk, set it in
`android/app/build.gradle` (`minSdk = 21`).

## 3. Run

```powershell
flutter devices          # confirm your phone is listed
flutter run              # or press Run in Android Studio / VS Code
```

## 4. Point the app at your server

1. Tap the ⚙️ (top-right) → enter your PC's Wi-Fi IPv4 + port, e.g.
   `192.168.1.42:8000` → **Test** → **Save**.
2. Back on the Sign tab the status chip should turn **green (Connected)**.
3. Use the Sign tab for camera recognition, or the Sinhala tab for text-to-video
   translation.

## Notes

- **Sinhala font:** the app uses `google_fonts` (Noto Sans Sinhala), fetched on
  first launch — so the first run needs internet. To work fully offline, bundle
  `NotoSansSinhala-Regular.ttf` under `assets/fonts/` and declare it in
  `pubspec.yaml`, then replace `GoogleFonts.notoSansSinhala(...)` with a
  `TextStyle(fontFamily: 'NotoSansSinhala')`.
- **Hands swapped?** The server mirrors the frame to match the training/demo
  pipeline. If recognition seems off for your camera, the flip can be toggled
  server-side (`{"action":"config","flip":false}` — see server README).
- **Performance:** frames are throttled to ~11 fps and JPEG-encoded on a
  background isolate. On a low-end phone, lower `ResolutionPreset.medium` to
  `.low` in `lib/services/frame_streamer.dart`.
- **Server default:** the app no longer defaults to `127.0.0.1`; set the PC
  Wi-Fi IP in Settings, or pass
  `--dart-define=SIGN_SERVER_HOST=192.168.1.42:8000` when running.
- **iOS:** primary target is Android. For iOS, add `NSCameraUsageDescription`
  to `Info.plist` and an ATS exception for the `ws://` host.
