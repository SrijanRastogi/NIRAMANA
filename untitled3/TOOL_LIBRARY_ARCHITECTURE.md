# Tool Library - Architecture Diagram

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     MANAGER DASHBOARD                            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Feature Grid (9 tiles)                                   │  │
│  │  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ │  │
│  │  │Material│ │Attend. │ │  DPR   │ │ Tasks  │ │ Petty  │ │  │
│  │  │Request │ │        │ │        │ │        │ │  Cash  │ │  │
│  │  └────────┘ └────────┘ └────────┘ └────────┘ └────────┘ │  │
│  │  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐            │  │
│  │  │Worker  │ │  Face  │ │Billing │ │  TOOL  │            │  │
│  │  │ Mgmt   │ │  Scan  │ │        │ │LIBRARY │ ◄─── NEW  │  │
│  │  └────────┘ └────────┘ └────────┘ └────────┘            │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    TOOL LIBRARY SCREEN                           │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │  🟢 BORROW TOOL                                     │  │  │
│  │  │  Scan QR and assign tool to worker                 │  │  │
│  │  └────────────────────────────────────────────────────┘  │  │
│  │                                                            │  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │  🟠 RETURN TOOL                                     │  │  │
│  │  │  Scan QR and mark tool as returned                 │  │  │
│  │  └────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
           │                                    │
           │ Borrow                             │ Return
           ▼                                    ▼
```

## Borrow Tool Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  STEP 1: SCAN TOOL QR                                           │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  QR Scanner Screen                                        │  │
│  │  • Camera opens                                           │  │
│  │  • Capture QR image                                       │  │
│  │  • Manual Tool ID input                                   │  │
│  │  • Validate tool exists                                   │  │
│  │  • Check status == AVAILABLE                             │  │
│  │  • Upload image to Cloudinary                            │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 2: BORROWER DETAILS                                       │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Worker Name:     [________________]  (required)          │  │
│  │  Mobile Number:   [__________]        (10 digits)         │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 3: ASSIGN PROJECT & RETURN TIME                           │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Project:         [▼ Select Project]  (dropdown)          │  │
│  │  Return Date:     [📅 Select Date]                        │  │
│  │  Return Time:     [🕐 Select Time]                        │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 4: SUBMIT                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  [✓ Submit Borrow Request]                                │  │
│  │                                                            │  │
│  │  Actions:                                                  │  │
│  │  1. Update tool status → IN_USE                           │  │
│  │  2. Create transaction record                             │  │
│  │  3. Save to Firestore (or Hive if offline)               │  │
│  │  4. Show success message                                  │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Return Tool Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  STEP 1: SCAN TOOL QR                                           │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  QR Scanner Screen                                        │  │
│  │  • Camera opens                                           │  │
│  │  • Capture QR image                                       │  │
│  │  • Manual Tool ID input                                   │  │
│  │  • Fetch active transaction                              │  │
│  │  • Check returnedAt == null                              │  │
│  │  • Display transaction details                           │  │
│  │  • Upload image to Cloudinary                            │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Transaction Details:                                            │
│  • Borrowed by: [Worker Name]                                   │
│  • Mobile: [1234567890]                                         │
│  • Borrowed on: [DD/MM/YYYY]                                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 2: CONDITION CHECK                                         │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Tool Condition: (required)                               │  │
│  │  ○ Good Condition                                         │  │
│  │  ○ Damaged                                                │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 3: SUBMIT                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  [✓ Submit Return]                                        │  │
│  │                                                            │  │
│  │  Actions:                                                  │  │
│  │  1. Update tool status → AVAILABLE                        │  │
│  │  2. Set returnedAt timestamp                              │  │
│  │  3. Save condition                                        │  │
│  │  4. Flag if DAMAGED (engineer review)                     │  │
│  │  5. Save to Firestore (or Hive if offline)               │  │
│  │  6. Show success message                                  │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         UI LAYER                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Tool Library │  │ Borrow Tool  │  │ Return Tool  │          │
│  │   Screen     │  │   Screen     │  │   Screen     │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                 │                 │                    │
└─────────┼─────────────────┼─────────────────┼────────────────────┘
          │                 │                 │
          ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                      SERVICE LAYER                               │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    ToolService                            │  │
│  │  • getToolById()                                          │  │
│  │  • isToolAvailable()                                      │  │
│  │  • getActiveTransaction()                                 │  │
│  │  • borrowTool() / borrowToolOffline()                     │  │
│  │  • returnTool() / returnToolOffline()                     │  │
│  │  • syncOfflineTransactions()                              │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────┬───────────────────────────────────┬───────────────────┘
          │                                   │
          ▼                                   ▼
┌──────────────────────┐          ┌──────────────────────┐
│   ONLINE STORAGE     │          │  OFFLINE STORAGE     │
│  ┌────────────────┐  │          │  ┌────────────────┐  │
│  │   Firestore    │  │          │  │      Hive      │  │
│  │                │  │          │  │                │  │
│  │ tools/         │  │          │  │ offline_tool_  │  │
│  │ tool_trans.../ │  │          │  │ transactions   │  │
│  └────────────────┘  │          │  │                │  │
│                      │          │  │ offline_tool_  │  │
│  ┌────────────────┐  │          │  │ returns        │  │
│  │  Cloudinary    │  │          │  └────────────────┘  │
│  │                │  │          │                      │
│  │ QR Images      │  │          │  Auto-sync when     │
│  └────────────────┘  │          │  online             │
└──────────────────────┘          └──────────────────────┘
```

## State Management

```
┌─────────────────────────────────────────────────────────────────┐
│                    STATE VARIABLES                               │
│  (Declared at top of State class)                               │
│                                                                  │
│  BorrowToolScreen:                                               │
│  • _scannedToolId: String?                                       │
│  • _qrImage: File?                                               │
│  • _selectedProjectId: String?                                   │
│  • _expectedReturnDate: DateTime?                                │
│  • _expectedReturnTime: TimeOfDay?                               │
│  • _isLoading: bool = false                                      │
│  • _isScanning: bool = false                                     │
│  • _projects: List<ProjectModel> = []                            │
│                                                                  │
│  ReturnToolScreen:                                               │
│  • _scannedToolId: String?                                       │
│  • _qrImage: File?                                               │
│  • _activeTransaction: ToolTransactionModel?                     │
│  • _selectedCondition: String?                                   │
│  • _isLoading: bool = false                                      │
│  • _isScanning: bool = false                                     │
│                                                                  │
│  QrScannerScreen:                                                │
│  • _qrImage: File?                                               │
│  • _isLoading: bool = false (final)                              │
└─────────────────────────────────────────────────────────────────┘
```

## Error Handling Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    ERROR SCENARIOS                               │
│                                                                  │
│  Tool Not Available                                              │
│  ├─ Check: isToolAvailable()                                     │
│  ├─ Action: Block borrow flow                                    │
│  └─ Message: "Tool is not available for borrowing"              │
│                                                                  │
│  No Active Transaction                                           │
│  ├─ Check: getActiveTransaction()                                │
│  ├─ Action: Block return flow                                    │
│  └─ Message: "No active transaction found for this tool"        │
│                                                                  │
│  Network Failure                                                 │
│  ├─ Check: Connectivity.checkConnectivity()                      │
│  ├─ Action: Save to Hive (offline mode)                         │
│  └─ Message: "Saved offline - will sync when online"            │
│                                                                  │
│  Validation Errors                                               │
│  ├─ Check: Form validators                                       │
│  ├─ Action: Show inline error                                    │
│  └─ Message: Field-specific error message                        │
│                                                                  │
│  Upload Failure                                                  │
│  ├─ Check: CloudinaryService.uploadImage()                       │
│  ├─ Action: Continue with offline mode                           │
│  └─ Message: "Failed to upload image. Saving offline."          │
└─────────────────────────────────────────────────────────────────┘
```

## Offline Sync Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    OFFLINE SYNC FLOW                             │
│                                                                  │
│  1. User performs action (borrow/return)                         │
│  2. Check connectivity                                           │
│  3. If offline:                                                  │
│     ├─ Save to Hive box                                          │
│     ├─ Mark as isSynced: false                                   │
│     └─ Show "offline - will sync" message                        │
│  4. When connectivity restored:                                  │
│     ├─ ConnectivityService detects online                        │
│     ├─ Call ToolService.syncOfflineTransactions()               │
│     ├─ Process each unsynced transaction                         │
│     ├─ Upload to Firestore                                       │
│     ├─ Remove from Hive on success                               │
│     └─ Retry on failure                                          │
│                                                                  │
│  Hive Boxes:                                                     │
│  • offline_tool_transactions (borrow operations)                 │
│  • offline_tool_returns (return operations)                      │
└─────────────────────────────────────────────────────────────────┘
```

## Security & Permissions

```
┌─────────────────────────────────────────────────────────────────┐
│                    ROLE-BASED ACCESS                             │
│                                                                  │
│  Manager:                                                        │
│  ✅ View Tool Library                                            │
│  ✅ Borrow Tools                                                 │
│  ✅ Return Tools                                                 │
│  ✅ View own transactions                                        │
│                                                                  │
│  Engineer:                                                       │
│  ⏳ View damaged tools (future)                                  │
│  ⏳ Approve repairs (future)                                     │
│                                                                  │
│  Owner:                                                          │
│  ⏳ View all transactions (future)                               │
│  ⏳ Generate reports (future)                                    │
│                                                                  │
│  Purchase Manager:                                               │
│  ❌ No access                                                    │
└─────────────────────────────────────────────────────────────────┘
```

## Performance Optimization

```
┌─────────────────────────────────────────────────────────────────┐
│                    OPTIMIZATION STRATEGIES                       │
│                                                                  │
│  Database:                                                       │
│  • Indexed queries (toolId, projectId, returnedAt)              │
│  • Batch operations for atomicity                               │
│  • Minimal document reads                                        │
│  • Efficient where clauses                                       │
│                                                                  │
│  Network:                                                        │
│  • Image compression before upload                               │
│  • Retry logic with exponential backoff                          │
│  • Offline-first architecture                                    │
│  • Lazy loading of project list                                  │
│                                                                  │
│  UI:                                                             │
│  • Async operations don't block UI                               │
│  • Loading indicators for user feedback                          │
│  • Cached project list                                           │
│  • Efficient widget rebuilds                                     │
└─────────────────────────────────────────────────────────────────┘
```

---

**Architecture Version:** 1.0  
**Last Updated:** January 25, 2026  
**Status:** ✅ PRODUCTION-READY
