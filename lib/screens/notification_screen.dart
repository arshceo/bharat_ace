import 'package:bharat_ace/core/models/notice_model.dart';
import 'package:bharat_ace/core/models/test_notification_model.dart';
import 'package:bharat_ace/core/providers/notification_providers.dart';
import 'package:bharat_ace/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';

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

    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: AppTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: AppTheme.white,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        backgroundColor: AppTheme.white,
        color: AppTheme.primary,
        onRefresh: () async {
          ref.invalidate(allNoticesProvider);
          ref.invalidate(classTestsProvider);
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 8.0),
              sliver: SliverToBoxAdapter(
                child: FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    "School Announcements",
                    style: AppTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.gray900,
                    ),
                  ),
                ),
              ),
            ),
            _buildNoticesList(context, noticesAsyncValue, ref),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 8.0),
              sliver: SliverToBoxAdapter(
                child: FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    "Tests & Assignments",
                    style: AppTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.gray900,
                    ),
                  ),
                ),
              ),
            ),
            _buildTestsList(context, testsAsyncValue, ref),
            const SliverToBoxAdapter(
                child: SizedBox(height: 80)), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildNoticesList(BuildContext context,
      AsyncValue<List<NoticeModel>> asyncValue, WidgetRef ref) {
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
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: FadeInUp(
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                      border: Border.all(color: AppTheme.gray200),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spaceLG),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusSM),
                                ),
                                child: Icon(
                                  Icons.campaign_rounded,
                                  size: 16,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spaceMD),
                              Expanded(
                                child: Text(
                                  notice.title,
                                  style:
                                      AppTheme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.gray900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spaceMD),
                          Text(
                            notice.message,
                            style: AppTheme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.gray600,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceMD),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: AppTheme.gray400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatTimestamp(notice.createdAt),
                                style: AppTheme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.gray400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            childCount: notices.length,
          ),
        );
      },
      loading: () => _buildLoadingShimmerList(context, 3),
      error: (err, stack) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _buildErrorState(
            message: "Could not load announcements.\n${err.toString()}",
            onRetry: () => ref.invalidate(allNoticesProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildTestsList(BuildContext context,
      AsyncValue<List<TestNotificationModel>> asyncValue, WidgetRef ref) {
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
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: FadeInUp(
                  duration: Duration(milliseconds: 400 + (index * 100)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                      border: Border.all(color: AppTheme.gray200),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spaceLG),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.info.withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusSM),
                                ),
                                child: Icon(
                                  Icons.quiz_rounded,
                                  size: 16,
                                  color: AppTheme.info,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spaceMD),
                              Expanded(
                                child: Text(
                                  test.title,
                                  style:
                                      AppTheme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.gray900,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondary.withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusSM),
                                ),
                                child: Text(
                                  test.subjectId,
                                  style: AppTheme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spaceMD),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Type: ${test.type.replaceAll('_', ' ').split(' ').map((e) => e[0].toUpperCase() + e.substring(1)).join(' ')}",
                                  style:
                                      AppTheme.textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.gray600,
                                  ),
                                ),
                              ),
                              Text(
                                "Max Marks: ${test.maxMarks}",
                                style: AppTheme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.gray600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spaceMD),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.event_available_rounded,
                                size: 14,
                                color: AppTheme.gray400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "On: ${_formatTimestamp(test.testDate)}",
                                style: AppTheme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.gray400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            childCount: tests.length,
          ),
        );
      },
      loading: () => _buildLoadingShimmerList(context, 2),
      error: (err, stack) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _buildErrorState(
            message: "Could not load tests.\n${err.toString()}",
            onRetry: () => ref.invalidate(classTestsProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingShimmerList(BuildContext context, int itemCount) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Shimmer.fromColors(
              baseColor: AppTheme.gray100,
              highlightColor: AppTheme.gray50,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                ),
              ),
            ),
          );
        },
        childCount: itemCount,
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
  }) {
    return Center(
      child: FadeIn(
        duration: const Duration(milliseconds: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceLG),
              decoration: BoxDecoration(
                color: AppTheme.gray50,
                borderRadius: BorderRadius.circular(AppTheme.radius2XL),
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppTheme.gray400,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState({
    required String message,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: FadeIn(
        duration: const Duration(milliseconds: 500),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLG),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceLG),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radius2XL),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppTheme.error,
                ),
              ),
              const SizedBox(height: AppTheme.spaceLG),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.gray600,
                ),
              ),
              const SizedBox(height: AppTheme.spaceLG),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceLG,
                    vertical: AppTheme.spaceMD,
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text("Retry"),
                onPressed: onRetry,
              )
            ],
          ),
        ),
      ),
    );
  }
}
