# Face Recognition - Quick Reference Guide

## 🎯 Quick Access

### Field Manager Dashboard
After selecting a project, you'll see these tiles:

1. Material Requests
2. Attendance (manual)
3. Daily Progress
4. Tasks
5. Petty Cash
6. **Worker Management** ⭐ NEW
7. **Face Scan Attendance** ⭐ NEW
8. Billing & Invoices

---

## 📱 How to Use

### Enroll a Worker
```
Dashboard → Worker Management → + Button
↓
Enter: Name, Role, Daily Wage
↓
Tap "Capture Face" → Take Photo
↓
Save Worker
```

### Mark Attendance
```
Dashboard → Face Scan Attendance
↓
Tap "Scan Face" → Camera Opens
↓
Capture Worker Face
↓
Auto-Recognized → Attendance Marked
```

---

## 🔐 Security Rules

✅ **GPS Required:** Must be within 100m of project site  
✅ **Time Window:** 6 AM - 8 PM only  
✅ **One Per Day:** Can't mark duplicate attendance  
✅ **Face Match:** 70% confidence threshold  
✅ **On-Device:** No cloud processing  

---

## 📊 What Gets Stored

### Worker Record
```
✅ Name, Role, Daily Wage
✅ Face Embedding (128 numbers)
❌ NO face photos
❌ NO raw images
```

### Attendance Record
```
✅ Date, Time, GPS Location
✅ Worker ID, Wage Amount
✅ Verification Method: "FACE"
✅ Match Confidence %
```

---

## ⚠️ Known Issues

### GPS Coordinates
Currently using placeholder (0.0, 0.0). GPS validation will work once project location is added to ProjectModel.

**Fix Required:**
- Add `projectLat` and `projectLng` to ProjectModel
- Update project creation to capture location
- Pass real coordinates to attendance screen

### TFLite Model (Optional)
Face recognition works without the model, but accuracy improves with it.

**To Add Model:**
1. Download MobileFaceNet model
2. Place in `assets/models/mobilefacenet.tflite`
3. Uncomment in `pubspec.yaml`
4. Run `flutter pub get`

---

## 🚨 Troubleshooting

| Problem | Solution |
|---------|----------|
| Face not recognized | Better lighting, clear photo, ensure enrolled |
| GPS fails | Check permissions, wait for GPS lock |
| Outside time window | Use manual attendance fallback |
| Camera permission denied | Grant in device settings |
| Model not found | App works without it (optional) |

---

## 📁 File Locations

### Screens
- `lib/manager/screens/worker_management_screen.dart`
- `lib/manager/screens/worker_enrollment_screen.dart`
- `lib/manager/screens/face_scan_attendance_screen.dart`

### Services
- `lib/services/face_recognition_service.dart`
- `lib/services/worker_service.dart`
- `lib/services/face_attendance_service.dart`

### Models
- `lib/models/worker_model.dart`

### Navigation
- `lib/manager/manager_pages.dart` (lines 512-548)

---

## 🎨 UI Components

### Worker Management Screen
- Stats card (total, active, with face)
- Worker list with status badges
- Floating action button (+ Enroll)
- Toggle show/hide inactive

### Worker Enrollment Screen
- Form fields (name, role, wage)
- Camera button for face capture
- Face preview
- Save button

### Face Scan Attendance Screen
- Instructions card
- Today's summary (present count, total wages)
- Scan face button
- Scanned workers list with confidence %
- Manual attendance fallback

---

## 📈 Success Indicators

✅ Worker enrolled with green "Face Enrolled" badge  
✅ Attendance marked with green checkmark  
✅ Confidence % shown (e.g., "95% Match")  
✅ Today's summary updates in real-time  
✅ Daily wage calculated automatically  

---

## 🔄 Data Flow

### Enrollment
```
Camera → Face Detection → Embedding Extraction → Firestore
```

### Attendance
```
Camera → Face Detection → Embedding Extraction → 
Match Database → GPS Check → Time Check → 
Mark Attendance → Calculate Wage
```

---

## 🎯 Role Access

| Role | Worker Management | Face Scan | View Reports |
|------|------------------|-----------|--------------|
| Field Manager | ✅ Full | ✅ Full | ✅ Yes |
| Engineer | ❌ No | ❌ No | ✅ Yes |
| Owner | ❌ No | ❌ No | ✅ Yes |
| Purchase Manager | ❌ No | ❌ No | ❌ No |

---

## 📝 Next Steps

1. **Test the flow:**
   - Enroll a test worker
   - Mark attendance via face scan
   - Verify wage calculation

2. **Add project GPS:**
   - Update ProjectModel
   - Capture location during project creation
   - Pass to attendance screen

3. **Integrate with dashboards:**
   - Owner: Add wage summaries
   - Engineer: Add attendance view

4. **Download model (optional):**
   - Improves face recognition accuracy
   - See `FACE_RECOGNITION_SETUP.md`

---

## 📚 Full Documentation

For complete details, see:
- `FACE_RECOGNITION_IMPLEMENTATION.md`
- `FACE_RECOGNITION_SETUP.md`
- `CONTEXT_TRANSFER_COMPLETE.md`

---

**Status:** ✅ Ready to Use  
**Last Updated:** January 25, 2026
