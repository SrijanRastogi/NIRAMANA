# Procurement Workflow - Status Flow Reference

## Quick Reference

### Status Codes
| Status | Description | Who Can Set | Next Status |
|--------|-------------|-------------|-------------|
| `REQUESTED` | MR created by Field Manager | Field Manager | ENGINEER_APPROVED, REJECTED |
| `ENGINEER_APPROVED` | Engineer approved MR | Engineer | OWNER_APPROVED, REJECTED |
| `OWNER_APPROVED` | Owner approved MR financially | Owner | PO_CREATED |
| `PO_CREATED` | Purchase Manager created PO | Purchase Manager | GRN_CONFIRMED |
| `GRN_CONFIRMED` | Field Manager confirmed delivery | Field Manager | BILL_GENERATED |
| `BILL_GENERATED` | Field Manager created bill | Field Manager | BILL_APPROVED |
| `BILL_APPROVED` | Engineer approved bill | Engineer | (Final) |
| `REJECTED` | Rejected at any approval stage | Engineer/Owner | (Terminal) |

## Workflow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    PROCUREMENT WORKFLOW                          │
└─────────────────────────────────────────────────────────────────┘

1. FIELD MANAGER
   │
   ├─► Creates Material Request (MR)
   │   Status: REQUESTED
   │   Contains: Materials list, quantity, priority, needed-by date
   │
   ▼

2. ENGINEER
   │
   ├─► Reviews MR
   │   ├─► APPROVE → Status: ENGINEER_APPROVED
   │   └─► REJECT → Status: REJECTED (with remarks)
   │
   ▼

3. OWNER
   │
   ├─► Financial Approval
   │   ├─► APPROVE → Status: OWNER_APPROVED
   │   └─► REJECT → Status: REJECTED (with remarks)
   │
   ▼

4. PURCHASE MANAGER
   │
   ├─► Creates Purchase Order (PO)
   │   Status: PO_CREATED
   │   Contains: Vendor details, rates, GST type, total amount
   │   Updates MR Status: PO_CREATED
   │
   ▼

5. FIELD MANAGER
   │
   ├─► Confirms Goods Receipt (GRN)
   │   Status: GRN_CONFIRMED
   │   Contains: Received quantities, delivery challan, discrepancies
   │   Updates PO Status: GRN_CONFIRMED
   │
   ▼

6. FIELD MANAGER
   │
   ├─► Creates Bill
   │   Status: BILL_GENERATED
   │   Contains: Vendor GSTIN, amounts, GST breakdown
   │   Linked to: PO, GRN
   │
   ▼

7. ENGINEER
   │
   ├─► Approves Bill
   │   Status: BILL_APPROVED
   │   Bill becomes visible to Owner
   │
   ▼

8. OWNER
   │
   └─► Views Approved Bills
       Can download PDF invoices
```

## Role Permissions Matrix

| Action | Field Manager | Engineer | Owner | Purchase Manager |
|--------|--------------|----------|-------|------------------|
| Create MR | ✅ | ❌ | ❌ | ❌ |
| Approve MR | ❌ | ✅ | ✅ (after Engineer) | ❌ |
| Reject MR | ❌ | ✅ | ✅ (after Engineer) | ❌ |
| View MRs | ✅ (own) | ✅ (all) | ✅ (all) | ✅ (owner-approved) |
| Create PO | ❌ | ❌ | ❌ | ✅ (after Owner approval) |
| View POs | ✅ | ✅ | ✅ | ✅ |
| Create GRN | ✅ | ❌ | ❌ | ❌ |
| View GRNs | ✅ | ✅ | ✅ | ✅ |
| Create Bill | ✅ (after GRN) | ❌ | ❌ | ❌ |
| Approve Bill | ❌ | ✅ | ❌ | ❌ |
| View Bills | ✅ (own) | ✅ (all) | ✅ (approved) | ✅ (all) |

## Validation Rules

### Material Request (MR)
```
CREATE:
✓ Must be Field Manager
✓ Must be project member
✓ Status must be REQUESTED
✓ engineerApproved must be false
✓ ownerApproved must be false

ENGINEER APPROVE:
✓ Must be Engineer
✓ Must be project member
✓ Current status must be REQUESTED
✓ New status must be ENGINEER_APPROVED
✓ Must set engineerApprovedBy and engineerApprovedAt

OWNER APPROVE:
✓ Must be Owner
✓ Must be project member
✓ Current status must be ENGINEER_APPROVED
✓ New status must be OWNER_APPROVED
✓ Must set ownerApprovedBy and ownerApprovedAt
```

### Purchase Order (PO)
```
CREATE:
✓ Must be Purchase Manager
✓ Must be project member
✓ MR must exist
✓ MR status must be OWNER_APPROVED
✓ PO status must be PO_CREATED
✓ Must have valid vendor GSTIN
✓ Must have items with rates
✓ Total amount must be calculated

UPDATE (when GRN created):
✓ Must be Field Manager
✓ Current status must be PO_CREATED
✓ New status must be GRN_CONFIRMED
```

### Goods Receipt Note (GRN)
```
CREATE:
✓ Must be Field Manager
✓ Must be project member
✓ PO must exist
✓ PO status must be PO_CREATED
✓ GRN status must be GRN_CONFIRMED
✓ Must have received quantities
✓ Must set verifiedBy and verifiedAt
```

### Bill
```
CREATE:
✓ Must be Field Manager
✓ Must be project member
✓ GRN must exist (or null for manual bills)
✓ GRN status must be GRN_CONFIRMED (if GRN exists)
✓ Must have valid vendor GSTIN
✓ GST must be auto-calculated
✓ Status must be BILL_GENERATED

ENGINEER APPROVE:
✓ Must be Engineer
✓ Must be project member
✓ Current status must be BILL_GENERATED
✓ New status must be BILL_APPROVED
✓ Must set approvedBy and approvedAt
```

## Error Messages

### Common Errors
```dart
// User not authenticated
"User not authenticated"

// Not a project member
"Access denied: Not a project member"

// Invalid status transition
"Invalid status transition: Current status is X, cannot change to Y"

// Missing approval
"Cannot create PO: Material Request not owner-approved"
"Cannot create GRN: Purchase Order not in correct status"
"Cannot create bill: GRN not confirmed"

// Permission denied
"Permission denied: Only Field Managers can create Material Requests"
"Permission denied: Only Engineers can approve Material Requests"
"Permission denied: Only Owners can financially approve Material Requests"
"Permission denied: Only Purchase Managers can create Purchase Orders"

// Validation errors
"Invalid GSTIN format"
"GST calculation error"
"Missing required fields"
```

## Code Examples

### Check Current Status
```dart
// Material Request
if (mr.status == 'REQUESTED') {
  // Engineer can approve
}

if (mr.status == 'ENGINEER_APPROVED') {
  // Owner can approve
}

if (mr.status == 'OWNER_APPROVED') {
  // Purchase Manager can create PO
}

// Purchase Order
if (po.status == 'PO_CREATED') {
  // Field Manager can create GRN
}

// Bill
if (bill.status == 'BILL_GENERATED') {
  // Engineer can approve
}
```

### Validate Workflow
```dart
// Before creating PO
final mr = await ProcurementService.getMRById(mrId);
if (mr.status != 'OWNER_APPROVED') {
  throw Exception('Cannot create PO: MR not owner-approved');
}

// Before creating GRN
final po = await ProcurementService.getPOById(poId);
if (po.status != 'PO_CREATED') {
  throw Exception('Cannot create GRN: PO not in correct status');
}

// Before creating Bill
final canCreate = await ProcurementService.canCreateBill(poId);
if (!canCreate) {
  throw Exception('Cannot create bill: GRN not confirmed');
}
```

## Status Colors (UI)

```dart
Color getStatusColor(String status) {
  switch (status) {
    case 'REQUESTED':
      return Colors.orange; // Pending
    case 'ENGINEER_APPROVED':
      return Colors.blue; // In Progress
    case 'OWNER_APPROVED':
      return Colors.purple; // Approved
    case 'PO_CREATED':
      return Colors.indigo; // PO Created
    case 'GRN_CONFIRMED':
      return Colors.teal; // Delivered
    case 'BILL_GENERATED':
      return Colors.amber; // Pending Approval
    case 'BILL_APPROVED':
      return Colors.green; // Complete
    case 'REJECTED':
      return Colors.red; // Rejected
    default:
      return Colors.grey;
  }
}
```

## Status Icons (UI)

```dart
IconData getStatusIcon(String status) {
  switch (status) {
    case 'REQUESTED':
      return Icons.pending_outlined;
    case 'ENGINEER_APPROVED':
      return Icons.engineering_outlined;
    case 'OWNER_APPROVED':
      return Icons.verified_outlined;
    case 'PO_CREATED':
      return Icons.shopping_cart_outlined;
    case 'GRN_CONFIRMED':
      return Icons.inventory_2_outlined;
    case 'BILL_GENERATED':
      return Icons.receipt_outlined;
    case 'BILL_APPROVED':
      return Icons.check_circle_outlined;
    case 'REJECTED':
      return Icons.cancel_outlined;
    default:
      return Icons.help_outline;
  }
}
```

## Timeline View

```dart
List<TimelineStep> getWorkflowTimeline(String currentStatus) {
  return [
    TimelineStep(
      title: 'MR Created',
      status: 'REQUESTED',
      isComplete: true,
      isCurrent: currentStatus == 'REQUESTED',
    ),
    TimelineStep(
      title: 'Engineer Approved',
      status: 'ENGINEER_APPROVED',
      isComplete: ['ENGINEER_APPROVED', 'OWNER_APPROVED', 'PO_CREATED', 
                   'GRN_CONFIRMED', 'BILL_GENERATED', 'BILL_APPROVED']
                  .contains(currentStatus),
      isCurrent: currentStatus == 'ENGINEER_APPROVED',
    ),
    TimelineStep(
      title: 'Owner Approved',
      status: 'OWNER_APPROVED',
      isComplete: ['OWNER_APPROVED', 'PO_CREATED', 'GRN_CONFIRMED', 
                   'BILL_GENERATED', 'BILL_APPROVED']
                  .contains(currentStatus),
      isCurrent: currentStatus == 'OWNER_APPROVED',
    ),
    TimelineStep(
      title: 'PO Created',
      status: 'PO_CREATED',
      isComplete: ['PO_CREATED', 'GRN_CONFIRMED', 'BILL_GENERATED', 
                   'BILL_APPROVED']
                  .contains(currentStatus),
      isCurrent: currentStatus == 'PO_CREATED',
    ),
    TimelineStep(
      title: 'GRN Confirmed',
      status: 'GRN_CONFIRMED',
      isComplete: ['GRN_CONFIRMED', 'BILL_GENERATED', 'BILL_APPROVED']
                  .contains(currentStatus),
      isCurrent: currentStatus == 'GRN_CONFIRMED',
    ),
    TimelineStep(
      title: 'Bill Generated',
      status: 'BILL_GENERATED',
      isComplete: ['BILL_GENERATED', 'BILL_APPROVED']
                  .contains(currentStatus),
      isCurrent: currentStatus == 'BILL_GENERATED',
    ),
    TimelineStep(
      title: 'Bill Approved',
      status: 'BILL_APPROVED',
      isComplete: currentStatus == 'BILL_APPROVED',
      isCurrent: currentStatus == 'BILL_APPROVED',
    ),
  ];
}
```

## Quick Commands

### Get Pending Items by Role

```dart
// Field Manager
final pendingGRNs = await ProcurementService.getPOsPendingGRN(projectId);

// Engineer
final pendingMRs = await ProcurementService.getEngineerPendingMRs(projectId);
final pendingBills = await GSTBillService.getPendingBillsForEngineer(projectId);

// Owner
final pendingMRs = await ProcurementService.getOwnerPendingMRs(projectId);

// Purchase Manager
final approvedMRs = await ProcurementService.getOwnerApprovedMRs(projectId);
```

## Troubleshooting

### Status Not Updating
1. Check Firestore rules are deployed
2. Verify user role in Firestore
3. Check project membership
4. Validate current status before update
5. Check console for rule violations

### Permission Denied
1. Verify user is authenticated
2. Check user role matches required role
3. Verify user is project member
4. Check Firestore rules for the operation

### Invalid Transition
1. Check current status
2. Verify required previous steps completed
3. Check if MR/PO/GRN exists
4. Validate status flow sequence
