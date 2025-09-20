import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:cwork_mobile/services/api_service.dart';
import 'package:cwork_mobile/screens/project_list_screen.dart';

// Mock ApiService
class MockApiService extends Mock implements ApiService {}

void main() {
  group('ProjectListScreen Unit Tests', () {
    late MockApiService mockApiService;
    late Widget testWidget;

    setUp(() {
      mockApiService = MockApiService();
      testWidget = MultiProvider(
        providers: [
          Provider<ApiService>.value(value: mockApiService),
        ],
        child: const MaterialApp(
          home: ProjectListScreen(),
        ),
      );
    });

    test('ProjectListScreen should initialize with correct state', () {
      const screen = ProjectListScreen();
      final state = screen.createState() as ProjectListScreenState;

      expect(state.isLoading, true);
      expect(state.error, isNull);
      expect(state.projects, isEmpty);
    });

    test('getStatusColor should return correct colors for different statuses', () {
      const screen = ProjectListScreen();
      final state = screen.createState() as ProjectListScreenState;

      expect(state.getStatusColor('active'), Colors.green);
      expect(state.getStatusColor('completed'), Colors.blue);
      expect(state.getStatusColor('cancelled'), Colors.red);
      expect(state.getStatusColor('draft'), Colors.grey);
      expect(state.getStatusColor(null), Colors.grey);
      expect(state.getStatusColor('unknown'), Colors.grey);
    });

    testWidgets('fetchProjects should call API and update state on success', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      final state = tester.state<ProjectListScreenState>(find.byType(ProjectListScreen));

      // Mock the API response
      final mockProjects = [
        {
          'id': '1',
          'title': 'Test Project',
          'status': 'active',
          'proposalCount': 5,
          'progress': 50.0,
          'budget': 1000
        }
      ];

      when(mockApiService.getProjects()).thenAnswer((_) => Future.value(mockProjects));

      // Call fetchProjects
      await state.fetchProjects();

      // Verify API was called
      verify(mockApiService.getProjects()).called(1);

      // Check state was updated
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.projects, mockProjects);
    });

    testWidgets('fetchProjects should handle API errors correctly', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      final state = tester.state<ProjectListScreenState>(find.byType(ProjectListScreen));

      // Mock API to throw an error
      when(mockApiService.getProjects()).thenThrow(Exception('Network error'));

      // Call fetchProjects
      await state.fetchProjects();

      // Verify API was called
      verify(mockApiService.getProjects()).called(1);

      // Check error state was set
      expect(state.isLoading, false);
      expect(state.error, isNotNull);
      expect(state.projects, isEmpty);
    });

    test('buildStatusChip should create a Chip widget with correct properties', () {
      const screen = ProjectListScreen();
      final state = screen.createState() as ProjectListScreenState;

      final chip = state.buildStatusChip('Test Label', Colors.red);

      // Verify it's a Chip widget
      expect(chip, isA<Chip>());
      // Additional checks could be done on the chip properties if needed
    });

    testWidgets('Project card building should handle null values gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      final state = tester.state<ProjectListScreenState>(find.byType(ProjectListScreen));

      // Test with minimal project data
      final projectWithNulls = {
        'id': null,
        'title': null,
        'status': null,
        'proposalCount': null,
        'progress': null,
        'budget': null
      };

      // This should not throw an exception
      expect(() => state.buildProjectCard(tester.element(find.byType(ProjectListScreen)), projectWithNulls, 0), returnsNormally);
    });
  });
}