import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../cubits/menu/person_cubit.dart';
import '../../../cubits/menu/product_cubit.dart';
import '../../../cubits/menu/stock_cubit.dart';
import '../../../cubits/menu/user_cubit.dart';
import '../../../cubits/menu/warehouse_cubit.dart';
import '../../../models/menu/person_model.dart';
import '../../../models/menu/product_model.dart';
import '../../../models/menu/stock_model.dart';
import '../../../models/menu/user_model.dart';
import '../../../models/menu/warehouse_model.dart';
import '../../../widgets/menu/generic_list_screen.dart';
import '../../../widgets/menu/secure_network_image.dart';
import '../../../widgets/notification_helper.dart';

class StockListScreen extends StatefulWidget {
  const StockListScreen({super.key});

  @override
  State<StockListScreen> createState() => _StockListScreenState();
}

class _StockListScreenState extends State<StockListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<StockCubit>().loadStocks(refresh: true);
    context.read<ProductCubit>().loadProducts(refresh: true);
    context.read<WarehouseCubit>().loadWarehouses();
    context.read<PersonCubit>().loadPersons(refresh: true);
    context.read<UserCubit>().loadUsers(refresh: true);
  }

  Future<void> _navigateToForm({StockModel? stock}) async {
    await context.push('/stock/form', extra: stock);
    context.read<StockCubit>().loadStocks(refresh: true);
  }

  Future<void> _onDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar stock'),
        content:
            const Text('¿Seguro que deseas eliminar este registro de stock?'),
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
        await context.read<StockCubit>().deleteStock(id);
        NotificationHelper.showSuccess(
            context, 'Stock eliminado correctamente');
        context.read<StockCubit>().loadStocks(refresh: true);
      } on DioException catch (e) {
        final message = e.response?.data['message'] ?? 'Error eliminando stock';
        NotificationHelper.showError(context, message);
      } catch (e) {
        NotificationHelper.showError(context, 'Error eliminando stock');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StockCubit, StockState>(
      builder: (context, stockState) {
        return BlocBuilder<ProductCubit, ProductState>(
          builder: (context, productState) {
            return BlocBuilder<WarehouseCubit, WarehouseState>(
              builder: (context, warehouseState) {
                return BlocBuilder<PersonCubit, PersonState>(
                  builder: (context, personState) {
                    return BlocBuilder<UserCubit, UserState>(
                      builder: (context, userState) {
                        if (stockState is StockLoading ||
                            productState is ProductLoading ||
                            warehouseState is WarehouseLoading ||
                            personState is PersonLoading ||
                            userState is UserLoading) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (stockState is StockLoaded &&
                            productState is ProductLoaded &&
                            warehouseState is WarehouseLoaded &&
                            personState is PersonLoaded &&
                            userState is UserLoaded) {
                          return GenericInfiniteListScreen<StockModel>(
                            title: 'Gestión de Stock',
                            items: stockState.stocks,
                            searchHint: 'Buscar por nombre de producto...',
                            onLoadMore: () =>
                                context.read<StockCubit>().loadMoreStocks(),
                            isLoadingMore: stockState.isLoadingMore,
                            hasMoreData: stockState.hasMoreData,
                            searchTextExtractor: (stock) {
                              final product = productState.products.firstWhere(
                                (p) => p.id == stock.productId,
                                orElse: () => ProductModel(
                                    id: 0, name: '', categoryId: 0),
                              );
                              return product.name;
                            },
                            onAddPressed: () => _navigateToForm(),
                            itemBuilder: (context, stock) {
                              final product = productState.products.firstWhere(
                                (p) => p.id == stock.productId,
                                orElse: () => ProductModel(
                                    id: 0,
                                    name: 'Producto no encontrado',
                                    categoryId: 0),
                              );

                              final warehouse =
                                  warehouseState.warehouses.firstWhere(
                                (w) => w.id == stock.warehouseId,
                                orElse: () => WarehouseModel(
                                    id: 0,
                                    name: 'Sin almacén',
                                    location: '',
                                    createdAt: DateTime.now()),
                              );

                              final person = stock.personId != null
                                  ? personState.persons.firstWhere(
                                      (p) => p.id == stock.personId,
                                      orElse: () => PersonModel(
                                          id: 0,
                                          name: 'Proveedor no encontrado',
                                          type: 'proveedor'),
                                    )
                                  : null;
                              final user = userState.users.firstWhere(
                                (u) => u.id == stock.userId,
                                orElse: () => UserModel(
                                    id: 0,
                                    username: 'Usuario no encontrado',
                                    role: 'user'),
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
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2),
                                                  ),
                                                ),
                                              ),
                                              // Error compacto para lista
                                              errorWidget: Container(
                                                color: Colors.grey[100],
                                                child: Icon(
                                                  Icons
                                                      .image_not_supported_outlined,
                                                  size: 24,
                                                  color: Colors.grey[400],
                                                ),
                                              ),
                                            )
                                          : Container(
                                              color: Colors.grey[100],
                                              child: Icon(
                                                Icons.store,
                                                size: 24,
                                                color: Colors.teal[300],
                                              ),
                                            ),
                                    ),
                                  ),
                                  title: Text(product.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Cantidad: ${stock.quantity}'),
                                      Text('Almacén: ${warehouse.name}'),
                                    ],
                                  ),
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Detalle Stock'),
                                        content: SizedBox(
                                          width: double.maxFinite,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
                                                    Icon(
                                                        Icons
                                                            .image_not_supported,
                                                        size: 50,
                                                        color: Colors.grey),
                                                    Text(
                                                        'No hay imagen disponible'),
                                                  ],
                                                ),
                                              const SizedBox(height: 16),
                                              // Campos de información
                                              _buildDetailRow(
                                                  'ID', stock.id.toString()),
                                              _buildDetailRow(
                                                  'Producto', product.name),
                                              _buildDetailRow('Cantidad',
                                                  stock.quantity.toString()),
                                              _buildDetailRow('Precio Entrada',
                                                  '\$${stock.entryPrice.toStringAsFixed(2)}'),
                                              _buildDetailRow('Precio Venta',
                                                  '\$${stock.salePrice.toStringAsFixed(2)}'),
                                              _buildDetailRow(
                                                  'Almacén', warehouse.name),
                                              _buildDetailRow(
                                                  'Proveedor',
                                                  person?.name ??
                                                      'Sin proveedor'),
                                              _buildDetailRow(
                                                  'Usuario Creador',
                                                  '${user.firstName ?? ''} ${user.lastName ?? ''}'
                                                          .trim()
                                                          .isNotEmpty
                                                      ? '${user.firstName ?? ''} ${user.lastName ?? ''}'
                                                          .trim()
                                                      : user.username),
                                              _buildDetailRow(
                                                  'Fecha Entrada',
                                                  stock.entryDate != null
                                                      ? DateFormat('yyyy-MM-dd')
                                                          .format(
                                                              stock.entryDate!)
                                                      : 'Sin fecha'),
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
                                          icon:
                                              const Icon(Icons.edit, size: 20),
                                          iconSize: 20,
                                          padding: const EdgeInsets.all(4),
                                          constraints: const BoxConstraints(
                                            minWidth: 32,
                                            minHeight: 32,
                                          ),
                                          onPressed: () =>
                                              _navigateToForm(stock: stock)),
                                      IconButton(
                                          icon: const Icon(Icons.delete,
                                              size: 20),
                                          iconSize: 20,
                                          padding: const EdgeInsets.all(4),
                                          constraints: const BoxConstraints(
                                            minWidth: 32,
                                            minHeight: 32,
                                          ),
                                          onPressed: () =>
                                              _onDelete(stock.id!)),
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
              },
            );
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
