# Scripts Directory

## 📁 Available Scripts

### `download_face_model.sh`

Downloads the MobileFaceNet model for face recognition.

**Usage:**
```bash
chmod +x scripts/download_face_model.sh
./scripts/download_face_model.sh
```

**What it does:**
- Creates `assets/models/` directory
- Checks if model already exists
- Shows download instructions
- (Auto-download when URL configured)

**Note:** Currently shows manual download instructions. Update the script with a valid download URL for automatic downloads.

---

## 🔧 Future Scripts

### Planned Scripts

1. **`setup_dev_environment.sh`**
   - Install Flutter dependencies
   - Download face model
   - Configure Firebase
   - Setup Android SDK

2. **`run_tests.sh`**
   - Run unit tests
   - Run integration tests
   - Generate coverage report

3. **`build_release.sh`**
   - Build release APK
   - Build release IPA
   - Generate checksums

4. **`deploy.sh`**
   - Deploy to Firebase App Distribution
   - Deploy to Play Store (internal)
   - Deploy to TestFlight

---

## 📝 Adding New Scripts

When adding new scripts:

1. **Make executable:**
   ```bash
   chmod +x scripts/your_script.sh
   ```

2. **Add shebang:**
   ```bash
   #!/bin/bash
   ```

3. **Add error handling:**
   ```bash
   set -e  # Exit on error
   ```

4. **Document in this README**

5. **Test thoroughly**

---

## 🆘 Troubleshooting

### Permission Denied
```bash
chmod +x scripts/download_face_model.sh
```

### Script Not Found
```bash
# Run from project root
cd /path/to/untitled3
./scripts/download_face_model.sh
```

### Windows Users
Use Git Bash or WSL to run shell scripts.

---

**Last Updated**: January 2026
