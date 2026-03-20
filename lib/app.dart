import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/services/ad_service.dart';
import 'core/services/discovery_access_api.dart';
import 'core/services/discovery_access_manager.dart';
import 'core/services/purchase_service.dart';
import 'features/auth/data/auth_api.dart';
import 'features/auth/data/secure_token_store.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/main_screen.dart';
import 'features/auth/presentation/screens/csae_screen.dart';
import 'features/auth/presentation/screens/privacy_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/reset_password_screen.dart';
import 'features/discovery/presentation/discovery_controller.dart';
import 'features/home/data/social_api.dart';
import 'features/home/presentation/home_controller.dart';
import 'features/home/presentation/screens/dashboard_screen.dart';

class DrawbackApp extends StatefulWidget {
  const DrawbackApp({super.key});

  @override
  State<DrawbackApp> createState() => _DrawbackAppState();
}

class _DrawbackAppState extends State<DrawbackApp> {
  late final AuthController _authController;
  late final HomeController _homeController;
  late final DiscoveryController _discoveryController;
  late final DiscoveryAccessManager _discoveryAccessManager;
  late final GoRouter _router;
  bool _isHandlingUnauthorized = false;
  bool _isRouterReady = false;

  @override
  void initState() {
    super.initState();

    final tokenStore = SecureTokenStore();
    final client = ApiClient(
      baseUrl: AppConfig.backendUrl,
      onUnauthorized: () {
        unawaited(_handleUnauthorizedSession());
      },
    );
    final authApi = AuthApi(client: client, tokenStore: tokenStore);
    final socialApi = SocialApi(client: client, tokenStore: tokenStore);
    final discoveryAccessApi = DiscoveryAccessApi(
      client: client,
      tokenStore: tokenStore,
    );

    // Create purchase and ad services
    final purchaseService = PurchaseService(
      client: client,
      tokenStore: tokenStore,
    );
    final adService = AdService();

    // Create discovery access manager
    _discoveryAccessManager = DiscoveryAccessManager(
      purchaseService: purchaseService,
      adService: adService,
      discoveryAccessApi: discoveryAccessApi,
    );

    _authController = AuthController(authApi: authApi, tokenStore: tokenStore)
      ..bootstrap();

    _homeController = HomeController(
      socialApi: socialApi,
      backendUrl: AppConfig.backendUrl,
      onUnauthorized: () {
        unawaited(_handleUnauthorizedSession());
      },
    );

    _discoveryController = DiscoveryController(
      socialApi: socialApi,
      onProfileUpdate: (profile) {
        _homeController.setProfile(profile);
      },
    );

    // Listen to auth state changes to initialize socket
    _authController.addListener(_handleAuthStateChange);

    // Listen to home controller changes to sync discovery game status
    _homeController.addListener(_handleHomeControllerChange);

    _router = GoRouter(
      refreshListenable: _authController,
      routes: <GoRoute>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) => MainScreen(
            controller: _authController,
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (BuildContext context, GoRouterState state) => LoginScreen(
            controller: _authController,
          ),
        ),
        GoRoute(
          path: '/register',
          builder: (BuildContext context, GoRouterState state) =>
              RegisterScreen(
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
          path: '/privacy',
          builder: (BuildContext context, GoRouterState state) =>
              const PrivacyScreen(),
        ),
        GoRoute(
          path: '/csae',
          builder: (BuildContext context, GoRouterState state) =>
              const CsaeScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (BuildContext context, GoRouterState state) =>
              DashboardScreen(
            controller: _homeController,
            authController: _authController,
            discoveryController: _discoveryController,
            discoveryAccessManager: _discoveryAccessManager,
            promptPasskeyEnrollment:
                state.extra is bool ? state.extra as bool : false,
            onLogout: () async {
              await _authController.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ),
      ],
      redirect: (BuildContext context, GoRouterState state) {
        final bool isAuthRoute = state.fullPath == '/login' ||
            state.fullPath == '/register' ||
            state.fullPath == '/reset-password' ||
            state.fullPath == '/privacy' ||
            state.fullPath == '/';

        if (_authController.isBootstrapping) {
          return null;
        }

        if (_authController.isAuthenticated &&
            isAuthRoute &&
            state.fullPath != '/login') {
          return '/home';
        }

        if (!_authController.isAuthenticated && state.fullPath == '/home') {
          return '/login';
        }

        return null;
      },
    );
    _isRouterReady = true;
  }

  Future<void> _handleUnauthorizedSession() async {
    if (!_authController.isAuthenticated) {
      return;
    }

    if (_isHandlingUnauthorized) {
      return;
    }

    _isHandlingUnauthorized = true;
    try {
      await _authController.logout();
      if (mounted && _isRouterReady) {
        _router.go('/login');
      }
    } finally {
      _isHandlingUnauthorized = false;
    }
  }

  void _handleAuthStateChange() {
    // Initialize socket when user becomes authenticated
    if (_authController.isAuthenticated &&
        _authController.accessToken != null) {
      _homeController.initializeSocket(_authController.accessToken!);
    } else {
      // Disconnect socket when user logs out
      _homeController.disconnectSocket();
      _discoveryAccessManager.clearTemporaryAccess();
    }
  }

  void _handleHomeControllerChange() {
    // Sync discovery game status from profile to discovery controller
    _discoveryController.setInitialStatus(_homeController.isInDiscoveryGame);
    _discoveryAccessManager.syncWithProfile(_homeController.profile);
  }

  @override
  void dispose() {
    _authController.removeListener(_handleAuthStateChange);
    _homeController.removeListener(_handleHomeControllerChange);
    _authController.dispose();
    _homeController.dispose();
    _discoveryController.dispose();
    _discoveryAccessManager.dispose();
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
