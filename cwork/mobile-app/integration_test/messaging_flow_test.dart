import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:cwork_mobile/main.dart';
import 'package:cwork_mobile/providers/auth_provider.dart';
import 'package:cwork_mobile/providers/wallet_provider.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';

// Mock providers for integration testing
class MockAuthProvider extends Mock implements AuthProvider {
  Future<List<dynamic>> getConversations() async => [];
  Future<List<dynamic>> getMessages(String conversationId) async => [];

  // Add user getter to mock provider
  Map<String, dynamic>? _user;
  @override
  Map<String, dynamic>? get user => _user;
  set user(Map<String, dynamic>? value) => _user = value;

  // Add sendMessage method to mock provider
  Future<Map<String, dynamic>?> sendMessage(String conversationId, String message) async {
    return null;
  }

  // Add connectWebSocket method to mock provider
  Future<bool> connectWebSocket() async {
    return true;
  }

  // Add errorMessage getter and setter to mock provider
  String? _errorMessage;
  @override
  String? get errorMessage => _errorMessage;
  set errorMessage(String? value) => _errorMessage = value;

  // Add isWebSocketConnected getter to mock provider
  bool _isWebSocketConnected = false;
  bool get isWebSocketConnected => _isWebSocketConnected;
  set isWebSocketConnected(bool value) => _isWebSocketConnected = value;
}
class MockWalletProvider extends Mock implements WalletProvider {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Messaging Flow Integration Test', () {
    late MockAuthProvider mockAuthProvider;
    late MockWalletProvider mockWalletProvider;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
      mockWalletProvider = MockWalletProvider();
      
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

    testWidgets('should send and receive messages in a conversation', (WidgetTester tester) async {
      // Mock conversation data
      final mockConversations = [
        {
          'id': 'conv-123',
          'participants': ['user1', 'user2'],
          'lastMessage': 'Hello there!',
          'lastMessageTime': '2024-01-01T12:00:00Z',
          'unreadCount': 0
        }
      ];

      final mockMessages = [
        {
          'id': 'msg-1',
          'sender': 'user1',
          'text': 'Hello!',
          'timestamp': '2024-01-01T10:00:00Z',
          'type': 'text'
        },
        {
          'id': 'msg-2',
          'sender': 'user2',
          'text': 'Hi there! How can I help?',
          'timestamp': '2024-01-01T10:01:00Z',
          'type': 'text'
        }
      ];

      when(mockAuthProvider.getConversations()).thenAnswer((_) async => mockConversations);
      when(mockAuthProvider.getMessages('conv-123')).thenAnswer((_) async => mockMessages);
      when(mockAuthProvider.sendMessage(any as String, any as String)).thenAnswer((_) async => {
        'id': 'msg-3',
        'sender': 'user1',
        'text': 'I need help with my project',
        'timestamp': '2024-01-01T10:02:00Z',
        'type': 'text'
      });

      // Start the app with authenticated user
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthProvider>.value(value: mockAuthProvider),
            Provider<WalletProvider>.value(value: mockWalletProvider),
          ],
          child: const MaterialApp(home: CWorkApp()),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to messaging screen
      await tester.tap(find.byIcon(Icons.message));
      await tester.pumpAndSettle();

      // Verify messaging screen is shown with conversations
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Hello there!'), findsOneWidget); // Last message preview

      // Tap on a conversation
      await tester.tap(find.text('Hello there!'));
      await tester.pumpAndSettle();

      // Verify conversation screen with messages
      expect(find.text('Hello!'), findsOneWidget);
      expect(find.text('Hi there! How can I help?'), findsOneWidget);

      // Send a new message
      await tester.enterText(find.byType(TextFormField), 'I need help with my project');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Verify new message is sent and appears in the chat
      expect(find.text('I need help with my project'), findsOneWidget);
    });

    testWidgets('should handle message sending failure', (WidgetTester tester) async {
      // Mock conversation data
      final mockConversations = [
        {
          'id': 'conv-123',
          'participants': ['user1', 'user2'],
          'lastMessage': 'Hello there!',
          'lastMessageTime': '2024-01-01T12:00:00Z',
          'unreadCount': 0
        }
      ];

      final mockMessages = [
        {
          'id': 'msg-1',
          'sender': 'user1',
          'text': 'Hello!',
          'timestamp': '2024-01-01T10:00:00Z',
          'type': 'text'
        }
      ];

      when(mockAuthProvider.getConversations()).thenAnswer((_) async => mockConversations);
      when(mockAuthProvider.getMessages('conv-123')).thenAnswer((_) async => mockMessages);
      when(mockAuthProvider.sendMessage(any as String, any as String)).thenAnswer((_) async => null);
      when(mockAuthProvider.errorMessage).thenReturn('Failed to send message: Network error');

      // Start the app with authenticated user
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthProvider>.value(value: mockAuthProvider),
            Provider<WalletProvider>.value(value: mockWalletProvider),
          ],
          child: const MaterialApp(home: CWorkApp()),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to messaging and open conversation
      await tester.tap(find.byIcon(Icons.message));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hello there!'));
      await tester.pumpAndSettle();

      // Try to send a message
      await tester.enterText(find.byType(TextFormField), 'Test message that will fail');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Verify error message is shown
      expect(find.text('Failed to send message: Network error'), findsOneWidget);
    });

    testWidgets('should show empty state when no conversations', (WidgetTester tester) async {
      when(mockAuthProvider.getConversations()).thenAnswer((_) async => []);

      // Start the app with authenticated user
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthProvider>.value(value: mockAuthProvider),
            Provider<WalletProvider>.value(value: mockWalletProvider),
          ],
          child: const MaterialApp(home: CWorkApp()),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to messaging screen
      await tester.tap(find.byIcon(Icons.message));
      await tester.pumpAndSettle();

      // Verify empty state is shown
      expect(find.text('No conversations yet'), findsOneWidget);
      expect(find.text('Start a conversation by messaging someone from a project'), findsOneWidget);
    });

    testWidgets('should handle WebSocket connection states', (WidgetTester tester) async {
      // Mock WebSocket connection states
      when(mockAuthProvider.isWebSocketConnected).thenReturn(false);
      when(mockAuthProvider.connectWebSocket()).thenAnswer((_) async => true);

      // Start the app with authenticated user
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthProvider>.value(value: mockAuthProvider),
            Provider<WalletProvider>.value(value: mockWalletProvider),
          ],
          child: const MaterialApp(home: CWorkApp()),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to messaging screen
      await tester.tap(find.byIcon(Icons.message));
      await tester.pumpAndSettle();

      // Verify connection status is shown when disconnected
      expect(find.text('Connecting...'), findsOneWidget);

      // Mock successful connection
      when(mockAuthProvider.isWebSocketConnected).thenReturn(true);
      await tester.pumpAndSettle();

      // Verify connected state
      expect(find.text('Connected'), findsOneWidget);
    });
  });
}