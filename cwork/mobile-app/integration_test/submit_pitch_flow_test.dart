import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:cwork_mobile/main.dart' as app;
import 'package:cwork_mobile/providers/auth_provider.dart';
import 'package:cwork_mobile/providers/wallet_provider.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:web3dart/web3dart.dart';

// Mock providers for integration testing
class MockAuthProvider extends Mock implements AuthProvider {
  // Add a user getter to mock the AuthProvider's user property
  dynamic _user;
  @override
  dynamic get user => _user;
  set user(dynamic value) => _user = value;

  // Add errorMessage to mock the AuthProvider's errorMessage property
  String? _errorMessage;
  @override
  String? get errorMessage => _errorMessage;
  set errorMessage(String? value) => _errorMessage = value;

  // Add getProject to mock the AuthProvider's getProject method
  @override
  Future<dynamic> getProject(String projectId) async => super.noSuchMethod(
    Invocation.method(#getProject, [projectId]),
    returnValue: Future.value(null),
    returnValueForMissingStub: Future.value(null),
  );

  // Add submitPitch to mock the AuthProvider's submitPitch method
  @override
  Future<dynamic> submitPitch(dynamic projectId, dynamic pitchData) async => super.noSuchMethod(
    Invocation.method(#submitPitch, [projectId, pitchData]),
    returnValue: Future.value(null),
    returnValueForMissingStub: Future.value(null),
  );
}
class MockWalletProvider extends Mock implements WalletProvider {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Submit Pitch Flow Integration Test', () {
    late MockAuthProvider mockAuthProvider;
    late MockWalletProvider mockWalletProvider;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
      mockWalletProvider = MockWalletProvider();
      
      // Setup mock behaviors - user is authenticated as freelancer
      when(mockAuthProvider.isAuthenticated).thenReturn(true);
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.user).thenReturn({
        'name': 'Test Freelancer',
        'email': 'freelancer@example.com',
        'role': 'freelancer',
        'skills': ['React', 'JavaScript', 'Flutter']
      });
      when(mockWalletProvider.isConnected).thenReturn(true);
      when(mockWalletProvider.address).thenReturn(EthereumAddress.fromHex('0xfreelancer123'));
      when(mockWalletProvider.balance).thenReturn('2.5 ETH');
    });

    testWidgets('should submit a pitch to a project successfully', (WidgetTester tester) async {
      // Mock project data
      final mockProject = {
        'id': 'project-123',
        'title': 'Website Development',
        'description': 'Need a responsive website built with React',
        'budget': 500.0,
        'timeline': 30,
        'status': 'open',
        'client': {'name': 'Test Client'},
        'skillsRequired': ['React', 'JavaScript']
      };

      when(mockAuthProvider.getProject('project-123')).thenAnswer((_) async => mockProject);
      when(mockAuthProvider.submitPitch(any, any)).thenAnswer((_) async => {
        'id': 'pitch-456',
        'projectId': 'project-123',
        'freelancerId': 'freelancer-789',
        'proposal': 'I can build this website with React and Node.js',
        'bidAmount': 450.0,
        'timeline': 25,
        'status': 'submitted'
      });

      // Start the app with authenticated user
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthProvider>.value(value: mockAuthProvider),
            Provider<WalletProvider>.value(value: mockWalletProvider),
          ],
          child: const MaterialApp(home: app.CWorkApp()),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to project list or details (assuming we're on a screen with projects)
      await tester.tap(find.text('Projects'));
      await tester.pumpAndSettle();

      // Find and tap on a project to view details
      await tester.tap(find.text('Website Development'));
      await tester.pumpAndSettle();

      // Verify project details screen
      expect(find.text('Website Development'), findsOneWidget);
      expect(find.text('Need a responsive website built with React'), findsOneWidget);

      // Tap submit pitch button
      await tester.tap(find.text('Submit Pitch'));
      await tester.pumpAndSettle();

      // Verify pitch form is shown
      expect(find.text('Submit Your Pitch'), findsOneWidget);

      // Fill out pitch form
      await tester.enterText(find.byType(TextFormField).at(0), 'I can build this website with React and Node.js');
      await tester.enterText(find.byType(TextFormField).at(1), '450'); // Bid amount
      await tester.enterText(find.byType(TextFormField).at(2), '25'); // Proposed timeline

      // Submit the pitch
      await tester.tap(find.text('Submit Pitch'));
      await tester.pumpAndSettle();

      // Verify success message
      expect(find.text('Pitch submitted successfully!'), findsOneWidget);
    });

    testWidgets('should show validation errors for invalid pitch data', (WidgetTester tester) async {
      // Mock project data
      final mockProject = {
        'id': 'project-123',
        'title': 'Website Development',
        'description': 'Need a responsive website built with React',
        'budget': 500.0,
        'timeline': 30,
        'status': 'open'
      };

      when(mockAuthProvider.getProject('project-123')).thenAnswer((_) async => mockProject);

      // Start the app with authenticated user
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthProvider>.value(value: mockAuthProvider),
            Provider<WalletProvider>.value(value: mockWalletProvider),
          ],
          child: const MaterialApp(home: app.CWorkApp()),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to project and open pitch form
      await tester.tap(find.text('Projects'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Website Development'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit Pitch'));
      await tester.pumpAndSettle();

      // Try to submit empty form
      await tester.tap(find.text('Submit Pitch'));
      await tester.pumpAndSettle();

      // Verify validation errors
      expect(find.text('Please enter your proposal'), findsOneWidget);
      expect(find.text('Please enter a bid amount'), findsOneWidget);

      // Fill with invalid data
      await tester.enterText(find.byType(TextFormField).at(0), 'Short'); // Too short proposal
      await tester.enterText(find.byType(TextFormField).at(1), '0'); // Zero bid amount
      await tester.enterText(find.byType(TextFormField).at(2), '0'); // Zero timeline

      await tester.tap(find.text('Submit Pitch'));
      await tester.pumpAndSettle();

      // Verify specific validation errors
      expect(find.text('Proposal must be at least 10 characters'), findsOneWidget);
      expect(find.text('Bid amount must be greater than 0'), findsOneWidget);
      expect(find.text('Timeline must be at least 1 day'), findsOneWidget);
    });

    testWidgets('should handle pitch submission failure', (WidgetTester tester) async {
      // Mock project data
      final mockProject = {
        'id': 'project-123',
        'title': 'Website Development',
        'description': 'Need a responsive website built with React',
        'budget': 500.0,
        'timeline': 30,
        'status': 'open'
      };

      when(mockAuthProvider.getProject('project-123')).thenAnswer((_) async => mockProject);
      when(mockAuthProvider.submitPitch(any, any)).thenAnswer((_) async => null);
      when(mockAuthProvider.errorMessage).thenReturn('Failed to submit pitch: Network error');

      // Start the app with authenticated user
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthProvider>.value(value: mockAuthProvider),
            Provider<WalletProvider>.value(value: mockWalletProvider),
          ],
          child: const MaterialApp(home: app.CWorkApp()),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to project and open pitch form
      await tester.tap(find.text('Projects'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Website Development'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit Pitch'));
      await tester.pumpAndSettle();

      // Fill valid form
      await tester.enterText(find.byType(TextFormField).at(0), 'I have extensive experience with React and can deliver a high-quality website.');
      await tester.enterText(find.byType(TextFormField).at(1), '480');
      await tester.enterText(find.byType(TextFormField).at(2), '28');

      // Submit the pitch
      await tester.tap(find.text('Submit Pitch'));
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.text('Failed to submit pitch: Network error'), findsOneWidget);
    });

    testWidgets('should show appropriate message for closed projects', (WidgetTester tester) async {
      // Mock closed project data
      final mockClosedProject = {
        'id': 'project-123',
        'title': 'Website Development',
        'description': 'Need a responsive website built with React',
        'budget': 500.0,
        'timeline': 30,
        'status': 'closed'
      };

      when(mockAuthProvider.getProject('project-123')).thenAnswer((_) async => mockClosedProject);

      // Start the app with authenticated user
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthProvider>.value(value: mockAuthProvider),
            Provider<WalletProvider>.value(value: mockWalletProvider),
          ],
          child: const MaterialApp(home: app.CWorkApp()),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to closed project
      await tester.tap(find.text('Projects'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Website Development'));
      await tester.pumpAndSettle();

      // Verify project is closed and submit button is disabled or shows appropriate message
      expect(find.text('Project Closed'), findsOneWidget);
      expect(find.text('Submit Pitch'), findsNothing); // Button should not be available
    });
  });
}