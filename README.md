# EduNest Mobile API MVP

Drop this `lib/` folder and `pubspec.yaml` into the existing `Edunest_Mobile` Flutter project.

Backend base URL is configured in:

```dart
lib/services/api_service.dart
```

Default:

```dart
https://edunest-backend-8e6z.onrender.com
```

Main implemented flow:

- Login/register
- Browse availability/course slots
- Create direct user booking
- Create PayOS/VietQR payment
- Display payment QR/link
- View lessons
- Tutor marks attendance and completes lesson
- Tutor wallet and payout request
- Basic REST chat
- Tutor creates availability

Run:

```bash
flutter pub get
flutter run
```
