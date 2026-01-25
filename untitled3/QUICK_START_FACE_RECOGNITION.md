# Face Recognition - Quick Start

## 🚀 Get Started in 3 Steps

### Step 1: Download Model (One-time setup)

```bash
# Create directory
mkdir -p assets/models

# Download model (choose one method):

# Method A: Manual download
# Visit: https://github.com/sirius-ai/MobileFaceNet_TF/releases
# Download: mobilefacenet.tflite
# Place in: assets/models/

# Method B: Use wget
wget -O assets/models/mobilefacenet.tflite \
  https://github.com/sirius-ai/MobileFaceNet_TF/releases/download/v1.0/mobilefacenet.tflite

# Method C: Use curl
curl -L -o assets/models/mobilefacenet.tflite \
  https://github.com/sirius-ai/MobileFaceNet_TF/releases/download/v1.0/mobilefacenet.tflite
```

### Step 2: Enable in pubspec.yaml

Edit `pubspec.yaml` and uncomment:

```yaml
assets:
  - assets/logo.png
  - assets/models/mobilefacenet.tflite  # ← Uncomment this line
```

### Step 3: Build & Run

```bash
flutter pub get
flutter run
```

## ✅ Verify Setup

Check logs for:
```
✅ Face Recognition Service initialized
```

## 🎯 Usage

### Enroll Worker
1. Manager Dashboard → Workers
2. Tap "Enroll Worker"
3. Fill details
4. Capture face
5. Save

### Mark Attendance
1. Manager Dashboard → Attendance
2. Tap "Face Scan"
3. Capture worker's face
4. Auto-marked if recognized

## ⚠️ Without Model

App works without model:
- Face recognition disabled
- Manual attendance works
- GPS validation works
- All other features work

## 🆘 Troubleshooting

### Build Error: "No file or variants found"
```bash
# Check file exists
ls -la assets/models/mobilefacenet.tflite

# If missing, download it
# See Step 1 above

# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Model Not Loading
```bash
# Verify file size (~4MB)
ls -lh assets/models/mobilefacenet.tflite

# Check it's a valid TFLite file
file assets/models/mobilefacenet.tflite

# Re-download if corrupted
rm assets/models/mobilefacenet.tflite
# Then download again (Step 1)
```

## 📚 Full Documentation

- Setup Guide: `FACE_RECOGNITION_SETUP.md`
- Implementation: `FACE_RECOGNITION_IMPLEMENTATION.md`
- Models Info: `assets/models/README.md`

## 🔗 Quick Links

- Model Source: https://github.com/sirius-ai/MobileFaceNet_TF
- TFLite Guide: https://www.tensorflow.org/lite
- ML Kit Docs: https://developers.google.com/ml-kit

---

**Need Help?** Check `FACE_RECOGNITION_SETUP.md` for detailed instructions.
