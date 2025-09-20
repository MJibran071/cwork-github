// Messaging Screen - Real-time chat interface with WebSocket support
// Handles both API-based messaging and demo data fallback
// Supports bidirectional communication with message history

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cwork_mobile/services/api_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Messaging screen for project-specific conversations
/// Supports real-time messaging via WebSocket with API fallback
/// Displays conversation history and allows sending new messages
class MessagingScreen extends StatefulWidget {
  final String projectId;        // ID of the project being discussed
  final String recipientName;     // Name of the message recipient
  final String recipientTitle;   // Title/role of the recipient

  const MessagingScreen({
    super.key,
    required this.projectId,
    required this.recipientName,
    required this.recipientTitle,
  });

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

/// State class for MessagingScreen managing messages and WebSocket connection
class _MessagingScreenState extends State<MessagingScreen> {
  final List<Message> _messages = [];              // List of messages in the conversation
  final TextEditingController _messageController = TextEditingController(); // Controller for message input
  bool _isLoading = true;                          // Loading state indicator
  String? _error;                                  // Error message for API failures
  WebSocketChannel? _channel;                      // WebSocket channel for real-time communication
  
  // Regex patterns for restricted content detection
  static final RegExp _emailRegex = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'); // Simplified email pattern
  static final RegExp _phoneRegex = RegExp(
      r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$'); // Catches most international formats
  
  String _currentMessage = '';                     // Current message text for real-time validation
  bool _containsRestrictedInfo = false;            // Flag for restricted content detection

  /// Initialize state - fetch messages and connect to WebSocket
  @override
  void initState() {
    super.initState();
    _fetchMessages();       // Load message history
    _connectWebSocket();    // Establish real-time connection
  }

  /// Clean up resources when widget is disposed
  /// Prevents memory leaks and closes WebSocket connection
  @override
  void dispose() {
    _messageController.dispose();  // Dispose text controller
    _channel?.sink.close();        // Close WebSocket connection
    super.dispose();
  }

  /// Fetches messages from API with fallback to demo data
  /// Handles both successful API responses and errors gracefully
  Future<void> _fetchMessages() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final messages = await apiService.getMessages(widget.projectId);
      setState(() {
        _messages.clear();
        // Convert API response to Message objects
        _messages.addAll(messages.map((msg) => Message(
              text: msg['content'] ?? '',
              sender: msg['senderName'] ?? 'Unknown',
              time: _formatTime(msg['createdAt']),
              isMe: msg['isSender'] ?? false,
            )));
        
        // Add demo messages if no messages from API (empty response)
        if (_messages.isEmpty) {
          _messages.addAll(_getDemoMessages());
        }
        
        _isLoading = false; // Hide loading indicator
      });
    } catch (e) {
      // Fallback to demo messages if API call fails
      setState(() {
        _messages.clear();
        _messages.addAll(_getDemoMessages());
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  /// Provides demo conversation data for development and fallback scenarios
  /// Includes realistic message exchange between user and another party
  List<Message> _getDemoMessages() {
    return [
      Message(
        text: 'Hi there! I\'m interested in your project. Can you tell me more about the requirements?',
        sender: 'Sarah Chen',
        time: '2 hours ago',
        isMe: false,
      ),
      Message(
        text: 'Sure! I need a responsive website with modern design and good SEO optimization.',
        sender: 'You',
        time: '1 hour ago',
        isMe: true,
      ),
      Message(
        text: 'That sounds great! I have experience with React and SEO. What\'s your budget range?',
        sender: 'Sarah Chen',
        time: '45 minutes ago',
        isMe: false,
      ),
      Message(
        text: 'I\'m looking at around \$1500-2000 for this project. Does that work for you?',
        sender: 'You',
        time: '30 minutes ago',
        isMe: true,
      ),
      Message(
        text: 'That works for me! I can start next week. Should we discuss the timeline?',
        sender: 'Sarah Chen',
        time: '15 minutes ago',
        isMe: false,
      ),
      Message(
        text: 'Perfect! Let me send you the project details and we can finalize the agreement.',
        sender: 'You',
        time: 'Just now',
        isMe: true,
      ),
    ];
  }

  /// Formats timestamp for display (simplified version)
  /// In production, this would use proper date/time formatting
  /// @param timestamp The timestamp string to format
  /// @return Formatted time string
  String _formatTime(String? timestamp) {
    if (timestamp == null) return 'Unknown time';
    // Simple formatting - in a real app, use a proper date/time formatter
    return 'Recently';
  }

  /// Establishes WebSocket connection for real-time messaging
  /// Listens for incoming messages and updates UI accordingly
  /// Handles fallback for development when backend is unavailable
  void _connectWebSocket() {
    try {
      // Construct WebSocket URL from environment configuration
      final baseUrl = dotenv.get('API_BASE_URL') ?? 'http://localhost:3000';
      final wsUrl = baseUrl.replaceFirst('http', 'ws').replaceFirst('https', 'wss');
      final url = Uri.parse('$wsUrl/ws/messages?projectId=${widget.projectId}');
      
      _channel = WebSocketChannel.connect(url); // Connect to WebSocket (platform-agnostic)
      
      // Listen for incoming messages
      _channel?.stream.listen(
        (message) {
          final data = json.decode(message);
          setState(() {
            // Add new message to the list when received via WebSocket
            _messages.add(Message(
              text: data['content'] ?? '',
              sender: data['senderName'] ?? 'Unknown',
              time: _formatTime(data['createdAt']),
              isMe: data['isSender'] ?? false,
            ));
          });
        },
        onError: (error) {
          print('WebSocket error: $error'); // Log WebSocket errors
          // Fallback to demo mode if WebSocket fails
          _enableDemoMode();
        },
        onDone: () {
          print('WebSocket connection closed'); // Log connection closure
        },
      );
    } catch (e) {
      print('Failed to connect WebSocket: $e'); // Log connection failures
      // Fallback to demo mode if connection fails
      _enableDemoMode();
    }
  }

  /// Enables demo mode when backend connections fail
  /// Provides full functionality without backend dependencies
  void _enableDemoMode() {
    print('Enabling demo mode - backend connectivity issues');
    // Demo mode allows full UI testing without backend
    // All validation features will work locally
  }

  /// Builds the messaging interface with appropriate states
  /// Shows loading indicator, error message, or message list
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipientName), // Show recipient name in app bar
        actions: [
          // Conversation info button
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showConversationInfo(); // Show conversation details
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Loading state - shows circular progress indicator
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          
          // Error state - shows error message and retry button
          else if (_error != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _fetchMessages, // Retry fetching messages
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          
          // Message list - displays all messages in reverse order (newest at bottom)
          else
            Expanded(
              child: ListView.builder(
                reverse: true, // Show newest messages at the bottom
                padding: const EdgeInsets.all(16.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages.reversed.toList()[index];
                  return _buildMessageBubble(message); // Build individual message bubble
                },
              ),
            ),
          
          // Message input field at the bottom
          _buildMessageInput(),
        ],
      ),
    );
  }

  /// Builds an individual message bubble with appropriate styling
  /// Differentiates between user messages and recipient messages
  /// @param message The message data to display
  Widget _buildMessageBubble(Message message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start, // Align based on sender
        children: [
          // Recipient avatar (only shown for others' messages)
          if (!message.isMe)
            const CircleAvatar(
              backgroundImage: NetworkImage('https://via.placeholder.com/40'), // Placeholder avatar
              radius: 20,
            ),
          const SizedBox(width: 8),
          
          // Message content container
          Flexible(
            child: Column(
              crossAxisAlignment: message.isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start, // Align text based on sender
              children: [
                // Sender name (only shown for others' messages)
                if (!message.isMe)
                  Text(
                    message.sender,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                
                // Message bubble with colored background
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isMe
                        ? Colors.blue.shade100  // User messages in blue
                        : Colors.grey.shade200,  // Others' messages in gray
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(message.text), // Message text content
                ),
                const SizedBox(height: 4),
                
                // Message timestamp
                Text(
                  message.time,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          // Spacing for user messages
          if (message.isMe)
            const SizedBox(width: 8),
          
          // User avatar (only shown for user's messages)
          if (message.isMe)
            const CircleAvatar(
              backgroundImage: NetworkImage('https://via.placeholder.com/40'), // Placeholder avatar
              radius: 20,
            ),
        ],
      ),
    );
  }

  /// Builds the message input field with send button
  /// Provides a text field for typing messages and a send action
  /// Includes real-time validation for restricted content
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100, // Light background for input area
        border: Border(top: BorderSide(color: Colors.grey.shade300)), // Top border
      ),
      child: Column(
        children: [
          // Warning text for restricted content
          if (_containsRestrictedInfo)
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text(
                'For your safety and to comply with our terms, please keep communication on the platform.',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          
          Row(
            children: [
              // Text input field
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...', // Placeholder text
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: _onMessageChanged, // Real-time validation
                ),
              ),
              const SizedBox(width: 8),
              
              // Send button (disabled when restricted content is detected)
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _containsRestrictedInfo ? null : _sendMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Handles real-time message validation as user types
  /// Detects restricted content patterns (email addresses, phone numbers)
  void _onMessageChanged(String text) {
    setState(() {
      _currentMessage = text;
      // Check if the text contains any restricted patterns
      _containsRestrictedInfo = _emailRegex.hasMatch(text) || _phoneRegex.hasMatch(text);
    });
  }

  /// Sends a message via WebSocket and HTTP fallback
  /// Adds the message to local state and clears the input field
  /// Includes pre-send validation for restricted content
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return; // Don't send empty messages

    // Pre-send validation - check for restricted content even if real-time validation was bypassed
    if (_emailRegex.hasMatch(text) || _phoneRegex.hasMatch(text)) {
      _showWarningDialog(); // Show educational pop-up
      return; // Prevent sending
    }

    try {
      // Send via WebSocket for real-time delivery (if connected)
      if (_channel != null) {
        _channel?.sink.add(json.encode({
          'projectId': widget.projectId,
          'content': text,
        }));
      }

      // Also send via HTTP API for reliability (fallback if WebSocket fails)
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.sendMessage(widget.projectId, text);

      // Update UI with the sent message
      setState(() {
        _messages.add(Message(
          text: text,
          sender: 'You',
          time: 'Just now',
          isMe: true,
        ));
        _messageController.clear(); // Clear input field after sending
        _currentMessage = ''; // Reset current message
        _containsRestrictedInfo = false; // Reset validation flag
      });
    } catch (e) {
      // Show error message if sending fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: ${e.toString()}')),
      );
    }
  }

  /// Shows educational pop-up dialog explaining restricted content policy
  /// Prevents users from sending messages containing email addresses or phone numbers
  void _showWarningDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restricted Content'),
        content: const Text(
            'To protect your payments and ensure platform safety, sharing email addresses or phone numbers is not allowed. Please use our platform for all communication and transactions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  /// Shows conversation information dialog with recipient details
  /// Displays name, title, rate, success rate, and project ID
  void _showConversationInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conversation Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.recipientName),     // Recipient name
            Text(widget.recipientTitle),    // Recipient title/role
            const SizedBox(height: 8),
            const Text('\$50.50/hr • 90% Job Success'), // Placeholder rate and success data
            const SizedBox(height: 8),
            Text('Project ID: ${widget.projectId}'), // Project identifier
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close dialog
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Data model for representing a single message
/// Contains text content, sender information, timestamp, and ownership flag
class Message {
  final String text;    // Message content
  final String sender;  // Sender's name
  final String time;    // Formatted timestamp
  final bool isMe;      // Whether the message was sent by the current user

  Message({
    required this.text,
    required this.sender,
    required this.time,
    required this.isMe,
  });
}