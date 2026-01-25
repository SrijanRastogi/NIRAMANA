# Face Recognition Setup Guide

## ⚠️ IMPORTANT: Model File Required

The face recognition feature requires a TensorFlow Lite model file that is **NOT included** in the repository due to its size (~4MB).

## 🚀 Quick Setup (5 minutes)

### Step 1: Create the models directory

```bash
mkdir -p assets/models
```

### Step 2: Download MobileFaceNet Model

**Option A: Direct Download (Recommended)**

Download the pre-trained MobileFaceNet model:

1. Visit: https://github.com/sirius-ai/MobileFaceNet_TF/releases
2. Download: `mobilefacenet.tflite` (or `mobilefacenet_v2.tflite`)
3. Place in: `assets/models/mobilefacenet.tflite`

**Option B: From TensorFlow Hub**

1. Visit: https://tfhub.dev/
2. Search: "MobileFaceNet"
3. Download the TFLite version
4. Rename to: `mobilefacenet.tflite`
5. Place in: `assets/models/`

**Option C: Convert from PyTorch/ONNX**

If you have a PyTorch or ONNX model:

```bash
# Install TensorFlow
pip install tensorflow

# Convert to TFLite
python convert_to_tflite.py
```

### Step 3: Enable in pubspec.yaml

Uncomment the model asset line in `pubspec.yaml`:

```yaml
assets:
  - assets/logo.png
  - assets/models/mobilefacenet.tflite  # Uncomment this line
```

### Step 4: Verify Setup

Run the app and check logs:

```bash
flutter run
```

Look for:
```
✅ Face Recognition Service initialized
```

If you see:
```
⚠️ MobileFaceNet model not found
```

Then the model file is missing or in the wrong location.

## 📁 Expected File Structure

```
untitled3/
├── assets/
│   ├── logo.png
│   └── models/
│       └── mobilefacenet.tflite  ← Must be here
├── lib/
├── pubspec.yaml
└── ...
```

## 🔍 Model Specifications

**MobileFaceNet Requirements:**
- **Input Shape**: [1, 112, 112, 3] (RGB image)
- **Output Shape**: [1, 128] (face embedding)
- **File Size**: ~4MB
- **Format**: TensorFlow Lite (.tflite)
- **Quantization**: Float32 (recommended) or Int8

## 🧪 Testing the Model

After setup, test face recognition:

1. Open the app
2. Navigate to: Manager Dashboard → Workers
3. Tap: "Enroll Worker"
4. Capture a face
5. Check for success message

## ❌ Troubleshooting

### Error: "No file or variants found for asset"

**Solution:**
1. Verify file exists: `ls -la assets/models/mobilefacenet.tflite`
2. Check pubspec.yaml has the asset uncommented
3. Run: `flutter clean && flutter pub get`
4. Rebuild: `flutter run`

### Error: "Failed to load face recognition model"

**Solution:**
1. Check file size: `ls -lh assets/models/mobilefacenet.tflite`
   - Should be ~4MB
2. Verify it's a valid TFLite file:
   ```bash
   file assets/models/mobilefacenet.tflite
   # Should show: TensorFlow Lite model
   ```
3. Try re-downloading the model

### Error: "Interpreter failed to initialize"

**Solution:**
1. Check TFLite Flutter plugin is installed:
   ```bash
   flutter pub get
   ```
2. Verify model format matches expected input/output shapes
3. Try a different model version

### Face Detection Works but Recognition Fails

**Solution:**
1. Model might be incompatible
2. Try MobileFaceNet v2 instead
3. Check model input/output shapes match code expectations

## 🔄 Alternative: Use Without Face Recognition

If you don't want to use face recognition, you can:

1. **Keep model commented out** in pubspec.yaml
2. **Use manual attendance only**
3. Workers can still be enrolled without face data
4. Attendance marking will use manual/GPS methods only

The app will work fine without the model - face recognition features will simply be disabled.

## 📚 Model Sources

### Recommended Models

1. **MobileFaceNet (Original)**
   - Source: https://github.com/sirius-ai/MobileFaceNet_TF
   - Accuracy: ~99.5% on LFW
   - Speed: ~20ms on mobile

2. **MobileFaceNet v2**
   - Source: https://github.com/deepinsight/insightface
   - Improved accuracy
   - Slightly larger file size

3. **FaceNet Mobile**
   - Source: https://github.com/davidsandberg/facenet
   - Higher accuracy
   - Larger model (~20MB)

### Training Your Own Model

If you want to train a custom model:

1. Use InsightFace or FaceNet
2. Train on your specific dataset
3. Convert to TFLite
4. Replace the model file

## 🔒 Security Notes

- Model file is **NOT** uploaded to Git (in .gitignore)
- Each developer must download separately
- Model contains no personal data
- Only face embeddings are stored, never raw images

## 📝 License

MobileFaceNet model is typically released under MIT or Apache 2.0 license. Check the specific model source for license terms.

## 🆘 Need Help?

1. Check logs: `flutter run --verbose`
2. Verify file permissions: `chmod 644 assets/models/mobilefacenet.tflite`
3. Try a clean build: `flutter clean && flutter pub get && flutter run`
4. Check model compatibility with TFLite Flutter version

## ✅ Verification Checklist

- [ ] Model file downloaded
- [ ] File placed in `assets/models/mobilefacenet.tflite`
- [ ] File size is ~4MB
- [ ] pubspec.yaml asset line uncommented
- [ ] `flutter pub get` executed
- [ ] App builds without errors
- [ ] Face recognition initializes successfully
- [ ] Worker enrollment works
- [ ] Face scanning works

## 🚀 Production Deployment

For production:

1. **Include model in CI/CD**
   - Store model in secure artifact repository
   - Download during build process
   - Don't commit to Git

2. **Optimize model**
   - Use quantized version (Int8) for smaller size
   - Test accuracy vs. size tradeoff

3. **Monitor performance**
   - Track initialization time
   - Monitor recognition accuracy
   - Log failures for improvement

## 📊 Expected Performance

With MobileFaceNet:
- **Initialization**: 100-500ms
- **Face Detection**: 50-200ms
- **Embedding Extraction**: 20-100ms
- **Matching**: <1ms per comparison
- **Total Time**: 200-800ms per face

## 🔄 Updates

To update the model:

1. Download new version
2. Replace `assets/models/mobilefacenet.tflite`
3. Test thoroughly
4. Update version in documentation
5. Notify team of changes

---

**Last Updated**: January 2026
**Model Version**: MobileFaceNet v1.0
**Compatibility**: TFLite Flutter ^0.10.4
