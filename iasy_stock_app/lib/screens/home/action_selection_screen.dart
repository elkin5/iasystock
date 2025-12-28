import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../config/get_it_config.dart';
import '../../cubits/cart_sale/cart_sale_cubit.dart';
import '../../cubits/invoice_scan/invoice_scan_cubit.dart';
import '../../cubits/invoice_scan/invoice_scan_state.dart';
import '../../cubits/product_identification/multiple_detection_cubit.dart';
import '../../cubits/product_identification/multiple_detection_state.dart';
import '../../cubits/product_identification/product_identification_cubit.dart';
import '../../cubits/product_identification/product_identification_state.dart';
import '../../cubits/product_stock/product_stock_cubit.dart';
import '../../models/menu/product_model.dart';
import '../../models/product_identification/product_identification_models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/notification_helper.dart';
import '../product_identification/multiple_detection_screen.dart';
import '../product_identification/product_identification_confirmation_screen.dart';

class ActionSelectionScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final String imageName;

  const ActionSelectionScreen({
    super.key,
    required this.imageBytes,
    required this.imageName,
  });

  @override
  State<ActionSelectionScreen> createState() => _ActionSelectionScreenState();
}

class _ActionSelectionScreenState extends State<ActionSelectionScreen> {
  bool _isProcessing = false;

  Future<void> _guard(Future<void> Function() action) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar acción')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPreview(theme),
                const SizedBox(height: 20),
                Text(
                  'Elige cómo quieres usar esta imagen',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecciona uno de los flujos asistidos para ventas o stock.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textMuted(context)),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Flujos de venta', theme),
                const SizedBox(height: 12),
                _buildActionGrid([
                  _CameraActionOption(
                    label: 'Registrar venta individual con imagen',
                    icon: Icons.add_shopping_cart_rounded,
                    color: theme.primaryColor,
                    onTap: () => _guard(_handleSaleSingle),
                  ),
                  _CameraActionOption(
                    label: 'Registrar venta múltiple con imagen',
                    icon: Icons.shopping_bag_rounded,
                    color: theme.primaryColor,
                    onTap: () => _guard(_handleSaleMultiple),
                  ),
                  _CameraActionOption(
                    label: 'Registrar con escáner de factura',
                    icon: Icons.receipt_long_rounded,
                    color: theme.primaryColor,
                    onTap: () => _guard(_handleSaleInvoice),
                  ),
                ]),
                const SizedBox(height: 28),
                _buildSectionTitle('Flujos de stock', theme),
                const SizedBox(height: 12),
                _buildActionGrid([
                  _CameraActionOption(
                    label: 'Registrar stock individual con imagen',
                    icon: Icons.inventory_2_rounded,
                    color: Colors.teal,
                    onTap: () => _guard(_handleStockSingle),
                  ),
                  _CameraActionOption(
                    label: 'Registrar stock múltiple con imagen',
                    icon: Icons.inventory_outlined,
                    color: Colors.teal,
                    onTap: () => _guard(_handleStockMultiple),
                  ),
                  _CameraActionOption(
                    label: 'Registrar stock con escáner de factura',
                    icon: Icons.document_scanner_rounded,
                    color: Colors.teal,
                    onTap: () => _guard(_handleStockInvoice),
                  ),
                ]),
              ],
            ),
          ),
          if (_isProcessing)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 3),
            ),
        ],
      ),
    );
  }

  Widget _buildPreview(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder(context)),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.memory(
              widget.imageBytes,
              height: 240,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceEmphasis(context),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.image_rounded, color: theme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.imageName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Volver a tomar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildActionGrid(List<_CameraActionOption> options) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 620;
        final crossAxisCount = isWide ? 2 : 1;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: options
              .map(
                (option) => SizedBox(
                  width: isWide
                      ? (constraints.maxWidth - 12) / crossAxisCount
                      : constraints.maxWidth,
                  child: _buildActionButton(option),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildActionButton(_CameraActionOption option) {
    return ElevatedButton.icon(
      onPressed: _isProcessing ? null : option.onTap,
      icon: Icon(option.icon),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          option.label,
          textAlign: TextAlign.left,
        ),
      ),
      style: ElevatedButton.styleFrom(
        alignment: Alignment.centerLeft,
        backgroundColor: option.color.withOpacity(0.1),
        foregroundColor: option.color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: option.color.withOpacity(0.3)),
        ),
      ),
    );
  }

  Future<void> _handleSaleSingle() async {
    final product = await _identifySingleProduct(source: 'SALE');
    if (product == null || !mounted) return;

    final cartCubit = getIt<CartSaleCubit>();

    try {
      final productToAdd = ProductModel(
        id: product.id,
        name: product.name,
        description: product.description,
        imageUrl: product.imageUrl,
        categoryId: product.categoryId,
        stockQuantity: product.stockQuantity,
      );

      await cartCubit.addProductToCart(productToAdd);

      if (!mounted) return;
      NotificationHelper.showSuccess(
        context,
        '${product.name} agregado al carrito',
      );
      await context.push('/home/cart_sale');
    } catch (e) {
      if (mounted) {
        NotificationHelper.showError(
          context,
          'Error al agregar producto: $e',
        );
      }
    }
  }

  Future<void> _handleSaleMultiple() async {
    final detectionResult = await _detectMultipleProducts(source: 'SALE');
    if (detectionResult == null || !mounted) return;

    final cartCubit = getIt<CartSaleCubit>();
    int addedCount = 0;

    for (final group in detectionResult.productGroups) {
      try {
        final productToAdd = ProductModel(
          id: group.product.id,
          name: group.product.name,
          description: group.product.description,
          imageUrl: group.product.imageUrl,
          categoryId: group.product.categoryId,
          stockQuantity: group.product.stockQuantity,
        );

        for (int i = 0; i < group.quantity; i++) {
          await cartCubit.addProductToCart(productToAdd);
        }
        addedCount += group.quantity;
      } catch (e) {
        if (mounted) {
          NotificationHelper.showError(
            context,
            'Error al agregar ${group.product.name}: $e',
          );
        }
      }
    }

    if (mounted && addedCount > 0) {
      NotificationHelper.showSuccess(
        context,
        'Se agregaron $addedCount productos al carrito',
      );
      await context.push('/home/cart_sale');
    }
  }

  Future<void> _handleSaleInvoice() async {
    final editingState = await _scanInvoice();
    if (editingState == null || !mounted) return;

    final cartCubit = getIt<CartSaleCubit>();
    final products = editingState.editedProducts;
    int productosAgregados = 0;
    int productosNoVinculados = 0;

    for (final item in products) {
      if (item.matchedProduct != null) {
        try {
          final product = ProductModel(
            id: item.matchedProduct!.id,
            name: item.matchedProduct!.name,
            description: item.matchedProduct!.description,
            categoryId: item.matchedProduct!.categoryId ?? 1,
            imageUrl: item.matchedProduct!.imageUrl,
            stockQuantity: item.matchedProduct!.stockQuantity,
          );

          await cartCubit.addProductToCart(
            product,
            quantity: item.quantity,
          );
          productosAgregados++;
        } catch (_) {
          productosNoVinculados++;
        }
      } else {
        productosNoVinculados++;
      }
    }

    getIt<InvoiceScanCubit>().reset();

    if (!mounted) return;

    if (productosAgregados > 0) {
      String mensaje = '$productosAgregados producto(s) agregado(s) al carrito';
      if (productosNoVinculados > 0) {
        mensaje += '\n$productosNoVinculados producto(s) no vinculados';
      }
      NotificationHelper.showSuccess(context, mensaje);
      await context.push('/home/cart_sale');
    } else if (productosNoVinculados > 0) {
      NotificationHelper.showError(
        context,
        'No se encontraron productos vinculados. $productosNoVinculados producto(s) no existen en el catálogo.',
      );
    } else {
      NotificationHelper.showError(
        context,
        'No se encontraron productos en la factura',
      );
    }
  }

  Future<void> _handleStockSingle() async {
    final product = await _identifySingleProduct(source: 'STOCK');
    if (product == null || !mounted) return;

    final productStockCubit = getIt<ProductStockCubit>();
    productStockCubit.startNewRecord();

    final productToAdd = ProductModel(
      id: product.id,
      name: product.name,
      description: product.description,
      imageUrl: product.imageUrl,
      categoryId: product.categoryId,
      stockQuantity: product.stockQuantity,
    );

    productStockCubit.addProductStockEntry(
      product: productToAdd,
      quantity: 1,
      entryPrice: 0,
      salePrice: 0,
      warehouseId: 1,
      entryDate: DateTime.now(),
    );

    NotificationHelper.showSuccess(
      context,
      'Producto ${product.name} agregado. Complete los datos de stock.',
    );
    await context.push('/home/product_stock');
  }

  Future<void> _handleStockMultiple() async {
    final detectionResult = await _detectMultipleProducts(source: 'STOCK');
    if (detectionResult == null || !mounted) return;

    final productStockCubit = getIt<ProductStockCubit>();
    productStockCubit.startNewRecord();

    int addedCount = 0;

    for (final group in detectionResult.productGroups) {
      try {
        final productToAdd = ProductModel(
          id: group.product.id,
          name: group.product.name,
          description: group.product.description,
          imageUrl: group.product.imageUrl,
          categoryId: group.product.categoryId,
          stockQuantity: group.product.stockQuantity,
        );

        productStockCubit.addProductStockEntry(
          product: productToAdd,
          quantity: group.quantity,
          entryPrice: 0,
          salePrice: 0,
          warehouseId: 1,
          entryDate: DateTime.now(),
        );
        addedCount += group.quantity;
      } catch (e) {
        if (mounted) {
          NotificationHelper.showError(
            context,
            'Error al agregar ${group.product.name}: $e',
          );
        }
      }
    }

    if (mounted && addedCount > 0) {
      NotificationHelper.showSuccess(
        context,
        'Se agregaron $addedCount productos. Complete los datos de stock.',
      );
      await context.push('/home/product_stock');
    }
  }

  Future<void> _handleStockInvoice() async {
    final editingState = await _scanInvoice();
    if (editingState == null || !mounted) return;

    final productStockCubit = getIt<ProductStockCubit>();
    final products = editingState.editedProducts;
    int productosAgregados = 0;
    int productosNoVinculados = 0;

    for (final item in products) {
      if (item.matchedProduct != null) {
        try {
          final product = ProductModel(
            id: item.matchedProduct!.id,
            name: item.matchedProduct!.name,
            description: item.matchedProduct!.description,
            categoryId: item.matchedProduct!.categoryId ?? 1,
            imageUrl: item.matchedProduct!.imageUrl,
            stockQuantity: item.matchedProduct!.stockQuantity,
          );

          productStockCubit.addProductStockEntry(
            product: product,
            quantity: item.quantity,
            entryPrice: item.unitPrice,
            salePrice: item.salePrice,
            warehouseId: 1,
          );
          productosAgregados++;
        } catch (_) {
          productosNoVinculados++;
        }
      } else {
        productosNoVinculados++;
      }
    }

    getIt<InvoiceScanCubit>().reset();

    if (!mounted) return;

    if (productosAgregados > 0) {
      String mensaje =
          '$productosAgregados producto(s) agregado(s) desde la factura';
      if (productosNoVinculados > 0) {
        mensaje += '\n$productosNoVinculados producto(s) no vinculados';
      }
      NotificationHelper.showSuccess(context, mensaje);
      await context.push('/home/product_stock');
    } else if (productosNoVinculados > 0) {
      NotificationHelper.showError(
        context,
        'No se encontraron productos vinculados. $productosNoVinculados producto(s) no existen en el catálogo.',
      );
    } else {
      NotificationHelper.showError(
        context,
        'No se encontraron productos en la factura',
      );
    }
  }

  Future<ProductSummary?> _identifySingleProduct({
    required String source,
  }) async {
    final identificationCubit = getIt<ProductIdentificationCubit>();
    BuildContext? dialogContext;

    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) {
          dialogContext = dialogCtx;
          return BlocProvider.value(
            value: identificationCubit,
            child: BlocConsumer<ProductIdentificationCubit,
                ProductIdentificationState>(
              listener: (context, state) {
                if (state is ProductIdentificationSuccess ||
                    state is ProductIdentificationError) {
                  if (dialogContext != null) {
                    Navigator.pop(dialogContext!);
                  }
                }
              },
              builder: (context, state) {
                if (state is ProductIdentificationProcessing) {
                  return AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            widget.imageBytes,
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Esto puede tomar unos segundos...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          );
        },
      ),
    );

    await identificationCubit.identifyOrCreateProduct(
      imageBytes: widget.imageBytes,
      imageName: widget.imageName,
      source: source,
    );

    if (!mounted) {
      identificationCubit.reset();
      return null;
    }

    final state = identificationCubit.state;
    ProductSummary? confirmedProduct;

    if (state is ProductIdentificationSuccess) {
      final confidence = state.result.confidence;
      final hasRelevantAlternatives = state
              .result.alternativeMatches.isNotEmpty &&
          state.result.alternativeMatches.any((alt) => alt.confidence >= 0.5);

      if (confidence >= 0.6 && !hasRelevantAlternatives) {
        confirmedProduct = state.result.product;
        NotificationHelper.showSuccess(
          context,
          'Producto identificado automáticamente: ${confirmedProduct.name}',
        );
      } else {
        confirmedProduct = await Navigator.push<ProductSummary>(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: identificationCubit,
              child: ProductIdentificationConfirmationScreen(
                result: state.result,
                source: source,
                capturedImageBytes: widget.imageBytes,
              ),
            ),
          ),
        );
      }
    } else if (state is ProductIdentificationError) {
      NotificationHelper.showError(context, state.message);
    }

    identificationCubit.reset();
    return confirmedProduct;
  }

  Future<MultipleProductDetectionResult?> _detectMultipleProducts({
    required String source,
  }) async {
    final multipleDetectionCubit = getIt<MultipleDetectionCubit>();
    BuildContext? dialogContext;

    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) {
          dialogContext = dialogCtx;
          return BlocProvider.value(
            value: multipleDetectionCubit,
            child: BlocConsumer<MultipleDetectionCubit, MultipleDetectionState>(
              listener: (context, state) {
                if (state is MultipleDetectionSuccess ||
                    state is MultipleDetectionError ||
                    state is MultipleDetectionEditingSelection) {
                  if (dialogContext != null) {
                    Navigator.pop(dialogContext!);
                  }
                }
              },
              builder: (context, state) {
                if (state is MultipleDetectionProcessing) {
                  return AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            widget.imageBytes,
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Esto puede tomar unos segundos...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          );
        },
      ),
    );

    await multipleDetectionCubit.detectMultipleProducts(
      imageBytes: widget.imageBytes,
      imageName: widget.imageName,
      source: source,
    );

    if (!mounted) {
      multipleDetectionCubit.reset();
      return null;
    }

    final state = multipleDetectionCubit.state;
    MultipleProductDetectionResult? result;

    if (state is MultipleDetectionSuccess) {
      final allHighConfidence = state.result.productGroups.every(
        (group) => group.averageConfidence >= 0.6,
      );
      if (allHighConfidence) {
        result = state.result;
      } else {
        result = await _navigateToMultipleDetectionEditing(
          multipleDetectionCubit,
        );
      }
    } else if (state is MultipleDetectionEditingSelection) {
      result = await _navigateToMultipleDetectionEditing(
        multipleDetectionCubit,
      );
    } else if (state is MultipleDetectionError) {
      NotificationHelper.showError(context, state.message);
    }

    multipleDetectionCubit.reset();
    return result;
  }

  Future<MultipleProductDetectionResult?> _navigateToMultipleDetectionEditing(
    MultipleDetectionCubit multipleDetectionCubit,
  ) async {
    final completer = Completer<MultipleProductDetectionResult?>();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: multipleDetectionCubit,
          child: MultipleDetectionScreen(
            initialImageBytes: widget.imageBytes,
            onConfirm: (result) {
              if (!completer.isCompleted) {
                completer.complete(result);
              }
            },
          ),
        ),
      ),
    );

    if (!completer.isCompleted) {
      completer.complete(null);
    }

    return completer.future;
  }

  Future<InvoiceScanEditing?> _scanInvoice() async {
    final invoiceScanCubit = getIt<InvoiceScanCubit>();
    BuildContext? dialogCtx;

    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogCtx = ctx;
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  widget.imageBytes,
                  width: 200,
                  height: 280,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text(
                'Analizando factura con IA...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Extrayendo productos...',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted(context),
                ),
              ),
            ],
          ),
        );
      },
    ));

    await invoiceScanCubit.scanInvoice(
      imageBytes: widget.imageBytes,
      imageName: widget.imageName,
    );

    if (dialogCtx != null) {
      Navigator.of(dialogCtx!).pop();
    }

    if (!mounted) {
      invoiceScanCubit.reset();
      return null;
    }

    final state = invoiceScanCubit.state;
    if (state is InvoiceScanEditing) {
      return state;
    } else if (state is InvoiceScanError) {
      NotificationHelper.showError(context, state.message);
    } else {
      NotificationHelper.showError(
        context,
        'No se encontraron productos en la factura',
      );
    }
    invoiceScanCubit.reset();
    return null;
  }
}

class _CameraActionOption {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _CameraActionOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
