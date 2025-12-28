import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/auth/auth_cubit.dart';
import '../widgets/home/category_card.dart';
import 'main_screen.dart';

class HomeScreen extends StatelessWidget {
  final Color? primaryColor;

  const HomeScreen({super.key, this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedPrimaryColor = primaryColor ?? theme.primaryColor;

    // Lista de tarjetas con colores distintivos y diferenciados
    final List<CategoryCard> cards = [
      const CategoryCard(
        icon: Icons.shopping_cart_rounded,
        text: 'Registrar Venta',
        color: Color(0xFF4CAF50), // Verde vibrante
        route: '/home/cart_sale_management',
      ),
      const CategoryCard(
        icon: Icons.inventory_2_rounded,
        text: 'Registrar Stock',
        color: Color(0xFF9C27B0), // Púrpura vibrante
        route: '/home/product_stock_management',
      ),
      const CategoryCard(
        icon: Icons.smart_toy_rounded,
        text: 'Asistente IA',
        color: Color(0xFF00BCD4), // Cian vibrante
        route: '/ai_assistant',
      ),
      const CategoryCard(
        icon: Icons.camera_alt_rounded,
        text: 'Cámara',
        color: Color(0xFF2196F3), // Azul vibrante
        route: '/home/camera',
      ),
      const CategoryCard(
        icon: Icons.warning_amber_rounded,
        text: 'Notificaciones',
        color: Color(0xFFFF5722), // Naranja vibrante
        route: '/home/notifications',
      ),
      const CategoryCard(
        icon: Icons.analytics_rounded,
        text: 'Estadísticas',
        color: Color(0xFFE91E63), // Rosa vibrante
        route: '/home/statistics',
      ),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          GeneralSliverAppBar(
            title: 'Panel Principal',
            subtitle: 'Acceso rápido a funciones principales',
            icon: Icons.home_rounded,
            primaryColor: resolvedPrimaryColor,
            onLogout: () => context.read<AuthCubit>().signOut(),
          ),
          SliverLayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.crossAxisExtent;

              // Calcular el número de columnas basado en el ancho de pantalla
              int crossAxisCount;
              double crossAxisSpacing;
              double mainAxisSpacing;
              EdgeInsets padding;

              if (screenWidth >= 1200) {
                // Pantallas muy grandes - 3 columnas
                crossAxisCount = 3;
                crossAxisSpacing = 24;
                mainAxisSpacing = 24;
                padding = const EdgeInsets.fromLTRB(24, 20, 24, 32);
              } else if (screenWidth >= 900) {
                // Pantallas grandes - 2 columnas
                crossAxisCount = 2;
                crossAxisSpacing = 20;
                mainAxisSpacing = 20;
                padding = const EdgeInsets.fromLTRB(20, 16, 20, 24);
              } else if (screenWidth >= 600) {
                // Tablets - 2 columnas
                crossAxisCount = 2;
                crossAxisSpacing = 16;
                mainAxisSpacing = 16;
                padding = const EdgeInsets.fromLTRB(16, 16, 16, 24);
              } else {
                // Móviles - 2 columnas con menos espaciado
                crossAxisCount = 2;
                crossAxisSpacing = 12;
                mainAxisSpacing = 12;
                padding = const EdgeInsets.fromLTRB(12, 16, 12, 20);
              }

              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: crossAxisSpacing,
                  mainAxisSpacing: mainAxisSpacing,
                  childAspectRatio: 1.0, // Mantener forma cuadrada
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: padding,
                    child: cards[index],
                  ),
                  childCount: cards.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
