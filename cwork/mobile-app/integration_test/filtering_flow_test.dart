import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:cwork_mobile/main.dart' as app;
import 'package:cwork_mobile/providers/auth_provider.dart';
import 'package:cwork_mobile/providers/wallet_provider.dart';
import 'package:cwork_mobile/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';

// Mock providers and services for integration testing
class MockAuthProvider extends Mock implements AuthProvider {
  // Add a user getter to mock the AuthProvider interface
  dynamic get user => super.noSuchMethod(Invocation.getter(#user));
}
class MockWalletProvider extends Mock implements WalletProvider {}
class MockApiService extends Mock implements ApiService {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Filtering Flow Integration Test', () {
    late MockAuthProvider mockAuthProvider;
    late MockWalletProvider mockWalletProvider;
    late MockApiService mockApiService;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
      mockWalletProvider = MockWalletProvider();
      mockApiService = MockApiService();
      
      // Setup mock behaviors - user is authenticated
      when(mockAuthProvider.isAuthenticated).thenReturn(true);
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.user).thenReturn({
        'name': 'Test User',
        'email': 'user@example.com',
        'role': 'freelancer'
      });
      when(mockWalletProvider.isConnected).thenReturn(true);
      when(mockWalletProvider.isLoading).thenReturn(false);
    });

    testWidgets('should filter projects by status successfully', (WidgetTester tester) async {
      // Mock project data with different statuses
      final mockProjects = [
        {
          'id': 'project-1',
          'title': 'Website Development',
          'description': 'Build a responsive website',
          'budget': 500.0,
          'timeline': 30,
          'status': 'open',
          'category': 'Web Development',
          'skillsRequired': ['React', 'JavaScript']
        },
        {
          'id': 'project-2',
          'title': 'Mobile App',
          'description': 'Develop a Flutter mobile app',
          'budget': 800.0,
          'timeline': 45,
          'status': 'in-progress',
          'category': 'Mobile Development',
          'skillsRequired': ['Flutter', 'Dart']
        },
        {
          'id': 'project-3',
          'title': 'API Integration',
          'description': 'Integrate third-party APIs',
          'budget': 300.0,
          'timeline': 20,
          'status': 'completed',
          'category': 'Backend Development',
          'skillsRequired': ['Node.js', 'REST API']
        }
      ];

      when(mockApiService.getProjects()).thenAnswer((_) async => mockProjects);
      // Note: Filtering methods like getProjectsByStatus may need to be implemented in ApiService
      // For now, we'll simulate filtering client-side or adjust tests accordingly

      // Start the app with authenticated user
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthProvider>.value(value: mockAuthProvider),
            Provider<WalletProvider>.value(value: mockWalletProvider),
            Provider<ApiService>.value(value: mockApiService),
          ],
          child: const MaterialApp(home: app.CWorkApp()),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to project list screen
      await tester.tap(find.text('Projects'));
      await tester.pumpAndSettle();

      // Verify all projects are shown initially
      expect(find.text('Website Development'), findsOneWidget);
      expect(find.text('Mobile App'), findsOneWidget);
      expect(find.text('API Integration'), findsOneWidget);

      // Open filter options
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Filter by 'open' status
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify only open projects are shown
      expect(find.text('Website Development'), findsOneWidget);
      expect(find.text('Mobile App'), findsNothing);
      expect(find.text('API Integration'), findsNothing);

      // Change filter to 'in-progress'
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();
      await tester.tap(find.text('In Progress'));
      await tester.pumpAndSettle();

      // Verify only in-progress projects are shown
      expect(find.text('Website Development'), findsNothing);
      expect(find.text('Mobile App'), findsOneWidget);
      expect(find.text('API Integration'), findsNothing);

      // Change filter to 'completed'
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      // Verify only completed projects are shown
      expect(find.text('Website Development'), findsNothing);
      expect(find.text('Mobile App'), findsNothing);
      expect(find.text('API Integration'), findsOneWidget);

      // Clear filters
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear Filters'));
      await tester.pumpAndSettle();

      // Verify all projects are shown again
      expect(find.text('Website Development'), findsOneWidget);
      expect(find.text('Mobile App'), findsOneWidget);
      expect(find.text('API Integration'), findsOneWidget);
    });

    testWidgets('should filter projects by category successfully', (WidgetTester tester) async {
      // Mock project data with different categories
      final mockProjects = [
        {
          'id': 'project-1',
          'title': 'Website Development',
          'description': 'Build a responsive website',
          'budget': 500.0,
          'timeline': 30,
          'status': 'open',
          'category': 'Web Development',
          'skillsRequired': ['React', 'JavaScript']
        },
        {
          'id': 'project-2',
          'title': 'Mobile App',
          'description': 'Develop a Flutter mobile app',
          'budget': 800.0,
          'timeline': 45,
          'status': 'open',
          'category': 'Mobile Development',
          'skillsRequired': ['Flutter', 'Dart']
        },
        {
          'id': 'project-3',
          'title': 'API Integration',
          'description': 'Integrate third-party APIs',
          'budget': 300.0,
          'timeline': 20,
          'status': 'open',
          'category': 'Backend Development',
          'skillsRequired': ['Node.js', 'REST API']
        }
      ];

      when(mockApiService.getProjects()).thenAnswer((_) async => mockProjects);
      // Category filtering would be implemented in ApiService or client-side

      // Start the app with authenticated user
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthProvider>.value(value: mockAuthProvider),
            Provider<WalletProvider>.value(value: mockWalletProvider),
            Provider<ApiService>.value(value: mockApiService),
          ],
          child: const MaterialApp(home: app.CWorkApp()),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to project list screen
      await tester.tap(find.text('Projects'));
      await tester.pumpAndSettle();

      // Open filter options
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Filter by 'Web Development' category
      await tester.tap(find.text('Web Development'));
      await tester.pumpAndSettle();

      // Verify only web development projects are shown
      expect(find.text('Website Development'), findsOneWidget);
      expect(find.text('Mobile App'), findsNothing);
      expect(find.text('API Integration'), findsNothing);

      // Change filter to 'Mobile Development'
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mobile Development'));
      await tester.pumpAndSettle();

      // Verify only mobile development projects are shown
      expect(find.text('Website Development'), findsNothing);
      expect(find.text('Mobile App'), findsOneWidget);
      expect(find.text('API Integration'), findsNothing);
    });

    testWidgets('should filter projects by budget range', (WidgetTester tester) async {
      // Mock project data with different budgets
      final mockProjects = [
        {
          'id': 'project-1',
          'title': 'Small Project',
          'description': 'Small budget project',
          'budget': 100.0,
          'timeline': 10,
          'status': 'open',
          'category': 'Web Development',
          'skillsRequired': ['HTML', 'CSS']
        },
        {
          'id': 'project-2',
          'title': 'Medium Project',
          'description': 'Medium budget project',
          'budget': 500.0,
          'timeline': 30,
          'status': 'open',
          'category': 'Web Development',
          'skillsRequired': ['React', 'JavaScript']
        },
        {
          'id': 'project-3',
          'title': 'Large Project',
          'description': 'Large budget project',
          'budget': 1000.0,
          'timeline': 60,
          'status': 'open',
          'category': 'Web Development',
          'skillsRequired': ['React', 'Node.js']
        }
      ];

      when(mockApiService.getProjects()).thenAnswer((_) async => mockProjects);
      // Budget range filtering would be implemented in ApiService or client-side

      // Start the app with authenticated user
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthProvider>.value(value: mockAuthProvider),
            Provider<WalletProvider>.value(value: mockWalletProvider),
            Provider<ApiService>.value(value: mockApiService),
          ],
          child: const MaterialApp(home: app.CWorkApp()),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to project list screen
      await tester.tap(find.text('Projects'));
      await tester.pumpAndSettle();

      // Open filter options
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Filter by budget range $0-$300
      await tester.tap(find.text('Budget: \$0 - \$300'));
      await tester.pumpAndSettle();

      // Verify only small budget projects are shown
      expect(find.text('Small Project'), findsOneWidget);
      expect(find.text('Medium Project'), findsNothing);
      expect(find.text('Large Project'), findsNothing);

      // Change filter to $300-$700
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Budget: \$300 - \$700'));
      await tester.pumpAndSettle();

      // Verify only medium budget projects are shown
      expect(find.text('Small Project'), findsNothing);
      expect(find.text('Medium Project'), findsOneWidget);
      expect(find.text('Large Project'), findsNothing);
    });

    testWidgets('should combine multiple filters', (WidgetTester tester) async {
      // Mock project data
      final mockProjects = [
        {
          'id': 'project-1',
          'title': 'React Website',
          'description': 'Build a React website',
          'budget': 500.0,
          'timeline': 30,
          'status': 'open',
          'category': 'Web Development',
          'skillsRequired': ['React', 'JavaScript']
        },
        {
          'id': 'project-2',
          'title': 'Flutter App',
          'description': 'Develop a Flutter app',
          'budget': 800.0,
          'timeline': 45,
          'status': 'open',
          'category': 'Mobile Development',
          'skillsRequired': ['Flutter', 'Dart']
        },
        {
          'id': 'project-3',
          'title': 'Node.js API',
          'description': 'Build a Node.js API',
          'budget': 300.0,
          'timeline': 20,
          'status': 'in-progress',
          'category': 'Backend Development',
          'skillsRequired': ['Node.js', 'REST API']
        }
      ];

      when(mockApiService.getProjects()).thenAnswer((_) async => mockProjects);
      // Combined filtering would be implemented in ApiService or client-side

      // Start the app with authenticated user
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthProvider>.value(value: mockAuthProvider),
            Provider<WalletProvider>.value(value: mockWalletProvider),
            Provider<ApiService>.value(value: mockApiService),
          ],
          child: const MaterialApp(home: app.CWorkApp()),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to project list screen
      await tester.tap(find.text('Projects'));
      await tester.pumpAndSettle();

      // Open filter options
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Apply multiple filters: status=open, category=Web Development
      await tester.tap(find.text('Open'));
      await tester.tap(find.text('Web Development'));
      await tester.pumpAndSettle();

      // Verify only matching project is shown
      expect(find.text('React Website'), findsOneWidget);
      expect(find.text('Flutter App'), findsNothing);
      expect(find.text('Node.js API'), findsNothing);
    });
  });
}