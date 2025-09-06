// lib/screens/buddy_group/buddy_group_creation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/buddy_group_model.dart';
import '../../core/services/buddy_group_service.dart';
import '../../widgets/professional_card.dart' as widgets;

// Provider for classmates
final classmatesProvider = FutureProvider<List<Student>>((ref) {
  return BuddyGroupService.getClassmates();
});

class BuddyGroupCreationScreen extends ConsumerStatefulWidget {
  const BuddyGroupCreationScreen({super.key});

  @override
  ConsumerState<BuddyGroupCreationScreen> createState() =>
      _BuddyGroupCreationScreenState();
}

class _BuddyGroupCreationScreenState
    extends ConsumerState<BuddyGroupCreationScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final Set<String> _selectedStudentIds = {};
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    final classmatesAsync = ref.watch(classmatesProvider);

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: Text(
          'Create Buddy Group',
          style: AppTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.white,
        elevation: 0,
      ),
      body: classmatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(error.toString()),
        data: (classmates) => _buildContent(classmates),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: widgets.ProfessionalCard(
        color: AppTheme.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: AppTheme.spaceMD),
            Text(
              'Error loading classmates',
              style: AppTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Text(error),
            const SizedBox(height: AppTheme.spaceLG),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(classmatesProvider);
              },
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<Student> classmates) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group name input
          widgets.ProfessionalCard(
            color: AppTheme.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Group Name',
                  style: AppTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMD),
                TextField(
                  controller: _groupNameController,
                  decoration: InputDecoration(
                    hintText: 'Enter group name (e.g., "Math Study Squad")',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                    filled: true,
                    fillColor: AppTheme.gray50,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spaceLG),

          // Classmates selection
          Expanded(
            child: widgets.ProfessionalCard(
              color: AppTheme.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Select Classmates',
                        style: AppTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_selectedStudentIds.length} selected',
                        style: AppTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  if (classmates.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 48,
                              color: AppTheme.gray400,
                            ),
                            const SizedBox(height: AppTheme.spaceMD),
                            Text(
                              'No classmates found',
                              style: AppTheme.textTheme.bodyLarge?.copyWith(
                                color: AppTheme.gray600,
                              ),
                            ),
                            Text(
                              'Make sure your class information is set up correctly',
                              textAlign: TextAlign.center,
                              style: AppTheme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.gray500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: classmates.length,
                        itemBuilder: (context, index) {
                          final student = classmates[index];
                          final isSelected =
                              _selectedStudentIds.contains(student.id);

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedStudentIds.remove(student.id);
                                } else {
                                  _selectedStudentIds.add(student.id);
                                }
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(
                                  bottom: AppTheme.spaceMD),
                              padding: const EdgeInsets.all(AppTheme.spaceMD),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primary.withOpacity(0.1)
                                    : AppTheme.white,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusMD),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : AppTheme.gray300,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Avatar
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor:
                                        AppTheme.primary.withOpacity(0.1),
                                    backgroundImage:
                                        student.avatarUrl.isNotEmpty
                                            ? NetworkImage(student.avatarUrl)
                                            : null,
                                    child: student.avatarUrl.isEmpty
                                        ? Text(
                                            student.name.isNotEmpty
                                                ? student.name[0].toUpperCase()
                                                : '?',
                                            style: AppTheme
                                                .textTheme.titleMedium
                                                ?.copyWith(
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),

                                  const SizedBox(width: AppTheme.spaceMD),

                                  // Student info
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student.name,
                                          style: AppTheme.textTheme.bodyLarge
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          student.email,
                                          style: AppTheme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: AppTheme.gray600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Online status
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: student.isOnline
                                          ? AppTheme.success
                                          : AppTheme.gray400,
                                    ),
                                  ),

                                  const SizedBox(width: AppTheme.spaceMD),

                                  // Selection indicator
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? AppTheme.primary
                                          : AppTheme.gray200,
                                    ),
                                    child: isSelected
                                        ? Icon(
                                            Icons.check,
                                            size: 16,
                                            color: AppTheme.white,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spaceLG),

          // Create button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canCreateGroup() ? _createGroup : null,
              child: _isCreating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Create Buddy Group'),
            ),
          ),
        ],
      ),
    );
  }

  bool _canCreateGroup() {
    return _groupNameController.text.trim().isNotEmpty &&
        _selectedStudentIds.isNotEmpty &&
        !_isCreating;
  }

  Future<void> _createGroup() async {
    if (!_canCreateGroup()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final groupId = await BuddyGroupService.createBuddyGroup(
        groupName: _groupNameController.text.trim(),
        memberIds: _selectedStudentIds.toList(),
      );

      if (groupId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Buddy group created successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        throw Exception('Failed to create group');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating group: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }
}
