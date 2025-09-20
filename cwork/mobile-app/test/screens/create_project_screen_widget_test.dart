import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cwork_mobile/screens/create_project_screen.dart';
import 'package:cwork_mobile/services/api_service.dart';

// Mock ApiService for testing
class MockApiService extends ApiService {
  MockApiService() : super();

  @override
  Future<Map<String, dynamic>> createProject(Map<String, dynamic> projectData) async {
    // Mock successful project creation
    await Future.delayed(const Duration(milliseconds: 100));
    return {
      'id': 'test-project-123',
      'title': projectData['title'] ?? 'Test Project',
      'description': projectData['description'] ?? 'Test description',
      'budget': projectData['budget'] ?? 1000.0,
      'deadline': projectData['deadline'] ?? 30,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}

void main() {
  group('CreateProjectScreen Widget Tests', () {
    testWidgets('Initial screen renders correctly with all form fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        Provider<ApiService>.value(
          value: MockApiService(),
          child: const MaterialApp(
            home: CreateProjectScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify app bar title
      expect(find.text('Create New Project'), findsOneWidget);

      // Verify all form fields are present
      expect(find.text('Project Title'), findsOneWidget);
      expect(find.text('Project Description'), findsOneWidget);
      expect(find.text('Budget (USD)'), findsOneWidget);
      expect(find.text('Deadline'), findsOneWidget);
      expect(find.text('Create Project'), findsOneWidget);

      // Verify initial deadline value is 30 days
      expect(find.text('30 days'), findsOneWidget);
    });

    testWidgets('Form validation works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        Provider<ApiService>.value(
          value: MockApiService(),
          child: const MaterialApp(
            home: CreateProjectScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Try to submit with empty form
      await tester.tap(find.text('Create Project'));
      await tester.pump();

      // Should show validation errors
      expect(find.text('Please enter a project title'), findsOneWidget);
      expect(find.text('Please enter a project description'), findsOneWidget);
      expect(find.text('Please enter a budget'), findsOneWidget);
    });

    testWidgets('Text fields accept input correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        Provider<ApiService>.value(
          value: MockApiService(),
          child: const MaterialApp(
            home: CreateProjectScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter project title
      await tester.enterText(find.byKey(const Key('Project Title')), 'Test Project');
      expect(find.text('Test Project'), findsOneWidget);

      // Enter project description
      await tester.enterText(find.byKey(const Key('Project Description')), 'This is a test project description');
      expect(find.text('This is a test project description'), findsOneWidget);

      // Enter budget
      await tester.enterText(find.byKey(const Key('Budget (USD)')), '1000');
      expect(find.text('1000'), findsOneWidget);
    });

    testWidgets('Deadline dropdown selection works', (WidgetTester tester) async {
      await tester.pumpWidget(
        Provider<ApiService>.value(
          value: MockApiService(),
          child: const MaterialApp(
            home: CreateProjectScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the deadline dropdown
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();

      // Select 14 days
      await tester.tap(find.text('14 days').last);
      await tester.pumpAndSettle();

      // Verify selection
      expect(find.text('14 days'), findsOneWidget);
    });

    testWidgets('Budget field validates numeric input', (WidgetTester tester) async {
      await tester.pumpWidget(
        Provider<ApiService>.value(
          value: MockApiService(),
          child: const MaterialApp(
            home: CreateProjectScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter invalid budget (non-numeric)
      await tester.enterText(find.byKey(const Key('Budget (USD)')), 'invalid');
      await tester.tap(find.text('Create Project'));
      await tester.pump();

      // Should show validation error
      expect(find.text('Please enter a valid number'), findsOneWidget);
    });

    testWidgets('Submit button shows loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        Provider<ApiService>.value(
          value: MockApiService(),
          child: const MaterialApp(
            home: CreateProjectScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Fill out valid form
      await tester.enterText(find.byKey(const Key('Project Title')), 'Test Project');
      await tester.enterText(find.byKey(const Key('Project Description')), 'Test description');
      await tester.enterText(find.byKey(const Key('Budget (USD)')), '1000');

      // Tap submit button
      await tester.tap(find.text('Create Project'));
      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Create Project'), findsNothing);
    });

    testWidgets('Successful project creation shows success message', (WidgetTester tester) async {
      await tester.pumpWidget(
        Provider<ApiService>.value(
          value: MockApiService(),
          child: const MaterialApp(
            home: CreateProjectScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Fill out valid form
      await tester.enterText(find.byKey(const Key('Project Title')), 'Test Project');
      await tester.enterText(find.byKey(const Key('Project Description')), 'Test description');
      await tester.enterText(find.byKey(const Key('Budget (USD)')), '1000');

      // Tap submit button
      await tester.tap(find.text('Create Project'));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      // Should show success snackbar
      expect(find.text('Project created successfully!'), findsOneWidget);
    });

    testWidgets('Form fields have correct keyboard types', (WidgetTester tester) async {
      await tester.pumpWidget(
        Provider<ApiService>.value(
          value: MockApiService(),
          child: const MaterialApp(
            home: CreateProjectScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Budget field should have number keyboard
      final budgetField = tester.widget<TextFormField>(find.byKey(const Key('Budget (USD)')));
      expect(budgetField.keyboardType, TextInputType.number);

      // Title and description should have text keyboard
      final titleField = tester.widget<TextFormField>(find.byKey(const Key('Project Title')));
      expect(titleField.keyboardType, TextInputType.text);

      final descField = tester.widget<TextFormField>(find.byKey(const Key('Project Description')));
      expect(descField.keyboardType, TextInputType.multiline);
    });
  });
}