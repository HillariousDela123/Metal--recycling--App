import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/plan_model.dart';
import '../models/activity_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../core/utils/helpers.dart';

/// State management provider for scheduling recycling plans, updating statuses, and logging activities.
class PlanProvider with ChangeNotifier {
  final DatabaseService _databaseService;
  final NotificationService _notificationService;
  final _uuid = const Uuid();

  List<PlanModel> _userPlans = [];
  List<ActivityModel> _userActivities = [];
  bool _isLoading = false;
  String? _errorMessage;

  PlanProvider({
    required DatabaseService databaseService,
    required NotificationService notificationService,
  })  : _databaseService = databaseService,
        _notificationService = notificationService;

  List<PlanModel> get userPlans => _userPlans;
  List<ActivityModel> get userActivities => _userActivities;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Impact Statistics
  double get totalRecycledKg {
    return _userPlans
        .where((p) => p.status == PlanStatus.completed)
        .fold(0.0, (sum, p) => sum + p.weightKg);
  }

  double get totalCo2SavedKg {
    return _userPlans
        .where((p) => p.status == PlanStatus.completed)
        .fold(0.0, (sum, p) => sum + AppHelpers.calculateCo2Saved(p.metalType, p.weightKg));
  }

  int get upcomingPlansCount {
    return _userPlans.where((p) => p.status == PlanStatus.pending || p.status == PlanStatus.confirmed).length;
  }

  /// Load plans and activities for the given user ID
  Future<void> loadUserData(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _userPlans = await _databaseService.getUserPlans(userId);
      _userActivities = await _databaseService.getUserActivities(userId);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Create a new recycling appointment plan
  Future<bool> createPlan({
    required String userId,
    required String serviceId,
    required String serviceName,
    required String metalType,
    required double weightKg,
    required DateTime scheduledDate,
    String notes = '',
    bool reminderEnabled = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newPlanId = 'plan_${_uuid.v4().substring(0, 8)}';
      final plan = PlanModel(
        planId: newPlanId,
        userId: userId,
        serviceId: serviceId,
        serviceName: serviceName,
        metalType: metalType,
        weightKg: weightKg,
        date: scheduledDate,
        status: PlanStatus.confirmed,
        notes: notes,
        reminderEnabled: reminderEnabled,
        createdAt: DateTime.now(),
      );

      // 1. Save to Database
      await _databaseService.createPlan(plan);
      _userPlans.insert(0, plan);

      // 2. Schedule notification if enabled
      if (reminderEnabled) {
        await _notificationService.scheduleRecyclingReminder(
          id: plan.planId.hashCode.abs() % 100000,
          metalType: metalType,
          serviceName: serviceName,
          scheduledDate: scheduledDate,
        );
      }

      // 3. Record Activity Log
      final activity = ActivityModel(
        activityId: 'act_${_uuid.v4().substring(0, 8)}',
        userId: userId,
        planId: plan.planId,
        action: 'PLAN_CREATED',
        title: 'Scheduled $metalType Drop-Off',
        description: 'Arranged ${weightKg.toStringAsFixed(1)} kg at $serviceName.',
        weightKg: weightKg,
        metalType: metalType,
        timestamp: DateTime.now(),
      );
      await _databaseService.recordActivity(activity);
      _userActivities.insert(0, activity);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update the status of an existing recycling plan
  Future<void> updatePlanStatus({
    required String userId,
    required String planId,
    required PlanStatus newStatus,
  }) async {
    try {
      await _databaseService.updatePlanStatus(planId, newStatus);

      final index = _userPlans.indexWhere((p) => p.planId == planId);
      if (index != -1) {
        final currentPlan = _userPlans[index];
        _userPlans[index] = currentPlan.copyWith(status: newStatus);

        // Record status change activity
        final activity = ActivityModel(
          activityId: 'act_${_uuid.v4().substring(0, 8)}',
          userId: userId,
          planId: planId,
          action: 'STATUS_UPDATED',
          title: 'Plan ${newStatus.displayName}',
          description: 'Recycling plan for ${currentPlan.metalType} was marked as ${newStatus.displayName}.',
          weightKg: currentPlan.weightKg,
          metalType: currentPlan.metalType,
          timestamp: DateTime.now(),
        );
        await _databaseService.recordActivity(activity);
        _userActivities.insert(0, activity);

        // Cancel notification if plan cancelled
        if (newStatus == PlanStatus.cancelled) {
          await _notificationService.cancelNotification(planId.hashCode.abs() % 100000);
        }

        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
