# Attendance Demo App

This repository contains a minimal Flutter demo app for tracking student attendance locally (mock data). It is intended as an MVP. Use this to build the APK locally.

Default users (from attendance_app_data.json):
- admin / admin123
- teacher1 / password

How to run locally:
1. Install Flutter SDK and Android SDK. Follow https://flutter.dev/docs/get-started/install
2. Clone this repo:
   git clone https://github.com/olzhasnurpeisov1990-afk/attendance-demo-app.git
3. Generate platform folders (only if this repo was not created with flutter):
   flutter create .
4. Fetch dependencies:
   flutter pub get
5. Run on device or emulator:
   flutter run
6. Build release APK:
   flutter build apk --release

Notes:
- The app uses a local JSON asset (assets/attendance_app_data.json) as initial data and stores attendance records in SharedPreferences on the device.
- For a production app, integrate Firebase or another backend and secure authentication.
