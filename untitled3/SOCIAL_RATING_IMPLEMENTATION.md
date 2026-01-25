# Social Rating System Implementation

## Overview
Successfully extended the existing social feature to make profile cards clickable and added a dynamic rating system where authorized users can rate others within shared projects.

## Features Implemented

### 1. Clickable Social Profile Cards
- **Updated SocialUserCard widget** to accept an `onTap` callback
- **Added rating display** in the card showing average rating and count
- **Added navigation indicator** (arrow icon) when card is clickable
- **Maintained existing UI design** without breaking changes

### 2. Profile Detail Screen
- **New ProfileDetailScreen** (`lib/common/screens/profile_detail_screen.dart`)
- **Displays comprehensive user information:**
  - Name, role, public ID
  - Average rating with star visualization
  - Active and completed projects
  - Rating count and average
- **Interactive rating button** for authorized users
- **Real-time rating updates** using Firestore streams

### 3. Dynamic Rating System
- **Rating scale:** 1-10 (as specified)
- **Authorization rules:**
  - Only Owners and Engineers can rate
  - Managers cannot rate
  - Cannot rate self
  - One rating per project per user
- **Rating data model:** `RatingModel` with project-scoped storage
- **Aggregate calculations:** Automatic average and count updates

### 4. Rating Service
- **New RatingService** (`lib/services/rating_service.dart`)
- **Core functions:**
  - `canCurrentUserRate()` - Role-based authorization
  - `hasUserRatedInProject()` - Duplicate prevention
  - `submitRating()` - Rating submission with validation
  - `getProjectsForRating()` - Available projects for rating
  - `_updateUserAggregateRating()` - Automatic aggregate updates

### 5. Data Models
- **Enhanced UserModel** with rating fields:
  - `ratingAvg: double` (0.0 to 10.0)
  - `ratingCount: int` (total ratings received)
- **New RatingModel** for individual ratings:
  - Stored per project: `/projects/{projectId}/ratings/{ratingId}`
  - Fields: ratedUserUid, ratedByUid, ratedByRole, rating, projectId, createdAt

## Navigation Flow

### Social Screen → Profile Detail
1. User taps on any social profile card
2. Navigates to `ProfileDetailScreen` with `ratedUserUid`
3. Screen loads user data, projects, and rating information
4. Shows "Rate User" button if authorized

### Rating Flow
1. User taps "Rate User" button or star icon
2. Rating dialog opens with:
   - Project selection dropdown (shared projects only)
   - Rating slider (1-10)
   - Visual feedback
3. Validates permissions and duplicates
4. Saves rating to project's ratings subcollection
5. Updates user's aggregate rating fields
6. Shows success/error feedback

## Security & Validation

### Role-Based Access Control
- **Owners (ownerclient):** ✅ Can rate
- **Engineers (projectengineer):** ✅ Can rate  
- **Managers (fieldmanager):** ❌ Cannot rate
- **Self-rating:** ❌ Prevented

### Duplicate Prevention
- Checks existing ratings per project before allowing new ones
- One rating per user per project enforced at service level

### Data Integrity
- Server-side timestamp for rating creation
- Automatic aggregate recalculation on each new rating
- Error handling for failed operations

## File Structure

```
lib/
├── models/
│   └── rating_model.dart                    # NEW: Rating data model
├── services/
│   └── rating_service.dart                  # NEW: Rating business logic
├── common/
│   ├── models/
│   │   ├── user_model.dart                  # UPDATED: Added rating fields
│   │   └── user_model.g.dart                # UPDATED: Hive adapter
│   ├── screens/
│   │   └── profile_detail_screen.dart       # NEW: Profile detail with rating
│   └── widgets/
│       └── social_user_card.dart            # UPDATED: Made clickable
├── manager/manager.dart                     # UPDATED: Added navigation
├── owner/owner.dart                         # UPDATED: Added navigation
└── engineer/engineer_dashboard.dart         # UPDATED: Added navigation
```

## Database Schema

### Firestore Structure
```
/projects/{projectId}/ratings/{ratingId}
{
  ratedUserUid: string,
  ratedByUid: string,
  ratedByRole: string,
  rating: number (1-10),
  projectId: string,
  createdAt: serverTimestamp
}

/users/{userId}
{
  // existing fields...
  ratingAvg: number (0.0-10.0),
  ratingCount: number
}
```

## Usage Examples

### For Owners
- Can see and rate Engineers in their projects
- Rating appears immediately in social cards
- Can rate same engineer in different projects

### For Engineers  
- Can see and rate Owners and Managers in their projects
- Cannot rate other Engineers (per visibility rules)
- Ratings help build professional reputation

### For Managers
- Can view all profiles and ratings
- Cannot submit ratings (view-only access)
- Can see who has been rated in their projects

## Testing Checklist

- [x] Social cards are clickable and navigate correctly
- [x] Profile detail screen loads user information
- [x] Rating dialog shows only shared projects
- [x] Role-based rating permissions work
- [x] Duplicate rating prevention works
- [x] Self-rating is prevented
- [x] Aggregate ratings update correctly
- [x] Real-time updates work
- [x] Error handling for failed operations
- [x] UI maintains existing design consistency

## Future Enhancements

1. **Rating Comments:** Add optional text feedback with ratings
2. **Rating History:** Show detailed rating breakdown per project
3. **Rating Analytics:** Dashboard for rating trends and insights
4. **Rating Notifications:** Notify users when they receive ratings
5. **Rating Filters:** Filter social profiles by rating ranges
6. **Rating Export:** Export rating data for reporting

## Compatibility

- ✅ Maintains existing social feature functionality
- ✅ Preserves existing UI/UX design
- ✅ Compatible with offline-first architecture
- ✅ Respects existing Firestore security rules
- ✅ Works with existing role-based visibility system

The implementation successfully extends the social feature while maintaining backward compatibility and following the existing architectural patterns.