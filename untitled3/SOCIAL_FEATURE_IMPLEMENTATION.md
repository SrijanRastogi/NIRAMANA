# Social Feature Implementation - Role-Based Professional Discovery

## Overview
Implemented a read-only professional directory feature that displays user profiles based on role-based visibility rules. This is NOT a social media feed - it's a professional discovery layer for finding team members.

## Architecture

### Service Layer
**`lib/services/social_service.dart`**
- `getCurrentUserRole()` - Fetches current user's role from Firestore
- `getVisibleUsers()` - Returns real-time stream of visible users based on role
- `getVisibleUsersByRole(String role)` - Optimized version when role is already known

### Widget Layer
**`lib/common/widgets/social_user_card.dart`**
- Reusable card component for displaying user profiles
- Shows: Name, Role badge, Public ID, Join date
- Consistent styling across all dashboards

### Screen Updates
- **Owner**: `lib/owner/owner.dart` - `_SocialTab` class
- **Manager**: `lib/manager/manager.dart` - `ManagerSocialScreen` class  
- **Engineer**: `lib/engineer/engineer_dashboard.dart` - `EngineerSocialScreen` class

## Role-Based Visibility Rules

### Owner Dashboard → Social Tab
**Query:**
```dart
Firestore.instance
  .collection('users')
  .where('role', isEqualTo: 'engineer')
  .orderBy('createdAt', descending: true)
```
- ✅ Shows: All Engineers
- ❌ Hides: Managers, Other Owners

### Manager Dashboard → Social Tab
**Query:**
```dart
Firestore.instance
  .collection('users')
  .where('role', isEqualTo: 'engineer')
  .orderBy('createdAt', descending: true)
```
- ✅ Shows: All Engineers
- ❌ Hides: Owners, Other Managers

### Engineer Dashboard → Social Tab
**Query:**
```dart
Firestore.instance
  .collection('users')
  .where('role', whereIn: ['owner', 'ownerClient', 'manager', 'fieldManager'])
  .orderBy('createdAt', descending: true)
```
- ✅ Shows: All Owners and Managers
- ❌ Hides: Other Engineers

## Implementation Details

### Query Logic
1. **Get Current User Role**: Reads `/users/{currentUserId}` to determine role
2. **Build Query**: Constructs Firestore query based on role
3. **Real-Time Stream**: Uses `.snapshots()` for live updates
4. **Filter Current User**: Excludes logged-in user from results
5. **Sort**: Orders by `createdAt` descending (newest first)

### Role Handling
The service handles multiple role name variations:
- `owner` / `ownerClient` → treated as Owner
- `manager` / `fieldManager` → treated as Manager
- `engineer` / `projectEngineer` → treated as Engineer

### Data Flow
```
User Opens Social Tab
    ↓
SocialService.getVisibleUsers()
    ↓
Get Current User Role (one-time Firestore read)
    ↓
Build Query Based on Role
    ↓
Stream Real-Time Results
    ↓
Filter Out Current User
    ↓
Display in ListView with SocialUserCard
```

## UI States Handled

1. **Loading**: Shows `CircularProgressIndicator`
2. **Empty**: Shows "No profiles available yet" message
3. **Error**: Shows readable error text with icon
4. **Success**: Displays list of user cards

## Security & Performance

### Security
- ✅ Uses existing Firestore rules: `allow list: if request.auth != null;`
- ✅ No new collections created
- ✅ No rule changes required
- ✅ Query-level filtering (server-side)

### Performance
- ✅ Real-time updates via streams
- ✅ Single role lookup per session (cached in service)
- ✅ Efficient Firestore queries with indexes
- ✅ Client-side filtering only for current user exclusion

## Firestore Index Requirements

### Required Composite Index
For Engineer query (whereIn + orderBy):
```
Collection: users
Fields: role (Ascending), createdAt (Descending)
```

**Note**: Firestore will automatically prompt to create this index when the query is first executed. Click the link in the error message to create it.

### Existing Indexes (Should Already Exist)
- `users` collection: `role` + `createdAt` (for Owner/Manager queries)

## Testing Checklist

- [ ] Owner sees only Engineers
- [ ] Manager sees only Engineers  
- [ ] Engineer sees Owners and Managers
- [ ] Current user never appears in their own list
- [ ] New users appear automatically (real-time)
- [ ] Empty state shows when no users match
- [ ] Error state shows on Firestore errors
- [ ] Results sorted by newest first
- [ ] Role badges display correctly
- [ ] Public IDs display correctly

## Future Enhancements (Not Implemented)

- User profile detail view
- Search/filter functionality
- Project-based filtering
- Contact/communication features
- Profile photos
- Activity status indicators

## Notes

- **No Project Context Required**: Social feature works independently of project selection
- **Automatic Updates**: New user accounts automatically appear when created
- **Read-Only**: No posting, chat, or interaction features
- **Scalable**: Query-level filtering ensures performance at scale
- **Future-Ready**: Architecture supports easy addition of features later

## Code Locations

- Service: `lib/services/social_service.dart`
- Widget: `lib/common/widgets/social_user_card.dart`
- Owner Screen: `lib/owner/owner.dart` (line ~855)
- Manager Screen: `lib/manager/manager.dart` (line ~484)
- Engineer Screen: `lib/engineer/engineer_dashboard.dart` (line ~1105)
