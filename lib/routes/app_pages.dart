import 'package:flutter_application_nisya/screens/dashboard/dashboard.dart';
import 'package:flutter_application_nisya/screens/profile/profile_page.dart';
import 'package:flutter_application_nisya/screens/survey/daftar_survey.dart';
import 'package:flutter_application_nisya/screens/survey/detail_survey.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/login_page.dart';
import '../screens/auth/register_page.dart';
import '../screens/splash/splash_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.survey,
        builder: (context, state) => const SurveyPage(),
      ),
      GoRoute(
        path: '/survey-detail/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return SurveyDetailPage(surveyId: id);
        },
      ),
    ],
  );
}
