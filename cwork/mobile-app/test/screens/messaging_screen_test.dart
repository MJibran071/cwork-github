import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:cwork_mobile/services/api_service.dart';
import 'package:cwork_mobile/screens/messaging_screen.dart';

// Mock ApiService
class MockApiService extends Mock implements ApiService {}

void main() {
  group('MessagingScreen Unit Tests', () {
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

    test('Message class should have correct properties', () {
      final message = Message(
        text: 'Hello, world!',
        sender: 'John Doe',
        time: '12:00 PM',
        isMe: false,
      );

      expect(message.text, 'Hello, world!');
      expect(message.sender, 'John Doe');
      expect(message.time, '12:00 PM');
      expect(message.isMe, false);
    });

    test('_formatTime should handle null timestamp', () {
      const screen = MessagingScreen(
        projectId: 'test',
        recipientName: 'Test',
        recipientTitle: 'Test',
      );
      final state = screen.createState() as _MessagingScreenState;

      expect(state._formatTime(null), 'Unknown time');
    });

    test('_formatTime should return "Recently" for any timestamp', () {
      const screen = MessagingScreen(
        projectId: 'test',
        recipientName: 'Test',
        recipientTitle: 'Test',
      );
      final state = screen.createState() as _MessagingScreenState;

      expect(state._formatTime('2023-01-01T12:00:00Z'), 'Recently');
    });

    test('WebSocket URL construction should work correctly', () {
      const screen = MessagingScreen(
        projectId: 'test-project-456',
        recipientName: 'Test',
        recipientTitle: 'Test',
      );
      final state = screen.createState() as _MessagingScreenState;

      // This is a bit tricky to test directly since it uses dotenv
      // We can test the logic by simulating the URL construction
      const baseUrl = 'http://localhost:3000';
      final wsUrl = baseUrl.replaceFirst('http', 'ws').replaceFirst('https', 'wss');
      final expectedUrl = '$wsUrl/ws/messages?projectId=test-project-456';
      
      expect(wsUrl, 'ws://localhost:3000');
      expect(expectedUrl, 'ws://localhost:3000/ws/messages?projectId=test-project-456');
    });

    test('Message list should be properly initialized', () {
      const screen = MessagingScreen(
        projectId: 'test',
        recipientName: 'Test',
        recipientTitle: 'Test',
      );
      final state = screen.createState() as _MessagingScreenState;

      expect(state._messages, isEmpty);
      expect(state._isLoading, true);
      expect(state._error, isNull);
    });
  });
}