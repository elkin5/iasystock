import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iasy_stock_app/cubits/product_stock/product_stock_cubit.dart';

import 'config/get_it_config.dart';
import 'cubits/auth/auth_cubit.dart';
import 'cubits/auth/auth_state.dart';
import 'cubits/cart_sale/cart_sale_cubit.dart';
// Cubits
import 'cubits/menu/audit_log_cubit.dart';
import 'cubits/menu/category_cubit.dart';
import 'cubits/menu/general_settings_cubit.dart';
import 'cubits/menu/person_cubit.dart';
import 'cubits/menu/product_cubit.dart';
import 'cubits/menu/promotion_cubit.dart';
import 'cubits/menu/sale_cubit.dart';
import 'cubits/menu/sale_item_cubit.dart';
import 'cubits/menu/stock_cubit.dart';
import 'cubits/menu/user_cubit.dart';
import 'cubits/menu/warehouse_cubit.dart';
import 'cubits/product_identification/multiple_detection_cubit.dart';
import 'cubits/product_stock/stock_registration_cubit.dart';
// Setup & Configuration
import 'guards/auth_guard.dart';
// Models
import 'models/auth/auth_user_model.dart';
// Routes
import 'routes/app_routes.dart';
// Screens
import 'screens/auth/callback_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/logout_callback_screen.dart';
import 'screens/auth/registration_screen.dart';
import 'screens/auth/unauthorized_screen.dart';
import 'screens/home_screen.dart';
import 'screens/main_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/user_options_screen.dart';
// Services
import 'services/auth/auth_service.dart';
import 'services/auth/token_monitor_service.dart';
import 'services/deep_link_error_handler.dart';
// Themes
import 'themes/dark_theme.dart';
import 'themes/light_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar el manejo de errores de deep links ANTES de setupDependencies
  DeepLinkErrorHandler().initialize();

  setupDependencies();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;
  TokenMonitorService? _tokenMonitorService;

  @override
  void initState() {
    super.initState();
    // Inicializar el servicio de monitoreo de tokens después de que el widget esté construido
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authCubit = getIt<AuthCubit>();
      final authService = getIt<AuthService>();
      _tokenMonitorService = TokenMonitorService(authCubit: authCubit);

      // Procesar callback de autenticación web si existe
      if (kIsWeb) {
        // Solo procesar callback si estamos en la ruta de callback (web)
        final currentPath = Uri.base.path;
        if (currentPath == '/login-callback') {
          final user = await authService.processWebCallback();
          if (user != null) {
            // El usuario ya está autenticado, solo emitir el estado
            authCubit.emit(AuthStateAuthenticated(user));
          }
        }
      } else {
        // Para plataformas móviles, manejar deep links de autenticación
        await _handleMobileAuthCallback(authService, authCubit);
      }

      // Escuchar cambios en el estado de autenticación
      authCubit.stream.listen((authState) {
        if (authState is AuthStateAuthenticated) {
          // Iniciar monitoreo cuando el usuario se autentica
          if (!(_tokenMonitorService?.isMonitoring ?? false)) {
            _tokenMonitorService?.startMonitoring();
          }
        } else if (authState is AuthStateUnauthenticated ||
            authState is AuthStateError) {
          // Detener monitoreo cuando el usuario no está autenticado
          _tokenMonitorService?.stopMonitoring();
        }
      });

      // Si ya hay un usuario autenticado, iniciar el monitoreo
      if (authCubit.isAuthenticated &&
          !(_tokenMonitorService?.isMonitoring ?? false)) {
        _tokenMonitorService?.startMonitoring();
      }
    });
  }

  @override
  void dispose() {
    _tokenMonitorService?.dispose();
    super.dispose();
  }

  void toggleTheme(bool value) {
    setState(() {
      isDarkMode = value;
    });
  }

  /// Maneja callbacks de autenticación en plataformas móviles
  Future<void> _handleMobileAuthCallback(
      AuthService authService, AuthCubit authCubit) async {
    try {
      // En móvil, el FlutterAppAuth maneja automáticamente los deep links
      // Solo necesitamos verificar si hay un usuario autenticado
      final currentUser = await authService.getCurrentUser();
      if (currentUser != null) {
        // El cubit ya maneja el estado de autenticación en su constructor
        // No necesitamos emitir manualmente aquí
        print(
            'Usuario autenticado encontrado en callback móvil: ${currentUser.username}');
      }
    } catch (e) {
      // Si hay error, no hacer nada - el usuario puede reintentar el login
      print('Error al procesar callback móvil: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData activeTheme = isDarkMode ? darkTheme : lightTheme;

    final GoRouter router = GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final authCubit = context.read<AuthCubit>();
        final isAuthenticated = authCubit.isAuthenticated;
        final currentPath = state.uri.path;
        final isLoginRoute = currentPath == '/login';
        final isCallbackRoute = currentPath == '/login-callback';
        final isLogoutCallbackRoute = currentPath == '/logout-callback';

        // No redirigir si estamos en callbacks (se manejan en main.dart)
        if (isCallbackRoute || isLogoutCallbackRoute) {
          return null;
        }

        // Si no está autenticado y no está en login, redirigir a login
        if (!isAuthenticated && !isLoginRoute) {
          return '/login';
        }

        // Si está autenticado y está en login, redirigir a home
        if (isAuthenticated && isLoginRoute) {
          return '/home';
        }

        return null;
      },
      routes: [
        // Ruta de login (no protegida)
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) {
            final user = state.extra as AuthUser?;
            return RegistrationScreen(user: user);
          },
        ),
        // Ruta de callback para autenticación web
        GoRoute(
          path: '/login-callback',
          builder: (context, state) => const CallbackScreen(),
        ),
        // Ruta de callback para logout
        GoRoute(
          path: '/logout-callback',
          builder: (context, state) => const LogoutCallbackScreen(),
        ),
        // Ruta de acceso no autorizado
        GoRoute(
          path: '/unauthorized',
          builder: (context, state) => const UnauthorizedScreen(),
        ),

        // Rutas protegidas con shell
        ShellRoute(
          builder: (context, state, child) {
            return MainScreen(
              isDarkMode: isDarkMode,
              onThemeChanged: toggleTheme,
              child: ProtectedRoute(child: child),
            );
          },
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => HomeScreen(
                key: const PageStorageKey('home'),
                primaryColor: activeTheme.primaryColor,
              ),
            ),
            GoRoute(
              path: '/menu',
              builder: (context, state) => const MenuScreen(
                key: PageStorageKey('menu'),
              ),
            ),
            GoRoute(
              path: '/user',
              builder: (context, state) => UserOptionsScreen(
                key: const PageStorageKey('user'),
                isDarkMode: isDarkMode,
                onThemeChanged: toggleTheme,
                primaryColor: activeTheme.primaryColor,
              ),
            ),
            ...getAppRoutes(
              isDarkMode: isDarkMode,
              onThemeChanged: toggleTheme,
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => const Scaffold(
        body: Center(child: Text('Página no encontrada')),
      ),
    );

    return DeepLinkErrorHandlerWidget(
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(create: (_) => getIt<AuthCubit>()),
          BlocProvider<UserCubit>(create: (_) => getIt<UserCubit>()),
          BlocProvider<PersonCubit>(create: (_) => getIt<PersonCubit>()),
          BlocProvider<AuditLogCubit>(create: (_) => getIt<AuditLogCubit>()),
          BlocProvider<CategoryCubit>(create: (_) => getIt<CategoryCubit>()),
          BlocProvider<GeneralSettingsCubit>(
              create: (_) => getIt<GeneralSettingsCubit>()),
          BlocProvider<ProductCubit>(create: (_) => getIt<ProductCubit>()),
          BlocProvider<PromotionCubit>(create: (_) => getIt<PromotionCubit>()),
          BlocProvider<SaleCubit>(create: (_) => getIt<SaleCubit>()),
          BlocProvider<SaleItemCubit>(create: (_) => getIt<SaleItemCubit>()),
          BlocProvider<StockCubit>(create: (_) => getIt<StockCubit>()),
          BlocProvider<StockRegistrationCubit>(
              create: (_) => getIt<StockRegistrationCubit>()),
          BlocProvider<WarehouseCubit>(create: (_) => getIt<WarehouseCubit>()),
          BlocProvider<CartSaleCubit>(create: (_) => getIt<CartSaleCubit>()),
          BlocProvider<ProductStockCubit>(
              create: (_) => getIt<ProductStockCubit>()),
          BlocProvider<MultipleDetectionCubit>(
              create: (_) => getIt<MultipleDetectionCubit>()),
        ],
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Iasy Stock App',
          routerConfig: router,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
        ),
      ),
    );
  }
}
