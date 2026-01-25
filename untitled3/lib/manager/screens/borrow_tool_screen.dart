import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import '../../services/tool_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/manager_service.dart';
import '../../common/models/project_model.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'tool_qr_scanner_screen.dart';

/// Borrow Tool Screen - Manager Only
class BorrowToolScreen extends StatefulWidget {
  const BorrowToolScreen({super.key});

  @override
  State<BorrowToolScreen> createState() => _BorrowToolScreenState();
}

class _BorrowToolScreenState extends State<BorrowToolScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _workerNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  String? _scannedToolId;
  File? _qrImage;
  String? _selectedProjectId;
  DateTime? _expectedReturnDate;
  TimeOfDay? _expectedReturnTime;
  bool _isLoading = false;
  bool _isScanning = false;

  List<ProjectModel> _projects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _workerNameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    try {
      final projectsStream = ManagerService.getProjectsWithAcceptanceStatus();
      final projectsWithStatus = await projectsStream.first;
      setState(() {
        _projects = projectsWithStatus
            .where((p) => p.areFeaturesEnabled)
            .map((p) => p.project)
            .toList();
      });
    } catch (e) {
      print('Error loading projects: $e');
    }
  }

  Future<void> _scanQrCode() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(builder: (_) => const ToolQrScannerScreen()),
      );

      if (result != null && mounted) {
        final toolId = result['toolId'] as String;
        final qrImage = result['qrImage'] as File;

        // Validate tool exists and is available
        final isAvailable = await ToolService.isToolAvailable(toolId);

        if (!isAvailable) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tool is not available for borrowing'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _isScanning = false;
          });
          return;
        }

        setState(() {
          _scannedToolId = toolId;
          _qrImage = qrImage;
          _isScanning = false;
        });
      } else {
        setState(() {
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning QR: $e')),
        );
      }
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _expectedReturnDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _expectedReturnTime = picked;
      });
    }
  }

  Future<void> _submitBorrow() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_scannedToolId == null || _qrImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan tool QR code first')),
      );
      return;
    }

    if (_selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a project')),
      );
      return;
    }

    if (_expectedReturnDate == null || _expectedReturnTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select expected return date and time')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = !connectivityResult.contains(ConnectivityResult.none);

      // Upload QR image to Cloudinary
      String? qrImageUrl;
      if (isOnline) {
        qrImageUrl = await CloudinaryService.uploadImage(_qrImage!);
        if (qrImageUrl == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload QR image. Saving offline.')),
            );
          }
        }
      }

      // Combine date and time
      final expectedReturnAt = DateTime(
        _expectedReturnDate!.year,
        _expectedReturnDate!.month,
        _expectedReturnDate!.day,
        _expectedReturnTime!.hour,
        _expectedReturnTime!.minute,
      );

      Map<String, dynamic> result;

      if (isOnline && qrImageUrl != null) {
        // Online: Save to Firestore
        result = await ToolService.borrowTool(
          toolId: _scannedToolId!,
          workerName: _workerNameController.text.trim(),
          mobileNumber: _mobileController.text.trim(),
          projectId: _selectedProjectId!,
          expectedReturnAt: expectedReturnAt,
          borrowQrImageUrl: qrImageUrl,
        );
      } else {
        // Offline: Save to Hive
        result = await ToolService.borrowToolOffline(
          toolId: _scannedToolId!,
          workerName: _workerNameController.text.trim(),
          mobileNumber: _mobileController.text.trim(),
          projectId: _selectedProjectId!,
          expectedReturnAt: expectedReturnAt,
          borrowQrImageUrl: qrImageUrl ?? 'offline_pending',
        );
      }

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isOnline ? 'Tool borrowed successfully' : 'Tool borrowed (offline - will sync)'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to borrow tool'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrow Tool'),
        backgroundColor: Colors.white.withValues(alpha: 0.55),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step 1: Scan QR
                _buildSectionCard(
                  title: 'Step 1: Scan Tool QR',
                  child: Column(
                    children: [
                      if (_scannedToolId != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Tool Scanned',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green,
                                      ),
                                    ),
                                    Text(
                                      'Tool ID: $_scannedToolId',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const Text(
                          'Scan the QR code on the tool',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _isScanning || _isLoading ? null : _scanQrCode,
                        icon: _isScanning
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.qr_code_scanner),
                        label: Text(_scannedToolId != null ? 'Scan Again' : 'Scan QR Code'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF136DEC),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Step 2: Worker Details
                _buildSectionCard(
                  title: 'Step 2: Borrower Details',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _workerNameController,
                        decoration: InputDecoration(
                          labelText: 'Worker Name *',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Worker name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _mobileController,
                        decoration: InputDecoration(
                          labelText: 'Mobile Number *',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Mobile number is required';
                          }
                          if (value.length != 10) {
                            return 'Mobile number must be 10 digits';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Step 3: Project & Return Time
                _buildSectionCard(
                  title: 'Step 3: Assign Project & Return Time',
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedProjectId,
                        decoration: InputDecoration(
                          labelText: 'Select Project *',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _projects.map((project) {
                          return DropdownMenuItem(
                            value: project.id,
                            child: Text(project.projectName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedProjectId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a project';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _selectDate,
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _expectedReturnDate != null
                                    ? '${_expectedReturnDate!.day}/${_expectedReturnDate!.month}/${_expectedReturnDate!.year}'
                                    : 'Select Date',
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _selectTime,
                              icon: const Icon(Icons.access_time),
                              label: Text(
                                _expectedReturnTime != null
                                    ? _expectedReturnTime!.format(context)
                                    : 'Select Time',
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitBorrow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Submit Borrow Request',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
