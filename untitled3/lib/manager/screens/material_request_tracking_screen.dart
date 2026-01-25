import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../models/material_request_model.dart';
import '../../services/procurement_service.dart';
import '../../common/project_context.dart';
import 'package:intl/intl.dart';

/// Material Request Tracking Screen - For Field Managers to track MR status
class MaterialRequestTrackingScreen extends StatefulWidget {
  const MaterialRequestTrackingScreen({super.key});

  @override
  State<MaterialRequestTrackingScreen> createState() => _MaterialRequestTrackingScreenState();
}

class _MaterialRequestTrackingScreenState extends State<MaterialRequestTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectId = ProjectContext.activeProjectId;
    if (projectId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Material Request Tracking')),
        body: const Center(child: Text('Please select a project first')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Material Request Tracking'),
        backgroundColor: const Color(0xFF136DEC),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.list_outlined)),
            Tab(text: 'Pending', icon: Icon(Icons.hourglass_empty)),
            Tab(text: 'Approved', icon: Icon(Icons.check_circle_outline)),
            Tab(text: 'Rejected', icon: Icon(Icons.cancel_outlined)),
            Tab(text: 'PO Created', icon: Icon(Icons.receipt_outlined)),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllMRsTab(projectId),
          _buildStatusTab(projectId, 'REQUESTED'),
          _buildApprovedTab(projectId),
          _buildStatusTab(projectId, 'REJECTED'),
          _buildStatusTab(projectId, 'PO_CREATED'),
        ],
      ),
    );
  }

  Widget _buildAllMRsTab(String projectId) {
    return StreamBuilder<List<MaterialRequestModel>>(
      stream: ProcurementService.getProjectMRs(projectId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final mrs = snapshot.data ?? [];
        if (mrs.isEmpty) {
          return const Center(child: Text('No material requests found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: mrs.length,
          itemBuilder: (context, index) => _buildMRCard(mrs[index]),
        );
      },
    );
  }

  Widget _buildStatusTab(String projectId, String status) {
    return StreamBuilder<List<MaterialRequestModel>>(
      stream: ProcurementService.getMRsByStatus(projectId, status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final mrs = snapshot.data ?? [];
        if (mrs.isEmpty) {
          return Center(
            child: Text('No ${status.toLowerCase().replaceAll('_', ' ')} requests'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: mrs.length,
          itemBuilder: (context, index) => _buildMRCard(mrs[index]),
        );
      },
    );
  }

  Widget _buildApprovedTab(String projectId) {
    return StreamBuilder<List<MaterialRequestModel>>(
      stream: ProcurementService.getProjectMRs(projectId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allMrs = snapshot.data ?? [];
        final approvedMrs = allMrs
            .where((mr) =>
                mr.status == 'ENGINEER_APPROVED' || mr.status == 'OWNER_APPROVED')
            .toList();

        if (approvedMrs.isEmpty) {
          return const Center(child: Text('No approved requests'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: approvedMrs.length,
          itemBuilder: (context, index) => _buildMRCard(approvedMrs[index]),
        );
      },
    );
  }

  Widget _buildMRCard(MaterialRequestModel mr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ExpansionTile(
              title: Row(
                children: [
                  _buildStatusBadge(mr.status),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MR ID: ${mr.id.substring(0, 8)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Priority: ${mr.priority}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _getPriorityColor(mr.priority),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                'Needed by: ${DateFormat('dd MMM yyyy').format(mr.neededBy)}',
                style: const TextStyle(fontSize: 12),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Materials:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...mr.materials.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• ${item.name}: ${item.quantity} ${item.unit}'),
                      )),
                      const SizedBox(height: 16),
                      _buildApprovalTimeline(mr),
                      if (mr.notes != null && mr.notes!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Notes:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(mr.notes!),
                      ],
                      if (mr.engineerRemarks != null && mr.engineerRemarks!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Engineer Remarks:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(mr.engineerRemarks!),
                            ],
                          ),
                        ),
                      ],
                      if (mr.ownerRemarks != null && mr.ownerRemarks!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Owner Remarks:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(mr.ownerRemarks!),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case 'REQUESTED':
        bgColor = Colors.blue;
        textColor = Colors.white;
        icon = Icons.hourglass_empty;
        break;
      case 'ENGINEER_APPROVED':
        bgColor = Colors.orange;
        textColor = Colors.white;
        icon = Icons.engineering;
        break;
      case 'OWNER_APPROVED':
        bgColor = Colors.green;
        textColor = Colors.white;
        icon = Icons.check_circle;
        break;
      case 'PO_CREATED':
        bgColor = Colors.purple;
        textColor = Colors.white;
        icon = Icons.receipt;
        break;
      case 'REJECTED':
        bgColor = Colors.red;
        textColor = Colors.white;
        icon = Icons.cancel;
        break;
      default:
        bgColor = Colors.grey;
        textColor = Colors.white;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 16),
          const SizedBox(width: 4),
          Text(
            status.replaceAll('_', ' '),
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalTimeline(MaterialRequestModel mr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Approval Timeline:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildTimelineStep(
          'Created',
          DateFormat('dd MMM, hh:mm a').format(mr.createdAt),
          true,
        ),
        _buildTimelineConnector(mr.engineerApproved),
        _buildTimelineStep(
          'Engineer Review',
          mr.engineerApprovedAt != null
              ? DateFormat('dd MMM, hh:mm a').format(mr.engineerApprovedAt!)
              : 'Pending',
          mr.engineerApproved,
        ),
        _buildTimelineConnector(mr.ownerApproved),
        _buildTimelineStep(
          'Owner Approval',
          mr.ownerApprovedAt != null
              ? DateFormat('dd MMM, hh:mm a').format(mr.ownerApprovedAt!)
              : 'Pending',
          mr.ownerApproved,
        ),
      ],
    );
  }

  Widget _buildTimelineStep(String label, String time, bool completed) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed ? Colors.green : Colors.grey[300],
            border: Border.all(
              color: completed ? Colors.green : Colors.grey[400]!,
              width: 2,
            ),
          ),
          child: completed
              ? const Icon(Icons.check, color: Colors.white, size: 14)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineConnector(bool completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Center(
              child: Container(
                width: 2,
                height: 16,
                color: completed ? Colors.green : Colors.grey[300],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
