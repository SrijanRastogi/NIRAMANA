# Cash Estimation - Usage Guide

## For Owners

### Initial Setup

1. **Navigate to Cash Estimation**
   - Open your project from the Owner Dashboard
   - Tap on "Milestones" from the action cards
   - Select "Cash Estimation"

2. **Configure Your Project**
   - On first visit, you'll see "Configuration Required"
   - Tap "Configure Now" or the settings icon (⚙️)
   - Enter:
     - Total Number of Floors (e.g., 3)
     - Total Estimated Cost (e.g., 5000000)
   - Tap "Save"

3. **View Real-Time Estimation**
   - Total Estimated Cost: Your configured amount
   - Utilized Amount: Cost of completed floors
   - Remaining Amount: What's left to spend
   - Progress bar shows completion percentage

### Managing Floors

1. **Access Floor Management**
   - From Owner Dashboard (with project selected)
   - Tap "Floor Management" action card

2. **Update Floor Status**
   - See list of all floors
   - Tap menu icon (⋮) on any floor
   - Select status:
     - **Pending**: Not started
     - **In Progress**: Currently under construction
     - **Completed**: Finished (counts toward utilized amount)

3. **Track Progress**
   - Completed floors automatically update cash estimation
   - View completion dates for finished floors
   - Monitor real-time cost utilization

### Understanding the Calculations

**Cost Per Floor**
```
Cost per floor = Total Estimated Cost ÷ Total Floors
```

**Utilized Amount**
```
Utilized = Number of Completed Floors × Cost per Floor
```

**Remaining Amount**
```
Remaining = Total Estimated Cost - Utilized Amount
```

**Example:**
- Total Floors: 3
- Total Cost: ₹60,00,000
- Cost per Floor: ₹20,00,000
- Completed Floors: 1
- Utilized: ₹20,00,000
- Remaining: ₹40,00,000
- Progress: 33.3%

### Reconfiguring

1. **Change Configuration**
   - Open Cash Estimation screen
   - Tap settings icon (⚙️)
   - You'll see a confirmation dialog
   - Enter new values
   - Tap "Save"

2. **Important Notes**
   - Reconfiguration affects all calculations
   - Existing floor statuses are preserved
   - New floors are auto-created if you increase count

### Tips

- **Accurate Estimates**: Enter realistic total cost for better tracking
- **Regular Updates**: Mark floors as completed promptly
- **Monitor Progress**: Check cash estimation regularly
- **Budget Planning**: Use remaining amount for financial planning

## For Engineers, Managers, Purchase Managers

### Access Restrictions

Cash Estimation is **Owner-Only**. If you try to access it, you'll see:

```
🔒 Owner Access Only

Cash estimation is only available to project owners.
```

This is intentional for financial privacy and control.

### Alternative Views

- **Engineers**: Focus on project details and approvals
- **Managers**: Track DPRs and material requests
- **Purchase Managers**: Handle procurement and billing

## Troubleshooting

### "Configuration Required" Message
**Solution**: Configure the project with total floors and estimated cost.

### Calculations Not Updating
**Solution**: 
1. Check floor status in Floor Management
2. Ensure floors are marked "completed" (not just "in progress")
3. Refresh the screen

### Can't Access Cash Estimation
**Solution**: 
1. Verify you're logged in as Owner
2. Ensure a project is selected
3. Check your user role in profile

### Wrong Cost Calculations
**Solution**:
1. Verify configuration (settings icon)
2. Check number of completed floors
3. Recalculate: completedFloors × (totalCost / totalFloors)

## Best Practices

1. **Configure Early**: Set up cash estimation when project starts
2. **Be Realistic**: Use accurate cost estimates
3. **Update Regularly**: Mark floors complete as work finishes
4. **Review Often**: Check estimation weekly for budget tracking
5. **Document Changes**: Note why you reconfigure (if needed)

## Data Privacy

- Only project owners can view cash estimation
- Financial data is project-scoped
- No data is shared with other roles
- All calculations are transparent and audit-ready

## Support

For issues or questions:
1. Check this guide first
2. Verify your role and permissions
3. Ensure project is properly configured
4. Contact system administrator if problems persist
