import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/project_model.dart';
import '../../models/rating_model.dart';
import '../../services/rating_service.dart';

/// Profile Detail Screen - Shows detailed user profile with rating capability
/// Displays user info, projects, ratings, and allows authorized users to rate
class ProfileDetailScreen extends StatefulWidget {
  final String ratedUserUid;

  const ProfileDetailScreen({
    super.key,
    required this.ratedUserUid,
  });

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  UserModel? _user;
  List<ProjectModel> _activeProjects = [];
  List<ProjectModel> _completedProjects = [];
  List<Map<String, dynamic>> _ratableProjects = [];
  bool _canRate = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      print('DEBUG: ProfileDetailScreen loading user with UID: ${widget.ratedUserUid}');
      
      // Load user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.ratedUserUid)
          .get();

      print('DEBUG: User document exists: ${userDoc.exists}');
      if (userDoc.exists) {
        print('DEBUG: User document data: ${userDoc.data()}');
        _user = UserModel.fromFirestore(userDoc);
        print('DEBUG: User loaded successfully: ${_user?.name}');
      } else {
        print('DEBUG: No user document found for UID: ${widget.ratedUserUid}');
      }

      // Load user's projects
      await _loadUserProjects();

      // Check if current user can rate
      _canRate = await RatingService.canCurrentUserRate();

      // Load ratable projects
      if (_canRate) {
        _ratableProjects = await RatingService.getProjectsForRating(widget.ratedUserUid);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('DEBUG: Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserProjects() async {
    try {
      // Get projects where user is involved
      final projectsSnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .get();

      final activeProjects = <ProjectModel>[];
      final completedProjects = <ProjectModel>[];

      for (final doc in projectsSnapshot.docs) {
        final project = ProjectModel.fromFirestore(doc);
        final projectData = doc.data();
        
        // Check if user is involved in this project
        final participants = List<String>.from(projectData['participants'] ?? []);
        final managerId = projectData['managerId'] as String?;
        final engineerId = projectData['engineerId'] as String?;
        final ownerId = projectData['ownerId'] as String?;
        
        final isInvolved = participants.contains(widget.ratedUserUid) ||
                          managerId == widget.ratedUserUid ||
                          engineerId == widget.ratedUserUid ||
                          ownerId == widget.ratedUserUid;

        if (isInvolved) {
          if (project.status.toLowerCase() == 'completed') {
            completedProjects.add(project);
          } else {
            activeProjects.add(project);
          }
        }
      }

      _activeProjects = activeProjects;
      _completedProjects = completedProjects;
    } catch (e) {
      // Handle error
    }
  }
  void _showRatingDialog() {
    if (_ratableProjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No projects available for rating this user'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _RatingDialog(
        userName: _user?.name ?? 'User',
        ratableProjects: _ratableProjects,
        onRatingSubmitted: (projectId, rating) async {
          final success = await RatingService.submitRating(
            ratedUserUid: widget.ratedUserUid,
            projectId: projectId,
            rating: rating,
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
          child: Text('User not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_user!.name),
        backgroundColor: Colors.white.withValues(alpha: 0.55),
        elevation: 0,
        actions: [
          if (_canRate && _ratableProjects.isNotEmpty)
            IconButton(
              onPressed: _showRatingDialog,
              icon: const Icon(Icons.star_rate),
              tooltip: 'Rate User',
            ),
        ],
      ),
      body: SingleChildScrollView(
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
            
            // Active Projects
            if (_activeProjects.isNotEmpty) ...[
              _buildProjectsSection('Active Projects', _activeProjects),
              const SizedBox(height: 16),
            ],
            
            // Completed Projects
            if (_completedProjects.isNotEmpty) ...[
              _buildProjectsSection('Completed Projects', _completedProjects),
              const SizedBox(height: 16),
            ],
            
            // Rate Button (if can rate)
            if (_canRate && _ratableProjects.isNotEmpty)
              _buildRateButton(),
          ],
        ),
      ),
    );
  }
  Widget _buildUserInfoCard() {
    final roleColor = _getRoleColor(_user!.role);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
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
              // Avatar
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [roleColor, roleColor.withOpacity(0.7)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: roleColor.withValues(alpha: 0.25),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Name
              Text(
                _user!.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              // Role Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: roleColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  _user!.roleDisplayName,
                  style: TextStyle(
                    color: roleColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Public ID
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.badge, size: 16, color: Color(0xFF6B7280)),
                  const SizedBox(width: 6),
                  Text(
                    'ID: ${_user!.generatedId}',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.ratedUserUid)
          .snapshots(),
      builder: (context, snapshot) {
        double ratingAvg = 0.0;
        int ratingCount = 0;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          ratingAvg = (data['ratingAvg'] ?? 0.0).toDouble();
          ratingCount = data['ratingCount'] ?? 0;
        }

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
                  const Icon(Icons.star, color: Colors.amber, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ratingCount > 0 ? '${ratingAvg.toStringAsFixed(1)}/10' : 'No ratings yet',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          ratingCount > 0 
                              ? '$ratingCount ${ratingCount == 1 ? 'rating' : 'ratings'}'
                              : 'Be the first to rate',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
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
            ),
          ),
        );
      },
    );
  }
  Widget _buildStarRating(double rating) {
    final normalizedRating = rating / 2; // Convert 10-scale to 5-scale for stars
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < normalizedRating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 16);
        } else if (index < normalizedRating) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 16);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 16);
        }
      }),
    );
  }

  Widget _buildProjectsSection(String title, List<ProjectModel> projects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        ...projects.map((project) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildProjectCard(project),
        )),
      ],
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

  Widget _buildRateButton() {
    return Container(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _showRatingDialog,
        icon: const Icon(Icons.star_rate),
        label: const Text('Rate User'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
      case 'pending':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
/// Rating Dialog Widget
class _RatingDialog extends StatefulWidget {
  final String userName;
  final List<Map<String, dynamic>> ratableProjects;
  final Function(String projectId, int rating) onRatingSubmitted;

  const _RatingDialog({
    required this.userName,
    required this.ratableProjects,
    required this.onRatingSubmitted,
  });

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  String? _selectedProjectId;
  int _selectedRating = 5;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rate ${widget.userName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project Selection
          const Text(
            'Select Project:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedProjectId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: widget.ratableProjects.map((project) {
              return DropdownMenuItem<String>(
                value: project['projectId'],
                child: Text(
                  project['projectName'],
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedProjectId = value;
              });
            },
            hint: const Text('Choose a project'),
          ),
          const SizedBox(height: 16),
          
          // Rating Selection
          const Text(
            'Rating (1-10):',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _selectedRating.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.star, color: Colors.amber),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _selectedRating.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: Colors.amber,
            onChanged: (value) {
              setState(() {
                _selectedRating = value.round();
              });
            },
          ),
          
          // Rating Labels
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Poor', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('Excellent', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting || _selectedProjectId == null
              ? null
              : () async {
                  setState(() {
                    _isSubmitting = true;
                  });
                  
                  await widget.onRatingSubmitted(_selectedProjectId!, _selectedRating);
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Submit Rating'),
        ),
      ],
    );
  }
}