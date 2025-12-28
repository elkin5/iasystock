import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

// Guards
import '../guards/auth_guard.dart';
// Models
import '../models/menu/category_model.dart';
import '../models/menu/general_settings_model.dart';
import '../models/menu/person_model.dart';
import '../models/menu/product_model.dart';
import '../models/menu/promotion_model.dart';
import '../models/menu/sale_item_model.dart';
import '../models/menu/sale_model.dart';
import '../models/menu/stock_model.dart';
import '../models/menu/user_model.dart';
import '../models/menu/warehouse_model.dart';
// Screens - Home
import '../screens/home/ai_assistant_screen.dart';
import '../screens/home/camera_screen.dart';
import '../screens/home/cart_sale/cart_sale_management_screen.dart';
// Screens - Sales
import '../screens/home/cart_sale/cart_sale_screen.dart';
import '../screens/home/notifications_screen.dart';
import '../screens/home/product_stock/product_stock_management_screen.dart';
import '../screens/home/product_stock/product_stock_screen.dart';
import '../screens/home/statistics/statistics_screen.dart';
// Screens - Menu
import '../screens/menu/audit_log/audit_log_list_screen.dart';
import '../screens/menu/category/category_form_screen.dart';
import '../screens/menu/category/category_list_screen.dart';
import '../screens/menu/general_settings/general_settings_form_screen.dart';
import '../screens/menu/general_settings/general_settings_list_screen.dart';
import '../screens/menu/person/person_form_screen.dart';
import '../screens/menu/person/person_list_screen.dart';
import '../screens/menu/product/product_form_screen.dart';
import '../screens/menu/product/product_list_screen.dart';
import '../screens/menu/promotion/promotion_form_screen.dart';
import '../screens/menu/promotion/promotion_list_screen.dart';
import '../screens/menu/sale/sale_form_screen.dart';
import '../screens/menu/sale/sale_list_screen.dart';
import '../screens/menu/sale_item/sale_item_form_screen.dart';
import '../screens/menu/sale_item/sale_item_list_screen.dart';
import '../screens/menu/stock/enhanced_stock_registration_screen.dart';
import '../screens/menu/stock/stock_form_screen.dart';
import '../screens/menu/stock/stock_list_screen.dart';
import '../screens/menu/stock/stock_registration_method_screen.dart';
import '../screens/menu/user/user_form_screen.dart';
import '../screens/menu/user/user_list_screen.dart';
import '../screens/menu/warehouse/warehouse_form_screen.dart';
import '../screens/menu/warehouse/warehouse_list_screen.dart';
// Screens - User Options
import '../screens/user_options/about_screen.dart';
import '../screens/user_options/change_theme_screen.dart';
import '../screens/user_options/contact_screen.dart';
import '../screens/user_options/edit_user_screen.dart';
import '../screens/user_options/update_app_screen.dart';
import '../screens/user_options/upgrade_to_premium_screen.dart';
// Widgets
import '../widgets/auth/role_based_widgets.dart';

List<GoRoute> getAppRoutes({
  required bool isDarkMode,
  required ValueChanged<bool> onThemeChanged,
}) =>
    [
      // Usuarios (solo admin y sudo)
      GoRoute(
        path: '/users',
        name: 'users',
        builder: (_, __) => const ProtectedRoute(
          requiredRole: 'admin',
          child: UserListScreen(),
        ),
        routes: [
          GoRoute(
            path: 'form',
            name: 'user_form',
            builder: (context, state) {
              final user = state.extra as UserModel?;
              return ProtectedRoute(
                requiredRole: 'admin',
                child: UserFormScreen(user: user),
              );
            },
          ),
        ],
      ),

      // Personas
      GoRoute(
        path: '/persons',
        name: 'persons',
        builder: (_, __) => const PersonListScreen(),
        routes: [
          GoRoute(
            path: 'form',
            name: 'person_form',
            builder: (context, state) {
              final person = state.extra as PersonModel?;
              return PersonFormScreen(person: person);
            },
          ),
        ],
      ),

      // Productos (inventario - sudo, admin, almacenista)
      GoRoute(
        path: '/products',
        name: 'products',
        builder: (_, __) => const InventoryAccessWidget(
          child: ProductListScreen(),
        ),
        routes: [
          GoRoute(
            path: 'form',
            name: 'product_form',
            builder: (context, state) {
              final product = state.extra as ProductModel?;
              return InventoryAccessWidget(
                child: ProductFormScreen(product: product),
              );
            },
          ),
        ],
      ),

      // Categorías
      GoRoute(
        path: '/categories',
        name: 'categories',
        builder: (_, __) => const CategoryListScreen(),
        routes: [
          GoRoute(
            path: 'form',
            name: 'category_form',
            builder: (context, state) {
              final category = state.extra as CategoryModel?;
              return CategoryFormScreen(category: category);
            },
          ),
        ],
      ),

      // Almacenes
      GoRoute(
        path: '/warehouses',
        name: 'warehouses',
        builder: (_, __) => const WarehouseListScreen(),
        routes: [
          GoRoute(
            path: 'form',
            name: 'warehouse_form',
            builder: (context, state) {
              final warehouse = state.extra as WarehouseModel?;
              return WarehouseFormScreen(warehouse: warehouse);
            },
          ),
        ],
      ),

      // Stock (inventario - sudo, admin, almacenista)
      GoRoute(
        path: '/stock',
        name: 'stock',
        builder: (_, __) => const InventoryAccessWidget(
          child: StockRegistrationMethodScreen(),
        ),
        routes: [
          GoRoute(
            path: 'list',
            name: 'stock_list',
            builder: (_, __) => const InventoryAccessWidget(
              child: StockListScreen(),
            ),
          ),
          GoRoute(
            path: 'form',
            name: 'stock_form',
            builder: (context, state) {
              final stock = state.extra as StockModel?;
              return InventoryAccessWidget(
                child: StockFormScreen(stock: stock),
              );
            },
          ),
          GoRoute(
            path: 'enhanced',
            name: 'enhanced_stock_form',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return InventoryAccessWidget(
                child: EnhancedStockRegistrationScreen(
                  product: extra?['product'] as ProductModel?,
                  initialQuantity: extra?['quantity'] as String?,
                  imageFile: extra?['imageFile'] as File?,
                ),
              );
            },
          ),
        ],
      ),

      // Ventas (sudo, admin, ventas)
      GoRoute(
        path: '/sales',
        name: 'sales',
        builder: (_, __) => const SalesAccessWidget(
          child: SaleListScreen(),
        ),
        routes: [
          GoRoute(
            path: 'form',
            name: 'sale_form',
            builder: (context, state) {
              final sale = state.extra as SaleModel?;
              return SalesAccessWidget(
                child: SaleFormScreen(sale: sale),
              );
            },
          ),
        ],
      ),

      // Detalles de ventas (sudo, admin, ventas)
      GoRoute(
        path: '/sale_items',
        name: 'sale_items',
        builder: (_, __) => const SalesAccessWidget(
          child: SaleItemListScreen(),
        ),
        routes: [
          GoRoute(
            path: 'form',
            name: 'sale_item_form',
            builder: (context, state) {
              final item = state.extra as SaleItemModel?;
              return SalesAccessWidget(
                child: SaleItemFormScreen(saleItem: item),
              );
            },
          ),
        ],
      ),

      // Promociones (sudo, admin, ventas)
      GoRoute(
        path: '/promotions',
        name: 'promotions',
        builder: (_, __) => const SalesAccessWidget(
          child: PromotionListScreen(),
        ),
        routes: [
          GoRoute(
            path: 'form',
            name: 'promotion_form',
            builder: (context, state) {
              final promo = state.extra as PromotionModel?;
              return SalesAccessWidget(
                child: PromotionFormScreen(promotion: promo),
              );
            },
          ),
        ],
      ),

      // Configuraciones Generales (solo sudo)
      GoRoute(
        path: '/general_settings',
        name: 'settings',
        builder: (_, __) => const RoleBasedWidget(
          requiredRole: 'sudo',
          child: GeneralSettingsListScreen(),
        ),
        routes: [
          GoRoute(
            path: 'form',
            name: 'settings_form',
            builder: (context, state) {
              final setting = state.extra as GeneralSettingsModel?;
              return RoleBasedWidget(
                requiredRole: 'sudo',
                child: GeneralSettingsFormScreen(setting: setting),
              );
            },
          ),
        ],
      ),

      // Logs (solo sudo)
      GoRoute(
        path: '/audit_logs',
        name: 'audit_logs',
        builder: (_, __) => const RoleBasedWidget(
          requiredRole: 'sudo',
          child: AuditLogListScreen(),
        ),
      ),

      // Pantallas principales
      GoRoute(
        path: '/home/notifications',
        name: 'notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/home/camera',
        name: 'camera',
        builder: (_, __) => const CameraScreen(),
      ),
      GoRoute(
        path: '/home/statistics',
        name: 'statistics',
        builder: (_, __) => const StatisticsScreen(),
      ),
      GoRoute(
        path: '/home/cart_sale',
        name: 'cart_sale',
        builder: (_, __) => const CartSaleScreen(),
      ),
      GoRoute(
        path: '/home/cart_sale_management',
        name: 'cart_sale_management',
        builder: (_, __) => const CartSaleManagementScreen(),
      ),
      GoRoute(
        path: '/home/product_stock',
        name: 'product_stock',
        builder: (_, __) => const ProductStockScreen(),
      ),
      GoRoute(
        path: '/home/product_stock_management',
        name: 'product_stock_management',
        builder: (_, __) => const ProductStockManagementScreen(),
      ),

      // Configuración de usuario
      GoRoute(
        path: '/user_config/edit_user',
        name: 'edit_user',
        builder: (_, __) => const EditUserScreen(),
      ),
      GoRoute(
        path: '/user_config/change_theme',
        name: 'change_theme',
        builder: (_, __) => ChangeThemeScreen(
          isDarkMode: isDarkMode,
          onThemeChanged: onThemeChanged,
        ),
      ),
      GoRoute(
        path: '/user_config/update_app',
        name: 'update_app',
        builder: (_, __) => const UpdateAppScreen(),
      ),
      GoRoute(
        path: '/user_config/upgrade_premium',
        name: 'upgrade_premium',
        builder: (_, __) => const UpgradeToPremiumScreen(),
      ),
      GoRoute(
        path: '/user_config/contact',
        name: 'contact',
        builder: (_, __) => const ContactScreen(),
      ),
      GoRoute(
        path: '/user_config/about',
        name: 'about',
        builder: (_, __) => const AboutScreen(),
      ),

      // Asistente AI
      GoRoute(
        path: '/ai_assistant',
        name: 'ai_assistant',
        builder: (_, __) => const AiAssistantScreen(),
      ),
    ];
