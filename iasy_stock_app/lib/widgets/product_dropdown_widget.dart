import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/menu/product_cubit.dart';
import '../models/menu/product_model.dart';
import '../theme/app_colors.dart';
import 'menu/secure_network_image.dart';

class ProductDropdownWidget extends StatelessWidget {
  final int? selectedProductId;
  final ValueChanged<int?>? onChanged;
  final String? labelText;
  final String? Function(int?)? validator;
  final bool enabled;
  final bool isRequired;

  const ProductDropdownWidget({
    super.key,
    this.selectedProductId,
    this.onChanged,
    this.labelText,
    this.validator,
    this.enabled = true,
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        if (state is ProductLoaded) {
          // Validar que el valor seleccionado existe en la lista de productos
          final validSelectedId =
              state.products.any((p) => p.id == selectedProductId)
                  ? selectedProductId
                  : null;

          return DropdownButtonFormField<int>(
            value: validSelectedId,
            decoration: InputDecoration(
              labelText: labelText ?? 'Producto${isRequired ? ' *' : ''}',
            ),
            items: state.products
                .map((product) => DropdownMenuItem(
                      value: product.id,
                      child: _ProductDropdownItem(product: product),
                    ))
                .toList(),
            selectedItemBuilder: (context) => state.products
                .map((product) => _ProductSelectedItem(product: product))
                .toList(),
            onChanged: enabled ? onChanged : null,
            validator: validator ??
                (isRequired
                    ? (val) => val == null ? 'Seleccione un producto' : null
                    : null),
          );
        }
        return const LinearProgressIndicator();
      },
    );
  }
}

class _ProductSelectedItem extends StatelessWidget {
  final ProductModel product;

  const _ProductSelectedItem({required this.product});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Imagen en miniatura más pequeña
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.surfaceBorder(context)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: _buildProductImage(context),
          ),
        ),
        const SizedBox(width: 8),
        // Solo el nombre del producto
        Flexible(
          child: Text(
            product.name,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildProductImage(BuildContext context) {
    return SecureNetworkImage(
      imageUrl: product.imageUrl,
      productId: product.id,
      width: 24,
      height: 24,
      fit: BoxFit.cover,
      placeholder: _buildLoadingPlaceholder(context, 12),
      errorWidget: _buildPlaceholderImage(context),
    );
  }

  Widget _buildPlaceholderImage(BuildContext context) {
    return Container(
      color: AppColors.surfaceEmphasis(context),
      child: Icon(
        Icons.inventory_2_outlined,
        color: AppColors.iconMuted(context),
        size: 16,
      ),
    );
  }

  Widget _buildLoadingPlaceholder(BuildContext context, double indicatorSize) {
    return Container(
      color: AppColors.surfaceEmphasis(context),
      child: Center(
        child: SizedBox(
          width: indicatorSize,
          height: indicatorSize,
          child: const CircularProgressIndicator(strokeWidth: 1.5),
        ),
      ),
    );
  }
}

class _ProductDropdownItem extends StatelessWidget {
  final ProductModel product;

  const _ProductDropdownItem({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Imagen en miniatura
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.surfaceBorder(context)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: _buildProductImage(context),
            ),
          ),
          const SizedBox(width: 8),
          // Información del producto
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (product.stockQuantity != null)
                  Text(
                    'Stock: ${product.stockQuantity}',
                    style: TextStyle(
                      color: _getStockColor(context, product.stockQuantity!,
                          product.stockMinimum),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(BuildContext context) {
    return SecureNetworkImage(
      imageUrl: product.imageUrl,
      productId: product.id,
      width: 32,
      height: 32,
      fit: BoxFit.cover,
      placeholder: _buildLoadingPlaceholder(context),
      errorWidget: _buildPlaceholderImage(context),
    );
  }

  Widget _buildPlaceholderImage(BuildContext context) {
    return Container(
      color: AppColors.surfaceEmphasis(context),
      child: Icon(
        Icons.inventory_2_outlined,
        color: AppColors.iconMuted(context),
        size: 20,
      ),
    );
  }

  Widget _buildLoadingPlaceholder(BuildContext context) {
    return Container(
      color: AppColors.surfaceEmphasis(context),
      child: const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Color _getStockColor(
      BuildContext context, int currentStock, int? minimumStock) {
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
