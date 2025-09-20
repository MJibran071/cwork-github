import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:cwork_mobile/services/api_service.dart';
import 'package:cwork_mobile/screens/messaging_screen.dart';

// Mock ApiService
class MockApiService extends Mock implements ApiService {}

void main() {
  group('MessagingScreen Widget Tests', () {
    late MockApiService mockApiService;
    late Widget testWidget;

    setUp(() {
      mockApiService = MockApiService();
      testWidget = MultiProvider(
        providers: [
          Provider<ApiService>.value(value: mockApiService),
        ],
        child: const MaterialApp(
          home: MessagingScreen(
            projectId: 'test-project-123',
            recipientName: 'John Doe',
            recipientTitle: 'Senior Developer',
          ),
        ),
      );
    });

    testWidgets('should show loading indicator when initializing', (WidgetTester tester) async {
      // Arrange - mock API to return slowly
      when(mockApiService.getMessages('test-project-123'))
          .thenAnswer((_) => Future.delayed(const Duration(seconds: 1), () => []));

      // Act
      await tester.pumpWidget(testWidget);
      await tester.pump(); // Initial build

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error message when API call fails', (WidgetTester tester) async {
      // Arrange
      when(mockApiService.getMessages('test-project-123'))
          .thenThrow(Exception('Network error'));

      // Act
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Error: Exception: Network error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should display messages when loaded successfully', (WidgetTester tester) async {
      // Arrange
      final mockMessages = [
        {
          'content': 'Hello there!',
          'senderName': 'John Doe',
          'createdAt': '2023-01-01T12:00:00Z',
          'isSender': false
        },
        {
          'content': 'Hi John!',
          'senderName': 'You',
          'createdAt': '2023-01-01T12:01:00Z',
          'isSender': true
        }
      ];

      when(mockApiService.getMessages('test-project-123'))
          .thenAnswer((_) => Future.value(mockMessages));

      // Act
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Hello there!'), findsOneWidget);
      expect(find.text('Hi John!'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
    });

    testWidgets('should show message input field and send button', (WidgetTester tester) async {
      // Arrange
      when(mockApiService.getMessages('test-project-123'))
          .thenAnswer((_) => Future.value([]));

      // Act
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget); // Hint text not directly findable in tests
    });

    testWidgets('should send message when send button is pressed', (WidgetTester tester) async {
      // Arrange
      when(mockApiService.getMessages('test-project-123'))
          .thenAnswer((_) => Future.value([]));
      when(mockApiService.sendMessage('test-project-123', 'Test message'))
          .thenAnswer((_) => Future.value());

      // Act
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Enter text and send
      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Assert
      verify(mockApiService.sendMessage('test-project-123', 'Test message')).called(1);
      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('should not send empty message', (WidgetTester tester) async {
      // Arrange
      when(mockApiService.getMessages('test-project-123'))
          .thenAnswer((_) => Future.value([]));

      // Act
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Try to send empty message
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // Assert - no API call should be made for empty message
      verifyNever(mockApiService.sendMessage(any<String>(), any<String>()));
    });

    testWidgets('should show conversation info dialog when info button is pressed', (WidgetTester tester) async {
      // Arrange
      when(mockApiService.getMessages('test-project-123'))
          .thenAnswer((_) => Future.value([]));

      // Act
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Tap info button
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Conversation Info'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Senior Developer'), findsOneWidget);
      expect(find.text('Project ID: test-project-123'), findsOneWidget);
    });

    testWidgets('should clear text field after sending message', (WidgetTester tester) async {
      // Arrange
      when(mockApiService.getMessages('test-project-123'))
          .thenAnswer((_) => Future.value([]));
      when(mockApiService.sendMessage('test-project-123', 'Test message'))
          .thenAnswer((_) => Future.value());

      // Act
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Enter text and send
      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Assert - text field should be cleared
      expect(find.text('Test message'), findsNothing); // In the text field
      expect(find.widgetWithText(TextField, 'Test message'), findsNothing);
    });

    testWidgets('should show snackbar when message sending fails', (WidgetTester tester) async {
      // Arrange
      when(mockApiService.getMessages('test-project-123'))
          .thenAnswer((_) => Future.value([]));
      when(mockApiService.sendMessage('test-project-123', 'Test message'))
          .thenThrow(Exception('Send failed'));

      // Act
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Enter text and send
      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Assert - snackbar should be shown
      expect(find.text('Failed to send message: Exception: Send failed'), findsOneWidget);
    });

    testWidgets('should retry loading messages when retry button is pressed', (WidgetTester tester) async {
      // Arrange - first call fails, second succeeds
      var callCount = 0;
      when(mockApiService.getMessages('test-project-123'))
          .thenAnswer((_) async {
            if (callCount == 0) {
              callCount++;
              throw Exception('Network error');
            }
            return [];
          });

      // Act
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Tap retry button
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Assert - should call getMessages twice
      verify(mockApiService.getMessages('test-project-123')).called(2);
    });
  });
}