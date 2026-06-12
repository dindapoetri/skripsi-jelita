import 'package:flutter/material.dart';
import '../data/models/skin_result_models.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/recommendation/recommendation_screen.dart';
import '../features/result/result_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/symptoms/skin_symptoms_screen.dart';
import '../features/authentication/login_screen.dart';
import '../features/authentication/signup_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/account_security_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const login = '/login';
  static const signup = '/signup';
  static const profile = '/profile';
  static const security = '/security';
  static const symptoms = '/symptoms';
  static const result = '/result';
  static const recommendation = '/recommendation';
  static const history = '/history';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case security:
        return MaterialPageRoute(builder: (_) => const AccountSecurityScreen());

      case symptoms:
        final imagePath = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => SkinSymptomsScreen(imagePath: imagePath),
        );

      case result:
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => ResultScreen(
              result: args['result'] as SkinResultModel,
              symptoms: args['symptoms'] as List<String>,
            ),
          );
        } else {
          final result = settings.arguments as SkinResultModel;
          return MaterialPageRoute(
            builder: (_) => ResultScreen(
              result: result,
              symptoms: const [],
            ),
          );
        }

      case recommendation:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => RecommendationScreen(
            result: args['result'] as SkinResultModel,
            symptoms: List<String>.from(args['symptoms']),
          ),
        );

      case history:
        return MaterialPageRoute(builder: (_) => const HistoryScreen());
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
