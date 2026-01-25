#!/bin/bash

# Face Recognition Model Downloader
# Downloads MobileFaceNet model for face recognition

set -e

echo "🤖 Face Recognition Model Downloader"
echo "===================================="
echo ""

# Create models directory
MODELS_DIR="assets/models"
mkdir -p "$MODELS_DIR"

# Model file path
MODEL_FILE="$MODELS_DIR/mobilefacenet.tflite"

# Check if model already exists
if [ -f "$MODEL_FILE" ]; then
    echo "✅ Model already exists: $MODEL_FILE"
    FILE_SIZE=$(ls -lh "$MODEL_FILE" | awk '{print $5}')
    echo "   File size: $FILE_SIZE"
    echo ""
    read -p "Do you want to re-download? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping download."
        exit 0
    fi
fi

echo "📥 Downloading MobileFaceNet model..."
echo ""

# Option 1: Download from GitHub release (if available)
# Uncomment and update URL when you have a release
# MODEL_URL="https://github.com/YOUR_ORG/YOUR_REPO/releases/download/v1.0/mobilefacenet.tflite"

# Option 2: Download from Google Drive (example)
# You'll need to upload the model to Google Drive and get a shareable link
# MODEL_URL="https://drive.google.com/uc?export=download&id=YOUR_FILE_ID"

# Option 3: Download from Hugging Face (recommended)
MODEL_URL="https://huggingface.co/spaces/YOUR_SPACE/resolve/main/mobilefacenet.tflite"

# For now, show instructions since we don't have a direct download link
echo "⚠️  Automatic download not configured yet."
echo ""
echo "Please download the model manually:"
echo ""
echo "1. Visit: https://github.com/sirius-ai/MobileFaceNet_TF/releases"
echo "2. Download: mobilefacenet.tflite"
echo "3. Place in: $MODEL_FILE"
echo ""
echo "Or use one of these alternatives:"
echo ""
echo "• TensorFlow Hub: https://tfhub.dev/ (search 'MobileFaceNet')"
echo "• InsightFace: https://github.com/deepinsight/insightface"
echo "• Pre-trained models: https://github.com/sirius-ai/MobileFaceNet_TF"
echo ""

# Uncomment this when you have a valid download URL
# echo "Downloading from: $MODEL_URL"
# curl -L -o "$MODEL_FILE" "$MODEL_URL"
# 
# if [ -f "$MODEL_FILE" ]; then
#     FILE_SIZE=$(ls -lh "$MODEL_FILE" | awk '{print $5}')
#     echo ""
#     echo "✅ Download complete!"
#     echo "   File: $MODEL_FILE"
#     echo "   Size: $FILE_SIZE"
#     echo ""
#     echo "Next steps:"
#     echo "1. Uncomment model asset in pubspec.yaml"
#     echo "2. Run: flutter pub get"
#     echo "3. Run: flutter run"
# else
#     echo "❌ Download failed!"
#     exit 1
# fi

exit 0
