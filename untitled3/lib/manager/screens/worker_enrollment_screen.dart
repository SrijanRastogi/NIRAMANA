import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import '../../services/worker_service.dart';
import '../../services/face_recognition_service.dart';
import '../../common/project_context.dart';

/// Worker Enrollment Screen - Field Manager Only
/// Allows enrollment of daily wagers with face recognition
class WorkerEnrollmentScreen extends StatefulWidget {
  const WorkerEnrollmentScreen({super.key});

  @override
  State<WorkerEnrollmentScreen> createState() => _WorkerEnrollmentScreenState();
}

class _WorkerEnrollmentScreenState extends State<WorkerEnrollmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _roleController = TextEditingController();
  final _wageController = TextEditingController();
  
  final _faceService = FaceRecognitionService();
  final _imagePicker = ImagePicker();
  
  File? _faceImage;
  List<double>? _faceEmbedding;
  bool _isProcessing = false;
  bool _isEnrolling = false;
  String? _errorMessage;

  // Common roles
  final List<String> _commonRoles = [
    'Mason',
    'Helper',
    'Carpenter',
    'Electrician',
    'Plumber',
    'Painter',
    'Welder',
    'Labor',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFaceService();
  }

  Future<void> _initializeFaceService() async {
    try {
      await _faceService.initialize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize face recognition: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _roleController.dispose();
    _wageController.dispose();
    super.dispose();
  }

  Future<void> _captureFace() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isProcessing = true;
        _errorMessage = null;
      });

      final imageFile = File(image.path);

      // Validate face quality
      final validation = await _faceService.validateFaceQuality(imageFile);

      if (validation['valid'] != true) {
        setState(() {
          _isProcessing = false;
          _errorMessage = validation['reason'];
        });
        return;
      }

      // Extract face embedding
      final embedding = await _faceService.extractFaceEmbedding(imageFile);

      if (embedding == null) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Failed to extract face features. Please try again.';
        });
        return;
      }

      setState(() {
        _faceImage = imageFile;
        _faceEmbedding = embedding;
        _isProcessing = false;
        _errorMessage = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Face captured successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Error capturing face: $e';
      });
    }
  }

  Future<void> _enrollWorker() async {
    if (!_formKey.currentState!.validate()) return;

    if (_faceEmbedding == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture face first')),
      );
      return;
    }

    final projectId = ProjectContext.activeProjectId;
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active project selected')),
      );
      return;
    }

    setState(() {
      _isEnrolling = true;
    });

    try {
      // Check if name already exists
      final nameExists = await WorkerService.isWorkerNameExists(
        projectId,
        _nameController.text.trim(),
      );

      if (nameExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Worker with this name already exists')),
          );
        }
        setState(() {
          _isEnrolling = false;
        });
        return;
      }

      // Enroll worker
      await WorkerService.enrollWorker(
        projectId: projectId,
        name: _nameController.text.trim(),
        nickname: _nicknameController.text.trim().isEmpty 
            ? null 
            : _nicknameController.text.trim(),
        role: _roleController.text.trim(),
        dailyWage: double.parse(_wageController.text.trim()),
        faceEmbedding: _faceEmbedding!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Worker enrolled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error enrolling worker: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isEnrolling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enroll Worker'),
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
                // Face Capture Section
                _buildFaceCaptureCard(),
                const SizedBox(height: 16),

                // Worker Details Section
                _buildDetailsCard(),
                const SizedBox(height: 24),

                // Enroll Button
                ElevatedButton(
                  onPressed: _isEnrolling ? null : _enrollWorker,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF136DEC),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isEnrolling
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Enroll Worker',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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

  Widget _buildFaceCaptureCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: const [
                  Icon(Icons.face, color: Color(0xFF136DEC)),
                  SizedBox(width: 8),
                  Text(
                    'Face Capture',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Face Image Preview
              if (_faceImage != null)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _faceImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.face_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No face captured',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
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
                    ],
                  ),
                ),

              if (_errorMessage != null) const SizedBox(height: 16),

              // Capture Button
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _captureFace,
                icon: _isProcessing
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.camera_alt),
                label: Text(_faceImage == null ? 'Capture Face' : 'Recapture Face'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF136DEC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Instructions
              Text(
                '• Face the camera directly\n'
                '• Ensure good lighting\n'
                '• Remove glasses if possible\n'
                '• Only one person in frame',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.person_outline, color: Color(0xFF136DEC)),
                  SizedBox(width: 8),
                  Text(
                    'Worker Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'e.g., Ravi Kumar',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter worker name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nickname
              TextFormField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText: 'Nickname (Optional)',
                  hintText: 'e.g., Ravi',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Role
              TextFormField(
                controller: _roleController,
                decoration: InputDecoration(
                  labelText: 'Role *',
                  hintText: 'Select or type role',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.work_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter worker role';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // Role chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonRoles.map((role) {
                  return ActionChip(
                    label: Text(role),
                    onPressed: () {
                      _roleController.text = role;
                    },
                    backgroundColor: Colors.blue[50],
                    labelStyle: const TextStyle(
                      color: Color(0xFF136DEC),
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Daily Wage
              TextFormField(
                controller: _wageController,
                decoration: InputDecoration(
                  labelText: 'Daily Wage (₹) *',
                  hintText: 'e.g., 700',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.currency_rupee),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter daily wage';
                  }
                  final wage = double.tryParse(value);
                  if (wage == null || wage <= 0) {
                    return 'Please enter valid wage amount';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
