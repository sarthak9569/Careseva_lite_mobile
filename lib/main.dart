import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/user_profile.dart';
import 'screens/auth_screen.dart';
import 'screens/patient_home_screen.dart';
import 'services/queue_store.dart';
import 'theme/mobile_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global exception handlers for production resilience
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[CareSeva Patient Error] ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('[CareSeva Patient Platform Error] $error\n$stack');
    return true;
  };

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
                'An unexpected error occurred. Please restart the app.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ),
    );
  };

  runApp(const CareSevaPatientApp());
}

class CareSevaPatientApp extends StatelessWidget {
  const CareSevaPatientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QueueStore(),
      child: Consumer<QueueStore>(
        builder: (context, queueStore, child) {
          final Widget homeWidget = queueStore.currentUser == null
              ? const AuthScreen(targetRole: UserRole.patient)
              : const PatientHomeScreen();

          return MaterialApp(
            title: 'CareSeva Patient',
            debugShowCheckedModeBanner: false,
            theme: MobileTheme.lightTheme,
            home: homeWidget,
          );
        },
      ),
    );
  }
}
