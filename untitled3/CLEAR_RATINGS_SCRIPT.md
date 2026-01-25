# Clear Ratings Script - Reset Rating Data for Testing

## Option 1: Manual Firestore Console Method (Recommended)

### Step 1: Open Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Firestore Database**

### Step 2: Clear Simple Ratings
1. Go to `projects/{your-project-id}/ratings`
2. Delete all documents in this collection
3. This clears the "Rate Team" ratings

### Step 3: Clear Comprehensive Ratings  
1. Go to `projects/{your-project-id}/comprehensive_ratings`
2. Delete all documents in this collection
3. This clears the "Rate Engineer Performance" ratings

### Step 4: Clear Impression Notifications (Optional)
1. Go to `users/{your-user-id}/impressions`
2. Delete rating-related impression documents
3. This clears the notification history

## Option 2: Flutter Code Method

I can create a temporary admin function to clear ratings programmatically.

## Option 3: Quick Test Method

Since we're in debug mode, the rating cards will show regardless of previous ratings. You can:
1. Submit new ratings (they'll create new documents)
2. Test the full flow without clearing old data
3. Clear data later when needed

## What Gets Cleared

### Simple Ratings (Rate Team):
- Path: `/projects/{projectId}/ratings/{ratingId}`
- Fields: `ratedUserUid`, `ratedByUid`, `rating`, `comment`, etc.

### Comprehensive Ratings (Rate Engineer):
- Path: `/projects/{projectId}/comprehensive_ratings/{ratingId}`
- Fields: `engineerUid`, `ratedByUid`, `deadlineRating`, `qualityRating`, etc.

### Impressions (Notifications):
- Path: `/users/{userId}/impressions/{impressionId}`
- Fields: `type: "rating_received"`, `projectId`, `rating`, etc.

## After Clearing Data

1. ✅ Rating cards will still show (debug mode)
2. ✅ You can submit new ratings
3. ✅ Fresh impression notifications will be created
4. ✅ Rating history will be reset

## Need Help?

If you want me to create a specific clearing function or need help with the Firestore console, let me know!