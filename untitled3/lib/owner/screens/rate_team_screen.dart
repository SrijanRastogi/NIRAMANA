import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../common/models/project_model.dart';
import '../../common/models/user_model.dart';
import '../../common/widgets/rating_dialog.dart';
import '../../services/simple_rating_service.dart';
import '../../services/impression_service.dart';

/// Rate Team Screen - Allows Owner to rate Engineer and Manager after project completion
class RateTeamScreen extends StatefulWidget {
  final String projectId;

  const RateTeamScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<RateTeamScreen> createState() => _RateTeamScreenState();
}

class _RateTeamScreenState extends State<RateTeamScreen> {
  ProjectModel? _project;
  UserModel? _engineer;
  UserModel? _manager;
  bool _isLoading = true;
  String? _errorMessage;
  final Map<String, bool> _hasRated = {}; // Track who has been rated

  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);

  @override
  void initState() {
    super.initState();
    _loadProjectData();
  }

  Future<void> _loadProjectData() async {
    try {
      // Load project
      final projectDoc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .get();

      if (!projectDoc.exists) {
        setState(() {
          _errorMessage = 'Project not found';
          _isLoading = false;
        });
        return;
      }

      _project = ProjectModel.fromFirestore(projectDoc);

      // Load engineer and manager
      await Future.wait([
        _loadEngineer(),
        _loadManager(),
        _checkExistingRatings(),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading project data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEngineer() async {
    if (_project?.createdBy == null) return;

    try {
      final engineerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_project!.createdBy)
          .get();

      if (engineerDoc.exists) {
        _engineer = UserModel.fromFirestore(engineerDoc);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadManager() async {
    if (_project?.managerUid == null) return;

    try {
      final managerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_project!.managerUid!)
          .get();

      if (managerDoc.exists) {
        _manager = UserModel.fromFirestore(managerDoc);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _checkExistingRatings() async {
    if (_project == null) return;

    try {
      // Check if engineer has been rated
      if (_engineer != null) {
        final canRateEngineer = await SimpleRatingService.canRateUser(
          projectId: widget.projectId,
          targetUserUid: _engineer!.uid,
        );
        _hasRated[_engineer!.uid] = !canRateEngineer;
      }

      // Check if manager has been rated
      if (_manager != null) {
        final canRateManager = await SimpleRatingService.canRateUser(
          projectId: widget.projectId,
          targetUserUid: _manager!.uid,
        );
        _hasRated[_manager!.uid] = !canRateManager;
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _rateUser(UserModel user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => RatingDialog(
        targetUserName: user.name,
        projectName: _project!.projectName,
        onSubmit: (rating, comment) async {
          // Submit rating
          final success = await SimpleRatingService.submitRating(
            projectId: widget.projectId,
            targetUserUid: user.uid,
            rating: rating,
            comment: comment,
          );

          if (!success) {
            throw Exception('Failed to submit rating');
          }

          // Create impression notification
          await ImpressionService.createRatingImpression(
            targetUserUid: user.uid,
            projectId: widget.projectId,
            projectName: _project!.projectName,
            rating: rating,
            comment: comment,
            fromRole: 'Owner',
            fromUserName: 'Project Owner', // Could be made dynamic
          );
        },
      ),
    );

    if (result == true) {
      // Rating submitted successfully
      await _checkExistingRatings();
      setState(() {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rating submitted for ${user.name}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
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
                  'Rate Team',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
                if (_project != null)
                  Text(
                    _project!.projectName,
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
      return const Center(
        child: CircularProgressIndicator(),
      );
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
          // Project Info Card
          _buildProjectInfoCard(),
          const SizedBox(height: 24),
          
          // Team Members Section
          const Text(
            'Rate Team Members',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Rate the performance of your team members for this completed project.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 20),
          
          // Engineer Card
          if (_engineer != null) ...[
            _buildTeamMemberCard(_engineer!, 'Project Engineer'),
            const SizedBox(height: 16),
          ],
          
          // Manager Card
          if (_manager != null) ...[
            _buildTeamMemberCard(_manager!, 'Field Manager'),
            const SizedBox(height: 16),
          ],
          
          // No team members message
          if (_engineer == null && _manager == null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.people_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text(
                    'No team members found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This project doesn\'t have assigned team members to rate.',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProjectInfoCard() {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _project?.projectName ?? 'Unknown Project',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const Text(
                          'Project Completed',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rate your team members based on their performance, communication, and professionalism during this project.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamMemberCard(UserModel user, String role) {
    final hasBeenRated = _hasRated[user.uid] ?? false;
    
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
          child: Row(
            children: [
              // Avatar
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [primary, accent],
                  ),
                ),
                child: Center(
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (user.generatedId.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${user.generatedId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Rate Button
              if (hasBeenRated) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Rated',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: () => _rateUser(user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Rate',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}