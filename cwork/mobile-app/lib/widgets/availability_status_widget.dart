// Availability Status Widget
// Displays and manages freelancer availability status with real-time updates

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cwork_mobile/models/availability_status.dart';
import 'package:cwork_mobile/services/api_service.dart';

/// Widget for displaying and managing freelancer availability status
/// Shows current status with color coding and allows editing
class AvailabilityStatusWidget extends StatefulWidget {
  final Availability initialAvailability;
  final bool editable;
  final Function(Availability)? onStatusChanged;

  const AvailabilityStatusWidget({
    super.key,
    required this.initialAvailability,
    this.editable = true,
    this.onStatusChanged,
  });

  @override
  State<AvailabilityStatusWidget> createState() => _AvailabilityStatusWidgetState();
}

class _AvailabilityStatusWidgetState extends State<AvailabilityStatusWidget> {
  late Availability _currentAvailability;
  bool _isEditing = false;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentAvailability = widget.initialAvailability;
    _messageController.text = _currentAvailability.customMessage;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  /// Updates the availability status via API
  Future<void> _updateAvailability(AvailabilityType newStatus, {String? customMessage}) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.updateAvailability(
        newStatus,
        customMessage: customMessage ?? _currentAvailability.customMessage,
      );

      setState(() {
        _currentAvailability = Availability.fromJson(response);
        _messageController.text = _currentAvailability.customMessage;
        _isEditing = false;
      });

      widget.onStatusChanged?.call(_currentAvailability);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update availability: ${e.toString()}')),
      );
    }
  }

  /// Builds the status indicator with color and text
  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _currentAvailability.status.color.withOpacity(0.1),
        border: Border.all(color: _currentAvailability.status.color, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentAvailability.status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _currentAvailability.status.displayName,
            style: TextStyle(
              color: _currentAvailability.status.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the custom message display
  Widget _buildCustomMessage() {
    if (_currentAvailability.customMessage.isEmpty) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        _currentAvailability.customMessage,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Builds the edit dialog for changing status and message
  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Availability'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<AvailabilityType>(
              initialValue: _currentAvailability.status,
              items: AvailabilityType.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: status.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(status.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newStatus) {
                if (newStatus != null) {
                  setState(() {
                    _currentAvailability = _currentAvailability.copyWith(status: newStatus);
                  });
                }
              },
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Custom Message (optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g., "Available for quick projects"',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _updateAvailability(
              _currentAvailability.status,
              customMessage: _messageController.text.trim(),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatusIndicator(),
            if (widget.editable)
              IconButton(
                icon: const Icon(Icons.edit, size: 16),
                onPressed: _showEditDialog,
                tooltip: 'Edit availability',
              ),
          ],
        ),
        _buildCustomMessage(),
        if (_currentAvailability.updatedAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Updated ${_formatTime(_currentAvailability.updatedAt!)}',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    
    return 'on ${dateTime.toString().split(' ')[0]}';
  }
}