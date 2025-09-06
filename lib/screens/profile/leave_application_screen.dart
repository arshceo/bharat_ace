// lib/screens/profile/leave_application_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../core/theme/app_theme.dart';
import '../../core/models/buddy_group_model.dart';
import '../../core/services/buddy_group_service.dart';
import '../../widgets/professional_card.dart' as widgets;

// Provider for leave applications
final leaveApplicationsProvider = FutureProvider<List<LeaveApplication>>((ref) {
  return BuddyGroupService.getUserLeaveApplications();
});

class LeaveApplicationScreen extends ConsumerStatefulWidget {
  const LeaveApplicationScreen({super.key});

  @override
  ConsumerState<LeaveApplicationScreen> createState() =>
      _LeaveApplicationScreenState();
}

class _LeaveApplicationScreenState
    extends ConsumerState<LeaveApplicationScreen> {
  final TextEditingController _reasonController = TextEditingController();
  DateTime? _selectedDate;
  LeaveType _selectedType = LeaveType.preDL;
  File? _selectedDocument;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final leaveApplicationsAsync = ref.watch(leaveApplicationsProvider);

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: Text(
          'Apply for DL (Discipline Leave)',
          style: AppTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Application form
            _buildApplicationForm(),

            const SizedBox(height: AppTheme.spaceLG),

            // Previous applications
            _buildPreviousApplications(leaveApplicationsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationForm() {
    return widgets.ProfessionalCard(
      color: AppTheme.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Leave Application',
            style: AppTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: AppTheme.spaceLG),

          // Leave type selection
          Text(
            'Leave Type',
            style: AppTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Row(
            children: [
              Expanded(
                child: _buildLeaveTypeCard(
                  type: LeaveType.preDL,
                  title: 'Pre-DL',
                  description: 'Apply before the leave date',
                  icon: Icons.schedule,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: _buildLeaveTypeCard(
                  type: LeaveType.postDL,
                  title: 'Post-DL',
                  description: 'Apply after the leave (1-2 days)',
                  icon: Icons.history,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spaceLG),

          // Date selection
          Text(
            'Leave Date',
            style: AppTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spaceLG),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.gray300),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: AppTheme.gray600),
                  const SizedBox(width: AppTheme.spaceMD),
                  Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'Select leave date',
                    style: AppTheme.textTheme.bodyLarge?.copyWith(
                      color: _selectedDate != null
                          ? AppTheme.gray900
                          : AppTheme.gray500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_selectedDate != null && !_canApplyForDate())
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spaceXS),
              child: Text(
                _getDateValidationMessage(),
                style: AppTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.error,
                ),
              ),
            ),

          const SizedBox(height: AppTheme.spaceLG),

          // Reason input
          Text(
            'Reason for Leave',
            style: AppTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          TextField(
            controller: _reasonController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Explain the reason for your leave...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              filled: true,
              fillColor: AppTheme.gray50,
            ),
          ),

          const SizedBox(height: AppTheme.spaceLG),

          // Document upload
          Text(
            'Supporting Document (Optional)',
            style: AppTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          GestureDetector(
            onTap: _pickDocument,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spaceLG),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedDocument != null
                      ? AppTheme.primary
                      : AppTheme.gray300,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                color: _selectedDocument != null
                    ? AppTheme.primary.withOpacity(0.1)
                    : AppTheme.gray50,
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedDocument != null
                        ? Icons.attach_file
                        : Icons.upload_file,
                    color: _selectedDocument != null
                        ? AppTheme.primary
                        : AppTheme.gray600,
                  ),
                  const SizedBox(width: AppTheme.spaceMD),
                  Expanded(
                    child: Text(
                      _selectedDocument != null
                          ? 'Document selected: ${_selectedDocument!.path.split('/').last}'
                          : 'Tap to upload document (image/PDF)',
                      style: AppTheme.textTheme.bodyLarge?.copyWith(
                        color: _selectedDocument != null
                            ? AppTheme.primary
                            : AppTheme.gray600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spaceLG),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canSubmit() ? _submitApplication : null,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Submit Leave Application'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveTypeCard({
    required LeaveType type,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          _selectedDate = null; // Reset date when type changes
        });
      },
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        decoration: BoxDecoration(
          color:
              isSelected ? AppTheme.primary.withOpacity(0.1) : AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.gray300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : AppTheme.gray600,
              size: 32,
            ),
            const SizedBox(height: AppTheme.spaceXS),
            Text(
              title,
              style: AppTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.primary : AppTheme.gray900,
              ),
            ),
            const SizedBox(height: AppTheme.space2XS),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.gray600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviousApplications(
      AsyncValue<List<LeaveApplication>> applicationsAsync) {
    return widgets.ProfessionalCard(
      color: AppTheme.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Previous Applications',
            style: AppTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spaceLG),
          applicationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text(
                'Error loading applications: $error',
                style: AppTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.error,
                ),
              ),
            ),
            data: (applications) {
              if (applications.isEmpty) {
                return Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 48,
                        color: AppTheme.gray400,
                      ),
                      const SizedBox(height: AppTheme.spaceMD),
                      Text(
                        'No previous applications',
                        style: AppTheme.textTheme.bodyLarge?.copyWith(
                          color: AppTheme.gray600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: applications.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppTheme.spaceMD),
                itemBuilder: (context, index) {
                  final app = applications[index];
                  return _buildApplicationCard(app);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(LeaveApplication application) {
    Color statusColor;
    IconData statusIcon;

    switch (application.status) {
      case LeaveStatus.approved:
        statusColor = AppTheme.success;
        statusIcon = Icons.check_circle;
        break;
      case LeaveStatus.rejected:
        statusColor = AppTheme.error;
        statusIcon = Icons.cancel;
        break;
      case LeaveStatus.pending:
        statusColor = AppTheme.warning;
        statusIcon = Icons.schedule;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Leave Date: ${application.leaveDate.day}/${application.leaveDate.month}/${application.leaveDate.year}',
                  style: AppTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceMD,
                  vertical: AppTheme.spaceXS,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: AppTheme.spaceXS),
                    Text(
                      application.status.name.toUpperCase(),
                      style: AppTheme.textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Text(
            application.reason,
            style: AppTheme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Row(
            children: [
              Text(
                'Type: ${application.type.name.toUpperCase()}',
                style: AppTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.gray600,
                ),
              ),
              const SizedBox(width: AppTheme.spaceLG),
              Text(
                'Applied: ${application.appliedAt.day}/${application.appliedAt.month}',
                style: AppTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.gray600,
                ),
              ),
            ],
          ),
          if (application.teacherComment != null) ...[
            const SizedBox(height: AppTheme.spaceMD),
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              decoration: BoxDecoration(
                color: AppTheme.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                border: Border.all(color: AppTheme.info.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Teacher Comment:',
                    style: AppTheme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.info,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceXS),
                  Text(
                    application.teacherComment!,
                    style: AppTheme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _pickDocument() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedDocument = File(pickedFile.path);
      });
    }
  }

  bool _canApplyForDate() {
    if (_selectedDate == null) return false;
    return BuddyGroupService.canApplyLeave(_selectedDate!, _selectedType);
  }

  String _getDateValidationMessage() {
    if (_selectedType == LeaveType.preDL) {
      return 'Pre-DL can only be applied before the leave date, not on the same day.';
    } else {
      return 'Post-DL can only be applied 1-2 days after the leave date.';
    }
  }

  bool _canSubmit() {
    return _selectedDate != null &&
        _canApplyForDate() &&
        _reasonController.text.trim().isNotEmpty &&
        !_isSubmitting;
  }

  Future<void> _submitApplication() async {
    if (!_canSubmit()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      String? documentUrl;

      // Upload document if selected
      if (_selectedDocument != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('leave_documents')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        await storageRef.putFile(_selectedDocument!);
        documentUrl = await storageRef.getDownloadURL();
      }

      // Submit application
      final applicationId = await BuddyGroupService.applyForLeave(
        reason: _reasonController.text.trim(),
        leaveDate: _selectedDate!,
        type: _selectedType,
        documentUrl: documentUrl,
      );

      if (applicationId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Leave application submitted successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );

        // Reset form
        setState(() {
          _reasonController.clear();
          _selectedDate = null;
          _selectedDocument = null;
        });

        // Refresh applications list
        ref.invalidate(leaveApplicationsProvider);
      } else {
        throw Exception('Failed to submit application');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting application: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}
