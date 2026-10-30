import 'package:go_router/go_router.dart';
import '../../core/constants/app_templates.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/history/history_screen.dart';
import '../../presentation/screens/reminders/reminder_detail_screen.dart';
import '../../presentation/screens/reminders/reminder_form_screen.dart';
import '../../presentation/screens/reminders/reminder_list_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/widgets/responsive_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ResponsiveScaffold(
        selectedIndex: 0,
        body: DashboardScreen(),
      ),
    ),
    GoRoute(
      path: '/reminders',
      builder: (context, state) => const ResponsiveScaffold(
        selectedIndex: 1,
        body: ReminderListScreen(),
      ),
      routes: [
        GoRoute(
          path: 'create',
          builder: (context, state) => ReminderFormScreen(
            initialTemplate: state.extra is ReminderTemplate
                ? state.extra as ReminderTemplate
                : null,
          ),
        ),
        GoRoute(
          path: ':id',
          builder: (context, state) => ReminderDetailScreen(
            reminderId: state.pathParameters['id']!,
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => ReminderFormScreen(
                reminderId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const ResponsiveScaffold(
        selectedIndex: 2,
        body: HistoryScreen(),
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const ResponsiveScaffold(
        selectedIndex: 3,
        body: SettingsScreen(),
      ),
    ),
  ],
);
