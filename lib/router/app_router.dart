import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_strings.dart';
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
import '../screens/homework/homework_screen.dart';
import '../screens/homework/homework_take_screen.dart';
import '../screens/homework/tutor_homework_screen.dart';
import '../screens/lesson/lesson_detail_screen.dart';
import '../screens/lesson/lesson_screen.dart';
import '../screens/materials/course_materials_screen.dart';
import '../screens/payment/payment_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/tutor/tutor_verification_screen.dart';
import '../screens/tutor/tutor_detail_screen.dart';
import '../screens/tutor/favorite_tutors_screen.dart';
import '../screens/admin/admin_tutor_detail_screen.dart';
import '../screens/admin/admin_payout_detail_screen.dart';
import '../screens/admin/report_tutor_screen.dart';
import '../screens/admin/admin_report_detail_screen.dart';
import '../screens/profile/terms_of_service_screen.dart' as legal;
import '../screens/report/my_reports_screen.dart';
import '../screens/report/tutor_reports_screen.dart';
import '../screens/admin/admin_reports_screen.dart';
import '../screens/support/create_support_report_screen.dart';
import '../screens/support/my_support_reports_screen.dart';

class AppRouter {
  static GoRouter build(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: auth,
      redirect: (context, state) {
        final loggedIn = auth.isAuthenticated;
        final location = state.uri.path;

        final isAuthRoute = location.startsWith('/login') ||
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

        if (loggedIn &&
            location == '/homework' &&
            ((!auth.isLearner && !auth.isTutor) || auth.isAdmin)) {
          return '/home';
        }

        if (loggedIn &&
            location.startsWith('/homework/') &&
            ((!auth.isLearner && !auth.isTutor) || auth.isAdmin)) {
          return '/home';
        }

        if (loggedIn &&
            location == '/materials' &&
            ((!auth.isLearner && !auth.isTutor) || auth.isAdmin)) {
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
              path: '/homework',
              builder: (_, state) {
                if (auth.isTutor) {
                  return TutorHomeworkScreen(
                    initialLessonId: int.tryParse(
                      state.uri.queryParameters['lessonId'] ?? '',
                    ),
                  );
                }

                return const HomeworkScreen();
              },
            ),
            GoRoute(
              path: '/materials',
              builder: (_, __) => const CourseMaterialsScreen(),
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
          path: '/homework/:lessonId/:homeworkId',
          builder: (context, state) {
            final lessonId =
                int.tryParse(state.pathParameters['lessonId'] ?? '');
            final homeworkId =
                int.tryParse(state.pathParameters['homeworkId'] ?? '');

            if (lessonId == null || homeworkId == null) {
              return const Scaffold(
                body: Center(
                  child: Text('Invalid homework'),
                ),
              );
            }

            return HomeworkTakeScreen(
              lessonId: lessonId,
              homeworkId: homeworkId,
            );
          },
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
          path: '/tutors/:id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');

            if (id == null) {
              return const Scaffold(
                body: Center(child: Text('Invalid tutor id')),
              );
            }

            return TutorDetailScreen(tutorId: id);
          },
        ),
        GoRoute(
          path: '/favorites',
          builder: (_, __) => const FavoriteTutorsScreen(),
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
            final bookingId =
                int.tryParse(state.pathParameters['bookingId'] ?? '') ?? 0;
            final lessonId =
                int.tryParse(state.uri.queryParameters['lessonId'] ?? '');

            return ReportTutorScreen(
              bookingId: bookingId,
              lessonId: lessonId,
            );
          },
        ),
        GoRoute(
          path: '/admin/report/:reportId',
          builder: (context, state) {
            final reportId =
                int.tryParse(state.pathParameters['reportId'] ?? '') ?? 0;

            return AdminReportDetailScreen(reportId: reportId);
          },
        ),
        GoRoute(
          path: '/terms-of-service',
          builder: (_, __) => const legal.TermsOfServiceScreen(),
        ),
        GoRoute(
          path: '/my-reports',
          builder: (_, __) => const MyReportsScreen(),
        ),
        GoRoute(
          path: '/tutor-reports',
          builder: (_, __) => const TutorReportsScreen(),
        ),
        GoRoute(
          path: '/admin/reports',
          builder: (_, __) => const AdminReportsScreen(),
        ),
        GoRoute(
          path: '/support-report/create',
          builder: (_, __) => const CreateSupportReportScreen(),
        ),
        GoRoute(
          path: '/support-reports/me',
          builder: (_, __) => const MySupportReportsScreen(),
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
    final t = context.l10n;
    final items = <_NavItem>[
      if (auth.isAdmin)
        _NavItem(
          '/admin',
          Icons.admin_panel_settings_outlined,
          Icons.admin_panel_settings,
          t.admin,
        ),
      if (!auth.isAdmin)
        _NavItem(
          '/home',
          Icons.home_outlined,
          Icons.home,
          t.home,
        ),
      if (!auth.isAdmin && !auth.isTutor)
        _NavItem(
          '/bookings',
          Icons.event_note_outlined,
          Icons.event_note,
          t.booking,
        ),
      if ((auth.isLearner || auth.isTutor) && !auth.isAdmin)
        _NavItem(
          '/course-tools',
          Icons.auto_stories_outlined,
          Icons.auto_stories,
          t.course,
          opensCourseTools: true,
        ),
      _NavItem(
        '/chat',
        Icons.chat_bubble_outline,
        Icons.chat_bubble,
        t.chat,
      ),
      if (auth.isTutor && !auth.isAdmin)
        _NavItem(
          '/wallet',
          Icons.account_balance_wallet_outlined,
          Icons.account_balance_wallet,
          t.wallet,
        ),
      _NavItem(
        '/profile',
        Icons.person_outline,
        Icons.person,
        t.profile,
      ),
    ];

    final current = items.indexWhere(
      (e) {
        if (e.opensCourseTools) return _isCourseLocation(location);
        return location == e.path || location.startsWith('${e.path}/');
      },
    );
    final index = current < 0 ? 0 : current;

    return Scaffold(
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isCourseLocation(location))
            _CourseQuickSwitchBar(location: location),
          NavigationBar(
            height: 66,
            labelTextStyle: WidgetStateProperty.all(
              const TextStyle(
                fontSize: 10,
                height: 1,
                letterSpacing: 0,
                fontWeight: FontWeight.w600,
              ),
            ),
            selectedIndex: index,
            onDestinationSelected: (i) {
              if (items[i].opensCourseTools) {
                _showCourseTools(context, location);
                return;
              }

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
        ],
      ),
    );
  }
}

bool _isCourseLocation(String location) {
  return location == '/lessons' ||
      location.startsWith('/lessons/') ||
      location == '/homework' ||
      location.startsWith('/homework/') ||
      location == '/materials' ||
      location.startsWith('/materials/');
}

class _CourseQuickSwitchBar extends StatelessWidget {
  final String location;

  const _CourseQuickSwitchBar({required this.location});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final t = context.l10n;

    return Material(
      color: colors.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colors.outlineVariant.withValues(alpha: 0.55),
              width: 0.5,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        child: Row(
          children: [
            _QuickCourseButton(
              icon: Icons.school_outlined,
              label: t.lesson,
              selected:
                  location == '/lessons' || location.startsWith('/lessons/'),
              onTap: () => context.go('/lessons'),
            ),
            const SizedBox(width: 8),
            _QuickCourseButton(
              icon: Icons.assignment_outlined,
              label: t.homework,
              selected:
                  location == '/homework' || location.startsWith('/homework/'),
              onTap: () => context.go('/homework'),
            ),
            const SizedBox(width: 8),
            _QuickCourseButton(
              icon: Icons.folder_copy_outlined,
              label: t.materials,
              selected: location == '/materials' ||
                  location.startsWith('/materials/'),
              onTap: () => context.go('/materials'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickCourseButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QuickCourseButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Expanded(
      child: InkWell(
        onTap: selected ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? colors.primaryContainer.withValues(alpha: 0.78)
                : colors.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? colors.primary.withValues(alpha: 0.28)
                  : colors.outlineVariant.withValues(alpha: 0.45),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected
                    ? colors.onPrimaryContainer
                    : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selected
                        ? colors.onPrimaryContainer
                        : colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showCourseTools(BuildContext shellContext, String location) {
  final theme = Theme.of(shellContext);
  final colors = theme.colorScheme;
  final t = AppStrings.of(shellContext, listen: false);

  return showGeneralDialog<void>(
    context: shellContext,
    barrierDismissible: true,
    barrierLabel: t.courseTools,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(dialogContext).pop(),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 74,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colors.outlineVariant.withValues(alpha: 0.6),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      _CourseToolAction(
                        icon: Icons.school_outlined,
                        selectedIcon: Icons.school,
                        label: t.lesson,
                        selected: location == '/lessons' ||
                            location.startsWith('/lessons/'),
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          shellContext.go('/lessons');
                        },
                      ),
                      _CourseToolAction(
                        icon: Icons.assignment_outlined,
                        selectedIcon: Icons.assignment,
                        label: t.homework,
                        selected: location == '/homework' ||
                            location.startsWith('/homework/'),
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          shellContext.go('/homework');
                        },
                      ),
                      _CourseToolAction(
                        icon: Icons.folder_copy_outlined,
                        selectedIcon: Icons.folder_copy,
                        label: t.materials,
                        selected: location == '/materials' ||
                            location.startsWith('/materials/'),
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          shellContext.go('/materials');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}

class _CourseToolAction extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CourseToolAction({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: selected
                ? colors.primaryContainer.withValues(alpha: 0.75)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? selectedIcon : icon,
                color: selected ? colors.onPrimaryContainer : colors.primary,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected
                      ? colors.onPrimaryContainer
                      : colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool opensCourseTools;

  const _NavItem(
    this.path,
    this.icon,
    this.selectedIcon,
    this.label, {
    this.opensCourseTools = false,
  });
}
