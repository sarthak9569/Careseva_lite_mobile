import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'models/user_profile.dart';
import 'screens/compounder_dashboard_screen.dart';
import 'screens/patient_home_screen.dart';
import 'screens/role_selection_screen.dart';
import 'services/queue_store.dart';
import 'theme/mobile_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global exception handlers for production resilience
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[CareSeva Mobile Error] ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('[CareSeva Mobile Platform Error] $error\n$stack');
    return true;
  };

  // Graceful Firebase Initialization
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[CareSeva Mobile] Firebase initialization notice: $e (Operating in hybrid/demo mode)');
  }

  // Custom UI Error Widget fallback
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return const Material(
      color: Color(0xFFF1F5F9),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 48),
              SizedBox(height: 12),
              Text(
                'Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              SizedBox(height: 6),
              Text(
                'An unexpected UI error occurred. Please try navigating back or restarting.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ),
    );
  };

  runApp(const CareSevaMobileApp());
}

class CareSevaMobileApp extends StatelessWidget {
  const CareSevaMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QueueStore(),
      child: Consumer<QueueStore>(
        builder: (context, queueStore, child) {
          Widget homeWidget;
          if (queueStore.currentUser == null) {
            homeWidget = const RoleSelectionScreen();
          } else if (queueStore.currentUser!.role == UserRole.patient) {
            homeWidget = const PatientHomeScreen();
          } else {
            homeWidget = const CompounderDashboardScreen();
          }

          return MaterialApp(
            title: 'CareSeva 2',
            debugShowCheckedModeBanner: false,
            theme: MobileTheme.lightTheme,
            home: homeWidget,
          );
        },
      ),
    );
  }
}
