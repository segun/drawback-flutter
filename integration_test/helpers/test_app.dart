import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:drawback_flutter/features/auth/presentation/auth_controller.dart';
import 'package:drawback_flutter/features/auth/presentation/screens/confirm_screen.dart';
import 'package:drawback_flutter/features/auth/presentation/screens/home_screen.dart';
import 'package:drawback_flutter/features/auth/presentation/screens/login_screen.dart';
import 'package:drawback_flutter/features/auth/presentation/screens/main_screen.dart';
import 'package:drawback_flutter/features/auth/presentation/screens/privacy_screen.dart';
import 'package:drawback_flutter/features/auth/presentation/screens/register_screen.dart';
import 'package:drawback_flutter/features/auth/presentation/screens/reset_password_screen.dart';

import 'mock_auth_api.dart';
import 'mock_token_store.dart';

/// Test app wrapper with mock dependencies
class TestApp extends StatefulWidget {
  const TestApp({
    this.initialRoute = '/',
    this.mockAuthApi,
    this.mockTokenStore,
    super.key,
  });

  final String initialRoute;
  final MockAuthApi? mockAuthApi;
  final MockTokenStore? mockTokenStore;

  @override
  State<TestApp> createState() => _TestAppState();
}

class _TestAppState extends State<TestApp> {
  late final MockAuthApi _mockAuthApi;
  late final MockTokenStore _mockTokenStore;
  late final AuthController _authController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    
    _mockAuthApi = widget.mockAuthApi ?? MockAuthApi();
    _mockTokenStore = widget.mockTokenStore ?? MockTokenStore();
    
    _authController = AuthController(
      authApi: _mockAuthApi,
      tokenStore: _mockTokenStore,
    )..bootstrap();

    _router = GoRouter(
      initialLocation: widget.initialRoute,
      refreshListenable: _authController,
      routes: <GoRoute>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const MainScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (BuildContext context, GoRouterState state) => LoginScreen(
            controller: _authController,
          ),
        ),
        GoRoute(
          path: '/register',
          builder: (BuildContext context, GoRouterState state) => RegisterScreen(
            controller: _authController,
          ),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (BuildContext context, GoRouterState state) =>
              ResetPasswordScreen(
                controller: _authController,
                tokenFromQuery: state.uri.queryParameters['token'],
              ),
        ),
        GoRoute(
          path: '/confirm',
          builder: (BuildContext context, GoRouterState state) => ConfirmScreen(
            status: state.uri.queryParameters['status'],
            email: state.uri.queryParameters['email'],
            reason: state.uri.queryParameters['reason'],
          ),
        ),
        GoRoute(
          path: '/privacy',
          builder: (BuildContext context, GoRouterState state) =>
              const PrivacyScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (BuildContext context, GoRouterState state) => HomeScreen(
            controller: _authController,
          ),
        ),
      ],
      redirect: (BuildContext context, GoRouterState state) {
        final bool isAuthRoute = state.fullPath == '/login' ||
            state.fullPath == '/register' ||
            state.fullPath == '/reset-password' ||
            state.fullPath == '/confirm' ||
            state.fullPath == '/privacy' ||
            state.fullPath == '/';

        if (_authController.isBootstrapping) {
          return null;
        }

        if (_authController.isAuthenticated && isAuthRoute) {
          return '/home';
        }

        if (!_authController.isAuthenticated && state.fullPath == '/home') {
          return '/login';
        }

        return null;
      },
    );
  }

  @override
  void dispose() {
    _authController.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DrawkcaB Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
