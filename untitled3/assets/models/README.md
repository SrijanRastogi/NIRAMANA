# Face Recognition Models Directory

## 📁 Required Files

This directory should contain the face recognition model file:

```
assets/models/
└── mobilefacenet.tflite  (NOT included - download separately)
```

## ⚠️ Model Not Included

The TensorFlow Lite model file is **NOT included** in this repository because:

1. **File Size**: ~4MB (too large for Git)
2. **License**: May have distribution restrictions
3. **Updates**: Models may be updated independently
4. **Customization**: Teams may use different models

## 📥 How to Get the Model

### Option 1: Download Pre-trained Model (Recommended)

**MobileFaceNet (Original)**
```bash
# Visit and download:
https://github.com/sirius-ai/MobileFaceNet_TF/releases

# Or use wget/curl:
wget https://github.com/sirius-ai/MobileFaceNet_TF/releases/download/v1.0/mobilefacenet.tflite
mv mobilefacenet.tflite assets/models/
```

**From TensorFlow Hub**
```bash
# Visit: https://tfhub.dev/
# Search: "MobileFaceNet" or "face recognition"
# Download TFLite version
# Place in: assets/models/mobilefacenet.tflite
```

### Option 2: Use the Download Script

```bash
# Make script executable
chmod +x scripts/download_face_model.sh

# Run the script
./scripts/download_face_model.sh
```

### Option 3: Convert Your Own Model

If you have a PyTorch or ONNX model:

```python
import tensorflow as tf

# Load your model
model = tf.keras.models.load_model('your_model.h5')

# Convert to TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

# Save
with open('assets/models/mobilefacenet.tflite', 'wb') as f:
    f.write(tflite_model)
```

## ✅ Verification

After placing the model file:

1. **Check file exists:**
   ```bash
   ls -lh assets/models/mobilefacenet.tflite
   ```
   Should show ~4MB file

2. **Verify it's a TFLite file:**
   ```bash
   file assets/models/mobilefacenet.tflite
   ```
   Should show: "TensorFlow Lite model"

3. **Uncomment in pubspec.yaml:**
   ```yaml
   assets:
     - assets/models/mobilefacenet.tflite
   ```

4. **Run Flutter:**
   ```bash
   flutter pub get
   flutter run
   ```

## 📋 Model Specifications

**Expected Model Format:**
- **Type**: TensorFlow Lite (.tflite)
- **Input Shape**: [1, 112, 112, 3] (RGB image)
- **Output Shape**: [1, 128] (face embedding vector)
- **Data Type**: Float32 (preferred) or Int8 (quantized)
- **File Size**: ~4MB (Float32) or ~1MB (Int8)

## 🔍 Supported Models

The app is designed for MobileFaceNet but can work with similar models:

1. **MobileFaceNet** (Recommended)
   - Fast and accurate
   - Optimized for mobile
   - ~4MB

2. **MobileFaceNet v2**
   - Improved accuracy
   - Slightly larger

3. **FaceNet Mobile**
   - Higher accuracy
   - Larger size (~20MB)

4. **Custom Models**
   - Must output 128-dim embeddings
   - Input should be 112x112 RGB

## 🚫 What NOT to Put Here

- ❌ Raw face images
- ❌ Training datasets
- ❌ Personal data
- ❌ Large checkpoint files
- ❌ Non-TFLite formats

## 🔒 Security & Privacy

- Model file is in `.gitignore` (not committed to Git)
- Contains no personal data
- Only mathematical weights
- Safe to share within team
- Check license before redistribution

## 📚 Additional Resources

- **MobileFaceNet Paper**: https://arxiv.org/abs/1804.07573
- **TFLite Guide**: https://www.tensorflow.org/lite
- **Face Recognition**: https://github.com/ageitgey/face_recognition
- **InsightFace**: https://github.com/deepinsight/insightface

## 🆘 Troubleshooting

### "No file or variants found for asset"
- Model file is missing
- Download and place in this directory
- Uncomment asset line in pubspec.yaml

### "Failed to load model"
- File might be corrupted
- Re-download the model
- Verify file size and format

### "Model initialization failed"
- Check TFLite Flutter plugin version
- Verify model input/output shapes
- Try a different model version

## 📝 Notes

- This directory is created automatically
- Model file must be downloaded separately
- See `FACE_RECOGNITION_SETUP.md` for detailed instructions
- Contact team lead if you need the model file

---

**Last Updated**: January 2026
**Required Model**: MobileFaceNet v1.0
**File Size**: ~4MB
