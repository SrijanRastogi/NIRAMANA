# Logout Flow Test Guide

## Test the Fixed Logout Navigation Flow

### Test Case 1: Normal Logout Flow
1. **Setup**: Have a user logged into any dashboard (Owner/Engineer/Manager)
2. **Action**: Click logout button
3. **Expected**: Navigate directly to LoginScreen (no onboarding)
4. **Verify**: No language selection, no app introduction

### Test Case 2: Login After Logout
1. **Setup**: After logout, user is on LoginScreen
2. **Action**: Login with valid credentials
3. **Expected**: Navigate directly to appropriate dashboard
4. **Verify**: No onboarding screens shown

### Test Case 3: Invalid Role Handling
1. **Setup**: User with invalid role in Firestore
2. **Action**: Try to login
3. **Expected**: Stay on LoginScreen with error message
4. **Verify**: Does NOT navigate to onboarding

### Test Case 4: Missing Firestore Record
1. **Setup**: User exists in Firebase Auth but not in Firestore
2. **Action**: Try Google sign-in
3. **Expected**: Stay on LoginScreen with error message
4. **Verify**: Does NOT navigate to onboarding

### Test Case 5: First-time User (Control Test)
1. **Setup**: Fresh app install, no previous language selection
2. **Action**: Open app
3. **Expected**: Show language selection → role selection
4. **Verify**: This flow should still work for new users

## Files Modified
- `untitled3/lib/common/services/logout_service.dart` - Fixed import path
- `untitled3/lib/auth/login_screen.dart` - Fixed error handling, removed WelcomeScreen navigation

## Key Changes
- Logout now goes to LoginScreen (not WelcomeScreen)
- LoginScreen errors show messages (not navigate to onboarding)
- Onboarding only shows for first-time users
- Returning users skip onboarding completely