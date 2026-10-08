import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/plan_model.dart';
import '../../viewmodels/auth_provider.dart';
import '../../viewmodels/plan_provider.dart';
import '../plan/plan_creation_screen.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor(PlanStatus status) {
    switch (status) {
      case PlanStatus.confirmed:
        return AppColors.info;
      case PlanStatus.completed:
        return AppColors.success;
      case PlanStatus.cancelled:
        return AppColors.error;
      case PlanStatus.pending:
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final planProvider = context.watch<PlanProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final plans = planProvider.userPlans;
    final activities = planProvider.userActivities;
    final userId = authProvider.currentUser?.userId ?? 'usr_guest';

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.historyTitle),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGreen,
          labelColor: isDark ? Colors.white : AppColors.primaryGreenDark,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text('Plans (${plans.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timeline_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text('Timeline (${activities.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            // 1. Plans Tab
            RefreshIndicator(
              onRefresh: () => planProvider.loadUserData(userId),
              child: plans.isEmpty
                  ? _buildEmptyState(
                      icon: Icons.calendar_today_rounded,
                      message: 'No recycling plans found.',
                      buttonText: 'Schedule a Drop-Off',
                      onAction: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PlanCreationScreen()),
                        );
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: plans.length,
                      itemBuilder: (context, index) {
                        final plan = plans[index];
                        final statusColor = _getStatusColor(plan.status);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      plan.metalType,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        plan.status.displayName,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.storefront_rounded, size: 16, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        plan.serviceName.isNotEmpty ? plan.serviceName : 'Certified Recycler',
                                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.scale_rounded, size: 16, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${plan.weightKg.toStringAsFixed(1)} kg',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text(
                                      DateFormatter.formatDateTime(plan.date),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                                if (plan.notes.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Note: ${plan.notes}',
                                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 8),
                                // Action Buttons (Mark as Complete / Cancel)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (plan.status != PlanStatus.completed && plan.status != PlanStatus.cancelled) ...[
                                      TextButton(
                                        onPressed: () {
                                          planProvider.updatePlanStatus(
                                            userId: userId,
                                            planId: plan.planId,
                                            newStatus: PlanStatus.cancelled,
                                          );
                                        },
                                        style: TextButton.styleFrom(foregroundColor: AppColors.error),
                                        child: const Text('Cancel Plan'),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: const Size(120, 38),
                                          padding: const EdgeInsets.symmetric(horizontal: 14),
                                        ),
                                        onPressed: () {
                                          planProvider.updatePlanStatus(
                                            userId: userId,
                                            planId: plan.planId,
                                            newStatus: PlanStatus.completed,
                                          );
                                        },
                                        child: const Text('Mark Completed', style: TextStyle(fontSize: 13)),
                                      ),
                                    ] else ...[
                                      Text(
                                        plan.status == PlanStatus.completed ? 'Drop-Off Finalized' : 'Plan Cancelled',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: plan.status == PlanStatus.completed ? AppColors.success : AppColors.error,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // 2. Timeline Tab
            RefreshIndicator(
              onRefresh: () => planProvider.loadUserData(userId),
              child: activities.isEmpty
                  ? _buildEmptyState(
                      icon: Icons.history_rounded,
                      message: AppStrings.noActivities,
                      buttonText: 'Create Recycling Plan',
                      onAction: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PlanCreationScreen()),
                        );
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: activities.length,
                      itemBuilder: (context, index) {
                        final act = activities[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.recycling_rounded, color: AppColors.primaryGreen, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            act.title,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ),
                                        Text(
                                          DateFormatter.formatRelative(act.timestamp),
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      act.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String buttonText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onAction,
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}
