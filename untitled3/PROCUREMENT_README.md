# Procurement-to-GST-Billing Workflow - Complete Implementation Guide

## 🎯 Overview

This implementation adds a complete procurement workflow to Niramana Setu, including:
- **New Role**: Purchase Manager
- **Status-Driven Workflow**: REQUESTED → ENGINEER_APPROVED → OWNER_APPROVED → PO_CREATED → GRN_CONFIRMED → BILL_GENERATED → BILL_APPROVED
- **Firestore Security**: Role-based access control with status validation
- **GST Compliance**: Auto-calculated GST with legal compliance
- **Complete Audit Trail**: Who approved what and when

## 📁 Files Created

### Models
```
lib/models/
├── material_request_model.dart      # Enhanced MR with approval workflow
├── purchase_order_model.dart        # New PO model
├── grn_model.dart                   # New GRN model
└── gst_bill_model.dart              # Enhanced (updated)

lib/purchase_manager/models/
└── purchase_manager_profile.dart    # Purchase Manager profile

lib/common/models/
├── user_model.dart                  # Updated with Purchase Manager role
└── project_model.dart               # Updated with Purchase Manager fields
```

### Services
```
lib/services/
├── procurement_service.dart         # Complete workflow management
└── procurement_migration_service.dart # Migration utilities

lib/purchase_manager/services/
└── purchase_manager_profile_service.dart # Profile management
```

### Security & Configuration
```
untitled3/
└── firestore.rules                  # Complete security rules
```

### Documentation
```
untitled3/
├── PROCUREMENT_WORKFLOW_IMPLEMENTATION.md  # Detailed workflow guide
├── IMPLEMENTATION_SUMMARY.md               # What's done, what's needed
├── STATUS_FLOW_REFERENCE.md                # Quick reference guide
└── PROCUREMENT_README.md                   # This file
```

## 🚀 Quick Start

### 1. Deploy Firestore Rules
```bash
cd untitled3
firebase deploy --only firestore:rules
```

### 2. Run Migration (Optional)
```dart
import 'package:untitled3/services/procurement_migration_service.dart';

// Add Purchase Manager fields to existing projects
await ProcurementMigrationService.migrateProjectsForPurchaseManager();

// Validate migration
final result = await ProcurementMigrationService.validateMigration();
print('Migration complete: ${result['isComplete']}');
```

### 3. Create Purchase Manager User
```dart
// 1. Register user with Firebase Auth
final userCredential = await FirebaseAuth.instance
    .createUserWithEmailAndPassword(
      email: 'pm@example.com',
      password: 'securePassword',
    );

// 2. Create user document with role
await FirebaseFirestore.instance
    .collection('users')
    .doc(userCredential.user!.uid)
    .set({
      'name': 'John Doe',
      'email': 'pm@example.com',
      'role': 'purchasemanager',
      'publicId': 'pman1234',
      'createdAt': Timestamp.now(),
    });

// 3. Create profile
final profile = PurchaseManagerProfile(
  uid: userCredential.user!.uid,
  name: 'John Doe',
  email: 'pm@example.com',
  phone: '+91-9876543210',
  companyName: 'ABC Procurement',
  experience: '5 years',
  specialization: 'Construction Materials',
  certifications: ['ISO 9001', 'CIPS Level 4'],
  createdAt: DateTime.now(),
);

await PurchaseManagerProfileService.saveProfile(profile);
```

### 4. Assign to Project
```dart
await ProcurementMigrationService.assignPurchaseManagerToProject(
  projectId: 'project123',
  purchaseManagerUid: userCredential.user!.uid,
  purchaseManagerPublicId: 'pman1234',
  purchaseManagerName: 'John Doe',
);
```

## 📊 Workflow Example

### Complete Flow
```dart
// 1. Field Manager creates Material Request
final mr = MaterialRequestModel(
  id: '',
  projectId: 'project123',
  createdBy: managerUid,
  createdAt: DateTime.now(),
  materials: [
    MaterialItem(name: 'Cement', quantity: 100, unit: 'bags'),
    MaterialItem(name: 'Steel TMT', quantity: 2.5, unit: 'tons'),
  ],
  priority: 'High',
  neededBy: DateTime.now().add(Duration(days: 3)),
  notes: 'For level 12 slab work',
);

final mrId = await ProcurementService.createMaterialRequest(mr);
print('✅ MR Created: $mrId');

// 2. Engineer approves MR
await ProcurementService.engineerApproveMR(mrId);
print('✅ Engineer Approved');

// 3. Owner approves MR (Financial approval)
await ProcurementService.ownerApproveMR(mrId);
print('✅ Owner Approved');

// 4. Purchase Manager creates PO
final po = PurchaseOrderModel(
  id: '',
  projectId: 'project123',
  mrId: mrId,
  createdBy: pmUid,
  createdAt: DateTime.now(),
  vendorName: 'ABC Traders',
  vendorGSTIN: '29ABCDE1234F1Z5',
  vendorAddress: '123 Main St, Bangalore',
  vendorContact: '+91-9876543210',
  items: [
    POItem(
      materialName: 'Cement',
      quantity: 100,
      unit: 'bags',
      rate: 350,
      amount: 35000,
    ),
    POItem(
      materialName: 'Steel TMT',
      quantity: 2.5,
      unit: 'tons',
      rate: 55000,
      amount: 137500,
    ),
  ],
  gstType: 'CGST_SGST',
  totalAmount: 203550, // Base: 172500 + GST: 31050
  poNumber: 'PO-2024-001',
);

final poId = await ProcurementService.createPurchaseOrder(po);
print('✅ PO Created: $poId');

// 5. Field Manager confirms GRN (after delivery)
final grn = GRNModel(
  id: '',
  projectId: 'project123',
  poId: poId,
  verifiedBy: managerUid,
  verifiedAt: DateTime.now(),
  receivedItems: [
    GRNItem(
      materialName: 'Cement',
      orderedQuantity: 100,
      receivedQuantity: 98,
      unit: 'bags',
      isComplete: false,
    ),
    GRNItem(
      materialName: 'Steel TMT',
      orderedQuantity: 2.5,
      receivedQuantity: 2.5,
      unit: 'tons',
      isComplete: true,
    ),
  ],
  deliveryChallanNumber: 'DC-2024-001',
  deliveryDate: DateTime.now(),
  notes: '2 cement bags damaged during transport',
);

final grnId = await ProcurementService.createGRN(grn);
print('✅ GRN Confirmed: $grnId');

// 6. Field Manager creates Bill
final bill = GSTBillModel(
  id: '',
  projectId: 'project123',
  poId: poId,
  grnId: grnId,
  createdBy: managerUid,
  createdAt: DateTime.now(),
  billNumber: 'BILL-2024-001',
  vendorName: 'ABC Traders',
  vendorGSTIN: '29ABCDE1234F1Z5',
  description: 'Cement (98 bags) + Steel TMT (2.5 tons)',
  quantity: 1,
  unit: 'lot',
  rate: 171800,
  baseAmount: 171800,
  gstRate: 18,
  cgstAmount: 15462,
  sgstAmount: 15462,
  igstAmount: 0,
  totalAmount: 202724,
  billSource: 'manual',
);

final billId = await GSTBillService.createBill(bill);
print('✅ Bill Created: $billId');

// 7. Engineer approves Bill
await GSTBillService.approveBill(
  projectId: 'project123',
  billId: billId,
  engineerId: engineerUid,
);
print('✅ Bill Approved');

// 8. Owner views approved bill
final approvedBills = await GSTBillService.getApprovedBills('project123').first;
print('✅ Owner can view ${approvedBills.length} approved bills');
```

## 🔐 Security Rules Summary

### Material Requests
- **Create**: Field Manager only
- **Read**: All project members
- **Approve (Engineer)**: REQUESTED → ENGINEER_APPROVED
- **Approve (Owner)**: ENGINEER_APPROVED → OWNER_APPROVED

### Purchase Orders
- **Create**: Purchase Manager only (requires Owner approval)
- **Read**: All project members
- **Update**: System only (when GRN created)

### GRN
- **Create**: Field Manager only (requires PO)
- **Read**: All project members

### Bills
- **Create**: Field Manager only (requires GRN)
- **Read**: All project members
- **Approve**: Engineer only

## 📱 UI Implementation Needed

### Purchase Manager Dashboard
```dart
// lib/purchase_manager/purchase_manager_dashboard.dart
- View owner-approved MRs
- Create POs
- View PO list
- Track PO status
- Profile management
```

### Screens to Create
1. `create_po_screen.dart` - Create Purchase Order
2. `po_list_screen.dart` - List all POs
3. `po_detail_screen.dart` - PO details
4. `grn_creation_screen.dart` - Create GRN (Field Manager)
5. `mr_approval_screen.dart` - Approve MRs (Engineer)
6. `mr_financial_approval_screen.dart` - Financial approval (Owner)

### Widgets to Create
1. `procurement_chain_widget.dart` - Visual workflow
2. `mr_card_widget.dart` - MR summary card
3. `po_card_widget.dart` - PO summary card
4. `status_timeline_widget.dart` - Status timeline

## 🧪 Testing

### Unit Tests
```dart
// test/models/material_request_model_test.dart
test('MaterialRequestModel serialization', () {
  final mr = MaterialRequestModel(...);
  final json = mr.toFirestore();
  final restored = MaterialRequestModel.fromFirestore(mockDoc);
  expect(restored.id, mr.id);
});

// test/services/procurement_service_test.dart
test('Engineer can approve MR', () async {
  final mrId = await ProcurementService.createMaterialRequest(mr);
  await ProcurementService.engineerApproveMR(mrId);
  final updated = await ProcurementService.getMRById(mrId);
  expect(updated.status, 'ENGINEER_APPROVED');
});
```

### Integration Tests
```dart
// integration_test/procurement_workflow_test.dart
testWidgets('Complete procurement workflow', (tester) async {
  // Create MR
  // Engineer approve
  // Owner approve
  // Create PO
  // Create GRN
  // Create Bill
  // Engineer approve bill
  // Verify complete
});
```

## 📈 Monitoring

### Firestore Console
Monitor these collections:
- `material_requests` - Check status distribution
- `purchase_orders` - Track PO creation rate
- `grn` - Monitor delivery confirmations
- `bills` - Track billing cycle

### Analytics Events
```dart
// Track workflow progression
FirebaseAnalytics.instance.logEvent(
  name: 'mr_created',
  parameters: {'project_id': projectId, 'priority': priority},
);

FirebaseAnalytics.instance.logEvent(
  name: 'po_created',
  parameters: {'project_id': projectId, 'vendor': vendorName},
);
```

## 🐛 Troubleshooting

### Common Issues

#### "Permission denied" errors
```
Solution: 
1. Check Firestore rules are deployed
2. Verify user role in users collection
3. Confirm user is project member
4. Check status transition is valid
```

#### "Invalid status transition"
```
Solution:
1. Check current status
2. Verify previous steps completed
3. Ensure correct role for action
4. Check Firestore console for actual status
```

#### "Cannot create PO: MR not owner-approved"
```
Solution:
1. Verify MR status is OWNER_APPROVED
2. Check both engineer and owner approved
3. Ensure no rejection in workflow
```

## 📚 Additional Resources

- **Workflow Details**: See `PROCUREMENT_WORKFLOW_IMPLEMENTATION.md`
- **Status Reference**: See `STATUS_FLOW_REFERENCE.md`
- **Implementation Status**: See `IMPLEMENTATION_SUMMARY.md`
- **GST Billing**: See `GST_BILLING_IMPLEMENTATION.md`

## 🔄 Migration Guide

### From Legacy Material Requests
```dart
// Option 1: Keep both systems running
// - New MRs use top-level collection
// - Old MRs stay in subcollections
// - UI determines which to use

// Option 2: Migrate all to top-level
await ProcurementMigrationService.migrateMaterialRequestsToTopLevel();
```

### Rollback Plan
```dart
// If needed, rollback migration
await ProcurementMigrationService.rollbackMigration();
```

## 🎓 Training Materials

### For Field Managers
1. How to create Material Requests
2. How to confirm GRN
3. How to create bills linked to PO/GRN

### For Engineers
1. How to review and approve MRs
2. How to review and approve bills
3. How to track procurement status

### For Owners
1. How to financially approve MRs
2. How to view approved bills
3. How to download reports

### For Purchase Managers
1. How to view approved MRs
2. How to create Purchase Orders
3. How to track PO status
4. How to manage vendor details

## 📞 Support

For issues or questions:
1. Check documentation files
2. Review Firestore rules
3. Check service code
4. Verify status flow
5. Contact development team

## 🚀 Future Enhancements

- [ ] Multi-vendor PO comparison
- [ ] Automated PO generation
- [ ] Partial GRN support
- [ ] Payment tracking
- [ ] Vendor performance analytics
- [ ] Budget vs actual tracking
- [ ] Material inventory management
- [ ] Automated reorder points
- [ ] Mobile notifications for approvals
- [ ] Email notifications
- [ ] WhatsApp integration
- [ ] Vendor portal

## ✅ Deployment Checklist

- [ ] Firestore rules deployed
- [ ] Indexes created
- [ ] Migration run (if needed)
- [ ] Purchase Manager users created
- [ ] Users assigned to projects
- [ ] UI screens implemented
- [ ] Navigation updated
- [ ] Testing completed
- [ ] Documentation reviewed
- [ ] Team trained
- [ ] Monitoring setup
- [ ] Backup plan ready

## 📝 Version History

### v1.0.0 (Current)
- Initial implementation
- Complete workflow
- Firestore security rules
- Migration utilities
- Documentation

---

**Last Updated**: January 2025
**Status**: Backend Complete, UI Pending
**Next Steps**: Implement UI screens
