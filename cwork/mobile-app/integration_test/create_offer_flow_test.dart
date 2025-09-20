import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:cwork_mobile/main.dart';
import 'package:cwork_mobile/providers/auth_provider.dart';
import 'package:cwork_mobile/providers/wallet_provider.dart';
import 'package:cwork_mobile/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:web3dart/web3dart.dart';

// Mock providers for integration testing
class MockAuthProvider extends Mock implements AuthProvider {}
class MockWalletProvider extends Mock implements WalletProvider {}
class MockApiService extends Mock implements ApiService {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Create Offer Flow Integration Test', () {
    late MockAuthProvider mockAuthProvider;
    late MockWalletProvider mockWalletProvider;
    late MockApiService mockApiService;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
      mockWalletProvider = MockWalletProvider();
      mockApiService = MockApiService();
      
      // Setup mock behaviors - user is authenticated and has wallet connected
      when(mockAuthProvider.isAuthenticated).thenReturn(true);
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.name).thenReturn('Test Client');
      when(mockAuthProvider.email).thenReturn('client@example.com');
      when(mockAuthProvider.role).thenReturn('client');
      when(mockWalletProvider.isConnected).thenReturn(true);
      when(mockWalletProvider.isLoading).thenReturn(false);
      when(mockWalletProvider.address).thenReturn(EthereumAddress.fromHex('0x1234567890abcdef'));
      when(mockWalletProvider.balance).thenReturn('5.0 ETH');
    });

    testWidgets('should create a new project offer successfully', (WidgetTester tester) async {
      // Start the app with authenticated user
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthProvider>.value(value: mockAuthProvider),
            Provider<WalletProvider>.value(value: mockWalletProvider),
            Provider<ApiService>.value(value: mockApiService),
          ],
          child: const MaterialApp(home: CWorkApp()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify we're on the home screen or client dashboard
      expect(find.text('Home'), findsOneWidget);
      
      // Navigate to create project screen
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify create project screen is shown
      expect(find.text('Create New Project'), findsOneWidget);

      // Fill out project creation form
      await tester.enterText(find.byType(TextFormField).at(0), 'Website Development');
      await tester.enterText(find.byType(TextFormField).at(1), 'Need a responsive website built with React');
      await tester.enterText(find.byType(TextFormField).at(2), '500'); // Budget
      await tester.enterText(find.byType(TextFormField).at(3), '30'); // Timeline in days

      // Select category from dropdown
      await tester.tap(find.text('Select Category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Web Development').last);
      await tester.pumpAndSettle();

      // Select skills required
      await tester.tap(find.text('Add Skills'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('React').last);
      await tester.tap(find.text('JavaScript').last);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Mock successful project creation
      when(mockApiService.createProject(anyNamed('projectData'))).thenAnswer((_) async => {
        'id': 'project-123',
        'title': 'Website Development',
        'description': 'Need a responsive website built with React',
        'budget': 500.0,
        'timeline': 30,
        'status': 'open'
      });

      // Submit the project
      await tester.tap(find.text('Create Project'));
      await tester.pumpAndSettle();

      // Verify success message and navigation
      expect(find.text('Project created successfully!'), findsOneWidget);
      expect(find.text('Website Development'), findsOneWidget); // Should be in project list
    });

    testWidgets('should show validation errors for invalid project data', (WidgetTester tester) async {
      // Start the app with authenticated user
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthProvider>.value(value: mockAuthProvider),
            Provider<WalletProvider>.value(value: mockWalletProvider),
            Provider<ApiService>.value(value: mockApiService),
          ],
          child: const MaterialApp(home: CWorkApp()),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to create project screen
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Try to submit empty form
      await tester.tap(find.text('Create Project'));
      await tester.pumpAndSettle();

      // Verify validation errors
      expect(find.text('Please enter a title'), findsOneWidget);
      expect(find.text('Please enter a description'), findsOneWidget);
      expect(find.text('Please enter a budget'), findsOneWidget);

      // Fill with invalid data
      await tester.enterText(find.byType(TextFormField).at(0), 'A'); // Too short title
      await tester.enterText(find.byType(TextFormField).at(1), 'Short'); // Too short description
      await tester.enterText(find.byType(TextFormField).at(2), '0'); // Zero budget
      await tester.enterText(find.byType(TextFormField).at(3), '0'); // Zero timeline

      await tester.tap(find.text('Create Project'));
      await tester.pumpAndSettle();

      // Verify specific validation errors
      expect(find.text('Title must be at least 3 characters'), findsOneWidget);
      expect(find.text('Description must be at least 10 characters'), findsOneWidget);
      expect(find.text('Budget must be greater than 0'), findsOneWidget);
      expect(find.text('Timeline must be at least 1 day'), findsOneWidget);
    });

    testWidgets('should handle project creation failure', (WidgetTester tester) async {
      // Start the app with authenticated user
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthProvider>.value(value: mockAuthProvider),
            Provider<WalletProvider>.value(value: mockWalletProvider),
            Provider<ApiService>.value(value: mockApiService),
          ],
          child: const MaterialApp(home: CWorkApp()),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to create project screen
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill out valid form
      await tester.enterText(find.byType(TextFormField).at(0), 'Mobile App Development');
      await tester.enterText(find.byType(TextFormField).at(1), 'Need a Flutter mobile app with backend integration');
      await tester.enterText(find.byType(TextFormField).at(2), '1000');
      await tester.enterText(find.byType(TextFormField).at(3), '45');

      // Mock project creation failure
      when(mockApiService.createProject(anyNamed('projectData'))).thenThrow(Exception('Failed to create project: Network error'));

      // Submit the project
      await tester.tap(find.text('Create Project'));
      await tester.pumpAndSettle();

      // Verify error message is shown
      expect(find.text('Failed to create project: Network error'), findsOneWidget);
    });

    testWidgets('should allow editing project details before submission', (WidgetTester tester) async {
      // Start the app with authenticated user
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthProvider>.value(value: mockAuthProvider),
            Provider<WalletProvider>.value(value: mockWalletProvider),
            Provider<ApiService>.value(value: mockApiService),
          ],
          child: const MaterialApp(home: CWorkApp()),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to create project screen
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill initial data
      await tester.enterText(find.byType(TextFormField).at(0), 'Initial Title');
      await tester.enterText(find.byType(TextFormField).at(1), 'Initial description that is long enough');
      await tester.enterText(find.byType(TextFormField).at(2), '200');
      await tester.enterText(find.byType(TextFormField).at(3), '15');

      // Edit the data
      await tester.enterText(find.byType(TextFormField).at(0), 'Updated Title');
      await tester.enterText(find.byType(TextFormField).at(1), 'Updated description that is also long enough');
      await tester.enterText(find.byType(TextFormField).at(2), '300');
      await tester.enterText(find.byType(TextFormField).at(3), '20');

      // Verify the values are updated
      expect(find.text('Updated Title'), findsOneWidget);
      expect(find.text('Updated description that is also long enough'), findsOneWidget);
      expect(find.text('300'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);

      // Mock successful submission
      when(mockApiService.createProject(anyNamed('projectData'))).thenAnswer((_) async => {
        'id': 'project-456',
        'title': 'Updated Title',
        'description': 'Updated description that is also long enough',
        'budget': 300.0,
        'timeline': 20,
        'status': 'open'
      });

      // Submit the project
      await tester.tap(find.text('Create Project'));
      await tester.pumpAndSettle();

      // Verify success
      expect(find.text('Project created successfully!'), findsOneWidget);
    });
  });
}