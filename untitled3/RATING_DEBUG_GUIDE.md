# Rating Feature Debug Guide

## Why Rating Cards Might Not Show

The rating cards in the Owner dashboard have specific conditions that must be met:

### Rate Team Card Requirements:
1. ✅ **Project Selected**: `ProjectContext.activeProjectId != null`
2. ✅ **Project Status**: Must be "completed" (case-insensitive)
3. ✅ **Project Exists**: Project document must exist in Firestore

### Comprehensive Engineer Rating Card Requirements:
1. ✅ **Project Selected**: `ProjectContext.activeProjectId != null`
2. ✅ **Engineer Assigned**: Project must have an engineer (`project.createdBy`)
3. ✅ **Owner Permission**: Current user must be project owner
4. ✅ **Not Already Rated**: Owner hasn't rated this engineer yet

## Debug Steps

### Step 1: Check Project Selection
- Open Owner dashboard
- Select a project (rating cards only show AFTER project selection)
- Verify `ProjectContext.activeProjectId` is set

### Step 2: Check Project Status
- Ensure project status is set to "completed"
- Status check is case-insensitive: "completed", "Completed", "COMPLETED" all work

### Step 3: Check Project Engineer
- Verify project has an engineer assigned (`createdBy` field)
- Engineer must exist in users collection

### Step 4: Check Owner Permissions
- Verify current user is the project owner (`ownerUid` field)

## Quick Fix: Add Debug Rating Cards

If you want to test the rating functionality immediately, you can temporarily modify the conditions to always show the cards for testing.