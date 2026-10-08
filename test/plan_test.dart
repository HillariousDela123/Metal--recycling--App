import 'package:flutter_test/flutter_test.dart';
import 'package:metal_recycling_app/core/utils/validators.dart';
import 'package:metal_recycling_app/core/utils/helpers.dart';
import 'package:metal_recycling_app/models/plan_model.dart';
import 'package:metal_recycling_app/models/activity_model.dart';

void main() {
  group('TC06 - Recycling Plan Creation & Validation', () {
    test('TC06.1: validateWeight enforces non-empty, positive numeric weights', () {
      expect(AppValidators.validateWeight(''), 'Weight is required');
      expect(AppValidators.validateWeight('-5'), 'Please enter a valid positive weight in kg');
      expect(AppValidators.validateWeight('0'), 'Please enter a valid positive weight in kg');
      expect(AppValidators.validateWeight('not-a-number'), 'Please enter a valid positive weight in kg');
      expect(AppValidators.validateWeight('25.5'), isNull);
    });

    test('TC06.2: PlanModel serialization and deserialization retains plan properties', () {
      final scheduledDate = DateTime(2026, 10, 15, 14, 30);
      final plan = PlanModel(
        planId: 'plan_998',
        userId: 'usr_abc',
        serviceId: 'srv_1',
        serviceName: 'Apex Recyclers',
        metalType: 'Aluminium',
        weightKg: 42.0,
        date: scheduledDate,
        status: PlanStatus.confirmed,
        notes: 'Clean cans in sacks',
        reminderEnabled: true,
        createdAt: DateTime(2026, 10, 8),
      );

      final map = plan.toMap();
      expect(map['planId'], 'plan_998');
      expect(map['metalType'], 'Aluminium');
      expect(map['weightKg'], 42.0);
      expect(map['status'], 'confirmed');

      final reconstructed = PlanModel.fromMap(map);
      expect(reconstructed.planId, plan.planId);
      expect(reconstructed.metalType, plan.metalType);
      expect(reconstructed.weightKg, plan.weightKg);
      expect(reconstructed.status, PlanStatus.confirmed);
      expect(reconstructed.reminderEnabled, isTrue);
    });

    test('TC06.3: calculateCo2Saved computes carbon reduction for aluminum, copper, and steel', () {
      // Aluminum: 9.0 kg CO2 / kg
      final alCo2 = AppHelpers.calculateCo2Saved('Aluminium', 10.0);
      expect(alCo2, 90.0);

      // Copper: 4.2 kg CO2 / kg
      final cuCo2 = AppHelpers.calculateCo2Saved('Copper', 10.0);
      expect(cuCo2, 42.0);

      // Steel: 1.8 kg CO2 / kg
      final steelCo2 = AppHelpers.calculateCo2Saved('Steel', 100.0);
      expect(steelCo2, 180.0);
    });
  });

  group('TC07 - Plan Status Transitions & Activity Audit Logging', () {
    test('TC07.1: Status transitions from pending to confirmed to completed', () {
      var plan = PlanModel(
        planId: 'plan_state_test',
        userId: 'usr_test',
        serviceId: 'srv_1',
        metalType: 'Copper',
        date: DateTime.now(),
        status: PlanStatus.pending,
        createdAt: DateTime.now(),
      );

      expect(plan.status, PlanStatus.pending);

      plan = plan.copyWith(status: PlanStatus.confirmed);
      expect(plan.status, PlanStatus.confirmed);

      plan = plan.copyWith(status: PlanStatus.completed);
      expect(plan.status, PlanStatus.completed);
    });

    test('TC07.2: ActivityModel serialization logs drop-off milestone accurately', () {
      final activity = ActivityModel(
        activityId: 'act_007',
        userId: 'usr_test',
        planId: 'plan_state_test',
        action: 'STATUS_UPDATED',
        title: 'Plan Completed',
        description: 'Successfully deposited 25kg of scrap steel.',
        weightKg: 25.0,
        metalType: 'Steel',
        timestamp: DateTime(2026, 10, 8, 12, 0),
      );

      final map = activity.toMap();
      expect(map['activityId'], 'act_007');
      expect(map['action'], 'STATUS_UPDATED');
      expect(map['weightKg'], 25.0);

      final reconstructed = ActivityModel.fromMap(map);
      expect(reconstructed.activityId, activity.activityId);
      expect(reconstructed.title, activity.title);
      expect(reconstructed.metalType, 'Steel');
    });
  });
}
