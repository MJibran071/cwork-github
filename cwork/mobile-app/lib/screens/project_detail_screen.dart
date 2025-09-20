import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cwork_mobile/screens/escrow_deposit_screen.dart';
import 'package:cwork_mobile/services/api_service.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  Map<String, dynamic>? _project;
  List<dynamic>? _proposals;
  List<dynamic>? _milestones;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProjectData();
  }

  Future<void> _fetchProjectData() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final project = await apiService.getProject(widget.projectId);
      final proposals = await apiService.getProposals(widget.projectId);
      final milestones = await apiService.getMilestones(widget.projectId);
      
      setState(() {
        _project = project;
        _proposals = proposals;
        _milestones = milestones;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchProjectData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_project?['title'] ?? 'Project Details'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Proposals'),
              Tab(text: 'Details'),
              Tab(text: 'Milestones'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ProposalsTab(proposals: _proposals ?? [], projectId: widget.projectId),
            ProjectDetailsTab(project: _project ?? {}),
            MilestonesTab(milestones: _milestones ?? [], projectId: widget.projectId),
          ],
        ),
      ),
    );
  }
}

class ProposalsTab extends StatelessWidget {
  final List<dynamic> proposals;
  final String projectId;

  const ProposalsTab({super.key, required this.proposals, required this.projectId});

  @override
  Widget build(BuildContext context) {
    if (proposals.isEmpty) {
      return const Center(
        child: Text('No proposals yet.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: proposals.length,
      itemBuilder: (context, index) => _buildProposalCard(context, proposals[index]),
    );
  }

  Widget _buildProposalCard(BuildContext context, dynamic proposal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(proposal['freelancerAvatar'] ?? 'https://via.placeholder.com/50'),
              ),
              title: Text(
                proposal['freelancerName'] ?? 'Unknown Freelancer',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(proposal['freelancerTitle'] ?? 'Freelancer'),
              trailing: Chip(
                label: Text(
                  '\$${proposal['hourlyRate'] ?? '0'}/hr',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.blue,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.attach_money, size: 16),
                const SizedBox(width: 4),
                Text('\$${proposal['totalEarned'] ?? '0'} earned'),
                const SizedBox(width: 16),
                const Icon(Icons.star, size: 16),
                const SizedBox(width: 4),
                Text('${proposal['jobSuccessRate'] ?? '0'}% Job Success'),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              proposal['coverLetter'] ?? 'No cover letter provided.',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // Navigate to messaging screen
                  },
                  child: const Text('Message'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _showHireDialog(context, proposal['id']);
                  },
                  child: const Text('Hire'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showHireDialog(BuildContext context, String proposalId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hire Freelancer'),
        content: const Text('Are you sure you want to hire this freelancer? You will need to deposit funds into escrow.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EscrowDepositScreen(projectId: projectId, milestoneIndex: 0),
                ),
              );
            },
            child: const Text('Continue to Escrow'),
          ),
        ],
      ),
    );
  }
}

class ProjectDetailsTab extends StatelessWidget {
  final Map<String, dynamic> project;

  const ProjectDetailsTab({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project Details',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            project['description'] ?? 'No description provided.',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Requirements:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (project['requirements'] != null)
            ...(project['requirements'] as List<dynamic>).map((req) => Text('- $req'))
          else
            const Text('No requirements specified.'),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Budget: \$${project['budget'] ?? '0'}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Deadline: ${project['deadline'] ?? 'Not specified'}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Status: ${project['status'] ?? 'Unknown'}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class MilestonesTab extends StatelessWidget {
  final List<dynamic> milestones;
  final String projectId;

  const MilestonesTab({super.key, required this.milestones, required this.projectId});

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Milestones',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Milestones will be created after hiring a freelancer.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project Milestones',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: milestones.length,
            itemBuilder: (context, index) => _buildMilestoneCard(milestones[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(dynamic milestone) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              milestone['title'] ?? 'Untitled Milestone',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              milestone['description'] ?? 'No description',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Amount: \$${milestone['amount'] ?? '0'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(
                    milestone['status'] ?? 'Pending',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: _getStatusColor(milestone['status']),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (milestone['dueDate'] != null)
              Text(
                'Due: ${milestone['dueDate']}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
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
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}