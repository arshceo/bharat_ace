import 'package:bharat_ace/core/models/notice_model.dart';
import 'package:bharat_ace/core/models/test_notification_model.dart';
import 'package:bharat_ace/core/providers/notification_providers.dart';
import 'package:bharat_ace/core/theme/app_colors.dart'; // Your app colors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp
import 'package:shimmer/shimmer.dart'; // For loading shimmer

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      return DateFormat('dd MMM yyyy, hh:mm a')
          .format(timestamp.toDate().toLocal());
    } catch (e) {
      return 'Invalid Date';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticesAsyncValue = ref.watch(allNoticesProvider);
    final testsAsyncValue = ref.watch(classTestsProvider);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text('Notifications',
            style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surfaceDark,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        elevation: 1,
      ),
      body: RefreshIndicator(
        backgroundColor: AppColors.primaryPurple,
        color: Colors.white,
        onRefresh: () async {
          ref.invalidate(allNoticesProvider);
          ref.invalidate(classTestsProvider);
          // A short delay to allow providers to start fetching
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 10.0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  "School Announcements",
                  style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
              ),
            ),
            _buildNoticesList(context, noticesAsyncValue, textTheme, ref),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 10.0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  "Tests & Assignments",
                  style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
              ),
            ),
            _buildTestsList(context, testsAsyncValue, textTheme, ref),
            const SliverToBoxAdapter(
                child: SizedBox(height: 30)), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildNoticesList(
      BuildContext context,
      AsyncValue<List<NoticeModel>> asyncValue,
      TextTheme textTheme,
      WidgetRef ref) {
    return asyncValue.when(
      data: (notices) {
        if (notices.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: _buildEmptyState(
                icon: Icons.campaign_outlined,
                message: "No new announcements.",
                textTheme: textTheme,
              ),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final notice = notices[index];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Card(
                  elevation: 2,
                  color: AppColors.surfaceDark,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notice.title,
                          style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notice.message,
                          style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary, height: 1.4),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 14,
                                color:
                                    AppColors.textSecondary.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Text(
                              _formatTimestamp(notice.createdAt),
                              style: textTheme.bodySmall?.copyWith(
                                  color:
                                      AppColors.textSecondary.withOpacity(0.7)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            childCount: notices.length,
          ),
        );
      },
      loading: () => _buildLoadingShimmerList(context, 3, 130),
      error: (err, stack) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildErrorState(
            message: "Could not load announcements.\n${err.toString()}",
            textTheme: textTheme,
            onRetry: () => ref.invalidate(allNoticesProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildTestsList(
      BuildContext context,
      AsyncValue<List<TestNotificationModel>> asyncValue,
      TextTheme textTheme,
      WidgetRef ref) {
    return asyncValue.when(
      data: (tests) {
        if (tests.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: _buildEmptyState(
                icon: Icons.checklist_rtl_outlined,
                message: "No tests scheduled for your class.",
                textTheme: textTheme,
              ),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final test = tests[index];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Card(
                  elevation: 2,
                  color: AppColors.surfaceDark,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                test.title,
                                style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryPurple.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(test.subjectId,
                                  style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.primaryPurple,
                                      fontWeight: FontWeight.w600)),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Type: ${test.type.replaceAll('_', ' ').split(' ').map((e) => e[0].toUpperCase() + e.substring(1)).join(' ')}", // Nicer format
                          style: textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Max Marks: ${test.maxMarks}",
                          style: textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.event_available_outlined,
                                size: 14,
                                color:
                                    AppColors.textSecondary.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Text(
                              "On: ${_formatTimestamp(test.testDate)}",
                              style: textTheme.bodySmall?.copyWith(
                                  color:
                                      AppColors.textSecondary.withOpacity(0.7)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            childCount: tests.length,
          ),
        );
      },
      loading: () => _buildLoadingShimmerList(context, 2, 150),
      error: (err, stack) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildErrorState(
            message: "Could not load tests.\n${err.toString()}",
            textTheme: textTheme,
            onRetry: () => ref.invalidate(classTestsProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingShimmerList(
      BuildContext context, int itemCount, double itemHeight) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Shimmer.fromColors(
              baseColor: AppColors.surfaceDark.withOpacity(0.8),
              highlightColor: AppColors.surfaceLight.withOpacity(0.5),
              child: Container(
                height: itemHeight,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          );
        },
        childCount: itemCount,
      ),
    );
  }

  Widget _buildEmptyState(
      {required IconData icon,
      required String message,
      required TextTheme textTheme}) {
    return Center(
      child: Opacity(
        opacity: 0.7,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
      {required String message,
      required TextTheme textTheme,
      required VoidCallback onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.redAccent.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple.withOpacity(0.8),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Retry"),
              onPressed: onRetry,
            )
          ],
        ),
      ),
    );
  }
}
