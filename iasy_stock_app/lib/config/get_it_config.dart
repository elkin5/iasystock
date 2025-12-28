import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
// Services
import 'package:iasy_stock_app/services/assistant/ai_assistant_service.dart';
import 'package:iasy_stock_app/services/assistant/chat_history_database_service.dart';
import 'package:iasy_stock_app/services/cart_sale/cart_sale_service.dart';
import 'package:iasy_stock_app/services/product_stock/product_stock_service.dart';

import '../cubits/auth/auth_cubit.dart';
import '../cubits/cart_sale/cart_sale_cubit.dart';
import '../cubits/chat/ai_assistant_cubit.dart';
import '../cubits/product_stock/stock_registration_cubit.dart';
import '../cubits/invoice_scan/invoice_scan_cubit.dart';
// Cubits
import '../cubits/menu/audit_log_cubit.dart';
import '../cubits/menu/category_cubit.dart';
import '../cubits/menu/general_settings_cubit.dart';
import '../cubits/menu/person_cubit.dart';
import '../cubits/menu/product_cubit.dart';
import '../cubits/menu/promotion_cubit.dart';
import '../cubits/menu/sale_cubit.dart';
import '../cubits/menu/sale_item_cubit.dart';
import '../cubits/menu/stock_cubit.dart';
import '../cubits/menu/user_cubit.dart';
import '../cubits/menu/warehouse_cubit.dart';
import '../cubits/product_identification/multiple_detection_cubit.dart';
import '../cubits/product_identification/product_identification_cubit.dart';
import '../cubits/product_stock/product_stock_cubit.dart';
import '../cubits/stats/stats_cubit.dart';
import '../services/auth/auth_service.dart';
import '../services/dio_interceptor.dart';
import '../services/invoice_scan/invoice_scan_service.dart';
import '../services/menu/audit_log_service.dart';
import '../services/menu/category_service.dart';
import '../services/menu/general_settings_service.dart';
import '../services/menu/person_service.dart';
import '../services/menu/product_service.dart';
import '../services/menu/promotion_service.dart';
import '../services/menu/sale_item_service.dart';
import '../services/menu/sale_service.dart';
import '../services/menu/stock_service.dart';
import '../services/menu/user_service.dart';
import '../services/menu/warehouse_service.dart';
import '../services/product_identification/product_identification_service.dart';
import '../services/stats/stats_service.dart';
// Configuration
import 'app_constants.dart';
import 'auth_config.dart';

/// Instancia centralizada de GetIt para inyección de dependencias
final getIt = GetIt.instance;

void setupDependencies() {
  // Primero registrar AuthService y AuthCubit ya que el interceptor los necesita
  getIt.registerSingleton<AuthService>(AuthService());
  getIt.registerLazySingleton(() => AuthCubit(getIt<AuthService>()));

  // Configurar Dio con el interceptor de autenticación
  final dio = Dio(BaseOptions(
    baseUrl: AuthConfig.apiBaseUrl,
    connectTimeout: AppConstants.connectTimeout,
    receiveTimeout: AppConstants.requestTimeout,
  ));

  // Agregar el interceptor de autenticación
  final authInterceptor = AuthInterceptor(
    authService: getIt<AuthService>(),
    authCubit: getIt<AuthCubit>(),
  );
  dio.interceptors.add(authInterceptor);

  // Agregar interceptor de logging en modo debug
  if (!kReleaseMode) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: true,
    ));
  }

  // Servicios
  getIt.registerSingleton<UserService>(UserService(dio));
  getIt.registerSingleton<PersonService>(PersonService(dio));
  getIt.registerSingleton<AuditLogService>(AuditLogService(dio));
  getIt.registerSingleton<CategoryService>(CategoryService(dio));
  getIt.registerSingleton<GeneralSettingsService>(GeneralSettingsService(dio));
  getIt.registerSingleton<ProductService>(ProductService(dio));
  getIt.registerSingleton<PromotionService>(PromotionService(dio));
  getIt.registerSingleton<SaleService>(SaleService(dio));
  getIt.registerSingleton<SaleItemService>(SaleItemService(dio));
  getIt.registerSingleton<StockService>(StockService(dio));
  getIt.registerSingleton<WarehouseService>(WarehouseService(dio));
  getIt.registerSingleton<AiAssistantService>(AiAssistantService(dio));
  getIt.registerSingleton<ChatHistoryDatabaseService>(
      ChatHistoryDatabaseService());
  getIt.registerSingleton<CartSaleService>(CartSaleService(
    productService: getIt<ProductService>(),
    personService: getIt<PersonService>(),
    dio: dio,
  ));
  getIt.registerSingleton<ProductStockService>(ProductStockService(
    productService: getIt<ProductService>(),
    personService: getIt<PersonService>(),
    dio: dio,
  ));
  getIt.registerSingleton<ProductIdentificationService>(
    ProductIdentificationService(dio: dio),
  );
  getIt.registerSingleton<InvoiceScanService>(
    InvoiceScanService(dio: dio),
  );
  getIt.registerSingleton<StatsService>(StatsService(dio));

// Resto de Cubits
  getIt.registerLazySingleton(() => UserCubit(getIt()));
  getIt.registerLazySingleton(() => PersonCubit(getIt()));
  getIt.registerLazySingleton(() => AuditLogCubit(getIt()));
  getIt.registerLazySingleton(() => CategoryCubit(getIt()));
  getIt.registerLazySingleton(() => GeneralSettingsCubit(getIt()));
  getIt.registerLazySingleton(() => ProductCubit(getIt()));
  getIt.registerLazySingleton(() => PromotionCubit(getIt()));
  getIt.registerLazySingleton(() => SaleCubit(getIt()));
  getIt.registerLazySingleton(() => SaleItemCubit(getIt()));
  getIt.registerLazySingleton(() => StockCubit(getIt()));
  getIt.registerLazySingleton(() => StockRegistrationCubit(getIt()));
  getIt.registerLazySingleton(() => WarehouseCubit(getIt()));
  getIt.registerLazySingleton(
      () => CartSaleCubit(cartSaleService: getIt<CartSaleService>()));
  getIt.registerLazySingleton(
      () => ProductStockCubit(service: getIt<ProductStockService>()));
  getIt.registerLazySingleton(() => AiAssistantCubit(
        assistantService: getIt<AiAssistantService>(),
        chatHistoryService: getIt<ChatHistoryDatabaseService>(),
        userService: getIt<UserService>(),
      ));
  getIt.registerFactory(() => ProductIdentificationCubit(
        service: getIt<ProductIdentificationService>(),
      ));
  getIt.registerFactory(() => MultipleDetectionCubit(
        service: getIt<ProductIdentificationService>(),
      ));
  getIt.registerFactory(() => InvoiceScanCubit(
        service: getIt<InvoiceScanService>(),
      ));
  getIt.registerFactory(() => StatsCubit(getIt<StatsService>()));
}
