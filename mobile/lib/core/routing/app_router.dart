import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/boot_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/scanner/presentation/scanner_screen.dart';
import '../../features/product_result/presentation/product_result_screen.dart';
import '../../features/product_result/presentation/nutrition_details_screen.dart';
import '../../features/product_result/presentation/ingredients_allergens_screen.dart';
import '../../features/assistant/presentation/assistant_screen.dart';
import '../../features/comparison/presentation/comparison_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/allergy_diet_preferences_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/language_settings_screen.dart';
import '../providers/core_providers.dart';

class AppRoutes {
  AppRoutes._();
  static const boot = '/boot';
  static const login = '/login';
  static const register = '/register';
  static const home = '/';
  static const scanner = '/scanner';
  static const result = '/result/:scanId';
  static const nutrition = '/result/:scanId/nutrition';
  static const ingredients = '/result/:scanId/ingredients';
  static const assistant = '/result/:scanId/assistant';
  static const comparison = '/compare';
  static const profile = '/profile';
  static const preferences = '/profile/preferences';
  static const history = '/history';
  static const settings = '/settings';
  static const languageSettings = '/settings/language';

  static String resultPath(String scanId) => '/result/$scanId';
  static String nutritionPath(String scanId) => '/result/$scanId/nutrition';
  static String ingredientsPath(String scanId) => '/result/$scanId/ingredients';
  static String assistantPath(String scanId) => '/result/$scanId/assistant';
}

/// Bridges Riverpod auth state into a Listenable so go_router's `refreshListenable` re-evaluates
/// redirects whenever login/logout happens, without rebuilding the whole router.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}

final _authRefreshNotifierProvider = Provider<_AuthRefreshNotifier>((ref) => _AuthRefreshNotifier(ref));

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(_authRefreshNotifierProvider);

  return GoRouter(
    // Start on a screen that says out loud that the app is starting. Launching straight onto
    // Home meant the greeting could begin and then be cut off when session restore finished and
    // redirected — disorienting for someone navigating entirely by ear.
    initialLocation: AppRoutes.boot,
    refreshListenable: refreshNotifier,
    observers: [ref.watch(routeObserverProvider)],
    redirect: (context, state) {
      final authStatus = ref.read(authControllerProvider).status;
      final location = state.matchedLocation;
      final atBoot = location == AppRoutes.boot;
      final goingToAuth = location == AppRoutes.login || location == AppRoutes.register;

      // Still restoring the session (and possibly signing back in from the device credentials).
      if (authStatus == AuthStatus.unknown) return atBoot ? null : AppRoutes.boot;
      if (authStatus != AuthStatus.authenticated) return goingToAuth ? null : AppRoutes.login;
      if (atBoot || goingToAuth) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.boot, builder: (context, state) => const BootScreen()),
      GoRoute(path: AppRoutes.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (context, state) => const RegisterScreen()),
      GoRoute(path: AppRoutes.home, builder: (context, state) => const HomeScreen()),
      GoRoute(path: AppRoutes.scanner, builder: (context, state) => const ScannerScreen()),
      GoRoute(
        path: AppRoutes.result,
        builder: (context, state) => ProductResultScreen(scanId: state.pathParameters['scanId']!),
      ),
      GoRoute(
        path: AppRoutes.nutrition,
        builder: (context, state) => NutritionDetailsScreen(scanId: state.pathParameters['scanId']!),
      ),
      GoRoute(
        path: AppRoutes.ingredients,
        builder: (context, state) => IngredientsAllergensScreen(scanId: state.pathParameters['scanId']!),
      ),
      GoRoute(
        path: AppRoutes.assistant,
        builder: (context, state) => AssistantScreen(
          scanId: state.pathParameters['scanId']!,
          initialQuestion: state.extra as String?,
        ),
      ),
      GoRoute(
        path: AppRoutes.comparison,
        builder: (context, state) => ComparisonScreen(
          scanIdA: state.uri.queryParameters['a'],
          scanIdB: state.uri.queryParameters['b'],
        ),
      ),
      GoRoute(path: AppRoutes.profile, builder: (context, state) => const ProfileScreen()),
      GoRoute(path: AppRoutes.preferences, builder: (context, state) => const AllergyDietPreferencesScreen()),
      GoRoute(path: AppRoutes.history, builder: (context, state) => const HistoryScreen()),
      GoRoute(path: AppRoutes.settings, builder: (context, state) => const SettingsScreen()),
      GoRoute(path: AppRoutes.languageSettings, builder: (context, state) => const LanguageSettingsScreen()),
    ],
  );
});
