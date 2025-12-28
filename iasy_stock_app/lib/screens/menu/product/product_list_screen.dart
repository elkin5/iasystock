import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../cubits/menu/category_cubit.dart';
import '../../../cubits/menu/product_cubit.dart';
import '../../../models/menu/category_model.dart';
import '../../../models/menu/product_model.dart';
import '../../../widgets/menu/generic_list_screen.dart';
import '../../../widgets/notification_helper.dart';
import '../../../widgets/menu/secure_network_image.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProductCubit>().loadProducts(refresh: true);
    context.read<CategoryCubit>().loadCategories(refresh: true);
  }

  Future<void> _navigateToForm({ProductModel? product}) async {
    await context.push('/products/form', extra: product);
    context.read<ProductCubit>().loadProducts(refresh: true);
  }

  Future<void> _onDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: const Text('¿Estás seguro de eliminar este producto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await context.read<ProductCubit>().deleteProduct(id);
        NotificationHelper.showSuccess(
            context, 'Producto eliminado correctamente');
        context.read<ProductCubit>().loadProducts(refresh: true);
      } on DioException catch (e) {
        final message =
            e.response?.data['message'] ?? 'Error eliminando producto';
        NotificationHelper.showError(context, message);
      } catch (e) {
        NotificationHelper.showError(context, 'Error eliminando producto');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, productState) {
        return BlocBuilder<CategoryCubit, CategoryState>(
          builder: (context, categoryState) {
            if (productState is ProductLoading ||
                categoryState is CategoryLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (productState is ProductLoaded &&
                categoryState is CategoryLoaded) {
              return GenericInfiniteListScreen<ProductModel>(
                title: 'Productos',
                items: productState.products,
                searchHint: 'Buscar por nombre...',
                searchTextExtractor: (p) => p.name,
                onAddPressed: () => _navigateToForm(),
                onLoadMore: () =>
                    context.read<ProductCubit>().loadMoreProducts(),
                isLoadingMore: productState.isLoadingMore,
                hasMoreData: productState.hasMoreData,
                itemBuilder: (context, product) {
                  final category = categoryState.categories.firstWhere(
                    (c) => c.id == product.categoryId,
                    orElse: () =>
                        CategoryModel(id: 0, name: 'N/A', description: ''),
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
                                    Icons.inventory,
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
                          Text('Categoría: ${category.name}'),
                          if (product.stockQuantity != null)
                            Text('Stock: ${product.stockQuantity}')
                          else
                            const Text('Stock: No especificado'),
                          if (product.expirationDate != null)
                            Text(
                                'Expira: ${DateFormat('yyyy-MM-dd').format(product.expirationDate!)}'),
                        ],
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Detalle Producto'),
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (product.imageUrl != null &&
                                      product.imageUrl!.isNotEmpty)
                                    SizedBox(
                                      width: 280, // Ancho fijo para AlertDialog
                                      height: 200,
                                      child: SecureNetworkImage(
                                        imageUrl: product.imageUrl,
                                        productId: product.id,
                                        width:
                                            280, // Ancho fijo en lugar de infinity
                                        height: 200,
                                        fit: BoxFit.contain,
                                      ),
                                    )
                                  else
                                    const Column(
                                      children: [
                                        Icon(Icons.image_not_supported,
                                            size: 50, color: Colors.grey),
                                        Text("No hay imagen disponible"),
                                      ],
                                    ),
                                  const SizedBox(height: 8),
                                  Text('ID: ${product.id ?? 'N/A'}'),
                                  Text('Nombre: ${product.name}'),
                                  Text(
                                      'Descripción: ${product.description ?? 'Sin descripción'}'),
                                  Text(
                                      'Categoría: ${category.id} - ${category.name}'),
                                  Text(
                                      'Stock actual: ${product.stockQuantity ?? 'No especificado'}'),
                                  Text(
                                      'Stock mínimo: ${product.stockMinimum ?? 'No especificado'}'),
                                  Text(
                                      'Fecha creación: ${product.createdAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(product.createdAt!) : 'No especificada'}'),
                                  Text(
                                      'Expiración: ${product.expirationDate != null ? DateFormat('yyyy-MM-dd').format(product.expirationDate!) : 'No especificada'}'),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cerrar')),
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
                              onPressed: () =>
                                  _navigateToForm(product: product)),
                          IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              iconSize: 20,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              onPressed: () => _onDelete(product.id!)),
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
}
