import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../config/get_it_config.dart';
import '../../../cubits/cart_sale/cart_sale_cubit.dart';
import '../../../cubits/cart_sale/cart_sale_state.dart';
import '../../../models/menu/sale_item_model.dart';
import '../../../services/cart_sale/cart_sale_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/home_layout_tokens.dart';
import '../../../widgets/cart_sale/cart_sale_client_modal.dart';
import '../../../widgets/cart_sale/cart_sale_product_modal.dart';
import '../../../widgets/home/general_sliver_app_bar.dart';
import '../../../widgets/home/home_ui_components.dart';
import '../../../widgets/menu/secure_network_image.dart';

class CartSaleScreen extends StatefulWidget {
  const CartSaleScreen({super.key});

  @override
  State<CartSaleScreen> createState() => _CartSaleScreenState();
}

class _CartSaleScreenState extends State<CartSaleScreen> {
  @override
  void initState() {
    super.initState();
    // Inicializar el cubit al entrar a la pantalla
    final cubit = getIt<CartSaleCubit>();
    if (cubit.state is! CartSaleLoaded) {
      cubit.startNewSale();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          // Limpiar el carrito cuando se navega hacia atrás
          getIt<CartSaleCubit>().forceRestart();
        }
      },
      child: Scaffold(
        body: BlocConsumer<CartSaleCubit, CartSaleState>(
          listener: (context, state) {
            if (state is CartSaleError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.danger(context),
                ),
              );
            } else if (state is CartSaleSaved) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Venta guardada exitosamente'),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              );
            } else if (state is CartSalePaymentCompleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Pago procesado exitosamente'),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              );
            } else if (state is CartSaleInitial) {
              // Cuando el estado vuelve a inicial, reiniciar automáticamente
              Future.delayed(const Duration(milliseconds: 50), () {
                if (context.mounted) {
                  getIt<CartSaleCubit>().startNewSale();
                }
              });
            }
          },
          builder: (context, state) {
            // Si el estado es inicial, mostrar loading mientras se reinicia
            if (state is CartSaleInitial) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return CustomScrollView(
              slivers: [
                GeneralSliverAppBar(
                  title: 'Carrito de Ventas',
                  subtitle: _getSubtitle(state),
                  icon: Icons.shopping_cart_rounded,
                  primaryColor: theme.primaryColor,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Sección Superior - Funcionalidades
                        _buildTopSection(context, state),

                        const SizedBox(height: HomeLayoutTokens.sectionSpacing),

                        // Sección Central - Productos del Carrito
                        _buildMiddleSection(context, state),

                        const SizedBox(height: HomeLayoutTokens.sectionSpacing),

                        // Sección Inferior - Resumen y Acciones
                        _buildBottomSection(context, state),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _getSubtitle(CartSaleState state) {
    if (state is CartSaleLoaded) {
      return 'Nueva Venta';
    }
    return 'Nueva Venta';
  }

  Widget _buildTopSection(BuildContext context, CartSaleState state) {
    final formattedSaleDate =
        state is CartSaleLoaded && state.sale.saleDate != null
            ? DateFormat('dd/MM/yyyy HH:mm:ss').format(state.sale.saleDate!)
            : DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());

    return HomeSectionCard(
      child: Column(
        children: [
          // Primera fila - Seleccionar Cliente y Fecha
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.person_rounded,
                  label:
                      (state is CartSaleLoaded && state.selectedClient != null)
                          ? state.selectedClient!.name
                          : 'Seleccionar Cliente',
                  color: Theme.of(context).primaryColor,
                  onPressed: () => _handleSelectClient(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceBorder(context)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.surfaceBorder(context),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          color: Colors.grey[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          formattedSaleDate,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Segunda fila - Agregar Producto
          _buildActionButton(
            icon: Icons.add_box_rounded,
            label: 'Agregar Producto',
            color: Theme.of(context).primaryColor,
            onPressed: () => _handleAddProduct(context),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMiddleSection(BuildContext context, CartSaleState state) {
    return HomeSectionCard(
      showBorder: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Productos en el Carrito',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (state is CartSaleLoaded) ...[
            if (state.saleItems.isEmpty)
              _buildEmptyCart()
            else
              ...state.saleItems
                  .asMap()
                  .entries
                  .map((entry) => _buildCartItemCard(
                      context, entry.value, state, entry.key + 1))
                  .toList(),
          ] else if (state is CartSaleLoading) ...[
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context, CartSaleState state) {
    if (state is! CartSaleLoaded || state.saleItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return HomeSectionCard(
      child: Column(
        children: [
          // Resumen de la venta
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Items', state.totalItems.toString()),
              _buildSummaryItem('Cantidad', state.totalQuantity.toString()),
              _buildSummaryItem(
                  'Total', '\$${state.totalValue.toStringAsFixed(2)}'),
            ],
          ),

          const SizedBox(height: 20),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.payment_rounded,
                  label: 'Pagar',
                  color: Theme.of(context).primaryColor,
                  onPressed: () => _handleProcessPayment(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.save_rounded,
                  label: 'Guardar',
                  color: Theme.of(context).primaryColor.withOpacity(0.9),
                  onPressed: () => _handleSavePendingSale(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.delete_rounded,
                  label: 'Cancelar',
                  color: AppColors.textMuted(context),
                  onPressed: () => getIt<CartSaleCubit>().forceRestart(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    final effectiveColor = onPressed != null ? color : color.withOpacity(0.5);
    return HomeActionButton(
      icon: icon,
      label: label,
      color: effectiveColor,
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    );
  }

  Widget _buildEmptyCart() {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.primaryColor.withOpacity(0.05),
        border: Border.all(color: theme.primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 48, color: theme.primaryColor),
          const SizedBox(height: 12),
          const Text(
            'El carrito está vacío',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Agrega productos para comenzar la venta',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(BuildContext context, SaleItemModel item,
      CartSaleLoaded state, int cardNumber) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).primaryColor.withOpacity(0.03),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.08),
        ),
      ),
      child: Column(
        children: [
          // Primera fila: Información del producto
          Row(
            children: [
              // Contador de cantidad
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '$cardNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Imagen del producto
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.15),
                  ),
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildProductImage(item, state),
                ),
              ),

              const SizedBox(width: 12),

              // Información del producto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getProductName(item, state),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${item.unitPrice.toStringAsFixed(2)} c/u',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Indicador de stock disponible
                    Text(
                      'Stock: ${_getStockAvailable(item, state)}',
                      style: TextStyle(
                        color: _getStockColor(context, item, state),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Botón eliminar
              IconButton(
                onPressed: () => _removeItem(context, item),
                icon: Icon(Icons.delete_outline,
                    color: AppColors.danger(context)),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Segunda fila: Controles de cantidad y precio total
          Row(
            children: [
              // Selector de cantidad simple y minimalista
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botón menos
                  GestureDetector(
                    onTap: () => _decreaseQuantity(context, item),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.remove,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  // Número de cantidad
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      item.quantity.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  // Botón más
                  GestureDetector(
                    onTap: _canIncreaseQuantity(item, state)
                        ? () => _increaseQuantity(context, item)
                        : null,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _canIncreaseQuantity(item, state)
                            ? Colors.grey[200]
                            : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        size: 16,
                        color: _canIncreaseQuantity(item, state)
                            ? Colors.grey
                            : Colors.grey[400],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 8),

              // Precio total (más espacio)
              Expanded(
                flex: 2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '\$${item.totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getProductName(SaleItemModel item, CartSaleLoaded state) {
    final product = state.products[item.productId];
    return product?.name ?? 'Producto ${item.productId}';
  }

  Widget _buildProductImage(SaleItemModel item, CartSaleLoaded state) {
    final product = state.products[item.productId];

    if (product != null &&
        product.imageUrl != null &&
        product.imageUrl!.isNotEmpty) {
      return SecureNetworkImage(
        imageUrl: product.imageUrl,
        productId: product.id,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        placeholder: Container(
          width: 60,
          height: 60,
          color: Colors.grey[200],
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: Container(
          width: 60,
          height: 60,
          color: Colors.grey[100],
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 24,
            color: Colors.grey[400],
          ),
        ),
      );
    }

    // Placeholder si no hay imagen
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey[200],
      child: Icon(
        Icons.inventory_2_outlined,
        color: Colors.grey[400],
        size: 30,
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // Métodos de manejo de eventos
  void _handleSelectClient(BuildContext context) {
    final cubit = getIt<CartSaleCubit>();

    showDialog(
      context: context,
      builder: (context) => CartSaleClientModal(
        cartSaleService: getIt<CartSaleService>(),
        onClientSelected: (client) {
          try {
            cubit.selectClient(client);
          } catch (e) {
            // Si hay error, mostrar mensaje y recrear el cubit
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    const Text('Error al seleccionar cliente. Reiniciando...'),
                backgroundColor: Theme.of(context).primaryColor,
              ),
            );
          }
        },
      ),
    );
  }

  void _handleAddProduct(BuildContext context) {
    final cubit = getIt<CartSaleCubit>();

    showDialog(
      context: context,
      builder: (context) => CartSaleProductModal(
        cartSaleService: getIt<CartSaleService>(),
        onProductSelected: (product) async {
          try {
            await cubit.addProductToCart(product);
          } catch (e) {
            // Si hay error, mostrar mensaje y recrear el cubit
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      const Text('Error al agregar producto. Reiniciando...'),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _increaseQuantity(BuildContext context, SaleItemModel item) {
    getIt<CartSaleCubit>().updateProductQuantity(
      item.productId,
      item.quantity + 1,
    );
  }

  // Verificar si se puede aumentar la cantidad sin exceder el stock
  bool _canIncreaseQuantity(SaleItemModel item, CartSaleLoaded state) {
    final product = state.products[item.productId];
    if (product?.stockQuantity == null)
      return true; // Si no hay info de stock, permitir
    return item.quantity < product!.stockQuantity!;
  }

  // Obtener stock disponible para mostrar
  String _getStockAvailable(SaleItemModel item, CartSaleLoaded state) {
    final product = state.products[item.productId];
    if (product?.stockQuantity == null) return 'Sin límite';
    return '${product!.stockQuantity!} unidades';
  }

  // Obtener color según el stock disponible
  Color _getStockColor(
      BuildContext context, SaleItemModel item, CartSaleLoaded state) {
    final product = state.products[item.productId];
    if (product?.stockQuantity == null) return AppColors.textMuted(context);

    final stockAvailable = product!.stockQuantity! - item.quantity;
    if (stockAvailable <= 0) return AppColors.danger(context);
    if (stockAvailable <= 2) return AppColors.warning(context);
    return AppColors.success(context);
  }

  void _decreaseQuantity(BuildContext context, SaleItemModel item) {
    if (item.quantity > 1) {
      getIt<CartSaleCubit>().updateProductQuantity(
        item.productId,
        item.quantity - 1,
      );
    }
  }

  void _removeItem(BuildContext context, SaleItemModel item) {
    getIt<CartSaleCubit>().removeProductFromCart(item.productId);
  }

  // Manejar procesamiento de pago con validaciones
  void _handleProcessPayment(BuildContext context) {
    final cubit = getIt<CartSaleCubit>();
    final state = cubit.state;

    // Validar que haya un cliente seleccionado
    if (state is CartSaleLoaded && state.selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Debe seleccionar un cliente antes de procesar el pago'),
          backgroundColor: AppColors.danger(context),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Mostrar confirmación antes de procesar el pago
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Pago'),
        content: Text(
            '¿Está seguro de procesar el pago por \$${cubit.state is CartSaleLoaded ? (cubit.state as CartSaleLoaded).sale.totalAmount.toStringAsFixed(2) : '0.00'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              cubit.processPayment(payMethod: 'Efectivo');
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  // Manejar guardado de venta pendiente con validaciones
  void _handleSavePendingSale(BuildContext context) {
    final cubit = getIt<CartSaleCubit>();
    final state = cubit.state;

    // Validar que haya un cliente seleccionado
    if (state is CartSaleLoaded && state.selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Debe seleccionar un cliente antes de guardar la venta'),
          backgroundColor: AppColors.danger(context),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Mostrar confirmación antes de guardar
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guardar Venta Pendiente'),
        content:
            const Text('¿Está seguro de guardar esta venta como pendiente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              cubit.savePendingSale();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
