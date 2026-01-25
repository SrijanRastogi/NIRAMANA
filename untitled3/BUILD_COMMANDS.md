# Flutter Build Commands - Quick Reference

## 🔧 After TFLite Fix

### Complete Clean & Rebuild Sequence

```bash
# Step 1: Clean Flutter cache
flutter clean

# Step 2: Remove build artifacts
Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue

# Step 3: Remove Gradle cache (Windows PowerShell)
Remove-Item -Recurse -Force android\.gradle -ErrorAction SilentlyContinue

# Step 4: Get dependencies
flutter pub get

# Step 5: Build for Android Debug
flutter build apk --debug
```

---

## 🚀 Quick Build (After First Build)

```bash
# For development/testing
flutter run

# For APK generation
flutter build apk --debug
```

---

## 🧹 Clean Commands

### Flutter Clean
```bash
flutter clean
```

### Deep Clean (Windows PowerShell)
```powershell
# Remove all build artifacts
Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .dart_tool -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force android\.gradle -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force android\build -ErrorAction SilentlyContinue
```

### Gradle Clean (if needed)
```bash
cd android
./gradlew clean
./gradlew --stop
cd ..
```

---

## 📦 Dependency Commands

### Get Dependencies
```bash
flutter pub get
```

### Upgrade Dependencies
```bash
flutter pub upgrade
```

### Check Outdated
```bash
flutter pub outdated
```

---

## 🔍 Analysis Commands

### Analyze All
```bash
flutter analyze
```

### Analyze Specific File
```bash
flutter analyze lib/services/face_recognition_service.dart
```

### Analyze Without Info Messages
```bash
flutter analyze --no-fatal-infos
```

---

## 🏗️ Build Commands

### Debug APK
```bash
flutter build apk --debug
```

### Release APK
```bash
flutter build apk --release
```

### App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

### Run on Device
```bash
flutter run
```

### Run with Specific Device
```bash
flutter devices
flutter run -d <device-id>
```

---

## 🐛 Troubleshooting Commands

### Check Flutter Doctor
```bash
flutter doctor
flutter doctor -v
```

### Check Flutter Version
```bash
flutter --version
```

### List Devices
```bash
flutter devices
```

### Kill Gradle Daemon
```bash
cd android
./gradlew --stop
cd ..
```

### Clear Pub Cache (Nuclear Option)
```bash
flutter pub cache repair
```

---

## 📱 Android Specific

### Check Android SDK
```bash
flutter doctor --android-licenses
```

### Gradle Info
```bash
cd android
./gradlew --version
cd ..
```

---

## 🎯 Recommended Build Sequence

### First Time After Fix
```bash
flutter clean
flutter pub get
flutter build apk --debug
```

### Subsequent Builds
```bash
flutter run
```

### If Build Fails
```bash
# Clean everything
flutter clean
Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force android\.gradle -ErrorAction SilentlyContinue

# Rebuild
flutter pub get
flutter build apk --debug
```

---

## ⚡ Quick Fixes

### "Gradle daemon failed"
```bash
cd android
./gradlew --stop
cd ..
flutter clean
flutter pub get
```

### "Could not resolve dependencies"
```bash
flutter pub cache repair
flutter pub get
```

### "Build timeout"
```bash
# Increase timeout or build with verbose
flutter build apk --debug --verbose
```

---

## 📊 Build Output Locations

### Debug APK
```
build/app/outputs/flutter-apk/app-debug.apk
```

### Release APK
```
build/app/outputs/flutter-apk/app-release.apk
```

### App Bundle
```
build/app/outputs/bundle/release/app-release.aab
```

---

**Last Updated:** January 25, 2026
