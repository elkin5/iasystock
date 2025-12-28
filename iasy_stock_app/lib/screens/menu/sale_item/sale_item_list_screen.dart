import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../cubits/menu/product_cubit.dart';
import '../../../cubits/menu/sale_item_cubit.dart';
import '../../../models/menu/product_model.dart';
import '../../../models/menu/sale_item_model.dart';
import '../../../widgets/menu/generic_list_screen.dart';
import '../../../widgets/menu/secure_network_image.dart';
import '../../../widgets/notification_helper.dart';

class SaleItemListScreen extends StatefulWidget {
  const SaleItemListScreen({super.key});

  @override
  State<SaleItemListScreen> createState() => _SaleItemListScreenState();
}

class _SaleItemListScreenState extends State<SaleItemListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SaleItemCubit>().loadSaleItems();
    context.read<ProductCubit>().loadProducts();
  }

  Future<void> _navigateToForm({SaleItemModel? item}) async {
    await context.push('/sale_items/form', extra: item);
    context.read<SaleItemCubit>().loadSaleItems();
  }

  Future<void> _onDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar ítem de venta'),
        content: const Text('¿Seguro que deseas eliminar este ítem?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await context.read<SaleItemCubit>().deleteSaleItem(id);
        NotificationHelper.showSuccess(context, 'Ítem eliminado correctamente');
        context.read<SaleItemCubit>().loadSaleItems();
      } on DioException catch (e) {
        final message = e.response?.data['message'] ?? 'Error eliminando ítem';
        NotificationHelper.showError(context, message);
      } catch (e) {
        NotificationHelper.showError(context, 'Error eliminando ítem');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SaleItemCubit, SaleItemState>(
      builder: (context, saleItemState) {
        return BlocBuilder<ProductCubit, ProductState>(
          builder: (context, productState) {
            if (saleItemState is SaleItemLoading ||
                productState is ProductLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (saleItemState is SaleItemLoaded &&
                productState is ProductLoaded) {
              return GenericListScreen<SaleItemModel>(
                title: 'Ítems de Venta',
                items: saleItemState.saleItems,
                searchHint: 'Buscar por producto o total...',
                searchTextExtractor: (item) {
                  final product = productState.products.firstWhere(
                    (p) => p.id == item.productId,
                    orElse: () => ProductModel(id: 0, name: '', categoryId: 0),
                  );
                  return '${product.name} ${item.totalPrice}';
                },
                onAddPressed: () => _navigateToForm(),
                itemBuilder: (context, item) {
                  final product = productState.products.firstWhere(
                    (p) => p.id == item.productId,
                    orElse: () => ProductModel(
                        id: 0, name: 'Producto no encontrado', categoryId: 0),
                  );

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: (product.imageUrl != null &&
                                  product.imageUrl!.isNotEmpty)
                              ? SecureNetworkImage(
                                  imageUrl: product.imageUrl,
                                  productId: product.id,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  // Placeholder compacto para lista
                                  placeholder: Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    ),
                                  ),
                                  // Error compacto para lista
                                  errorWidget: Container(
                                    color: Colors.grey[100],
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 24,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[100],
                                  child: Icon(
                                    Icons.receipt_long,
                                    size: 24,
                                    color: Colors.teal[300],
                                  ),
                                ),
                        ),
                      ),
                      title: Text(product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cantidad: ${item.quantity}'),
                          Text(
                              'Total: \$${item.totalPrice.toStringAsFixed(2)}'),
                        ],
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Detalle Ítem de Venta'),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Imagen del producto
                                  if (product.imageUrl != null &&
                                      product.imageUrl!.isNotEmpty)
                                    SizedBox(
                                      width: 280,
                                      height: 200,
                                      child: SecureNetworkImage(
                                        imageUrl: product.imageUrl,
                                        productId: product.id,
                                        width: 280,
                                        height: 200,
                                        fit: BoxFit.contain,
                                      ),
                                    )
                                  else
                                    const Column(
                                      children: [
                                        Icon(Icons.image_not_supported,
                                            size: 50, color: Colors.grey),
                                        Text('No hay imagen disponible'),
                                      ],
                                    ),
                                  const SizedBox(height: 16),
                                  // Campos de información
                                  _buildDetailRow('ID', item.id.toString()),
                                  _buildDetailRow(
                                      'Venta ID', item.saleId.toString()),
                                  _buildDetailRow('Producto', product.name),
                                  _buildDetailRow(
                                      'Cantidad', item.quantity.toString()),
                                  _buildDetailRow('Precio unitario',
                                      '\$${item.unitPrice.toStringAsFixed(2)}'),
                                  _buildDetailRow('Precio total',
                                      '\$${item.totalPrice.toStringAsFixed(2)}'),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cerrar'),
                              ),
                            ],
                          ),
                        );
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              iconSize: 20,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              onPressed: () => _navigateToForm(item: item)),
                          IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              iconSize: 20,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              onPressed: () => _onDelete(item.id!)),
                        ],
                      ),
                    ),
                  );
                },
              );
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
