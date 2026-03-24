# 🎓 ClassMate

A production-grade university class management Android app built with Flutter + Firebase.

> **Platform:** Android APK only  
> **Users:** ~60 students + 1 admin  
> **Backend:** Firebase (Auth, Firestore, Storage, FCM, Remote Config)

---

## ✨ Features

| Feature | Offline? |
|---|---|
| Login / Register / Forgot Password | Online |
| Persistent login | ✅ Offline |
| User profiles | ✅ Cached |
| Announcements with push notifications | Online (FCM) |
| Tasks & Assignments (personal + class-wide) | ✅ Full offline CRUD |
| Weekly Timetable with class reminders | ✅ Cached |
| Exam Tracker with countdown + reminders | ✅ Cached |
| Study Materials (download / Drive links) | List cached |
| Admin Panel (post, manage, upload) | Online |
| OTA Update prompts via Remote Config | Online |
| Dark / Light mode | ✅ Local pref |

---

## 🚀 Getting Started

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) (stable channel, 3.x+)
- [Android Studio](https://developer.android.com/studio) or VS Code with Flutter extension
- [Firebase CLI](https://firebase.google.com/docs/cli): `npm install -g firebase-tools`
- A Firebase project with Android app registered

### 1. Clone the Repo

```bash
git clone https://github.com/your-username/classmate.git
cd classmate
```

### 2. Set Up Environment Variables (`.env`)

```bash
cp .env.example .env
```

Open `.env` and fill in your real Firebase values:

```
FIREBASE_API_KEY=AIzaSy...
FIREBASE_AUTH_DOMAIN=classmate-xyz.firebaseapp.com
FIREBASE_PROJECT_ID=classmate-xyz
FIREBASE_STORAGE_BUCKET=classmate-xyz.appspot.com
FIREBASE_MESSAGING_SENDER_ID=123456789012
FIREBASE_APP_ID=1:123456789012:android:abc123def456
```

**Where to find these values:**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project → ⚙️ Project Settings → Your apps → Android app
3. Copy values from the SDK configuration section

> ⚠️ **`.env` must never be committed.** It is listed in `.gitignore`.
> The app will crash on launch if `.env` is missing — this is intentional.

### 3. Install Flutter Dependencies

```bash
flutter pub get
```

### 4. Deploy Firebase Rules & Indexes

```bash
firebase login
firebase use --add   # select your Firebase project

# Deploy Firestore rules + indexes
firebase deploy --only firestore

# Deploy Storage rules
firebase deploy --only storage
```

### 5. Set Up Firebase Remote Config

In the Firebase Console → Remote Config, add these keys with defaults:

| Key | Type | Default Value |
|---|---|---|
| `app_version` | String | `1.0.0` |
| `update_message` | String | *(empty)* |
| `force_update` | Boolean | `false` |
| `maintenance_mode` | Boolean | `false` |
| `apk_download_url` | String | *(empty)* |
| `allowed_email_domains` | String | `@marwadiuniversity.ac.in,@gmail.com` |

### 6. Enable FCM (Push Notifications)

1. Firebase Console → Project Settings → Cloud Messaging
2. Enable Firebase Cloud Messaging API (V1)
3. No server key is needed — the app uses FCM HTTP v1 API with user ID tokens

### 7. Set the Admin User

After registering your account in the app:
1. Firebase Console → Firestore → `users` collection
2. Find your document (your UID)
3. Change `role` field from `"student"` to `"admin"`

### 8. Run the App

```bash
flutter run
```

---

## 📦 Building the Release APK

```bash
flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/debug-info \
  --target-platform android-arm64
```

**Output:** `build/app/outputs/flutter-apk/app-release.apk`

> Keep `build/debug-info/` safe — you need it to decode crash stack traces.
> **Do not commit it** (it's in `.gitignore`).

### Signing the APK

Create `android/key.properties` (gitignored):

```
storePassword=<password>
keyPassword=<password>
keyAlias=classmate
storeFile=<absolute_path>/classmate-release.jks
```

Then build as above — Gradle picks up `key.properties` automatically.

---

## 🔐 Security

See [SECURITY.md](./SECURITY.md) for:
- Files that must never be committed
- How to regenerate local config
- Known security limitations
- How to report vulnerabilities

---

## 🏗️ Architecture

```
lib/
├── main.dart                  ← dotenv load → Firebase init → app start
├── firebase_options.dart      ← gitignored, reads from .env
├── core/
│   ├── constants/             ← colors, strings, sizes
│   ├── theme/                 ← light + dark ThemeData
│   ├── utils/                 ← validators, formatters, sanitizer
│   ├── services/              ← auth, firestore, storage, notifications, remote config
│   └── security/              ← root detection, emulator detection, dio interceptor
├── features/                  ← auth, home, tasks, timetable, materials, exams,
│                                 announcements, profile, admin
├── shared/
│   ├── widgets/               ← reusable UI components
│   └── models/                ← Firestore data models
└── router/
    └── app_router.dart        ← go_router with auth guards
```

**State management:** `flutter_riverpod`  
**Navigation:** `go_router`  
**Design:** Material Design 3, Deep Indigo + Cyan palette, Plus Jakarta Sans + Inter

---

## 📁 Project Structure

See [the full folder tree](./SECURITY.md) for complete details.

---

## 📝 License

Private — for internal university use only.
