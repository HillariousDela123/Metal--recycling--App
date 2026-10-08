import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import '../models/user_model.dart';

/// Firebase Authentication wrapper with offline/mock fallback capability.
class AuthService {
  fb.FirebaseAuth? _firebaseAuth;
  UserModel? _mockCurrentUser;
  final StreamController<UserModel?> _authStateController = StreamController<UserModel?>.broadcast();

  AuthService() {
    _init();
  }

  void _init() {
    try {
      if (Firebase.apps.isNotEmpty) {
        _firebaseAuth = fb.FirebaseAuth.instance;
        _firebaseAuth?.authStateChanges().listen((fb.User? fbUser) {
          if (fbUser != null) {
            _authStateController.add(UserModel(
              userId: fbUser.uid,
              name: fbUser.displayName ?? 'Recycling Eco Hero',
              email: fbUser.email ?? '',
              createdAt: DateTime.now(),
            ));
          } else {
            _authStateController.add(null);
          }
        });
      }
    } catch (_) {
      // Firebase not yet initialized; fallback mode enabled
    }
  }

  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  UserModel? get currentUser => _mockCurrentUser;

  /// Sign in with email and password
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      if (_firebaseAuth != null) {
        final credential = await _firebaseAuth!.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final fbUser = credential.user!;
        final user = UserModel(
          userId: fbUser.uid,
          name: fbUser.displayName ?? 'Metal Recycler',
          email: fbUser.email ?? email,
          createdAt: DateTime.now(),
        );
        _mockCurrentUser = user;
        _authStateController.add(user);
        return user;
      }
    } catch (e) {
      if (_firebaseAuth != null) rethrow;
    }

    // Mock demonstration fallback
    await Future.delayed(const Duration(milliseconds: 600));
    final mockUser = UserModel(
      userId: 'usr_${email.hashCode.abs()}',
      name: email.split('@').first.toUpperCase(),
      email: email,
      totalRecycledKg: 45.5,
      ecoPoints: 320,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );
    _mockCurrentUser = mockUser;
    _authStateController.add(mockUser);
    return mockUser;
  }

  /// Register new user
  Future<UserModel> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      if (_firebaseAuth != null) {
        final credential = await _firebaseAuth!.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final fbUser = credential.user!;
        await fbUser.updateDisplayName(name);
        final user = UserModel(
          userId: fbUser.uid,
          name: name,
          email: email,
          createdAt: DateTime.now(),
        );
        _mockCurrentUser = user;
        _authStateController.add(user);
        return user;
      }
    } catch (e) {
      if (_firebaseAuth != null) rethrow;
    }

    // Mock demonstration fallback
    await Future.delayed(const Duration(milliseconds: 600));
    final mockUser = UserModel(
      userId: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      totalRecycledKg: 0.0,
      ecoPoints: 50,
      createdAt: DateTime.now(),
    );
    _mockCurrentUser = mockUser;
    _authStateController.add(mockUser);
    return mockUser;
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth?.signOut();
    } catch (_) {}
    _mockCurrentUser = null;
    _authStateController.add(null);
  }

  /// Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      if (_firebaseAuth != null) {
        await _firebaseAuth!.sendPasswordResetEmail(email: email);
      }
    } catch (_) {}
  }

  void dispose() {
    _authStateController.close();
  }
}
