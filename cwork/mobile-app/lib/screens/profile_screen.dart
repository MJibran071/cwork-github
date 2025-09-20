import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cwork_mobile/services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _roleController;
  late TextEditingController _bioController;

  Map<String, dynamic>? _profileData;
  List<dynamic> _reviews = [];
  List<dynamic> _projects = [];
  Map<String, dynamic>? _reviewStats;
  bool _isLoading = true;
  bool _isEditing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _roleController = TextEditingController();
    _bioController = TextEditingController();
    _fetchProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileData() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final profile = await apiService.getProfile();
      final userId = profile['id'] ?? profile['_id'];
      
      // Fetch reviews and projects in parallel
      final reviewsFuture = apiService.getUserReviews(userId);
      final projectsFuture = apiService.getProjects();
      final statsFuture = apiService.getReviewStats(userId);

      final results = await Future.wait([reviewsFuture, projectsFuture, statsFuture]);

      setState(() {
        _profileData = profile;
        _reviews = results[0] as List<dynamic>;
        _projects = results[1] as List<dynamic>;
        _reviewStats = results[2] as Map<String, dynamic>;
        _nameController.text = profile['name'] ?? '';
        _emailController.text = profile['email'] ?? '';
        _phoneController.text = profile['phone'] ?? '';
        _roleController.text = profile['role'] ?? '';
        _bioController.text = profile['bio'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final updates = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'bio': _bioController.text,
      };
      
      await apiService.updateProfile(updates);
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      await _fetchProfileData(); // Refresh profile data
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: ${e.toString()}')),
      );
    }
  }


  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(
                    review['reviewerAvatar'] ?? 'https://via.placeholder.com/40',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['reviewerName'] ?? 'Anonymous',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(' ${review['rating']?.toString() ?? '0'}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              review['comment'] ?? '',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              review['createdAt'] != null
                ? '${DateTime.parse(review['createdAt']).toLocal()}'.split(' ')[0]
                : '',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectItem(Map<String, dynamic> project) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project['title'] ?? 'Untitled Project',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              project['description'] ?? 'No description',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(project['status']?.toString().toUpperCase() ?? 'UNKNOWN'),
                  backgroundColor: _getStatusColor(project['status']),
                ),
                const Spacer(),
                Text(
                  '\$${project['budget']?.toString() ?? '0'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in progress':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isLoading && _profileData != null)
            IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit),
              onPressed: _isEditing ? _saveProfile : _toggleEdit,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _fetchProfileData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Header with Avatar
                        Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundImage: NetworkImage(
                                  _profileData?['avatar'] ?? 'https://via.placeholder.com/100',
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _profileData?['name'] ?? 'No name',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _profileData?['role'] ?? 'No role',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              if (_reviewStats != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 16),
                                    Text(' ${_reviewStats?['averageRating']?.toStringAsFixed(1) ?? '0.0'}'),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.reviews, color: Colors.blue, size: 16),
                                    Text(' ${_reviewStats?['total']?.toString() ?? '0'}'),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Personal Information Section
                        const Text(
                          'Personal Information',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        // Name Field
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                          ),
                          enabled: _isEditing,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Email Field (read-only)
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          enabled: false, // Email should not be editable
                          readOnly: true,
                        ),
                        const SizedBox(height: 16),

                        // Phone Field
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            border: OutlineInputBorder(),
                          ),
                          enabled: _isEditing,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),

                        // Role Field (read-only)
                        TextFormField(
                          controller: _roleController,
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            border: OutlineInputBorder(),
                          ),
                          enabled: false,
                          readOnly: true,
                        ),
                        const SizedBox(height: 16),

                        // Bio Field
                        TextFormField(
                          controller: _bioController,
                          decoration: const InputDecoration(
                            labelText: 'Bio',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          enabled: _isEditing,
                          maxLines: 4,
                          minLines: 3,
                        ),
                        const SizedBox(height: 24),

                        // Stats Section
                        const Text(
                          'Statistics',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('Projects', _projects.length.toString()),
                            _buildStatItem('Completed', _projects.where((p) => p['status'] == 'completed').length.toString()),
                            _buildStatItem('Rating', _reviewStats?['averageRating']?.toStringAsFixed(1) ?? '0.0'),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Client Reviews Section
                        if (_reviews.isNotEmpty) ...[
                          const Text(
                            'Client Reviews',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Column(
                            children: _reviews.map((review) => _buildReviewItem(review)).toList(),
                          ),
                          const SizedBox(height: 32),
                        ],

                        // Project Catalog Section
                        if (_projects.isNotEmpty) ...[
                          const Text(
                            'Project Portfolio',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Column(
                            children: _projects.map((project) => _buildProjectItem(project)).toList(),
                          ),
                          const SizedBox(height: 32),
                        ],

                        // Action Buttons when editing
                        if (_isEditing)
                          Center(
                            child: Column(
                              children: [
                                ElevatedButton(
                                  onPressed: _saveProfile,
                                  child: const Text('Save Changes'),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _toggleEdit,
                                  child: const Text('Cancel'),
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

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}