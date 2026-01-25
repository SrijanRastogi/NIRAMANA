# Procurement-to-GST-Billing Workflow - Complete Implementation

## Overview
Complete procurement workflow with Purchase Manager role, status-driven approvals, and GST-compliant billing for Niramana Setu construction project management app.

## Architecture

### New Role: Purchase Manager
- **Backend Role**: `purchasemanager`
- **Permissions**: Create Purchase Orders (PO) only after Owner approval
- **Cannot**: Edit Material Requests or GRNs

### Data Models

#### 1. Material Request Model (`lib/models/material_request_model.dart`)
```dart
MaterialRequestModel {
  String id;
  String projectId;
  String createdBy; // Field Manager UID
  List<MaterialItem> materials;
  String status; // REQUESTED, ENGINEER_APPROVED, OWNER_APPROVED, PO_CREATED, REJECTED
  bool engineerApproved;
  bool ownerApproved;
  DateTime createdAt;
}
```

#### 2. Purchase Order Model (`lib/models/purchase_order_model.dart`)
```dart
PurchaseOrderModel {
  String id;
  String projectId;
  String mrId; // Material Request ID
  String createdBy; // Purchase Manager UID
  String vendorName;
  String vendorGSTIN;
  List<POItem> items;
  String gstType; // CGST_SGST or IGST
  double totalAmount;
  String status; // PO_CREATED, GRN_CONFIRMED, BILL_GENERATED, BILL_APPROVED
}
```

#### 3. GRN Model (`lib/models/grn_model.dart`)
```dart
GRNModel {
  String id;
  String projectId;
  String poId; // Purchase Order ID
  String verifiedBy; // Field Manager UID
  List<GRNItem> receivedItems;
  String status; // GRN_CONFIRMED
  DateTime verifiedAt;
}
```

#### 4. GST Bill Model (Enhanced - `lib/models/gst_bill_model.dart`)
```dart
GSTBillModel {
  String id;
  String projectId;
  String? poId; // Purchase Order ID (optional for backward compatibility)
  String? grnId; // GRN ID (optional for backward compatibility)
  String createdBy; // Field Manager UID
  String vendorGSTIN;
  double taxableAmount;
  double cgst;
  double sgst;
  double igst;
  double totalAmount;
  String status; // BILL_GENERATED, BILL_APPROVED
  String? pdfUrl;
}
```

## Firestore Schema

### Top-Level Collections

#### 1. `material_requests/{mrId}`
```json
{
  "projectId": "project123",
  "createdBy": "managerUid",
  "materials": [
    {"name": "Cement", "quantity": 100, "unit": "bags"}
  ],
  "status": "REQUESTED",
  "engineerApproved": false,
  "ownerApproved": false,
  "createdAt": "timestamp",
  "engineerApprovedBy": null,
  "engineerApprovedAt": null,
  "engineerRemarks": null,
  "ownerApprovedBy": null,
  "ownerApprovedAt": null,
  "ownerRemarks": null,
  "priority": "High",
  "neededBy": "timestamp",
  "notes": "For level 12 slab"
}
```

#### 2. `purchase_orders/{poId}`
```json
{
  "projectId": "project123",
  "mrId": "mr123",
  "createdBy": "purchaseManagerUid",
  "vendorName": "ABC Traders",
  "vendorGSTIN": "29ABCDE1234F1Z5",
  "vendorAddress": "123 Main St",
  "vendorContact": "+91-9876543210",
  "items": [
    {
      "materialName": "Cement",
      "quantity": 100,
      "unit": "bags",
      "rate": 350,
      "amount": 35000
    }
  ],
  "gstType": "CGST_SGST",
  "totalAmount": 41300,
  "status": "PO_CREATED",
  "createdAt": "timestamp",
  "poNumber": "PO-2024-001"
}
```

#### 3. `grn/{grnId}`
```json
{
  "projectId": "project123",
  "poId": "po123",
  "verifiedBy": "managerUid",
  "receivedItems": [
    {
      "materialName": "Cement",
      "orderedQuantity": 100,
      "receivedQuantity": 98,
      "unit": "bags",
      "isComplete": false
    }
  ],
  "status": "GRN_CONFIRMED",
  "verifiedAt": "timestamp",
  "deliveryChallanNumber": "DC-2024-001",
  "deliveryDate": "timestamp",
  "notes": "2 bags damaged"
}
```

#### 4. `bills/{billId}` (New structure)
```json
{
  "projectId": "project123",
  "poId": "po123",
  "grnId": "grn123",
  "createdBy": "managerUid",
  "source": "MANUAL",
  "vendorGSTIN": "29ABCDE1234F1Z5",
  "taxableAmount": 35000,
  "cgst": 3150,
  "sgst": 3150,
  "igst": 0,
  "totalAmount": 41300,
  "status": "BILL_GENERATED",
  "pdfUrl": "https://storage.googleapis.com/...",
  "createdAt": "timestamp"
}
```

### Project Document (Enhanced)
```json
{
  "projectName": "Skyline Apartments",
  "engineerId": "engineerUid",
  "ownerId": "ownerUid",
  "ownerUid": "ownerUid",
  "managerId": "managerUid",
  "managerUid": "managerUid",
  "purchaseManagerId": "pmPublicId",
  "purchaseManagerUid": "pmUid",
  "purchaseManagerName": "John Doe",
  "status": "ACTIVE"
}
```

## Status Flow (Backend-Enforced)

### Complete Workflow
```
1. REQUESTED (Field Manager creates MR)
   ↓
2. ENGINEER_APPROVED (Engineer approves MR)
   ↓
3. OWNER_APPROVED (Owner approves MR financially)
   ↓
4. PO_CREATED (Purchase Manager creates PO)
   ↓
5. GRN_CONFIRMED (Field Manager confirms delivery)
   ↓
6. BILL_GENERATED (Field Manager creates bill)
   ↓
7. BILL_APPROVED (Engineer approves bill)
```

### Status Transitions (Firestore Rules Enforced)

| From Status | To Status | Role | Validation |
|------------|-----------|------|------------|
| REQUESTED | ENGINEER_APPROVED | Engineer | MR exists, status is REQUESTED |
| REQUESTED | REJECTED | Engineer | MR exists, remarks required |
| ENGINEER_APPROVED | OWNER_APPROVED | Owner | MR is engineer-approved |
| ENGINEER_APPROVED | REJECTED | Owner | MR is engineer-approved, remarks required |
| OWNER_APPROVED | PO_CREATED | Purchase Manager | MR is owner-approved |
| PO_CREATED | GRN_CONFIRMED | Field Manager | PO exists, status is PO_CREATED |
| GRN_CONFIRMED | BILL_GENERATED | Field Manager | GRN exists and confirmed |
| BILL_GENERATED | BILL_APPROVED | Engineer | Bill exists, status is BILL_GENERATED |

## Services

### Procurement Service (`lib/services/procurement_service.dart`)

#### Material Request Operations
```dart
// Create MR (Field Manager)
Future<String> createMaterialRequest(MaterialRequestModel mr)

// Engineer approval
Future<void> engineerApproveMR(String mrId)
Future<void> engineerRejectMR(String mrId, String remarks)

// Owner approval
Future<void> ownerApproveMR(String mrId)
Future<void> ownerRejectMR(String mrId, String remarks)

// Streams
Stream<List<MaterialRequestModel>> getEngineerPendingMRs(String projectId)
Stream<List<MaterialRequestModel>> getOwnerPendingMRs(String projectId)
Stream<List<MaterialRequestModel>> getOwnerApprovedMRs(String projectId)
```

#### Purchase Order Operations
```dart
// Create PO (Purchase Manager, requires Owner approval)
Future<String> createPurchaseOrder(PurchaseOrderModel po)

// Streams
Stream<List<PurchaseOrderModel>> getProjectPOs(String projectId)
Stream<List<PurchaseOrderModel>> getPOsPendingGRN(String projectId)
Future<PurchaseOrderModel?> getPOById(String poId)
```

#### GRN Operations
```dart
// Create GRN (Field Manager)
Future<String> createGRN(GRNModel grn)

// Streams
Stream<List<GRNModel>> getProjectGRNs(String projectId)
Future<GRNModel?> getGRNByPOId(String poId)
Future<GRNModel?> getGRNById(String grnId)
```

#### Workflow Validation
```dart
// Validate if bill can be created
Future<bool> canCreateBill(String poId)

// Get complete procurement chain
Future<Map<String, dynamic>> getProcurementChain(String mrId)
```

## Firestore Security Rules

### Key Rules

#### Material Requests
- **Create**: Field Manager only, status must be REQUESTED
- **Read**: All project members
- **Update (Engineer)**: REQUESTED → ENGINEER_APPROVED or REJECTED
- **Update (Owner)**: ENGINEER_APPROVED → OWNER_APPROVED or REJECTED
- **Update (System)**: OWNER_APPROVED → PO_CREATED (when PO created)

#### Purchase Orders
- **Create**: Purchase Manager only, MR must be OWNER_APPROVED
- **Read**: All project members
- **Update**: System only (when GRN created)

#### GRN
- **Create**: Field Manager only, PO must be PO_CREATED
- **Read**: All project members

#### Bills
- **Create**: Field Manager only, GRN must be GRN_CONFIRMED (or null for manual bills)
- **Read**: All project members
- **Update (Field Manager)**: Only pending bills
- **Update (Engineer)**: BILL_GENERATED → BILL_APPROVED

## Validation Rules (Backend-Enforced)

### Critical Validations
1. ✅ No bill without GRN (except manual/legacy bills)
2. ✅ No PO without Owner approval
3. ✅ No GST without system calculation
4. ✅ No cross-project access
5. ✅ All status transitions validated
6. ✅ Role-based permissions enforced
7. ✅ Project membership required

### GST Calculation (Auto-calculated)
```dart
// Same state: CGST + SGST
if (vendorStateCode == projectStateCode) {
  cgst = baseAmount * (gstRate / 100) / 2;
  sgst = baseAmount * (gstRate / 100) / 2;
  igst = 0;
}

// Different state: IGST
else {
  cgst = 0;
  sgst = 0;
  igst = baseAmount * (gstRate / 100);
}

totalAmount = baseAmount + cgst + sgst + igst;
```

## OCR & Storage

### Bill Images
- **Storage Path**: `storage/bills/{projectId}/{billId}.jpg`
- **OCR**: Asynchronous processing
- **Manual Correction**: Always allowed
- **Workflow**: Never blocked by OCR failure

### PDF Generation
- **Format**: GST-compliant invoice
- **Storage**: Firebase Storage
- **URL**: Saved in Firestore `pdfUrl` field
- **Generation**: Client-side using `pdf` package

## Integration with Existing Features

### Backward Compatibility
- ✅ Existing Owner/Engineer/Manager flows unchanged
- ✅ Legacy material requests still work (subcollection)
- ✅ Manual bills without PO/GRN supported
- ✅ Existing GST bill service compatible

### Enhanced Features
- ✅ Project model includes Purchase Manager
- ✅ User model includes Purchase Manager role
- ✅ GST Bill model links to PO and GRN
- ✅ Complete audit trail (who approved when)

## Usage Examples

### 1. Field Manager Creates Material Request
```dart
final mr = MaterialRequestModel(
  id: '',
  projectId: 'project123',
  createdBy: currentUserId,
  createdAt: DateTime.now(),
  materials: [
    MaterialItem(name: 'Cement', quantity: 100, unit: 'bags'),
  ],
  priority: 'High',
  neededBy: DateTime.now().add(Duration(days: 3)),
  notes: 'For level 12 slab',
);

final mrId = await ProcurementService.createMaterialRequest(mr);
```

### 2. Engineer Approves MR
```dart
await ProcurementService.engineerApproveMR(mrId);
```

### 3. Owner Approves MR
```dart
await ProcurementService.ownerApproveMR(mrId);
```

### 4. Purchase Manager Creates PO
```dart
final po = PurchaseOrderModel(
  id: '',
  projectId: 'project123',
  mrId: mrId,
  createdBy: currentUserId,
  createdAt: DateTime.now(),
  vendorName: 'ABC Traders',
  vendorGSTIN: '29ABCDE1234F1Z5',
  items: [
    POItem(
      materialName: 'Cement',
      quantity: 100,
      unit: 'bags',
      rate: 350,
      amount: 35000,
    ),
  ],
  gstType: 'CGST_SGST',
  totalAmount: 41300,
);

final poId = await ProcurementService.createPurchaseOrder(po);
```

### 5. Field Manager Confirms GRN
```dart
final grn = GRNModel(
  id: '',
  projectId: 'project123',
  poId: poId,
  verifiedBy: currentUserId,
  verifiedAt: DateTime.now(),
  receivedItems: [
    GRNItem(
      materialName: 'Cement',
      orderedQuantity: 100,
      receivedQuantity: 98,
      unit: 'bags',
      isComplete: false,
    ),
  ],
  deliveryChallanNumber: 'DC-2024-001',
);

final grnId = await ProcurementService.createGRN(grn);
```

### 6. Field Manager Creates Bill
```dart
final bill = GSTBillModel(
  id: '',
  projectId: 'project123',
  poId: poId,
  grnId: grnId,
  createdBy: currentUserId,
  createdAt: DateTime.now(),
  billNumber: 'BILL-2024-001',
  vendorName: 'ABC Traders',
  vendorGSTIN: '29ABCDE1234F1Z5',
  description: 'Cement - 98 bags',
  quantity: 98,
  unit: 'bags',
  rate: 350,
  baseAmount: 34300,
  gstRate: 18,
  cgstAmount: 3087,
  sgstAmount: 3087,
  igstAmount: 0,
  totalAmount: 40474,
  billSource: 'manual',
);

final billId = await GSTBillService.createBill(bill);
```

### 7. Engineer Approves Bill
```dart
await GSTBillService.approveBill(
  projectId: 'project123',
  billId: billId,
  engineerId: currentUserId,
);
```

## Testing Checklist

### Material Request Flow
- [ ] Field Manager can create MR
- [ ] Engineer can approve MR
- [ ] Engineer can reject MR with remarks
- [ ] Owner can approve engineer-approved MR
- [ ] Owner can reject engineer-approved MR with remarks
- [ ] Cannot skip approval steps

### Purchase Order Flow
- [ ] Purchase Manager can create PO only after Owner approval
- [ ] Cannot create PO without Owner approval
- [ ] PO links to correct MR
- [ ] MR status updates to PO_CREATED

### GRN Flow
- [ ] Field Manager can create GRN
- [ ] Cannot create GRN without PO
- [ ] PO status updates to GRN_CONFIRMED
- [ ] Received quantities tracked correctly

### Bill Flow
- [ ] Cannot create bill without GRN (except manual bills)
- [ ] GST auto-calculates correctly
- [ ] Engineer can approve bill
- [ ] Owner can view approved bills
- [ ] PDF generates correctly

### Security
- [ ] Cross-project access blocked
- [ ] Role permissions enforced
- [ ] Status transitions validated
- [ ] Unauthorized updates rejected

## Deployment Steps

1. **Update Firestore Rules**
   ```bash
   firebase deploy --only firestore:rules
   ```

2. **Update Project Documents**
   - Add `purchaseManagerUid`, `purchaseManagerId`, `purchaseManagerName` fields
   - Run migration script if needed

3. **Create Purchase Manager Users**
   - Register users with role `purchasemanager`
   - Assign to projects

4. **Test Workflow**
   - Create test MR → Engineer approve → Owner approve → Create PO → Create GRN → Create Bill → Engineer approve

5. **Monitor**
   - Check Firestore logs for rule violations
   - Verify status transitions
   - Validate GST calculations

## Future Enhancements

- [ ] Multi-vendor PO comparison
- [ ] Automated PO generation from approved MRs
- [ ] Partial GRN support
- [ ] Bill payment tracking
- [ ] Vendor performance analytics
- [ ] Budget vs actual tracking
- [ ] Material inventory management
- [ ] Automated reorder points

## Notes

- All data is project-scoped
- Status transitions are backend-enforced
- GST is always auto-calculated
- OCR is optional and non-blocking
- Backward compatibility maintained
- Existing flows unchanged
- Complete audit trail maintained
