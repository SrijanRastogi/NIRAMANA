# Tool Library - Quick Start Guide

## 🎯 Access

**Manager Dashboard → Tool Library**

---

## 📱 Features

### 1. Borrow Tool
```
Tool Library → Borrow Tool
↓
Scan QR Code → Enter Tool ID
↓
Worker Name + Mobile Number
↓
Select Project + Return Date/Time
↓
Submit
```

### 2. Return Tool
```
Tool Library → Return Tool
↓
Scan QR Code → Enter Tool ID
↓
Select Condition (Good/Damaged)
↓
Submit
```

---

## 🔐 Business Rules

### Borrowing
- ✅ Tool must be AVAILABLE
- ✅ QR image required
- ✅ Worker details required
- ✅ Project assignment required
- ✅ Return date/time required

### Returning
- ✅ Tool must be IN_USE
- ✅ Active transaction must exist
- ✅ QR image required
- ✅ Condition check required

---

## 📊 Data Storage

### Firestore Collections
```
tools/{toolId}
  - toolName
  - status (AVAILABLE | IN_USE)
  - createdAt

tool_transactions/{transactionId}
  - toolId
  - workerName
  - mobileNumber
  - projectId
  - borrowedAt
  - expectedReturnAt
  - returnedAt
  - condition (GOOD | DAMAGED)
  - borrowQrImageUrl
  - returnQrImageUrl
  - managerId
```

### Offline Storage (Hive)
```
offline_tool_transactions - Pending borrows
offline_tool_returns - Pending returns
```

---

## 🌐 Offline Support

**Borrow Offline:**
- Saves to Hive
- Shows "offline - will sync" message
- Auto-syncs when online

**Return Offline:**
- Saves to Hive
- Shows "offline - will sync" message
- Auto-syncs when online

---

## 🚨 Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| Tool not available | Status is IN_USE | Wait for return or use different tool |
| No active transaction | Tool not borrowed | Check tool ID or borrow first |
| Invalid mobile number | Not 10 digits | Enter valid 10-digit number |
| Missing QR image | Camera not used | Capture QR code image |
| Upload failed | Network issue | Will save offline and sync later |

---

## 📁 Files Created

### Models
- `lib/models/tool_model.dart`
- `lib/models/tool_transaction_model.dart`
- `lib/models/tool_transaction_model.g.dart`

### Services
- `lib/services/tool_service.dart`

### Screens
- `lib/manager/screens/tool_library_screen.dart`
- `lib/manager/screens/borrow_tool_screen.dart`
- `lib/manager/screens/return_tool_screen.dart`
- `lib/manager/screens/tool_qr_scanner_screen.dart`

### Modified
- `lib/manager/manager_pages.dart` (added tile)
- `lib/main.dart` (registered Hive adapter)

---

## ✅ Status

**IMPLEMENTATION: COMPLETE**
**COMPILE STATUS: NO ERRORS**
**READY FOR: TESTING & DEMO**

---

## 🔄 Next Steps

1. Test borrow flow
2. Test return flow
3. Test offline mode
4. Test error handling
5. Deploy to production

---

**Last Updated:** January 25, 2026
