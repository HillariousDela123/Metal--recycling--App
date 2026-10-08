import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/service_model.dart';
import '../models/plan_model.dart';
import '../models/activity_model.dart';

/// Database service handling Cloud Firestore CRUD operations with offline fallback.
class DatabaseService {
  FirebaseFirestore? _firestore;

  // Local state cache / fallback data
  final List<ServiceModel> _mockServices = [
    const ServiceModel(
      serviceId: 'srv_1',
      name: 'Apex Industrial Metal Recyclers',
      lat: 37.7749,
      lng: -122.4194,
      acceptedMetals: ['Copper', 'Aluminium', 'Brass', 'Steel'],
      address: '1420 Recycle Way, Bay District',
      phone: '+1 (555) 234-5678',
      operatingHours: 'Mon - Fri: 7:00 AM - 5:30 PM',
      rating: 4.9,
      pricePerKg: {'Copper': 8.50, 'Aluminium': 2.10, 'Brass': 5.20, 'Steel': 0.65},
      isVerified: true,
    ),
    const ServiceModel(
      serviceId: 'srv_2',
      name: 'EcoAlloy Scrap & Foundry Center',
      lat: 37.7833,
      lng: -122.4167,
      acceptedMetals: ['Aluminium', 'Steel', 'Iron'],
      address: '89 Green Forge Rd, Metro Industrial',
      phone: '+1 (555) 876-5432',
      operatingHours: 'Mon - Sat: 8:00 AM - 6:00 PM',
      rating: 4.7,
      pricePerKg: {'Aluminium': 2.15, 'Steel': 0.70, 'Iron': 0.48},
      isVerified: true,
    ),
    const ServiceModel(
      serviceId: 'srv_3',
      name: 'Vulcan Copper & Precious Metal Depot',
      lat: 37.7650,
      lng: -122.4300,
      acceptedMetals: ['Copper', 'Brass', 'Lead'],
      address: '304 Conduit Blvd, South Docks',
      phone: '+1 (555) 456-7890',
      operatingHours: 'Tue - Sun: 9:00 AM - 4:00 PM',
      rating: 4.8,
      pricePerKg: {'Copper': 8.75, 'Brass': 5.40, 'Lead': 2.35},
      isVerified: true,
    ),
    const ServiceModel(
      serviceId: 'srv_4',
      name: 'Pacific Green Steel & Castings',
      lat: 37.7900,
      lng: -122.4000,
      acceptedMetals: ['Steel', 'Iron', 'Aluminium'],
      address: '512 Harbor Ave, Docklands Pier 9',
      phone: '+1 (555) 998-1122',
      operatingHours: 'Mon - Fri: 6:30 AM - 4:30 PM',
      rating: 4.6,
      pricePerKg: {'Steel': 0.68, 'Iron': 0.50, 'Aluminium': 2.05},
      isVerified: true,
    ),
  ];

  final List<PlanModel> _mockPlans = [];
  final List<ActivityModel> _mockActivities = [];

  DatabaseService() {
    _init();
  }

  void _init() {
    try {
      if (Firebase.apps.isNotEmpty) {
        _firestore = FirebaseFirestore.instance;
      }
    } catch (_) {
      // Offline fallback
    }

    // Prepopulate initial demo plan & activity
    _mockPlans.add(PlanModel(
      planId: 'plan_demo_101',
      userId: 'usr_demo',
      serviceId: 'srv_1',
      serviceName: 'Apex Industrial Metal Recyclers',
      metalType: 'Copper',
      weightKg: 18.5,
      date: DateTime.now().add(const Duration(days: 2)),
      status: PlanStatus.confirmed,
      notes: 'Clean stripped copper cables and pipe fittings.',
      reminderEnabled: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ));

    _mockActivities.add(ActivityModel(
      activityId: 'act_demo_1',
      userId: 'usr_demo',
      planId: 'plan_demo_101',
      action: 'PLAN_CREATED',
      title: 'Scheduled Copper Drop-Off',
      description: 'Booked 18.5 kg Copper delivery with Apex Industrial Recyclers.',
      weightKg: 18.5,
      metalType: 'Copper',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    ));
  }

  // --- USER PROFILE ---
  Future<void> saveUserProfile(UserModel user) async {
    try {
      if (_firestore != null) {
        await _firestore!
            .collection(AppConstants.usersCollection)
            .doc(user.userId)
            .set(user.toMap(), SetOptions(merge: true));
        return;
      }
    } catch (_) {}
  }

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      if (_firestore != null) {
        final doc = await _firestore!.collection(AppConstants.usersCollection).doc(userId).get();
        if (doc.exists && doc.data() != null) {
          return UserModel.fromMap(doc.data()!, documentId: doc.id);
        }
      }
    } catch (_) {}
    return null;
  }

  // --- RECYCLING SERVICES ---
  Future<List<ServiceModel>> getRecyclingServices() async {
    try {
      if (_firestore != null) {
        final snapshot = await _firestore!.collection(AppConstants.servicesCollection).get();
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.map((doc) => ServiceModel.fromMap(doc.data(), documentId: doc.id)).toList();
        }
      }
    } catch (_) {}
    return List.from(_mockServices);
  }

  // --- RECYCLING PLANS ---
  Future<void> createPlan(PlanModel plan) async {
    try {
      if (_firestore != null) {
        await _firestore!
            .collection(AppConstants.plansCollection)
            .doc(plan.planId)
            .set(plan.toMap());
      }
    } catch (_) {}
    _mockPlans.insert(0, plan);
  }

  Future<List<PlanModel>> getUserPlans(String userId) async {
    try {
      if (_firestore != null) {
        final snapshot = await _firestore!
            .collection(AppConstants.plansCollection)
            .where('userId', isEqualTo: userId)
            .get();
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.map((doc) => PlanModel.fromMap(doc.data(), documentId: doc.id)).toList();
        }
      }
    } catch (_) {}
    return _mockPlans.where((p) => p.userId == userId || p.userId == 'usr_demo').toList();
  }

  Future<void> updatePlanStatus(String planId, PlanStatus status) async {
    try {
      if (_firestore != null) {
        await _firestore!
            .collection(AppConstants.plansCollection)
            .doc(planId)
            .update({'status': status.name});
      }
    } catch (_) {}

    final index = _mockPlans.indexWhere((p) => p.planId == planId);
    if (index != -1) {
      _mockPlans[index] = _mockPlans[index].copyWith(status: status);
    }
  }

  // --- ACTIVITIES & AUDIT LOGS ---
  Future<void> recordActivity(ActivityModel activity) async {
    try {
      if (_firestore != null) {
        await _firestore!
            .collection(AppConstants.activitiesCollection)
            .doc(activity.activityId)
            .set(activity.toMap());
      }
    } catch (_) {}
    _mockActivities.insert(0, activity);
  }

  Future<List<ActivityModel>> getUserActivities(String userId) async {
    try {
      if (_firestore != null) {
        final snapshot = await _firestore!
            .collection(AppConstants.activitiesCollection)
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .get();
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.map((doc) => ActivityModel.fromMap(doc.data(), documentId: doc.id)).toList();
        }
      }
    } catch (_) {}
    return _mockActivities.where((a) => a.userId == userId || a.userId == 'usr_demo').toList();
  }
}
