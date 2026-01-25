import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../models/user_model.dart';
import '../models/project_model.dart';
import '../../services/social_rating_service.dart';
import '../../services/simple_rating_service.dart';
import '../widgets/rating_dialog.dart';

/// User Profile Screen for construction management system
/// Shows detailed user information, projects, and ratings with rating capability
class UserProfileScreen extends StatefulWidget {
  final String userUid;

  const UserProfileScreen({
    super.key,
    required this.userUid,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  UserModel? _user;
  List<ProjectModel> _completedProjects = [];
  List<Map<String, dynamic>> _availableProjectsForRating = [];
  Map<String, dynamic> _ratingStats = {};
  bool _canRate = false;
  bool _isLoading = true;

  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Load user basic info
      final user = await SocialRatingService.getUserByUid(widget.userUid);
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Load completed projects
      final completedProjects = await SocialRatingService.getUserCompletedProjects(widget.userUid);
      
      // Check if current user can rate this user
      final canRate = await SocialRatingService.canCurrentUserRate(widget.userUid);
      
      // Load available projects for rating
      List<Map<String, dynamic>> availableProjects = [];
      if (canRate) {
        availableProjects = await SocialRatingService.getProjectsAvailableForRating(widget.userUid);
      }

      // Load rating statistics
      final ratingStats = await SocialRatingService.getUserRatingStats(widget.userUid);

      setState(() {
        _user = user;
        _completedProjects = completedProjects;
        _canRate = canRate;
        _availableProjectsForRating = availableProjects;
        _ratingStats = ratingStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showRatingDialog() {
    if (_availableProjectsForRating.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No completed projects available for rating'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // For simplicity, use the first available project
    final project = _availableProjectsForRating.first;
    final projectId = project['id'] as String;
    final projectName = project['name'] as String;

    showDialog(
      context: context,
      builder: (context) => RatingDialog(
        targetUserName: _user?.name ?? 'User',
        projectName: projectName,
        onSubmit: (rating, comment) async {
          final success = await SimpleRatingService.submitRating(
            targetUserUid: widget.userUid,
            projectId: projectId,
            rating: rating,
            comment: comment,
          );

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Rating submitted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            // Refresh data
            _loadUserData();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to submit rating'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.white.withValues(alpha: 0.55),
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.white.withValues(alpha: 0.55),
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'User not found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // User Info Card
                        _buildUserInfoCard(),
                        const SizedBox(height: 16),
                        
                        // Rating Card
                        _buildRatingCard(),
                        const SizedBox(height: 16),
                        
                        // Projects Section
                        if (_completedProjects.isNotEmpty) ...[
                          _buildProjectsSection(),
                          const SizedBox(height: 16),
                        ],
                        
                        // Rate Button
                        if (_canRate && _availableProjectsForRating.isNotEmpty)
                          _buildRateButton(),
                      ],
                    ),
                  ),
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
            child: Text(
              _user!.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F1F1F),
              ),
            ),
          ),
          if (_canRate && _availableProjectsForRating.isNotEmpty)
            GestureDetector(
              onTap: _showRatingDialog,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.star_rate, size: 22, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard() {
    final roleColor = _getRoleColor(_user!.role);
    
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
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Avatar
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [roleColor, roleColor.withOpacity(0.7)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: roleColor.withValues(alpha: 0.25),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Name
              Text(
                _user!.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Role Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: roleColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  _user!.roleDisplayName,
                  style: TextStyle(
                    color: roleColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Public ID
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.badge, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'ID: ${_user!.generatedId}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingCard() {
    final ratingAvg = (_ratingStats['ratingAvg'] ?? 0.0) as double;
    final ratingCount = (_ratingStats['ratingCount'] ?? 0) as int;
    final breakdown = (_ratingStats['breakdown'] ?? {}) as Map<String, dynamic>;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ratingCount > 0 ? '${ratingAvg.toStringAsFixed(1)}/10' : 'No ratings yet',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          ratingCount > 0 
                              ? '$ratingCount ${ratingCount == 1 ? 'rating' : 'ratings'}'
                              : 'Be the first to rate',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (ratingCount > 0)
                    _buildStarRating(ratingAvg),
                ],
              ),
              
              // Rating breakdown
              if (breakdown.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Rating Breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                _buildRatingBreakdown(breakdown),
              ],
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildStarRating(double rating) {
    final normalizedRating = rating / 2; // Convert 10-scale to 5-scale for stars
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < normalizedRating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 18);
        } else if (index < normalizedRating) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 18);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 18);
        }
      }),
    );
  }

  Widget _buildRatingBreakdown(Map<String, dynamic> breakdown) {
    return Column(
      children: [
        _buildBreakdownItem('Deadline Adherence', breakdown['deadline'] ?? 0.0, Icons.schedule),
        const SizedBox(height: 8),
        _buildBreakdownItem('Quality & Defects', breakdown['defect'] ?? 0.0, Icons.build_circle),
        const SizedBox(height: 8),
        _buildBreakdownItem('Payment & Conduct', breakdown['payment'] ?? 0.0, Icons.payment),
      ],
    );
  }

  Widget _buildBreakdownItem(String label, double score, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ),
        Text(
          '${score.toStringAsFixed(1)}/10',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectsSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.folder_open, color: primary, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Completed Projects',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_completedProjects.length}',
                      style: const TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...(_completedProjects.take(5).map((project) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildProjectCard(project),
              ))),
              if (_completedProjects.length > 5) ...[
                const SizedBox(height: 8),
                Text(
                  'And ${_completedProjects.length - 5} more projects...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(ProjectModel project) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            height: 8,
            width: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.projectName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  'COMPLETED',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateButton() {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _showRatingDialog,
        icon: const Icon(Icons.star_rate, size: 24),
        label: const Text(
          'Rate User',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: Colors.amber.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'ownerclient':
      case 'owner':
        return const Color(0xFF7A5AF8);
      case 'fieldmanager':
      case 'manager':
        return const Color(0xFF136DEC);
      case 'projectengineer':
      case 'engineer':
        return const Color(0xFF10B981);
      case 'contractor':
        return const Color(0xFFF59E0B);
      case 'purchasemanager':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }
}