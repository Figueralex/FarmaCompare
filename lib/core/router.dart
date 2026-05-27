import 'package:go_router/go_router.dart';
import '../screens/search_screen.dart';
import '../screens/results_screen.dart';

import '../screens/settings_screen.dart';
import '../screens/pharmacy_selection_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/results/:query',
      builder: (context, state) {
        final query = state.pathParameters['query'] ?? '';
        return ResultsScreen(initialQuery: query);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
      routes: [
        GoRoute(
          path: 'pharmacies',
          builder: (context, state) => const PharmacySelectionScreen(),
        ),
      ],
    ),
  ],
);
