import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/admin/admin_screen.dart';
import '../screens/auth/auth_flow_type.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/availability/create_availability_screen.dart';
import '../screens/booking/booking_screen.dart';
import '../screens/chat/chat_detail_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/lesson/lesson_detail_screen.dart';
import '../screens/lesson/lesson_screen.dart';
import '../screens/payment/payment_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/tutor/tutor_verification_screen.dart';
import '../screens/admin/admin_tutor_detail_screen.dart';
import '../screens/admin/admin_payout_detail_screen.dart';
import '../screens/admin/report_tutor_screen.dart';
import '../screens/admin/admin_report_detail_screen.dart';

class AppRouter {
  static GoRouter build(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: auth,
      redirect: (context, state) {
        final loggedIn = auth.isAuthenticated;
        final location = state.uri.path;

        final isAuthRoute =
            location.startsWith('/login') ||
                location.startsWith('/register') ||
                location.startsWith('/verify-email');

        if (!loggedIn && !isAuthRoute) {
          return '/login';
        }

        if (loggedIn && isAuthRoute) {
          if (auth.isAdmin) return '/admin';
          if (auth.isTutor) return '/tutor-verification';
          return '/home';
        }

        if (loggedIn && location.startsWith('/admin') && !auth.isAdmin) {
          return '/home';
        }

        if (loggedIn && location.startsWith('/tutor-verification')) {
          if (!auth.isTutor || auth.isAdmin) {
            return '/home';
          }
        }

        if (loggedIn && location.startsWith('/wallet')) {
          if (!auth.isTutor || auth.isAdmin) {
            return '/home';
          }
        }

        if (loggedIn &&
            location.startsWith('/availability/create') &&
            (!auth.isTutor || auth.isAdmin)) {
          return '/home';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: '/login/tutor',
          builder: (_, __) => const RoleLoginScreen(
            type: AuthFlowType.tutor,
          ),
        ),
        GoRoute(
          path: '/login/learner',
          builder: (_, __) => const RoleLoginScreen(
            type: AuthFlowType.learner,
          ),
        ),
        GoRoute(
          path: '/register',
          builder: (_, __) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/register/tutor',
          builder: (_, __) => const RoleRegisterScreen(
            type: AuthFlowType.tutor,
          ),
        ),
        GoRoute(
          path: '/register/learner',
          builder: (_, __) => const RoleRegisterScreen(
            type: AuthFlowType.learner,
          ),
        ),
        GoRoute(
          path: '/verify-email',
          builder: (context, state) {
            final email = state.uri.queryParameters['email'] ?? '';
            final type = state.uri.queryParameters['type'] ?? 'learner';

            return VerifyEmailScreen(
              email: email,
              type: type,
            );
          },
        ),

        ShellRoute(
          builder: (context, state, child) {
            return MainShell(
              auth: auth,
              location: state.uri.path,
              child: child,
            );
          },
          routes: [
            GoRoute(
              path: '/admin',
              builder: (_, __) => const AdminScreen(),
            ),
            GoRoute(
              path: '/home',
              builder: (_, __) => const HomeScreen(),
            ),
            GoRoute(
              path: '/bookings',
              builder: (_, __) => const BookingScreen(),
            ),
            GoRoute(
              path: '/lessons',
              builder: (_, __) => const LessonScreen(),
            ),
            GoRoute(
              path: '/chat',
              builder: (_, __) => const ChatScreen(),
            ),
            GoRoute(
              path: '/wallet',
              builder: (_, __) => const WalletScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (_, __) => const ProfileScreen(),
            ),
          ],
        ),

        GoRoute(
          path: '/payment',
          builder: (context, state) {
            final payment = state.extra;

            if (payment == null) {
              return const Scaffold(
                body: Center(
                  child: Text('Payment data is missing'),
                ),
              );
            }

            return PaymentScreen(
              payment: payment as dynamic,
            );
          },
        ),

        GoRoute(
          path: '/availability/create',
          builder: (_, __) => const CreateAvailabilityScreen(),
        ),

        GoRoute(
          path: '/lessons/:id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');

            if (id == null) {
              return const Scaffold(
                body: Center(
                  child: Text('Invalid lesson id'),
                ),
              );
            }

            return LessonDetailScreen(
              lessonId: id,
            );
          },
        ),

        GoRoute(
          path: '/tutor-verification',
          builder: (_, __) => const TutorVerificationScreen(),
        ),

        GoRoute(
          path: '/admin/tutor/:id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');

            if (id == null) {
              return const Scaffold(
                body: Center(child: Text('Invalid tutor id')),
              );
            }

            return AdminTutorDetailScreen(tutorId: id);
          },
        ),

        GoRoute(
          path: '/admin/payout/:id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');

            if (id == null) {
              return const Scaffold(
                body: Center(child: Text('Invalid payout id')),
              );
            }

            return AdminPayoutDetailScreen(payoutId: id);
          },
        ),

        GoRoute(
          path: '/report/booking/:bookingId',
          builder: (context, state) {
            final bookingId = int.tryParse(state.pathParameters['bookingId'] ?? '') ?? 0;
            final lessonId = int.tryParse(state.uri.queryParameters['lessonId'] ?? '');

            return ReportTutorScreen(
              bookingId: bookingId,
              lessonId: lessonId,
            );
          },
        ),
        GoRoute(
          path: '/admin/report/:reportId',
          builder: (context, state) {
            final reportId = int.tryParse(state.pathParameters['reportId'] ?? '') ?? 0;

            return AdminReportDetailScreen(reportId: reportId);
          },
        ),

        GoRoute(
          path: '/chat/:id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');

            if (id == null) {
              return const Scaffold(
                body: Center(
                  child: Text('Invalid conversation id'),
                ),
              );
            }

            return ChatDetailScreen(
              conversationId: id,
            );
          },
        ),
      ],
    );
  }
}

class MainShell extends StatelessWidget {
  final AuthProvider auth;
  final String location;
  final Widget child;

  const MainShell({
    super.key,
    required this.auth,
    required this.location,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_NavItem>[
      if (auth.isAdmin)
        const _NavItem(
          '/admin',
          Icons.admin_panel_settings_outlined,
          Icons.admin_panel_settings,
          'Admin',
        ),
      if (!auth.isAdmin)
        const _NavItem(
          '/home',
          Icons.home_outlined,
          Icons.home,
          'Home',
        ),
      if (!auth.isAdmin)
        const _NavItem(
          '/bookings',
          Icons.event_note_outlined,
          Icons.event_note,
          'Booking',
        ),
      if (!auth.isAdmin)
        const _NavItem(
          '/lessons',
          Icons.school_outlined,
          Icons.school,
          'Lesson',
        ),
      const _NavItem(
        '/chat',
        Icons.chat_bubble_outline,
        Icons.chat_bubble,
        'Chat',
      ),
      if (auth.isTutor && !auth.isAdmin)
        const _NavItem(
          '/wallet',
          Icons.account_balance_wallet_outlined,
          Icons.account_balance_wallet,
          'Wallet',
        ),
      const _NavItem(
        '/profile',
        Icons.person_outline,
        Icons.person,
        'Profile',
      ),
    ];

    final current = items.indexWhere((e) => location.startsWith(e.path));
    final index = current < 0 ? 0 : current;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          context.go(items[i].path);
        },
        destinations: items.map((e) {
          return NavigationDestination(
            icon: Icon(e.icon),
            selectedIcon: Icon(e.selectedIcon),
            label: e.label,
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem(
      this.path,
      this.icon,
      this.selectedIcon,
      this.label,
      );
}