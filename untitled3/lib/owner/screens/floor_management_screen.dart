import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../services/floor_cash_estimation_service.dart';
import '../../models/floor_model.dart';
import '../../common/project_context.dart';

/// Floor Management Screen - OWNER ONLY
/// Allows owners to view and update floor completion status
class FloorManagementScreen extends StatelessWidget {
  const FloorManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projectId = ProjectContext.activeProjectId;
    
    if (projectId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Floor Management'),
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
        title: const Text('Floor Management'),
        backgroundColor: Colors.white.withValues(alpha: 0.55),
        elevation: 0,
      ),
      body: SafeArea(
        child: StreamBuilder<List<FloorModel>>(
          stream: FloorCashEstimationService().getFloorsStream(projectId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final floors = snapshot.data ?? [];

            if (floors.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.layers_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Floors Configured',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Configure the project in Cash Estimation to create floors.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: floors.length,
              itemBuilder: (context, index) {
                final floor = floors[index];
                return _FloorCard(
                  floor: floor,
                  projectId: projectId,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _FloorCard extends StatelessWidget {
  final FloorModel floor;
  final String projectId;

  const _FloorCard({
    required this.floor,
    required this.projectId,
  });

  Color _getStatusColor() {
    switch (floor.status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (floor.status) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.construction;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  String _getStatusLabel() {
    switch (floor.status) {
      case 'completed':
        return 'Completed';
      case 'in_progress':
        return 'In Progress';
      default:
        return 'Pending';
    }
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    try {
      await FloorCashEstimationService().updateFloorStatus(
        projectId: projectId,
        floorId: floor.id,
        status: newStatus,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Floor ${floor.floorNumber} marked as ${_getStatusLabel()}'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showStatusMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.radio_button_unchecked, color: Colors.grey),
              title: const Text('Mark as Pending'),
              onTap: () {
                Navigator.pop(context);
                _updateStatus(context, 'pending');
              },
            ),
            ListTile(
              leading: const Icon(Icons.construction, color: Colors.orange),
              title: const Text('Mark as In Progress'),
              onTap: () {
                Navigator.pop(context);
                _updateStatus(context, 'in_progress');
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Mark as Completed'),
              onTap: () {
                Navigator.pop(context);
                _updateStatus(context, 'completed');
              },
            ),
          ],
        ),
      ),
    );
  }

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
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getStatusColor().withValues(alpha: 0.2),
                ),
                child: Icon(
                  _getStatusIcon(),
                  color: _getStatusColor(),
                ),
              ),
              title: Text(
                'Floor ${floor.floorNumber}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    _getStatusLabel(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (floor.completedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Completed: ${_formatDate(floor.completedAt!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showStatusMenu(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
