import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/app_data_provider.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  final api = ApiService(prefs: prefs);

  final authProvider = AuthProvider(api: api);
  await authProvider.bootstrap();

  final appDataProvider = AppDataProvider(api: api);

  // Track app install once.
  // Use unawaited so app startup is not blocked if Render backend is sleeping.
  unawaited(api.trackInstall());

  runApp(
    EduNestApp(
      api: api,
      authProvider: authProvider,
      appDataProvider: appDataProvider,
    ),
  );
}

class EduNestApp extends StatefulWidget {
  final ApiService api;
  final AuthProvider authProvider;
  final AppDataProvider appDataProvider;

  const EduNestApp({
    super.key,
    required this.api,
    required this.authProvider,
    required this.appDataProvider,
  });

  @override
  State<EduNestApp> createState() => _EduNestAppState();
}

class _EduNestAppState extends State<EduNestApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    // Build router only once.
    // AuthProvider is already passed as refreshListenable in AppRouter.
    _router = AppRouter.build(widget.authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(
          value: widget.api,
        ),
        ChangeNotifierProvider<AuthProvider>.value(
          value: widget.authProvider,
        ),
        ChangeNotifierProvider<AppDataProvider>.value(
          value: widget.appDataProvider,
        ),
      ],
      child: MaterialApp.router(
        title: 'EduNest',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: _router,
      ),
    );
  }
}