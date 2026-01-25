import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/face_attendance_service.dart';
import '../../services/worker_service.dart';
import '../../models/worker_model.dart';
import '../../common/project_context.dart';

/// Face Scan Attendance Screen - Field Manager Only
/// Allows face-based attendance marking with GPS validation
class FaceScanAttendanceScreen extends StatefulWidget {
  final double projectLat;
  final double projectLng;

  const FaceScanAttendanceScreen({
    super.key,
    required this.projectLat,
    required this.projectLng,
  });

  @override
  State<FaceScanAttendanceScreen> createState() => _FaceScanAttendanceScreenState();
}

class _FaceScanAttendanceScreenState extends State<FaceScanAttendanceScreen> {
  final _imagePicker = ImagePicker();
  bool _isProcessing = false;
  List<Map<String, dynamic>> _scannedWorkers = [];
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final projectId = ProjectContext.activeProjectId;

    if (projectId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Face Scan Attendance'),
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
        title: const Text('Face Scan Attendance'),
        backgroundColor: Colors.white.withValues(alpha: 0.55),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Navigate to attendance history
            },
            tooltip: 'Attendance History',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Instructions Card
            _buildInstructionsCard(),
            const SizedBox(height: 8),

            // Today's Attendance Summary
            _buildTodaysSummary(projectId),
            const SizedBox(height: 8),

            // Scanned Workers List
            Expanded(
              child: _scannedWorkers.isEmpty
                  ? _buildEmptyState()
                  : _buildScannedWorkersList(),
            ),

            // Error Message
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : () => _scanFace(projectId),
                      icon: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.camera_alt),
                      label: Text(_isProcessing ? 'Processing...' : 'Scan Face'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF136DEC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to manual attendance
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Manual'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue[50]!.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[200]!),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.info_outline, color: Color(0xFF136DEC), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'How to Use',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF136DEC),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Tap "Scan Face" to open camera\n'
                  '2. Capture worker\'s face clearly\n'
                  '3. System will auto-recognize and mark attendance\n'
                  '4. GPS and time validation applied automatically',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodaysSummary(String projectId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<Map<String, dynamic>?>(
        stream: FaceAttendanceService.getTodayAttendanceStream(projectId),
        builder: (context, snapshot) {
          final attendance = snapshot.data;
          final records = attendance?['records'] as List<FaceAttendanceRecord>? ?? [];
          final presentCount = records.where((r) => r.present).length;
          final totalWages = records
              .where((r) => r.present)
              .fold<double>(0, (sum, r) => sum + r.dailyWage);

          return ClipRRect(
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
                    _buildSummaryItem(
                      'Present Today',
                      presentCount.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey[300],
                    ),
                    _buildSummaryItem(
                      'Total Wages',
                      '₹${totalWages.toStringAsFixed(0)}',
                      Icons.currency_rupee,
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.face_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Workers Scanned Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Scan Face" to start marking attendance',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannedWorkersList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _scannedWorkers.length,
      itemBuilder: (context, index) {
        final worker = _scannedWorkers[index];
        return _buildWorkerCard(worker);
      },
    );
  }

  Widget _buildWorkerCard(Map<String, dynamic> worker) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green[50]!.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green[200]!),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Colors.green, Color(0xFF059669)],
                    ),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker['worker']['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        worker['worker']['role'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified, size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  '${(worker['confidence'] * 100).toStringAsFixed(0)}% Match',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₹${worker['worker']['wage']}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
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

  Future<void> _scanFace(String projectId) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Capture image
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );

      if (image == null) {
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      final imageFile = File(image.path);

      // Process face scan
      final result = await FaceAttendanceService.processFaceScan(
        projectId: projectId,
        imageFile: imageFile,
        projectLat: widget.projectLat,
        projectLng: widget.projectLng,
      );

      if (result['success'] == true) {
        setState(() {
          _scannedWorkers.insert(0, result);
          _isProcessing = false;
          _errorMessage = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${result['worker']['name']} marked present'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _isProcessing = false;
          _errorMessage = result['error'];
        });

        if (result['unrecognized'] == true) {
          // Show option to enroll new worker
          if (mounted) {
            _showEnrollNewWorkerDialog();
          }
        }
      }

    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  void _showEnrollNewWorkerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Face Not Recognized'),
        content: const Text(
          'This worker is not enrolled in the system. Would you like to enroll them now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to enrollment screen
            },
            child: const Text('Enroll Now'),
          ),
        ],
      ),
    );
  }
}
