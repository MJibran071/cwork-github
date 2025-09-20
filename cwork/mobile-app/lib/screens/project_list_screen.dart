// Project List Screen - Displays user's projects with demo data fallback
// Shows project cards with status, progress, and budget information
// Handles loading states, errors, and empty states gracefully

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:cwork_mobile/screens/project_detail_screen.dart';
import 'package:cwork_mobile/services/api_service.dart';

/// Screen that displays a list of user projects with interactive cards
/// Supports both real API data and demo projects as fallback
class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => ProjectListScreenState();
}

/// State class for ProjectListScreen managing project data and UI state
class ProjectListScreenState extends State<ProjectListScreen> {
  List<dynamic> projects = [];      // List of projects to display
  bool isLoading = true;            // Loading state indicator
  String? error;                    // Error message if API call fails

  /// Initialize state and fetch projects when widget is created
  @override
  void initState() {
    super.initState();
    fetchProjects(); // Load projects immediately after widget initialization
  }

  /// Fetches projects from API with fallback to demo data
  /// Handles both successful API responses and errors gracefully
  Future<void> fetchProjects() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final apiProjects = await apiService.getProjects();
      setState(() {
        // Use API data if available, otherwise fall back to demo projects
        projects = apiProjects.isNotEmpty ? apiProjects : getDemoProjects();
        isLoading = false; // Hide loading indicator
      });
    } catch (e) {
      // Fallback to demo projects if API call fails
      setState(() {
        projects = getDemoProjects();
        isLoading = false; // Hide loading indicator
      });
    }
  }

  /// Provides demo project data for development and fallback scenarios
  /// Includes various project statuses and details for testing UI
  List<dynamic> getDemoProjects() {
    return [
      {
        'id': 'demo-1',
        'title': 'Website Redesign',
        'status': 'Active',
        'proposalCount': 5,
        'progress': 30,
        'budget': '1500'
      },
      {
        'id': 'demo-2',
        'title': 'Mobile App Development',
        'status': 'Active',
        'proposalCount': 8,
        'progress': 50,
        'budget': '3000'
      },
      {
        'id': 'demo-3',
        'title': 'Logo Design',
        'status': 'Completed',
        'proposalCount': 3,
        'progress': 100,
        'budget': '500'
      },
      {
        'id': 'demo-4',
        'title': 'SEO Optimization',
        'status': 'Draft',
        'proposalCount': 0,
        'progress': 0,
        'budget': '800'
      }
    ];
  }

  /// Builds the project list UI with responsive states
  /// Shows loading indicator, error message, empty state, or project list
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen title
          Text(
            'My Projects',
            style: AppTheme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          
          // Loading state - shows circular progress indicator
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          
          // Error state - shows error message and retry button
          else if (error != null)
            Column(
              children: [
                Text(
                  'Error: $error',
                  style: AppTheme.textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: AppTheme.spacingS),
                ElevatedButton(
                  onPressed: fetchProjects, // Retry fetching projects
                  child: const Text('Retry'),
                ),
              ],
            )
          
          // Empty state - shows message when no projects are available
          else if (projects.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    'No projects found',
                    style: AppTheme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    'Create your first project to get started!',
                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            )
          
          // Projects list - displays all projects in a scrollable list
          else
            Expanded(
              child: ListView.builder(
                itemCount: projects.length,
                itemBuilder: (context, index) => buildProjectCard(context, projects[index], index),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds an individual project card with project details
  /// Includes title, status chips, progress bar, budget, and action button
  /// @param context Build context
  /// @param project Project data map
  /// @param index Index in the list for animation timing
  Widget buildProjectCard(BuildContext context, dynamic project, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)), // Staggered animations
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project title
              Text(
                project['title'] ?? 'Untitled Project',
                style: AppTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppTheme.spacingS),
              
              // Status and proposal count chips
              Row(
                children: [
                  buildStatusChip(project['status'] ?? 'Draft', getStatusColor(project['status'])),
                  const SizedBox(width: AppTheme.spacingXS),
                  buildStatusChip('${project['proposalCount'] ?? 0} Proposals', Theme.of(context).colorScheme.primary),
                ],
              ),
              const SizedBox(height: AppTheme.spacingS),
              
              // Progress bar showing project completion percentage
              LinearProgressIndicator(
                value: (project['progress'] ?? 0.0) / 100,
                backgroundColor: AppTheme.gray200,
                color: getStatusColor(project['status']),
                minHeight: 6,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusS),
              ),
              const SizedBox(height: AppTheme.spacingS),
              
              // Budget and view details button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Project budget display
                  Text(
                    '\$${project['budget'] ?? '0'}',
                    style: AppTheme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                  ),
                  
                  // View details button - navigates to project detail screen
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProjectDetailScreen(projectId: project['id']),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingM,
                        vertical: AppTheme.spacingXS,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                      ),
                    ),
                    child: Text(
                    'View Details',
                    style: AppTheme.textTheme.labelLarge,
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

  /// Builds a styled status chip with background and text color
  /// Used for project status and proposal count indicators
  /// @param label Text to display in the chip
  /// @param color Base color for the chip styling
  Widget buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingXS,
        vertical: AppTheme.spacingXXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), // Subtle background color
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
        border: Border.all(color: color.withOpacity(0.3), width: 1), // Border with matching color
      ),
      child: Text(
        label,
        style: AppTheme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  /// Returns appropriate color based on project status
  /// Maps status strings to corresponding theme colors
  /// @param status Project status string (case-insensitive)
  /// @return Color associated with the status
  Color getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return AppTheme.successGreen; // Green for active projects
      case 'completed':
        return AppTheme.primaryBlue;  // Blue for completed projects
      case 'cancelled':
        return AppTheme.errorRed;     // Red for cancelled projects
      default:
        return AppTheme.gray400;      // Gray for unknown/default status
    }
  }
}