import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../models/material_request_model.dart';
import '../../models/purchase_order_model.dart';
import '../../services/procurement_service.dart';
import '../../common/project_context.dart';
import 'package:intl/intl.dart';
import 'create_po_screen.dart';
import 'po_details_screen.dart';

/// Purchase Manager Dashboard - Complete PO workflow management
class PurchaseManagerDashboard extends StatefulWidget {
  const PurchaseManagerDashboard({super.key});

  @override
  State<PurchaseManagerDashboard> createState() => _PurchaseManagerDashboardState();
}

class _PurchaseManagerDashboardState extends State<PurchaseManagerDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        appBar: AppBar(title: const Text('Purchase Manager')),
        body: const Center(child: Text('Please select a project first')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Purchase Manager'),
            Text(
              ProjectContext.activeProjectName ?? 'Project',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF136DEC),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending MRs', icon: Icon(Icons.pending_actions_outlined)),
            Tab(text: 'Active POs', icon: Icon(Icons.receipt_outlined)),
            Tab(text: 'Completed', icon: Icon(Icons.check_circle_outline)),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingMRsTab(projectId),
          _buildActivePOsTab(projectId),
          _buildCompletedPOsTab(projectId),
        ],
      ),
    );
  }

  Widget _buildPendingMRsTab(String projectId) {
    return StreamBuilder<List<MaterialRequestModel>>(
      stream: ProcurementService.getOwnerApprovedMRs(projectId),
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('No pending Material Requests'),
                const SizedBox(height: 8),
                const Text(
                  'Waiting for Owner approval',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: mrs.length,
          itemBuilder: (context, index) => _buildMRCard(context, mrs[index]),
        );
      },
    );
  }

  Widget _buildActivePOsTab(String projectId) {
    return StreamBuilder<List<PurchaseOrderModel>>(
      stream: ProcurementService.getProjectPOs(projectId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final pos = snapshot.data ?? [];
        final activePOs = pos.where((po) => po.status == 'PO_CREATED').toList();

        if (activePOs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('No active Purchase Orders'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activePOs.length,
          itemBuilder: (context, index) => _buildPOCard(context, activePOs[index]),
        );
      },
    );
  }

  Widget _buildCompletedPOsTab(String projectId) {
    return StreamBuilder<List<PurchaseOrderModel>>(
      stream: ProcurementService.getProjectPOs(projectId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final pos = snapshot.data ?? [];
        final completedPOs = pos.where((po) => po.status == 'GRN_CONFIRMED').toList();

        if (completedPOs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('No completed Purchase Orders'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: completedPOs.length,
          itemBuilder: (context, index) => _buildPOCard(context, completedPOs[index]),
        );
      },
    );
  }

  Widget _buildMRCard(BuildContext context, MaterialRequestModel mr) {
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
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.pending_actions, color: Colors.blue),
              ),
              title: Text(
                'MR ID: ${mr.id.substring(0, 8)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('${mr.materials.length} items • Priority: ${mr.priority}'),
                  Text(
                    'Needed by: ${DateFormat('dd MMM yyyy').format(mr.neededBy)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              trailing: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreatePOScreen(mr: mr),
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create PO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF136DEC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPOCard(BuildContext context, PurchaseOrderModel po) {
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
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt, color: Colors.purple),
              ),
              title: Text(
                po.poNumber ?? 'PO ID: ${po.id.substring(0, 8)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(po.vendorName),
                  Text(
                    '₹ ${po.totalAmount.toStringAsFixed(2)} • ${po.items.length} items',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              trailing: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PODetailsScreen(po: po),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward_ios, size: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
