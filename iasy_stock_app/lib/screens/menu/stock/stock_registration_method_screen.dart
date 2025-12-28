import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../config/get_it_config.dart';
import '../../../cubits/product_identification/multiple_detection_cubit.dart';
import '../../../cubits/product_stock/product_stock_cubit.dart';
import '../../../models/menu/product_model.dart';
import '../../../widgets/notification_helper.dart';
import '../../home/camera_screen.dart';
import '../../product_identification/multiple_detection_screen.dart';

class StockRegistrationMethodScreen extends StatelessWidget {
  const StockRegistrationMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Stock'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona el método de registro',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Elige cómo deseas registrar productos en stock',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),

            // Método 1: Desde Cámara (Reconocimiento Inteligente)
            _buildMethodCard(
              context,
              icon: Icons.camera_alt,
              title: 'Desde Cámara',
              subtitle: 'Toma una foto y reconoce productos automáticamente',
              color: Colors.green,
              onTap: () => _navigateToCameraFlow(context),
            ),

            const SizedBox(height: 16),

            // Método 2: Detección Múltiple
            _buildMethodCard(
              context,
              icon: Icons.scanner,
              title: 'Detección Múltiple',
              subtitle: 'Detecta múltiples productos en una sola imagen',
              color: Colors.teal,
              onTap: () => _navigateToMultipleDetection(context),
            ),

            const SizedBox(height: 16),

            // Método 3: Registro Manual
            _buildMethodCard(
              context,
              icon: Icons.edit_note,
              title: 'Registro Manual',
              subtitle: 'Completa el formulario manualmente',
              color: Colors.blue,
              onTap: () => _navigateToManualRegistration(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCameraFlow(BuildContext context) async {
    // Flujo unificado actualizado: Cámara -> Confirmar -> Selección de acción (IA)
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraScreen(),
      ),
    );
  }

  Future<void> _navigateToMultipleDetection(BuildContext context) async {
    final multipleDetectionCubit = getIt<MultipleDetectionCubit>();

    // Navegar a la pantalla de detección múltiple con callback
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: multipleDetectionCubit,
          child: MultipleDetectionScreen(
            onConfirm: (result) async {
              // Mostrar resumen de productos detectados
              final totalProducts = result.uniqueProducts;
              final totalQuantity = result.productGroups.fold<int>(
                0,
                (sum, group) => sum + group.quantity,
              );

              if (context.mounted) {
                NotificationHelper.showSuccess(
                  context,
                  'Detectados $totalProducts productos ($totalQuantity unidades)',
                );

                // Agregar todos los productos detectados al ProductStockCubit
                // (similar a cómo funciona el carrito en ventas)
                final productStockCubit = getIt<ProductStockCubit>();

                // Asegurarse de que el cubit esté en estado inicial
                productStockCubit.startNewRecord();

                // Agregar cada producto detectado al stock basket
                for (final group in result.productGroups) {
                  // Agregar cada unidad detectada como una entrada individual
                  // (el usuario podrá ajustar cantidades en la pantalla de stock)
                  productStockCubit.addProductStockEntry(
                    product: ProductModel(
                      id: group.product.id,
                      name: group.product.name,
                      description: group.product.description,
                      categoryId: group.product.categoryId,
                      imageUrl: group.product.imageUrl,
                      stockQuantity: group.product.stockQuantity,
                    ),
                    quantity: group.quantity,
                    entryPrice: 0,
                    // Usuario deberá ingresar precio de entrada
                    salePrice: 0,
                    // Usuario deberá ingresar precio de venta
                    warehouseId: 1,
                    // TODO: obtener almacén por defecto o permitir selección
                    entryDate: DateTime.now(),
                  );
                }

                // Navegar a la pantalla de registro de stock por lotes
                if (context.mounted) {
                  await context.push('/home/product_stock');
                }
              }
            },
          ),
        ),
      ),
    );

    // Resetear el cubit después de usarlo
    multipleDetectionCubit.reset();
  }

  void _navigateToManualRegistration(BuildContext context) {
    // Ir directamente al formulario manual de stock
    context.push('/stock/form');
  }
}
