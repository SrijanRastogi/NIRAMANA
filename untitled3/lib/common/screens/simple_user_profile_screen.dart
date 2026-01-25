import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/project_model.dart';
import '../widgets/rating_dialog.dart';
import '../../services/simple_rating_service.dart';

/// Simple User Profile Screen - Shows basic user info and projects
/// Fallback screen when detailed profile data is not available
class SimpleUserProfileScreen extends StatefulWidget {
  final String userUid;

  const SimpleUserProfileScreen({
    super.key,
    required this.userUid,
  });

  @override
  State<SimpleUserProfileScreen> createState() => _SimpleUserProfileScreenState();
}

class _SimpleUserProfileScreenState extends State<SimpleUserProfileScreen> {
  UserModel? _user;
  List<ProjectModel> _userProjects = [];
  List<Map<String, dynamic>> _ratableProjects = [];
  Map<String, dynamic> _ratingSummary = {'ratingAvg': 0.0, 'ratingCount': 0};
  bool _isLoading = true;
  bool _isLoadingRatableProjects = false;
  String? _errorMessage;

  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Try to load user from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userUid)
          .get();

      if (userDoc.exists) {
        _user = UserModel.fromFirestore(userDoc);
        await _loadUserProjects();
        await _loadRatingSummary();
        await _loadRatableProjects();
      } else {
        // If user not found by UID, try to find by other means
        await _findUserByAlternativeMethod();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading profile: $e';
      });
    }
  }

  Future<void> _findUserByAlternativeMethod() async {
    try {
      // Try to find user in projects as owner, manager, or engineer
      final projectsSnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .get();

      for (final projectDoc in projectsSnapshot.docs) {
        final project = ProjectModel.fromFirestore(projectDoc);
        
        // Check if the userUid matches any role in the project
        if (project.ownerUid == widget.userUid ||
            project.managerUid == widget.userUid ||
            project.createdBy == widget.userUid ||
            project.purchaseManagerUid == widget.userUid) {
          
          // Create a basic user model from project data
          _user = UserModel(
            uid: widget.userUid,
            name: _getNameFromProject(project, widget.userUid),
            email: '',
            role: _getRoleFromProject(project, widget.userUid),
            generatedId: _getPublicIdFromProject(project, widget.userUid),
            createdAt: project.createdAt,
            ratingAvg: 0.0,
            ratingCount: 0,
          );
          
          await _loadUserProjects();
          await _loadRatingSummary();
          await _loadRatableProjects();
          break;
        }
      }
    } catch (e) {
      _errorMessage = 'Could not find user information';
    }
  }

  String _getNameFromProject(ProjectModel project, String uid) {
    if (project.ownerUid == uid) return project.ownerName ?? 'Owner';
    if (project.managerUid == uid) return project.managerName ?? 'Manager';
    if (project.purchaseManagerUid == uid) return project.purchaseManagerName ?? 'Purchase Manager';
    return 'Engineer'; // Default for createdBy
  }

  String _getRoleFromProject(ProjectModel project, String uid) {
    if (project.ownerUid == uid) return 'ownerclient';
    if (project.managerUid == uid) return 'fieldmanager';
    if (project.purchaseManagerUid == uid) return 'purchasemanager';
    return 'projectengineer'; // Default for createdBy
  }

  String _getPublicIdFromProject(ProjectModel project, String uid) {
    if (project.ownerUid == uid) return project.ownerId ?? 'N/A';
    if (project.managerUid == uid) return project.managerId ?? 'N/A';
    if (project.purchaseManagerUid == uid) return project.purchaseManagerId ?? 'N/A';
    return 'N/A'; // Default for engineer
  }

  Future<void> _loadUserProjects() async {
    if (_user == null) return;

    try {
      final projectsSnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .get();

      final userProjects = <ProjectModel>[];
      
      for (final doc in projectsSnapshot.docs) {
        final project = ProjectModel.fromFirestore(doc);
        
        // Check if user is involved in this project
        if (project.ownerUid == widget.userUid ||
            project.managerUid == widget.userUid ||
            project.createdBy == widget.userUid ||
            project.purchaseManagerUid == widget.userUid) {
          userProjects.add(project);
        }
      }

      _userProjects = userProjects;
    } catch (e) {
      // Handle error silently
    }
  }

  /// Load user's rating summary
  Future<void> _loadRatingSummary() async {
    if (_user == null) return;
    
    try {
      _ratingSummary = await SimpleRatingService.getUserRatingSummary(widget.userUid);
    } catch (e) {
      _ratingSummary = {'ratingAvg': 0.0, 'ratingCount': 0};
    }
  }

  /// Load projects where current user can rate this user
  Future<void> _loadRatableProjects() async {
    if (_user == null) return;
    
    setState(() {
      _isLoadingRatableProjects = true;
    });
    
    try {
      _ratableProjects = await SimpleRatingService.getSharedCompletedProjects(widget.userUid);
    } catch (e) {
      _ratableProjects = [];
    } finally {
      setState(() {
        _isLoadingRatableProjects = false;
      });
    }
  }

  /// Show rating dialog for a specific project
  Future<void> _showRatingDialog(Map<String, dynamic> project) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => RatingDialog(
        targetUserName: _user!.name,
        projectName: project['projectName'],
        onSubmit: (rating, comment) async {
          final success = await SimpleRatingService.submitRating(
            projectId: project['projectId'],
            targetUserUid: widget.userUid,
            rating: rating,
            comment: comment,
          );
          
          if (!success) {
            throw Exception('Failed to submit rating');
          }
        },
      ),
    );

    if (result == true) {
      // Rating submitted successfully, refresh data
      await _loadRatingSummary();
      await _loadRatableProjects();
      setState(() {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rating submitted successfully!'),
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
            child: Text(
              _user?.name ?? 'Profile',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F1F1F),
              ),
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

    if (_user == null || _errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'User not found',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'This user may not have completed their profile setup',
              style: TextStyle(color: Colors.grey),
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
          // User Info Card
          _buildUserInfoCard(),
          const SizedBox(height: 16),
          
          // Projects Section
          if (_userProjects.isNotEmpty) ...[
            _buildProjectsSection(),
            const SizedBox(height: 16),
          ],
          
          // Rating Section
          if (_ratableProjects.isNotEmpty) ...[
            _buildRatingSection(),
            const SizedBox(height: 16),
          ],
          
          // Contact Info (if available)
          _buildContactInfoCard(),
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
                    colors: [roleColor, roleColor.withValues(alpha: 0.7)],
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
                  _getRoleDisplayName(_user!.role),
                  style: TextStyle(
                    color: roleColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Public ID
              if (_user!.generatedId.isNotEmpty) ...[
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
                const SizedBox(height: 16),
              ],

              // Rating Summary
              if (_ratingSummary['ratingCount'] > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${_ratingSummary['ratingAvg'].toStringAsFixed(1)}/10',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${_ratingSummary['ratingCount']} ${_ratingSummary['ratingCount'] == 1 ? 'rating' : 'ratings'})',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_outline, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'No ratings yet',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
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
                    'Projects',
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
                      '${_userProjects.length}',
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
              ...(_userProjects.take(5).map((project) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildProjectCard(project),
              ))),
              if (_userProjects.length > 5) ...[
                const SizedBox(height: 8),
                Text(
                  'And ${_userProjects.length - 5} more projects...',
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getStatusColor(project.status),
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
                  project.status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(project.status),
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

  Widget _buildRatingSection() {
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
                  const Icon(Icons.star_rate, color: Colors.amber, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Rate Professional',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const Spacer(),
                  if (_isLoadingRatableProjects)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              if (_ratableProjects.isEmpty && !_isLoadingRatableProjects) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No completed projects to rate',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text(
                  'You can rate ${_user!.name} for these completed projects:',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                
                ...(_ratableProjects.map((project) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRatableProjectCard(project),
                ))),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatableProjectCard(Map<String, dynamic> project) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: Colors.green, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project['projectName'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Completed',
                  style: TextStyle(
                    color: Colors.green[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showRatingDialog(project),
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
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoCard() {
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
                  const Icon(Icons.info_outline, color: primary, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Professional Info',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildInfoRow('Role', _getRoleDisplayName(_user!.role)),
              const SizedBox(height: 8),
              _buildInfoRow('Member Since', _formatDate(_user!.createdAt)),
              const SizedBox(height: 8),
              _buildInfoRow('Projects Involved', '${_userProjects.length}'),
              const SizedBox(height: 8),
              _buildInfoRow('Average Rating', _ratingSummary['ratingCount'] > 0 
                  ? '${_ratingSummary['ratingAvg'].toStringAsFixed(1)}/10 (${_ratingSummary['ratingCount']} ratings)'
                  : 'Not rated yet'),
              
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is a basic profile view. Full profile features coming soon.',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'ownerclient':
      case 'owner':
        return 'Owner';
      case 'fieldmanager':
      case 'manager':
        return 'Manager';
      case 'projectengineer':
      case 'engineer':
        return 'Engineer';
      case 'contractor':
        return 'Contractor';
      case 'purchasemanager':
        return 'Purchase Manager';
      default:
        return role;
    }
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF10B981);
      case 'completed':
        return const Color(0xFF3B82F6);
      case 'pending_owner_approval':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}