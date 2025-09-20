import 'package:flutter/material.dart';
import 'package:cwork_mobile/widgets/error_alert.dart';

/// Example usage of ErrorAlert widget
/// Demonstrates how to use the ErrorAlert in different scenarios
class ErrorAlertExample extends StatelessWidget {
  const ErrorAlertExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Alert Examples'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Session expired error example
            ErrorAlert.sessionExpired(),
            
            const SizedBox(height: 16),
            
            // Generic error example
            ErrorAlert.genericError('Failed to load data. Please try again.'),
            
            const SizedBox(height: 16),
            
            // Custom error example
            const ErrorAlert(
              title: 'Connection Error',
              description: 'Unable to connect to the server. Check your internet connection.',
            ),
            
            const SizedBox(height: 32),
            
            // Button to show error in dialog
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Error'),
                    content: ErrorAlert.sessionExpired(),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Show Error Dialog'),
            ),
          ],
        ),
      ),
    );
  }
}