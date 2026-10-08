import 'package:flutter_test/flutter_test.dart';
import 'package:metal_recycling_app/core/utils/validators.dart';
import 'package:metal_recycling_app/models/user_model.dart';

void main() {
  group('TC01 - User Registration & Input Validation Tests', () {
    test('TC01.1: validateEmail returns null on valid emails', () {
      expect(AppValidators.validateEmail('user@greenmetal.org'), isNull);
      expect(AppValidators.validateEmail('eco.champion@recycle.co'), isNull);
    });

    test('TC01.2: validateEmail returns error message on invalid email formats', () {
      expect(AppValidators.validateEmail(''), 'Email is required');
      expect(AppValidators.validateEmail('invalid-email'), 'Please enter a valid email address');
      expect(AppValidators.validateEmail('user@domain'), 'Please enter a valid email address');
    });

    test('TC01.3: validatePassword enforces minimum character constraint', () {
      expect(AppValidators.validatePassword(''), 'Password is required');
      expect(AppValidators.validatePassword('12345'), 'Password must be at least 6 characters');
      expect(AppValidators.validatePassword('SecretPass123'), isNull);
    });

    test('TC01.4: validateName checks minimum length', () {
      expect(AppValidators.validateName(''), 'Name is required');
      expect(AppValidators.validateName('A'), 'Name must be at least 2 characters');
      expect(AppValidators.validateName('Sarah Connor'), isNull);
    });
  });

  group('TC02 - Authentication & UserModel Serialization Tests', () {
    test('TC02.1: UserModel serialize toMap and deserialize fromMap accurately', () {
      final user = UserModel(
        userId: 'usr_test_101',
        name: 'Alex Turner',
        email: 'alex@recycle.org',
        totalRecycledKg: 24.5,
        ecoPoints: 150,
        createdAt: DateTime(2026, 1, 15),
      );

      final map = user.toMap();
      expect(map['userId'], 'usr_test_101');
      expect(map['name'], 'Alex Turner');
      expect(map['email'], 'alex@recycle.org');
      expect(map['totalRecycledKg'], 24.5);
      expect(map['ecoPoints'], 150);

      final reconstructedUser = UserModel.fromMap(map);
      expect(reconstructedUser.userId, user.userId);
      expect(reconstructedUser.name, user.name);
      expect(reconstructedUser.email, user.email);
      expect(reconstructedUser.totalRecycledKg, user.totalRecycledKg);
      expect(reconstructedUser.ecoPoints, user.ecoPoints);
    });

    test('TC02.2: UserModel copyWith retains unaffected properties', () {
      final original = UserModel(
        userId: 'usr_orig',
        name: 'Original Name',
        email: 'orig@test.com',
        totalRecycledKg: 10.0,
        ecoPoints: 50,
        createdAt: DateTime.now(),
      );

      final updated = original.copyWith(
        name: 'Updated Name',
        totalRecycledKg: 35.0,
      );

      expect(updated.name, 'Updated Name');
      expect(updated.totalRecycledKg, 35.0);
      expect(updated.userId, original.userId);
      expect(updated.email, original.email);
    });
  });
}
