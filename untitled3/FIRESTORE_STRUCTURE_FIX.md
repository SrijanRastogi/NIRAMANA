# Firestore Structure Fix - Project-Scoped Collections

## Problem
The current implementation uses **top-level collections** with `projectId` filters:
```dart
// ❌ WRONG - Top-level collection
FirebaseFirestore.instance
  .collection("purchase_orders")
  .where("createdBy", isEqualTo: uid)

// ❌ WRONG - Top-level collection with projectId filter  
FirebaseFirestore.instance
  .collection("material_requests")
  .where("projectId", isEqualTo: projectId)
```

## Solution
Use **project-scoped subcollections**:
```dart
// ✅ CORRECT - Subcollection under project
FirebaseFirestore.instance
  .collection("projects")
  .doc(projectId)
  .collection("purchaseOrders")

// ✅ CORRECT - Subcollection under project
FirebaseFirestore.instance
  .collection("projects")
  .doc(projectId)
  .collection("materialRequests")
```

## Collections to Fix

### 1. Material Requests
**From**: `material_requests` (top-level)
**To**: `projects/{projectId}/materialRequests` (subcollection)

### 2. Purchase Orders
**From**: `purchase_orders` (top-level)
**To**: `projects/{projectId}/purchaseOrders` (subcollection)

### 3. GRN (Goods Receipt Notes)
**From**: `grn` (top-level)
**To**: `projects/{projectId}/grn` (subcollection)

### 4. Bills
**From**: `bills` or `gst_bills` (top-level)
**To**: `projects/{projectId}/gst_bills` (subcollection) - Already correct!

## Files Requiring Changes

### High Priority (Core Service)
1. `lib/services/procurement_service.dart` - All methods
2. `lib/services/procurement_validation_service.dart` - Validation queries

### Medium Priority (UI)
3. `lib/purchase_manager/screens/purchase_manager_dashboard.dart` - Stats query
4. `lib/services/procurement_migration_service.dart` - Migration logic

### Low Priority (Already Correct or Legacy)
- `lib/services/gst_bill_service.dart` - Already uses subcollections ✅
- Other screens that use ProcurementService - Will work automatically after service fix

## Implementation Strategy

### Option 1: Update Service Layer (Recommended)
Update `procurement_service.dart` to use subcollections. All UI code will work automatically.

### Option 2: Hybrid Approach
Keep top-level collections for cross-project queries (admin/reporting), use subcollections for project-specific operations.

### Option 3: Migration Path
1. Create new subcollection structure
2. Migrate existing data
3. Update service layer
4. Deprecate top-level collections

## Recommended Approach

**Use subcollections for project-scoped data** because:
- ✅ Better security (project-level rules)
- ✅ Better performance (no projectId filters needed)
- ✅ Cleaner data model
- ✅ Easier to manage permissions
- ✅ Follows Firestore best practices

**Keep top-level collections only for**:
- Cross-project analytics
- Admin dashboards
- Global search/reporting

## Next Steps

1. Update `procurement_service.dart` to use subcollections
2. Update Firestore security rules for subcollections
3. Create migration script to move existing data
4. Update documentation
5. Test all procurement workflows

---

**Status**: Analysis Complete - Ready for Implementation
**Impact**: Breaking change - Requires data migration
**Priority**: High - Security and performance improvement
