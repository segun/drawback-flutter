import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'features/auth/data/auth_api.dart';
import 'features/auth/data/secure_token_store.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/screens/confirm_screen.dart';
import 'features/auth/presentation/screens/home_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/main_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/reset_password_screen.dart';

class DrawbackApp extends StatefulWidget {
  const DrawbackApp({super.key});

  @override
  State<DrawbackApp> createState() => _DrawbackAppState();
}

class _DrawbackAppState extends State<DrawbackApp> {
  late final AuthController _authController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final tokenStore = SecureTokenStore();
    final client = ApiClient(baseUrl: AppConfig.backendUrl);
    final authApi = AuthApi(client: client, tokenStore: tokenStore);

    _authController = AuthController(authApi: authApi, tokenStore: tokenStore)
      ..bootstrap();

    _router = GoRouter(
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
      title: 'DrawkcaB',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
