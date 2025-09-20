import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:cwork_mobile/services/api_service.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  String _projectTitle = '';
  String _projectDescription = '';
  double _budget = 0;
  int _deadlineDays = 30;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create New Project',
          style: AppTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Project Details',
                style: AppTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Project Title',
                  hintText: 'Enter your project title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                style: AppTheme.textTheme.bodyLarge,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a project title';
                  }
                  return null;
                },
                onSaved: (value) => _projectTitle = value!,
              ),
              const SizedBox(height: AppTheme.spacingM),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Project Description',
                  hintText: 'Describe your project requirements',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  alignLabelWithHint: true,
                ),
                style: AppTheme.textTheme.bodyLarge,
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a project description';
                  }
                  return null;
                },
                onSaved: (value) => _projectDescription = value!,
              ),
              const SizedBox(height: AppTheme.spacingM),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Budget (USD)',
                        hintText: '0.00',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        prefixText: '\$ ',
                      ),
                      style: AppTheme.textTheme.bodyLarge,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a budget';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                      onSaved: (value) => _budget = double.parse(value!),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'Deadline',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      style: AppTheme.textTheme.bodyLarge,
                      initialValue: _deadlineDays,
                      items: [7, 14, 30, 60, 90]
                          .map((days) => DropdownMenuItem(
                                value: days,
                                child: Text(
                                  '$days days',
                                  style: AppTheme.textTheme.bodyLarge,
                                ),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _deadlineDays = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingXL),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitProject,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingM,
                    horizontal: AppTheme.spacingXL,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : Text(
                        'Create Project',
                        style: AppTheme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitProject() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      final apiService = Provider.of<ApiService>(context, listen: false);
      try {
        await apiService.createProject({
          'title': _projectTitle,
          'description': _projectDescription,
          'budget': _budget,
          'deadlineDays': _deadlineDays,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project created successfully!')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create project: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}