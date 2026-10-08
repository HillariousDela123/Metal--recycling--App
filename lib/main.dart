import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'viewmodels/auth_provider.dart';
import 'viewmodels/service_provider.dart';
import 'viewmodels/plan_provider.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/register_screen.dart';
import 'views/home/metal_selection_screen.dart';
import 'views/map/service_discovery_screen.dart';
import 'views/plan/plan_creation_screen.dart';
import 'views/history/activity_history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (gracefully falls back if configuration file is pending)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization skipped or pending configuration: $e');
  }

  // Initialize Local Notifications
  await NotificationService().init();

  runApp(const MetalRecyclingApp());
}

class MetalRecyclingApp extends StatelessWidget {
  const MetalRecyclingApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Instantiate core service singletons
    final authService = AuthService();
    final databaseService = DatabaseService();
    final locationService = LocationService();
    final notificationService = NotificationService();

    return MultiProvider(
      providers: [
        // Services
        Provider<AuthService>.value(value: authService),
        Provider<DatabaseService>.value(value: databaseService),
        Provider<LocationService>.value(value: locationService),
        Provider<NotificationService>.value(value: notificationService),

        // ViewModels / State Providers
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            authService: authService,
            databaseService: databaseService,
          ),
        ),
        ChangeNotifierProvider<ServiceProvider>(
          create: (_) => ServiceProvider(
            databaseService: databaseService,
            locationService: locationService,
          ),
        ),
        ChangeNotifierProvider<PlanProvider>(
          create: (_) => PlanProvider(
            databaseService: databaseService,
            notificationService: notificationService,
          ),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            home: auth.isAuthenticated
                ? const MetalSelectionScreen()
                : const LoginScreen(),
            routes: {
              '/login': (_) => const LoginScreen(),
              '/register': (_) => const RegisterScreen(),
              '/home': (_) => const MetalSelectionScreen(),
              '/discovery': (_) => const ServiceDiscoveryScreen(),
              '/plan_creation': (_) => const PlanCreationScreen(),
              '/history': (_) => const ActivityHistoryScreen(),
            },
          );
        },
      ),
    );
  }
}
