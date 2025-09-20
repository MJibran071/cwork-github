import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:cwork_mobile/services/api_service.dart';
import 'package:cwork_mobile/screens/project_detail_screen.dart';

// Mock ApiService
class MockApiService extends Mock implements ApiService {}

void main() {
  group('ProjectDetailScreen Unit Tests', () {
    late MockApiService mockApiService;
    late Widget testWidget;

    setUp(() {
      mockApiService = MockApiService();
      testWidget = MultiProvider(
        providers: [
          Provider<ApiService>.value(value: mockApiService),
        ],
        child: const MaterialApp(
          home: ProjectDetailScreen(projectId: 'test-project-123'),
        ),
      );
    });

    test('ProjectDetailScreen should initialize with correct state', () {
      const screen = ProjectDetailScreen(projectId: 'test-project-123');
      final state = screen.createState() as _ProjectDetailScreenState;

      expect(state._isLoading, true);
      expect(state._error, isNull);
      expect(state._project, isNull);
      expect(state._proposals, isNull);
      expect(state._milestones, isNull);
    });

    test('_fetchProjectData should call multiple APIs and update state on success', () async {
      const screen = ProjectDetailScreen(projectId: 'test-project-123');
      final state = screen.createState() as _ProjectDetailScreenState;

      // Mock API responses
      final mockProject = {'id': 'test-project-123', 'title': 'Test Project'};
      final mockProposals = [{'id': 'prop-1', 'freelancerName': 'John Doe'}];
      final mockMilestones = [{'id': 'mile-1', 'title': 'Milestone 1'}];

      when(mockApiService.getProject('test-project-123'))
          .thenAnswer((_) => Future.value(mockProject));
      when(mockApiService.getProposals('test-project-123'))
          .thenAnswer((_) => Future.value(mockProposals));
      when(mockApiService.getMilestones('test-project-123'))
          .thenAnswer((_) => Future.value(mockMilestones));

      // Call _fetchProjectData
      await state._fetchProjectData();

      // Verify all APIs were called
      verify(mockApiService.getProject('test-project-123')).called(1);
      verify(mockApiService.getProposals('test-project-123')).called(1);
      verify(mockApiService.getMilestones('test-project-123')).called(1);

      // Check state was updated
      expect(state._isLoading, false);
      expect(state._error, isNull);
      expect(state._project, mockProject);
      expect(state._proposals, mockProposals);
      expect(state._milestones, mockMilestones);
    });

    test('_fetchProjectData should handle API errors correctly', () async {
      const screen = ProjectDetailScreen(projectId: 'test-project-123');
      final state = screen.createState() as _ProjectDetailScreenState;

      // Mock API to throw an error
      when(mockApiService.getProject('test-project-123'))
          .thenThrow(Exception('Network error'));

      // Call _fetchProjectData
      await state._fetchProjectData();

      // Verify API was called
      verify(mockApiService.getProject('test-project-123')).called(1);

      // Check error state was set
      expect(state._isLoading, false);
      expect(state._error, isNotNull);
      expect(state._project, isNull);
      expect(state._proposals, isNull);
      expect(state._milestones, isNull);
    });

    test('MilestonesTab _getStatusColor should return correct colors', () {
      const milestonesTab = MilestonesTab(milestones: [], projectId: 'test');
      
      expect(milestonesTab._getStatusColor('completed'), Colors.green);
      expect(milestonesTab._getStatusColor('in progress'), Colors.blue);
      expect(milestonesTab._getStatusColor('pending'), Colors.orange);
      expect(milestonesTab._getStatusColor('cancelled'), Colors.red);
      expect(milestonesTab._getStatusColor(null), Colors.grey);
      expect(milestonesTab._getStatusColor('unknown'), Colors.grey);
    });

    test('ProposalsTab should handle null values gracefully', () {
      const proposalsTab = ProposalsTab(proposals: [], projectId: 'test');
      
      // Test with proposal containing null values
      final proposalWithNulls = {
        'id': null,
        'freelancerName': null,
        'freelancerTitle': null,
        'hourlyRate': null,
        'totalEarned': null,
        'jobSuccessRate': null,
        'coverLetter': null
      };

      // Should not throw when building card
      expect(() => proposalsTab._buildProposalCard(BuildContext(), proposalWithNulls), returnsNormally);
    });

    test('ProjectDetailsTab should handle null project data', () {
      const projectDetailsTab = ProjectDetailsTab(project: {});
      
      // Should not throw when building with empty project
      expect(() => projectDetailsTab.build(BuildContext()), returnsNormally);
    });

    test('MilestonesTab should handle empty milestones list', () {
      const milestonesTab = MilestonesTab(milestones: [], projectId: 'test');
      
      // Should not throw when building with empty milestones
      expect(() => milestonesTab.build(BuildContext()), returnsNormally);
    });
  });
}