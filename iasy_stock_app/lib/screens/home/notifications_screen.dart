import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/get_it_config.dart';
import '../../models/menu/product_model.dart';
import '../../services/menu/product_service.dart';
import '../../services/menu/sale_item_service.dart';
import '../../services/menu/sale_service.dart';
import '../../widgets/home/general_sliver_app_bar.dart';
import '../../widgets/home/home_ui_components.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _searchController = TextEditingController();
  final _dateFormatter = DateFormat('dd/MM/yyyy');

  bool _isLoading = false;
  String? _error;
  List<_StockNotification> _notifications = [];
  List<_StockNotification> _filtered = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final productService = getIt<ProductService>();
      final products = await productService.getAll(page: 0, size: 200);

      final candidates = products.where((p) {
        final currentStock = p.stockQuantity ?? 0;
        final minStock = p.stockMinimum ?? 0;
        return currentStock <= 0 || (minStock > 0 && currentStock <= minStock);
      }).toList();

      final notifications = <_StockNotification>[];
      for (final product in candidates) {
        final lastSaleDate =
            await _fetchLastSaleDate(product.id ?? 0).catchError((_) => null);
        notifications.add(_StockNotification(
          product: product,
          lastSaleDate: lastSaleDate,
        ));
      }

      if (!mounted) return;

      setState(() {
        _notifications = notifications;
        _filtered = notifications;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar las notificaciones: $e';
        _isLoading = false;
      });
    }
  }

  Future<DateTime?> _fetchLastSaleDate(int productId) async {
    if (productId == 0) return null;
    final saleItemService = getIt<SaleItemService>();
    final saleService = getIt<SaleService>();

    final saleItems =
        await saleItemService.findByProductId(productId, page: 0, size: 20);
    if (saleItems.isEmpty) return null;

    final saleIds = saleItems.map((e) => e.saleId).toSet().take(10);
    DateTime? latest;

    for (final saleId in saleIds) {
      try {
        final sale = await saleService.getById(saleId);
        final saleDate = sale.saleDate ?? sale.createdAt;
        if (saleDate != null) {
          if (latest == null || saleDate.isAfter(latest!)) {
            latest = saleDate;
          }
        }
      } catch (_) {
        continue;
      }
    }

    return latest;
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = _notifications;
      } else {
        final lower = query.toLowerCase();
        _filtered = _notifications
            .where((n) =>
                n.product.name.toLowerCase().contains(lower) ||
                (n.product.description ?? '')
                    .toLowerCase()
                    .contains(lower))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: CustomScrollView(
          slivers: [
            GeneralSliverAppBar(
              title: 'Notificaciones',
              subtitle: 'Productos sin stock o por debajo del mínimo',
              icon: Icons.notifications_active_rounded,
              primaryColor: primaryColor,
              onLogout: _isLoading ? null : _loadNotifications,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: _filter,
                      decoration: InputDecoration(
                        hintText: 'Buscar producto o descripción...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  _filter('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_error != null)
                      HomeEmptyState(
                        icon: Icons.error_outline_rounded,
                        title: 'Error al cargar',
                        message: _error!,
                        iconColor: Colors.redAccent,
                      )
                    else if (_filtered.isEmpty)
                      HomeEmptyState(
                        icon: Icons.notifications_none_rounded,
                        title: 'Sin notificaciones',
                        message:
                            'No hay productos sin stock o por debajo del mínimo.',
                        iconColor: Colors.grey[500],
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final notification = _filtered[index];
                          return _buildNotificationCard(
                              notification, primaryColor);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
      _StockNotification notification, Color primaryColor) {
    final product = notification.product;
    final currentStock = product.stockQuantity ?? 0;
    final minStock = product.stockMinimum ?? 0;
    final isOut = currentStock <= 0;

    String sinceText = 'Sin ventas registradas';
    if (notification.lastSaleDate != null) {
      sinceText = 'Desde ${_dateFormatter.format(notification.lastSaleDate!)}';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOut ? Icons.error_rounded : Icons.warning_amber_rounded,
                  color: isOut ? Colors.redAccent : Colors.orangeAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        (isOut ? Colors.redAccent : Colors.orangeAccent)
                            .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    isOut ? 'Sin stock' : 'Bajo stock',
                    style: TextStyle(
                      color: isOut ? Colors.redAccent : Colors.orangeAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (product.description != null &&
                product.description!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  product.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildBadge(
                  icon: Icons.inventory_2_rounded,
                  label: 'Stock actual',
                  value: '$currentStock u.',
                  color: isOut ? Colors.redAccent : primaryColor,
                ),
                _buildBadge(
                  icon: Icons.flag_rounded,
                  label: 'Stock mínimo',
                  value: minStock > 0 ? '$minStock u.' : 'No definido',
                  color: Colors.orangeAccent,
                ),
                _buildBadge(
                  icon: Icons.history_rounded,
                  label: 'Última venta',
                  value: sinceText,
                  color: Colors.blueGrey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StockNotification {
  final ProductModel product;
  final DateTime? lastSaleDate;

  _StockNotification({
    required this.product,
    required this.lastSaleDate,
  });
}
