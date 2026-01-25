import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../models/comprehensive_rating_model.dart';
import '../../common/models/user_model.dart';
import '../../services/comprehensive_rating_service.dart';

/// Comprehensive Rating Screen - Detailed Engineer performance evaluation
/// Based on deadlines, defect history, payment advice, communication, and professionalism
class ComprehensiveRatingScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  const ComprehensiveRatingScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<ComprehensiveRatingScreen> createState() => _ComprehensiveRatingScreenState();
}

class _ComprehensiveRatingScreenState extends State<ComprehensiveRatingScreen> {
  UserModel? _engineer;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Rating values (1-10)
  int _deadlineRating = 5;
  int _qualityRating = 5;
  int _paymentRating = 5;
  int _communicationRating = 5;
  int _professionalismRating = 5;

  // Feedback controllers
  final TextEditingController _deadlineFeedbackController = TextEditingController();
  final TextEditingController _qualityFeedbackController = TextEditingController();
  final TextEditingController _paymentFeedbackController = TextEditingController();
  final TextEditingController _communicationFeedbackController = TextEditingController();
  final TextEditingController _professionalismFeedbackController = TextEditingController();
  final TextEditingController _overallCommentsController = TextEditingController();

  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);

  @override
  void initState() {
    super.initState();
    _loadEngineerData();
  }

  @override
  void dispose() {
    _deadlineFeedbackController.dispose();
    _qualityFeedbackController.dispose();
    _paymentFeedbackController.dispose();
    _communicationFeedbackController.dispose();
    _professionalismFeedbackController.dispose();
    _overallCommentsController.dispose();
    super.dispose();
  }

  Future<void> _loadEngineerData() async {
    try {
      _engineer = await ComprehensiveRatingService.getProjectEngineer(widget.projectId);
      
      if (_engineer == null) {
        setState(() {
          _errorMessage = 'Engineer not found for this project';
          _isLoading = false;
        });
        return;
      }

      // Check if already rated
      final canRate = await ComprehensiveRatingService.canRateEngineer(
        projectId: widget.projectId,
        engineerUid: _engineer!.uid,
      );

      if (!canRate) {
        setState(() {
          _errorMessage = 'Engineer has already been rated for this project';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading engineer data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitRating() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await ComprehensiveRatingService.submitComprehensiveRating(
        projectId: widget.projectId,
        engineerUid: _engineer!.uid,
        deadlineRating: _deadlineRating,
        qualityRating: _qualityRating,
        paymentRating: _paymentRating,
        communicationRating: _communicationRating,
        professionalismRating: _professionalismRating,
        deadlineFeedback: _deadlineFeedbackController.text.trim(),
        qualityFeedback: _qualityFeedbackController.text.trim(),
        paymentFeedback: _paymentFeedbackController.text.trim(),
        communicationFeedback: _communicationFeedbackController.text.trim(),
        professionalismFeedback: _professionalismFeedbackController.text.trim(),
        overallComments: _overallCommentsController.text.trim(),
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comprehensive rating submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Failed to submit rating');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  double get _overallRating {
    return ComprehensiveRatingModel.calculateOverallRating(
      deadlineRating: _deadlineRating,
      qualityRating: _qualityRating,
      paymentRating: _paymentRating,
      communicationRating: _communicationRating,
      professionalismRating: _professionalismRating,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary.withValues(alpha: 0.12),
                  accent.withValues(alpha: 0.10),
                  Colors.white,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                _buildAppBar(),
                
                // Content
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, size: 22),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rate Engineer Performance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
                Text(
                  widget.projectName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5C5C5C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Engineer Info Card
          _buildEngineerInfoCard(),
          const SizedBox(height: 24),
          
          // Overall Rating Display
          _buildOverallRatingCard(),
          const SizedBox(height: 24),
          
          // Rating Categories
          _buildRatingCategory(
            'Deadline Management',
            'Meeting project deadlines and time commitments',
            Icons.schedule,
            _deadlineRating,
            (value) => setState(() => _deadlineRating = value),
            _deadlineFeedbackController,
          ),
          const SizedBox(height: 20),
          
          _buildRatingCategory(
            'Work Quality & Defects',
            'Quality of work delivered and defect management',
            Icons.high_quality,
            _qualityRating,
            (value) => setState(() => _qualityRating = value),
            _qualityFeedbackController,
          ),
          const SizedBox(height: 20),
          
          _buildRatingCategory(
            'Payment & Financial Advice',
            'Financial management and payment recommendations',
            Icons.payments,
            _paymentRating,
            (value) => setState(() => _paymentRating = value),
            _paymentFeedbackController,
          ),
          const SizedBox(height: 20),
          
          _buildRatingCategory(
            'Communication',
            'Regular updates and clear communication',
            Icons.chat_bubble_outline,
            _communicationRating,
            (value) => setState(() => _communicationRating = value),
            _communicationFeedbackController,
          ),
          const SizedBox(height: 20),
          
          _buildRatingCategory(
            'Professionalism',
            'Overall professional conduct and reliability',
            Icons.person_outline,
            _professionalismRating,
            (value) => setState(() => _professionalismRating = value),
            _professionalismFeedbackController,
          ),
          const SizedBox(height: 24),
          
          // Overall Comments
          _buildOverallCommentsSection(),
          const SizedBox(height: 32),
          
          // Submit Button
          _buildSubmitButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEngineerInfoCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
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
          child: Row(
            children: [
              // Avatar
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [primary, accent],
                  ),
                ),
                child: Center(
                  child: Text(
                    _engineer!.name.isNotEmpty ? _engineer!.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Engineer Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _engineer!.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Project Engineer',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    if (_engineer!.generatedId.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${_engineer!.generatedId}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
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
    );
  }

  Widget _buildOverallRatingCard() {
    final rating = _overallRating;
    final description = ComprehensiveRatingModel(
      id: '',
      projectId: '',
      engineerUid: '',
      ratedByUid: '',
      ratedByName: '',
      deadlineRating: 0,
      qualityRating: 0,
      paymentRating: 0,
      communicationRating: 0,
      professionalismRating: 0,
      overallRating: rating,
      deadlineFeedback: '',
      qualityFeedback: '',
      paymentFeedback: '',
      communicationFeedback: '',
      professionalismFeedback: '',
      overallComments: '',
      createdAt: DateTime.now(),
    ).getRatingDescription();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Overall Rating',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: _getRatingColor(rating),
                ),
              ),
              Text(
                '$description / 10',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _getRatingColor(rating),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingCategory(
    String title,
    String description,
    IconData icon,
    int currentRating,
    Function(int) onRatingChanged,
    TextEditingController feedbackController,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$currentRating/10',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _getRatingColor(currentRating.toDouble()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Rating Slider
              Slider(
                value: currentRating.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: primary,
                inactiveColor: Colors.grey.withValues(alpha: 0.3),
                onChanged: (value) => onRatingChanged(value.round()),
              ),
              
              // Rating Labels
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('1 - Poor', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Text('5 - Average', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Text('10 - Excellent', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 16),
              
              // Feedback Field
              TextField(
                controller: feedbackController,
                maxLines: 2,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'Add specific feedback (optional)',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallCommentsSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.comment, color: primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Overall Comments',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _overallCommentsController,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Share your overall thoughts about the engineer\'s performance...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitRating,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Submit Comprehensive Rating',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 8.0) return Colors.green;
    if (rating >= 6.0) return Colors.orange;
    return Colors.red;
  }
}