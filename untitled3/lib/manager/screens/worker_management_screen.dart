import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../models/worker_model.dart';
import '../../services/worker_service.dart';
import '../../common/project_context.dart';
import 'worker_enrollment_screen.dart';

/// Worker Management Screen - Field Manager Only
/// Lists all workers and allows management
class WorkerManagementScreen extends StatefulWidget {
  const WorkerManagementScreen({super.key});

  @override
  State<WorkerManagementScreen> createState() => _WorkerManagementScreenState();
}

class _WorkerManagementScreenState extends State<WorkerManagementScreen> {
  bool _showInactive = false;

  @override
  Widget build(BuildContext context) {
    final projectId = ProjectContext.activeProjectId;

    if (projectId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Worker Management'),
          backgroundColor: Colors.white.withValues(alpha: 0.55),
          elevation: 0,
        ),
        body: const Center(
          child: Text('No active project selected'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Management'),
        backgroundColor: Colors.white.withValues(alpha: 0.55),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showInactive ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _showInactive = !_showInactive;
              });
            },
            tooltip: _showInactive ? 'Hide Inactive' : 'Show Inactive',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Stats Card
            _buildStatsCard(projectId),
            const SizedBox(height: 8),

            // Workers List
            Expanded(
              child: StreamBuilder<List<WorkerModel>>(
                stream: WorkerService.getActiveWorkersStream(projectId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  var workers = snapshot.data ?? [];

                  if (!_showInactive) {
                    workers = workers.where((w) => w.active).toList();
                  }

                  if (workers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Workers Enrolled',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to enroll your first worker',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: workers.length,
                    itemBuilder: (context, index) {
                      return _WorkerCard(
                        worker: workers[index],
                        projectId: projectId,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const WorkerEnrollmentScreen(),
            ),
          );

          if (result == true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Worker enrolled successfully')),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Enroll Worker'),
        backgroundColor: const Color(0xFF136DEC),
      ),
    );
  }

  Widget _buildStatsCard(String projectId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: WorkerService.getWorkerStats(projectId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Total',
                      stats['total'].toString(),
                      Icons.people,
                      Colors.blue,
                    ),
                    _buildStatItem(
                      'Active',
                      stats['active'].toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                    _buildStatItem(
                      'With Face',
                      stats['withFace'].toString(),
                      Icons.face,
                      Colors.purple,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2937),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _WorkerCard extends StatelessWidget {
  final WorkerModel worker;
  final String projectId;

  const _WorkerCard({
    required this.worker,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: worker.active ? 0.55 : 0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: worker.active 
                    ? Colors.white.withValues(alpha: 0.45)
                    : Colors.grey.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              leading: Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: worker.hasFaceEmbedding
                        ? [Colors.green, Colors.green[700]!]
                        : [Colors.grey, Colors.grey[700]!],
                  ),
                ),
                child: Icon(
                  worker.hasFaceEmbedding ? Icons.face : Icons.person,
                  color: Colors.white,
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      worker.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: worker.active ? const Color(0xFF1F2937) : Colors.grey,
                      ),
                    ),
                  ),
                  if (!worker.active)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Inactive',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    worker.role,
                    style: TextStyle(
                      color: worker.active ? const Color(0xFF6B7280) : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.currency_rupee,
                        size: 14,
                        color: worker.active ? Colors.green : Colors.grey,
                      ),
                      Text(
                        '${worker.dailyWage.toStringAsFixed(0)}/day',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: worker.active ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (worker.hasFaceEmbedding)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.verified, size: 12, color: Colors.green),
                              SizedBox(width: 4),
                              Text(
                                'Face Enrolled',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'deactivate') {
                    await WorkerService.deactivateWorker(projectId, worker.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Worker deactivated')),
                      );
                    }
                  } else if (value == 'reactivate') {
                    await WorkerService.reactivateWorker(projectId, worker.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Worker reactivated')),
                      );
                    }
                  } else if (value == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Worker'),
                        content: Text('Are you sure you want to delete ${worker.displayName}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await WorkerService.deleteWorker(projectId, worker.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Worker deleted')),
                        );
                      }
                    }
                  }
                },
                itemBuilder: (context) => [
                  if (worker.active)
                    const PopupMenuItem(
                      value: 'deactivate',
                      child: Row(
                        children: [
                          Icon(Icons.block, size: 20),
                          SizedBox(width: 8),
                          Text('Deactivate'),
                        ],
                      ),
                    )
                  else
                    const PopupMenuItem(
                      value: 'reactivate',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 20),
                          SizedBox(width: 8),
                          Text('Reactivate'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
