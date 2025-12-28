import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../config/get_it_config.dart';
import '../../../cubits/product_stock/product_stock_cubit.dart';
import '../../../cubits/product_stock/product_stock_state.dart';
import '../../../models/menu/warehouse_model.dart';
import '../../../models/product_stock/product_stock_model.dart';
import '../../../services/menu/warehouse_service.dart';
import '../../../services/product_stock/product_stock_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/home/general_sliver_app_bar.dart';
import '../../../widgets/menu/secure_network_image.dart';
import '../../../widgets/product_stock/product_stock_entry_modal.dart';
import '../../../widgets/product_stock/product_stock_provider_modal.dart';

class ProductStockScreen extends StatefulWidget {
  const ProductStockScreen({super.key});

  @override
  State<ProductStockScreen> createState() => _ProductStockScreenState();
}

class _ProductStockScreenState extends State<ProductStockScreen> {
  final _currencyFormatter =
      NumberFormat.currency(locale: 'es_CO', symbol: r'$');

  List<WarehouseModel>? _warehousesCache;
  bool _loadingWarehouses = false;

  late ProductStockCubit _cubit;
  late ProductStockService _productStockService;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _cubit = context.read<ProductStockCubit>();
      _productStockService = getIt<ProductStockService>();
      if (_cubit.state is! ProductStockLoaded) {
        _cubit.startNewRecord();
      }
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          _cubit.startNewRecord();
        }
      },
      child: Scaffold(
        body: BlocConsumer<ProductStockCubit, ProductStockState>(
          listener: (context, state) {
            if (state is ProductStockError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.danger(context),
                ),
              );
            } else if (state is ProductStockProcessed) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      const Text('Registros de stock procesados correctamente'),
                  backgroundColor: theme.primaryColor,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is ProductStockInitial || state is ProductStockLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ProductStockProcessing) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is! ProductStockLoaded) {
              return const SizedBox.shrink();
            }

            return CustomScrollView(
              slivers: [
                GeneralSliverAppBar(
                  title: 'Gestión de Stock',
                  subtitle: _getSubtitle(state),
                  icon: Icons.inventory_2_rounded,
                  primaryColor: theme.primaryColor,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Sección Superior - Selección de Producto y Proveedor
                        _buildTopSection(context, state),

                        const SizedBox(height: 24),

                        // Sección Central - Registros de Stock
                        _buildMiddleSection(context, state),

                        const SizedBox(height: 24),

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

  String _getSubtitle(ProductStockLoaded state) {
    if (state.hasEntries) {
      final uniqueProducts =
          state.entries.map((e) => e.product.id).toSet().length;
      return '$uniqueProducts producto${uniqueProducts != 1 ? 's' : ''} - ${state.totalItems} registro${state.totalItems != 1 ? 's' : ''}';
    }
    return 'Registra ingresos de stock manualmente';
  }

  Widget _buildTopSection(BuildContext context, ProductStockLoaded state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Selector de proveedor (opcional)
          _buildSelectionButton(
            icon: Icons.store_mall_directory_rounded,
            label: state.selectedProvider != null
                ? state.selectedProvider!.name
                : 'Proveedor (opcional)',
            color: Theme.of(context).primaryColor,
            onPressed: () => _handleSelectProvider(context),
          ),

          const SizedBox(height: 16),

          // Botón agregar registro
          SizedBox(
            width: double.infinity,
            child: _buildActionButton(
              icon: Icons.add_box_rounded,
              label: 'Agregar Registro de Stock',
              color: Theme.of(context).primaryColor,
              onPressed: () => _handleAddEntry(context, state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onPressed,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: onPressed,
                child: Text(actionLabel),
              ),
              if (secondaryActionLabel != null &&
                  onSecondaryPressed != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onSecondaryPressed,
                  child: Text(secondaryActionLabel),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiddleSection(BuildContext context, ProductStockLoaded state) {
    final entries = state.entries;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Registros de Stock',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            _buildEmptyEntriesState(context, state)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _buildEntryCard(context, state, entry, index);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyEntriesState(
      BuildContext context, ProductStockLoaded state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        border:
            Border.all(color: Theme.of(context).primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_outlined,
            size: 48,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 12),
          const Text(
            'Agrega movimientos de stock',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Cada registro incluye un producto específico con su cantidad, precios y almacén.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(BuildContext context, ProductStockLoaded state,
      ProductStockEntry entry, int index) {
    final product = entry.product;
    final stock = entry.stock;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).primaryColor.withOpacity(0.03),
        border:
            Border.all(color: Theme.of(context).primaryColor.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Imagen del producto
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? SecureNetworkImage(
                        imageUrl: product.imageUrl,
                        productId: product.id,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: Theme.of(context).primaryColor,
                          size: 28,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.description != null)
                      Text(
                        product.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _handleEditEntry(context, state, entry, index),
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Editar registro',
              ),
              IconButton(
                onPressed: () => _cubit.removeEntry(index),
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Eliminar registro',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _buildEntryInfo(
                label: 'Cantidad',
                value: '${stock.quantity} unidades',
                icon: Icons.format_list_numbered_rounded,
              ),
              _buildEntryInfo(
                label: 'Precio de entrada',
                value: _currencyFormatter.format(stock.entryPrice),
                icon: Icons.request_page_rounded,
              ),
              _buildEntryInfo(
                label: 'Precio de venta',
                value: _currencyFormatter.format(stock.salePrice),
                icon: Icons.point_of_sale_rounded,
              ),
              if (stock.warehouseId != null)
                _buildEntryInfo(
                  label: 'Almacén',
                  value: '#${stock.warehouseId}',
                  icon: Icons.store_mall_directory_rounded,
                ),
              _buildEntryInfo(
                label: 'Fecha de entrada',
                value:
                    '${stock.entryDate?.day.toString().padLeft(2, '0')}/${stock.entryDate?.month.toString().padLeft(2, '0')}/${stock.entryDate?.year ?? ''}',
                icon: Icons.calendar_today_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEntryInfo({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey[600], size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context, ProductStockLoaded state) {
    if (!state.hasEntries) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Resumen de la venta
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child:
                    _buildSummaryItem('Registros', state.totalItems.toString()),
              ),
              Expanded(
                child: _buildSummaryItem(
                    'Unidades', state.totalQuantity.toString()),
              ),
              Expanded(
                child: _buildSummaryItem('Valor Entrada',
                    _currencyFormatter.format(state.totalEntryValue)),
              ),
              Expanded(
                child: _buildSummaryItem('Valor Venta',
                    _currencyFormatter.format(state.totalSaleValue)),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Botón de procesar
          SizedBox(
            width: double.infinity,
            child: _buildActionButton(
              icon: Icons.cloud_upload_rounded,
              label: 'Procesar Registros',
              color: Theme.of(context).primaryColor,
              onPressed: () => _cubit.processProductStock(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withOpacity(0.12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _handleSelectProvider(BuildContext context) async {
    final provider = await showDialog(
      context: context,
      builder: (context) => ProductStockProviderModal(
        productStockService: _productStockService,
        onProviderSelected: (provider) => Navigator.of(context).pop(provider),
      ),
    );

    if (provider != null) {
      _cubit.selectProvider(provider);
    }
  }

  Future<void> _handleAddEntry(
      BuildContext context, ProductStockLoaded state) async {
    final warehouses = await _ensureWarehouses();
    if (!mounted || warehouses == null || warehouses.isEmpty) {
      return;
    }

    final result = await showDialog<ProductStockEntryResult>(
      context: context,
      builder: (context) => ProductStockEntryModal(
        warehouses: warehouses,
      ),
    );

    if (result != null) {
      _cubit.addProductStockEntry(
        product: result.product,
        quantity: result.quantity,
        entryPrice: result.entryPrice,
        salePrice: result.salePrice,
        warehouseId: result.warehouseId,
        entryDate: result.entryDate,
      );
    }
  }

  Future<void> _handleEditEntry(BuildContext context, ProductStockLoaded state,
      ProductStockEntry entry, int index) async {
    final warehouses = await _ensureWarehouses();
    if (!mounted || warehouses == null || warehouses.isEmpty) {
      return;
    }

    final result = await showDialog<ProductStockEntryResult>(
      context: context,
      builder: (context) => ProductStockEntryModal(
        warehouses: warehouses,
        initialEntry: entry,
      ),
    );

    if (result != null) {
      _cubit.updateProductStockEntry(
        index,
        product: result.product,
        quantity: result.quantity,
        entryPrice: result.entryPrice,
        salePrice: result.salePrice,
        warehouseId: result.warehouseId,
        entryDate: result.entryDate,
      );
    }
  }

  Future<List<WarehouseModel>?> _ensureWarehouses() async {
    if (_warehousesCache != null && _warehousesCache!.isNotEmpty) {
      return _warehousesCache;
    }

    if (_loadingWarehouses) {
      return _warehousesCache;
    }

    setState(() => _loadingWarehouses = true);
    try {
      final warehouses =
          await getIt<WarehouseService>().getAll(page: 0, size: 100);
      _warehousesCache = warehouses;
      return warehouses;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar almacenes: $e'),
            backgroundColor: AppColors.danger(context),
          ),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _loadingWarehouses = false);
      }
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[700], fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'P';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Widget _buildSelectionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    final effectiveColor = onPressed != null ? color : color.withOpacity(0.5);
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: effectiveColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: onPressed != null ? 2 : 0,
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
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 13),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: effectiveColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: onPressed != null ? 2 : 0,
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
