# Project-Scoped Collections - FIXED ✅

## Summary
All procurement-related collections have been converted from **top-level collections** to **project-scoped subcollections** for better security, performance, and data organization.

---

## Changes Made

### 1. Material Requests
**Before** (❌ Top-level):
```dart
FirebaseFirestore.instance
  .collection('material_requests')
  .where('projectId', isEqualTo: projectId)
```

**After** (✅ Project-scoped):
```dart
FirebaseFirestore.instance
  .collection('projects')
  .doc(projectId)
  .collection('materialRequests')
```

### 2. Purchase Orders
**Before** (❌ Top-level):
```dart
FirebaseFirestore.instance
  .collection('purchase_orders')
  .where('createdBy', isEqualTo: uid)
```

**After** (✅ Project-scoped):
```dart
FirebaseFirestore.instance
  .collection('projects')
  .doc(projectId)
  .collection('purchaseOrders')
```

### 3. GRN (Goods Receipt Notes)
**Before** (❌ Top-level):
```dart
FirebaseFirestore.instance
  .collection('grn')
  .where('projectId', isEqualTo: projectId)
```

**After** (✅ Project-scoped):
```dart
FirebaseFirestore.instance
  .collection('projects')
  .doc(projectId)
  .collection('grn')
```

### 4. GST Bills
**Status**: ✅ Already using project-scoped subcollections
```dart
FirebaseFirestore.instance
  .collection('projects')
  .doc(projectId)
  .collection('gst_bills')
```

---

## Files Modified

### Core Service Layer
1. **`lib/services/procurement_service.dart`** ✅
   - All Material Request methods updated
   - All Purchase Order methods updated
   - All GRN methods updated
   - Workflow validation methods updated
   - Method signatures updated to require `projectId`

### UI Layer
2. **`lib/purchase_manager/screens/purchase_manager_dashboard.dart`** ✅
   - Removed top-level `purchase_orders` query
   - Updated `material_requests` query to use subcollection
   - Stats now use project-based aggregation

---

## Method Signature Changes

### Material Requests
```dart
// OLD
static Future<void> engineerApproveMR(String mrId)

// NEW  
static Future<void> engineerApproveMR(String projectId, String mrId)
```

```dart
// OLD
static Future<void> ownerApproveMR(String mrId)

// NEW
static Future<void> ownerApproveMR(String projectId, String mrId)
```

### Purchase Orders
```dart
// OLD
static Future<PurchaseOrderModel?> getPOById(String poId)

// NEW
static Future<PurchaseOrderModel?> getPOById(String projectId, String poId)
```

### GRN
```dart
// OLD
static Future<GRNModel?> getGRNByPOId(String poId)

// NEW
static Future<GRNModel?> getGRNByPOId(String projectId, String poId)
```

```dart
// OLD
static Future<GRNModel?> getGRNById(String grnId)

// NEW
static Future<GRNModel?> getGRNById(String projectId, String grnId)
```

### Workflow Validation
```dart
// OLD
static Future<bool> canCreateBill(String poId)

// NEW
static Future<bool> canCreateBill(String projectId, String poId)
```

```dart
// OLD
static Future<Map<String, dynamic>> getProcurementChain(String mrId)

// NEW
static Future<Map<String, dynamic>> getProcurementChain(String projectId, String mrId)
```

---

## Benefits

### 1. Security ✅
- **Project-level access control**: Firestore rules can enforce permissions at project level
- **No cross-project leaks**: Data is isolated by project
- **Simpler rules**: No need to validate `projectId` in every rule

### 2. Performance ✅
- **No filters needed**: Direct subcollection access is faster
- **Better indexing**: Firestore optimizes subcollection queries
- **Reduced query complexity**: No compound indexes needed for `projectId + status`

### 3. Data Organization ✅
- **Logical hierarchy**: Data is organized under projects
- **Easier cleanup**: Deleting a project deletes all subcollections
- **Better scalability**: Subcollections scale better than filtered top-level collections

### 4. Cost Optimization ✅
- **Fewer reads**: No need to filter by `projectId`
- **Efficient queries**: Direct path to data
- **Better caching**: Firestore can cache subcollection data more effectively

---

## Firestore Structure

### New Structure
```
projects/
  {projectId}/
    ├── materialRequests/
    │   ├── {mrId}
    │   │   ├── projectId: "project123"
    │   │   ├── status: "REQUESTED"
    │   │   ├── materials: [...]
    │   │   └── ...
    │   └── ...
    │
    ├── purchaseOrders/
    │   ├── {poId}
    │   │   ├── projectId: "project123"
    │   │   ├── mrId: "mr123"
    │   │   ├── status: "PO_CREATED"
    │   │   └── ...
    │   └── ...
    │
    ├── grn/
    │   ├── {grnId}
    │   │   ├── projectId: "project123"
    │   │   ├── poId: "po123"
    │   │   ├── status: "GRN_CONFIRMED"
    │   │   └── ...
    │   └── ...
    │
    └── gst_bills/
        ├── {billId}
        │   ├── projectId: "project123"
        │   ├── poId: "po123"
        │   ├── grnId: "grn123"
        │   └── ...
        └── ...
```

---

## Migration Required

### ⚠️ IMPORTANT: Data Migration Needed

Existing data in top-level collections needs to be migrated:

1. **`material_requests`** → **`projects/{projectId}/materialRequests`**
2. **`purchase_orders`** → **`projects/{projectId}/purchaseOrders`**
3. **`grn`** → **`projects/{projectId}/grn`**

### Migration Script
See `lib/services/procurement_migration_service.dart` for migration utilities.

### Migration Steps
```dart
// 1. Read all documents from top-level collection
final oldMRs = await FirebaseFirestore.instance
    .collection('material_requests')
    .get();

// 2. Write to project-scoped subcollection
for (var doc in oldMRs.docs) {
  final data = doc.data();
  final projectId = data['projectId'];
  
  await FirebaseFirestore.instance
      .collection('projects')
      .doc(projectId)
      .collection('materialRequests')
      .doc(doc.id)
      .set(data);
}

// 3. Delete old top-level documents (after verification)
```

---

## Firestore Security Rules Update

### Old Rules (Top-level)
```javascript
match /material_requests/{mrId} {
  allow read: if request.auth != null 
    && isProjectMember(resource.data.projectId);
  allow create: if request.auth != null 
    && isFieldManager()
    && request.resource.data.projectId != null;
}
```

### New Rules (Subcollection)
```javascript
match /projects/{projectId}/materialRequests/{mrId} {
  allow read: if request.auth != null 
    && isProjectMember(projectId);
  allow create: if request.auth != null 
    && isFieldManager()
    && isProjectMember(projectId);
}
```

**Benefits**:
- ✅ No need to validate `projectId` in data
- ✅ Simpler permission checks
- ✅ Better performance

---

## Testing Checklist

### Unit Tests
- [ ] Material Request CRUD operations
- [ ] Purchase Order CRUD operations
- [ ] GRN CRUD operations
- [ ] Workflow validation methods
- [ ] Method signature compatibility

### Integration Tests
- [ ] Create MR → Engineer approve → Owner approve
- [ ] Create PO after Owner approval
- [ ] Create GRN after PO
- [ ] Create bill after GRN
- [ ] Complete procurement chain

### UI Tests
- [ ] Purchase Manager dashboard loads
- [ ] Material requests display correctly
- [ ] Purchase orders display correctly
- [ ] GRN creation works
- [ ] Bill creation works

---

## Breaking Changes

### ⚠️ API Changes
All methods now require `projectId` as the first parameter:

**Before**:
```dart
await ProcurementService.engineerApproveMR(mrId);
```

**After**:
```dart
await ProcurementService.engineerApproveMR(projectId, mrId);
```

### Files That Need Updates
Any file calling these methods needs to pass `projectId`:
- `lib/engineer/screens/mr_approval_screen.dart`
- `lib/owner/screens/mr_financial_approval_screen.dart`
- `lib/manager/screens/grn_creation_screen.dart`
- `lib/common/widgets/procurement_chain_widget.dart`
- And any other files using ProcurementService

---

## Rollback Plan

If issues arise:
1. Keep old top-level collections temporarily
2. Revert service layer changes
3. Run data sync from subcollections back to top-level
4. Update Firestore rules back to old structure

---

## Next Steps

1. ✅ Update service layer (DONE)
2. ✅ Update UI layer (DONE)
3. ⏳ Update all calling code to pass `projectId`
4. ⏳ Update Firestore security rules
5. ⏳ Run data migration
6. ⏳ Test all workflows
7. ⏳ Deploy to production

---

**Status**: ✅ SERVICE LAYER COMPLETE
**Date**: January 2025
**Impact**: Breaking changes - requires migration and calling code updates
**Priority**: HIGH - Better security and performance
