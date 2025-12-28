import 'package:flutter/material.dart';

import '../../models/menu/product_model.dart';
import '../../services/cart_sale/cart_sale_service.dart';
import '../../theme/app_colors.dart';
import '../menu/secure_network_image.dart';

class CartSaleProductModal extends StatefulWidget {
  final CartSaleService cartSaleService;
  final Function(ProductModel) onProductSelected;

  const CartSaleProductModal({
    super.key,
    required this.cartSaleService,
    required this.onProductSelected,
  });

  @override
  State<CartSaleProductModal> createState() => _CartSaleProductModalState();
}

class _CartSaleProductModalState extends State<CartSaleProductModal> {
  final TextEditingController _searchController = TextEditingController();
  List<ProductModel> _products = [];
  List<ProductModel> _mostSoldProducts = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar productos más vendidos
      final mostSold =
          await widget.cartSaleService.getMostSoldProducts(limit: 5);

      // Cargar productos generales
      final products = await widget.cartSaleService.getProductsForCart(
        orderByMostSold: true,
        size: 20,
      );

      setState(() {
        _mostSoldProducts = mostSold;
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error al cargar productos: $e');
    }
  }

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) {
      await _loadInitialData();
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });

    try {
      final products = await widget.cartSaleService.getProductsForCart(
        searchQuery: query,
        orderByMostSold: false,
        size: 20,
      );

      setState(() {
        _products = products;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      _showErrorSnackBar('Error al buscar productos: $e');
    }
  }

  void _addProductToCart(ProductModel product) {
    widget.onProductSelected(product);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} agregado al carrito'),
        backgroundColor: AppColors.success(context),
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.of(context).pop();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger(context),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.shopping_bag_rounded,
                  color: theme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Seleccionar Producto',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Barra de búsqueda
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _searchProducts('');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.surfaceEmphasis(context),
              ),
              onChanged: (value) {
                if (value.length >= 2) {
                  _searchProducts(value);
                } else if (value.isEmpty) {
                  _searchProducts('');
                }
              },
            ),

            const SizedBox(height: 16),

            // Contenido
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildProductList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_products.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Productos más vendidos (solo si no hay búsqueda)
        if (_searchQuery.isEmpty && _mostSoldProducts.isNotEmpty) ...[
          _buildSectionHeader('Más Vendidos'),
          SizedBox(
            height: 100, // Aumentado para evitar overflow
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _mostSoldProducts.length,
              itemBuilder: (context, index) {
                final product = _mostSoldProducts[index];
                return _buildMostSoldProductCard(product);
              },
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Header de la lista de productos
        _buildSectionHeader(_searchQuery.isEmpty
            ? 'Todos los Productos'
            : 'Resultados de Búsqueda'),

        // Lista de productos
        Expanded(
          child: ListView.builder(
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              return _buildProductCard(product);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted(context),
            ),
      ),
    );
  }

  Widget _buildMostSoldProductCard(ProductModel product) {
    return Container(
      width: 120, // Reducido aún más
      margin: const EdgeInsets.only(right: 6),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        child: InkWell(
          onTap: () => _addProductToCart(product),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(6), // Reducido padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Importante para evitar overflow
              children: [
                // Imagen del producto
                Container(
                  height: 35, // Reducido más
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.surfaceBorder(context)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: _buildProductImage(product, size: 35),
                  ),
                ),

                const SizedBox(height: 4), // Reducido espaciado

                // Nombre del producto
                Expanded(
                  // Usar Expanded para el texto
                  child: Text(
                    product.name ?? 'Sin nombre',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 10, // Reducido más
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 2),

                // Stock con color basado en cantidad
                Text(
                  '${product.stockQuantity ?? 0}', // Texto más corto
                  style: TextStyle(
                    fontSize: 8, // Reducido más
                    fontWeight: FontWeight.w500,
                    color: _getStockColor(
                        product.stockQuantity ?? 0, product.stockMinimum),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _addProductToCart(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Imagen del producto
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildProductImage(product, size: 60),
                ),
              ),

              const SizedBox(width: 12),

              // Información del producto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name ?? 'Sin nombre',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.description != null &&
                        product.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        product.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Disponible',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        Text(
                          'Stock: ${product.stockQuantity ?? 0}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getStockColor(product.stockQuantity ?? 0,
                                product.stockMinimum),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Botón agregar
              IconButton(
                onPressed: () => _addProductToCart(product),
                icon: const Icon(Icons.add_circle),
                color: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No hay productos disponibles'
                : 'No se encontraron productos',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Contacta al administrador para agregar productos'
                : 'Intenta con otros términos de búsqueda',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Método para construir imagen del producto usando SecureNetworkImage
  Widget _buildProductImage(ProductModel product, {required double size}) {
    if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
      return SecureNetworkImage(
        imageUrl: product.imageUrl,
        productId: product.id,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: Container(
          width: size,
          height: size,
          color: Colors.grey.shade200,
          child: Center(
            child: SizedBox(
              width: size * 0.3,
              height: size * 0.3,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: _buildPlaceholderImage(size),
      );
    }
    return _buildPlaceholderImage(size);
  }

  Widget _buildPlaceholderImage(double size) {
    return Container(
      width: size,
      height: size,
      color: Colors.grey.shade200,
      child: Icon(
        Icons.inventory_2_outlined,
        color: Colors.grey.shade400,
        size: size * 0.4,
      ),
    );
  }

  // Método para obtener color del stock basado en cantidad y mínimo
  Color _getStockColor(int currentStock, int? minimumStock) {
    if (minimumStock == null) return AppColors.textMuted(context);

    if (currentStock <= minimumStock) {
      return AppColors.danger(context); // Stock bajo
    } else if (currentStock <= minimumStock * 2) {
      return AppColors.warning(context); // Stock medio
    } else {
      return AppColors.success(context); // Stock suficiente
    }
  }
}
