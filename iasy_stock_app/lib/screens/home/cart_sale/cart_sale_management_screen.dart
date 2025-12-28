import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../config/get_it_config.dart';
import '../../../cubits/cart_sale/cart_sale_cubit.dart';
import '../../../cubits/invoice_scan/invoice_scan_cubit.dart';
import '../../../cubits/invoice_scan/invoice_scan_state.dart';
import '../../../cubits/product_identification/multiple_detection_cubit.dart';
import '../../../cubits/product_identification/multiple_detection_state.dart';
import '../../../cubits/product_identification/product_identification_cubit.dart';
import '../../../cubits/product_identification/product_identification_state.dart';
import '../../../models/cart_sale/cart_sale_model.dart';
import '../../../models/menu/product_model.dart';
import '../../../models/menu/sale_item_model.dart';
import '../../../models/menu/sale_model.dart';
import '../../../models/product_identification/product_identification_models.dart';
import '../../../services/cart_sale/cart_sale_service.dart';
import '../../../services/menu/person_service.dart';
import '../../../services/menu/product_service.dart';
import '../../../services/menu/user_service.dart';
import '../../../theme/home_layout_tokens.dart';
import '../../../widgets/home/general_sliver_app_bar.dart';
import '../../../widgets/home/home_ui_components.dart';
import '../../../widgets/notification_helper.dart';
import '../../product_identification/multiple_detection_screen.dart';
import '../../product_identification/product_identification_confirmation_screen.dart';

class CartSaleManagementScreen extends StatefulWidget {
  const CartSaleManagementScreen({super.key});

  @override
  State<CartSaleManagementScreen> createState() =>
      _CartSaleManagementScreenState();
}

class _CartSaleManagementScreenState extends State<CartSaleManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<CartSaleModel> _allSales = [];
  List<CartSaleModel> _filteredSales = [];
  Map<int, String> _clientNames = {}; // Cache de nombres de clientes
  bool _isLoading = true;
  String? _errorMessage;
  final NumberFormat _currencyFormatter =
      NumberFormat.currency(locale: 'es_CO', symbol: r'$');

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSales() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cartSaleService = getIt<CartSaleService>();
      final sales = await cartSaleService.getAll(page: 0, size: 100);
      sales.sort(_compareByDateDesc);

      // Cargar nombres de clientes
      await _loadClientNames(sales);

      setState(() {
        _allSales = List<CartSaleModel>.from(sales);
        _filteredSales = List<CartSaleModel>.from(sales);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar las ventas: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  int _compareByDateDesc(CartSaleModel a, CartSaleModel b) {
    final dateA = a.sale.saleDate ??
        a.sale.createdAt ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final dateB = b.sale.saleDate ??
        b.sale.createdAt ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final comparison = dateB.compareTo(dateA);
    if (comparison != 0) return comparison;
    final idA = a.sale.id ?? 0;
    final idB = b.sale.id ?? 0;
    return idB.compareTo(idA);
  }

  Future<void> _loadClientNames(List<CartSaleModel> sales) async {
    final personService = getIt<PersonService>();
    final clientIds = sales
        .where((sale) => sale.sale.personId != null)
        .map((sale) => sale.sale.personId!)
        .toSet();

    for (final clientId in clientIds) {
      try {
        final person = await personService.getById(clientId);
        _clientNames[clientId] = person.name ?? 'Sin nombre';
      } catch (e) {
        _clientNames[clientId] = 'Cliente ID: $clientId';
      }
    }
  }

  void _filterSales(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSales = _allSales;
      } else {
        _filteredSales = _allSales.where((sale) {
          final saleId = sale.sale.id.toString();
          final clientName = sale.sale.personId?.toString() ?? '';
          final totalAmount = sale.sale.totalAmount.toString();
          final payMethod = sale.sale.payMethod ?? '';
          final state = sale.sale.state ?? '';

          return saleId.contains(query.toLowerCase()) ||
              clientName.toLowerCase().contains(query.toLowerCase()) ||
              totalAmount.contains(query.toLowerCase()) ||
              payMethod.toLowerCase().contains(query.toLowerCase()) ||
              state.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadSales,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            GeneralSliverAppBar(
              title: 'Gestión de Ventas',
              subtitle: 'Administra y revisa todas las ventas',
              icon: Icons.receipt_long_rounded,
              primaryColor: theme.primaryColor,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildTopSection(context, theme),
                    const SizedBox(height: HomeLayoutTokens.sectionSpacing),
                    _buildSearchSection(context, theme),
                    const SizedBox(height: HomeLayoutTokens.sectionSpacing),
                    _buildSummarySection(theme),
                    const SizedBox(height: HomeLayoutTokens.sectionSpacing),
                    _buildSalesListSection(context, theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection(BuildContext context, ThemeData theme) {
    return HomeSectionCard(
      child: Column(
        children: [
          Text(
            'Opciones de Registro',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: HomeLayoutTokens.smallSpacing),
          Row(
            children: [
              Expanded(
                child: HomeActionButton(
                  icon: Icons.add_shopping_cart_rounded,
                  label: 'Registrar venta manualmente',
                  color: theme.primaryColor,
                  onPressed: () => _openManualSale(context),
                ),
              ),
              const SizedBox(width: HomeLayoutTokens.smallSpacing),
              Expanded(
                child: HomeActionButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Registrar venta individual con imagen',
                  color: theme.primaryColor,
                  onPressed: () => _handleRegisterWithImage(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: HomeLayoutTokens.smallSpacing),
          Row(
            children: [
              Expanded(
                child: HomeActionButton(
                  icon: Icons.scanner,
                  label: 'Registrar venta múltiple con imagen',
                  color: theme.primaryColor,
                  onPressed: () => _handleMultipleDetection(context),
                ),
              ),
              const SizedBox(width: HomeLayoutTokens.smallSpacing),
              Expanded(
                child: HomeActionButton(
                  icon: Icons.receipt_long_rounded,
                  label: 'Registrar con escáner de factura',
                  color: theme.primaryColor,
                  onPressed: () => _handleInvoiceScan(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Maneja el escaneo de factura/documento con OCR para agregar productos al carrito
  Future<void> _handleInvoiceScan(BuildContext context) async {
    // Paso 1: Mostrar selector de fuente de imagen
    final imageSource = await _showImageSourceSelector(context);
    if (imageSource == null || !context.mounted) return;

    // Paso 2: Capturar imagen desde la fuente seleccionada
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: imageSource,
      imageQuality: 90, // Mayor calidad para OCR
    );

    if (pickedFile == null || !context.mounted) return;

    // Leer bytes de la imagen
    final imageBytes = await pickedFile.readAsBytes();
    final imageName = pickedFile.name;

    final invoiceScanCubit = getIt<InvoiceScanCubit>();

    // Variable para guardar el contexto del diálogo
    BuildContext? dialogCtx;

    // Paso 3: Mostrar modal de procesamiento con imagen
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
                  imageBytes,
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
              const Text(
                'Extrayendo productos para venta...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
    ));

    // Paso 4: Ejecutar escaneo OCR
    await invoiceScanCubit.scanInvoice(
      imageBytes: imageBytes,
      imageName: imageName,
    );

    // Paso 5: Cerrar el diálogo de procesamiento usando su propio contexto
    if (dialogCtx != null && dialogCtx!.mounted) {
      Navigator.of(dialogCtx!).pop();
    }

    if (!context.mounted) return;

    // Paso 6: Manejar resultado - Cargar productos al carrito con precios del sistema
    final state = invoiceScanCubit.state;

    if (state is InvoiceScanEditing) {
      final cartCubit = getIt<CartSaleCubit>();
      final products = state.editedProducts;
      int productosAgregados = 0;
      int productosNoVinculados = 0;

      // Agregar cada producto con match al carrito usando precios del sistema
      for (final item in products) {
        if (item.matchedProduct != null) {
          try {
            // Crear ProductModel desde el MatchedProduct
            final product = ProductModel(
              id: item.matchedProduct!.id,
              name: item.matchedProduct!.name,
              description: item.matchedProduct!.description,
              categoryId: item.matchedProduct!.categoryId ?? 1,
              imageUrl: item.matchedProduct!.imageUrl,
              stockQuantity: item.matchedProduct!.stockQuantity,
            );

            // Agregar al carrito con la cantidad de la factura
            // El precio de venta se obtiene automáticamente del sistema (stock más reciente)
            await cartCubit.addProductToCart(product, quantity: item.quantity);
            productosAgregados++;
          } catch (e) {
            // Si hay error al agregar, continuar con el siguiente
          }
        } else {
          productosNoVinculados++;
        }
      }

      // Resetear el cubit de escaneo
      invoiceScanCubit.reset();

      // Mostrar resultado al usuario y navegar si hay productos
      if (context.mounted) {
        if (productosAgregados > 0) {
          String mensaje =
              '$productosAgregados producto(s) agregado(s) al carrito';
          if (productosNoVinculados > 0) {
            mensaje += '\n$productosNoVinculados producto(s) no vinculados';
          }
          NotificationHelper.showSuccess(context, mensaje);

          // Navegar a la pantalla de carrito para completar la venta
          await context.push('/home/cart_sale');

          // Recargar ventas cuando regrese
          if (mounted) {
            await _loadSales();
          }
        } else if (productosNoVinculados > 0) {
          NotificationHelper.showError(
            context,
            'No se encontraron productos vinculados. $productosNoVinculados producto(s) no existen en el catálogo.',
          );
        } else {
          NotificationHelper.showError(
              context, 'No se encontraron productos en la factura');
        }
      }
    } else if (state is InvoiceScanError) {
      if (context.mounted) {
        NotificationHelper.showError(context, state.message);
      }
    }
  }

  Future<void> _openManualSale(BuildContext context) async {
    await context.push('/home/cart_sale');
    if (!mounted) return;
    await _loadSales();
  }

  /// Muestra un diálogo para seleccionar la fuente de la imagen (cámara o galería)
  Future<ImageSource?> _showImageSourceSelector(BuildContext context) async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar fuente de imagen'),
          content: const Text('¿Desde dónde deseas obtener la imagen?'),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.photo_library_rounded),
              label: const Text('Galería'),
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
            ),
            TextButton.icon(
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Cámara'),
              onPressed: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        );
      },
    );
  }

  /// Maneja el registro de venta con imagen (identificación inteligente)
  Future<void> _handleRegisterWithImage(BuildContext context) async {
    // Paso 1: Mostrar selector de fuente de imagen
    final imageSource = await _showImageSourceSelector(context);
    if (imageSource == null || !context.mounted) return;

    // Paso 2: Capturar imagen desde la fuente seleccionada
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: imageSource,
      imageQuality: 85,
    );

    if (pickedFile == null || !context.mounted) return;

    // Leer bytes de la imagen (compatible con web y móvil)
    final imageBytes = await pickedFile.readAsBytes();
    final imageName = pickedFile.name;

    // Paso 2: Procesar con IA
    final identificationCubit = getIt<ProductIdentificationCubit>();

    // Mostrar diálogo de loading con imagen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: identificationCubit,
        child: BlocConsumer<ProductIdentificationCubit,
            ProductIdentificationState>(
          listener: (context, state) {
            if (state is ProductIdentificationSuccess ||
                state is ProductIdentificationError) {
              Navigator.pop(dialogContext);
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
                        imageBytes,
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
      ),
    );

    // Trigger identificación
    await identificationCubit.identifyOrCreateProduct(
      imageBytes: imageBytes,
      imageName: imageName,
      source: 'SALE',
    );

    if (!context.mounted) return;

    // Paso 3: Manejar resultado
    final state = identificationCubit.state;

    if (state is ProductIdentificationSuccess) {
      ProductSummary? confirmedProduct;

      // ✅ Verificar si se debe auto-confirmar o mostrar pantalla de confirmación
      final confidence = state.result.confidence;
      final hasRelevantAlternatives = state
              .result.alternativeMatches.isNotEmpty &&
          state.result.alternativeMatches.any((alt) => alt.confidence >= 0.5);

      // Auto-confirmar si confianza >= 60% Y no hay alternativas relevantes
      if (confidence >= 0.6 && !hasRelevantAlternatives) {
        confirmedProduct = state.result.product;

        if (context.mounted) {
          NotificationHelper.showSuccess(
            context,
            'Producto identificado automáticamente: ${confirmedProduct.name}',
          );
        }
      } else {
        // Mostrar pantalla de confirmación si:
        // - Confianza < 60% (requiere validación manual)
        // - O hay alternativas relevantes (confianza >= 50%)
        confirmedProduct = await Navigator.push<ProductSummary>(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: identificationCubit,
              child: ProductIdentificationConfirmationScreen(
                result: state.result,
                source: 'SALE',
                capturedImageBytes: imageBytes,
              ),
            ),
          ),
        );
      }

      if (confirmedProduct != null && context.mounted) {
        // Paso 4: Agregar producto confirmado al carrito
        final cartCubit = getIt<CartSaleCubit>();

        try {
          // Convertir ProductSummary a ProductModel
          final productToAdd = ProductModel(
            id: confirmedProduct.id,
            name: confirmedProduct.name,
            description: confirmedProduct.description,
            imageUrl: confirmedProduct.imageUrl,
            categoryId: confirmedProduct.categoryId,
            stockQuantity: confirmedProduct.stockQuantity,
          );

          // Agregar al carrito
          await cartCubit.addProductToCart(productToAdd);

          // Paso 5: Navegar a CartSaleScreen para completar la venta
          if (context.mounted) {
            NotificationHelper.showSuccess(
              context,
              '${confirmedProduct.name} agregado al carrito',
            );

            // Navegar a la pantalla de carrito para completar la venta
            await context.push('/home/cart_sale');

            // Recargar ventas cuando regrese
            if (mounted) {
              await _loadSales();
            }
          }
        } catch (e) {
          if (context.mounted) {
            NotificationHelper.showError(
              context,
              'Error al agregar producto: $e',
            );
          }
        }
      }
    } else if (state is ProductIdentificationError) {
      if (context.mounted) {
        NotificationHelper.showError(
          context,
          state.message,
        );
      }
    }

    // Resetear el cubit de identificación para el próximo uso
    identificationCubit.reset();
  }

  /// Maneja la detección múltiple de productos para agregar a venta
  Future<void> _handleMultipleDetection(BuildContext context) async {
    // Paso 1: Mostrar selector de fuente de imagen (igual que individual)
    final imageSource = await _showImageSourceSelector(context);
    if (imageSource == null || !context.mounted) return;

    // Paso 2: Capturar imagen desde la fuente seleccionada
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: imageSource,
      imageQuality: 85,
    );

    if (pickedFile == null || !context.mounted) return;

    // Leer bytes de la imagen
    final imageBytes = await pickedFile.readAsBytes();
    final imageName = pickedFile.name;

    final multipleDetectionCubit = getIt<MultipleDetectionCubit>();
    final cartCubit = getIt<CartSaleCubit>();

    // Paso 3: Mostrar modal de procesamiento con imagen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: multipleDetectionCubit,
        child: BlocConsumer<MultipleDetectionCubit, MultipleDetectionState>(
          listener: (context, state) {
            // Cerrar modal cuando termine de procesar (éxito o error)
            if (state is MultipleDetectionSuccess ||
                state is MultipleDetectionError ||
                state is MultipleDetectionEditingSelection) {
              Navigator.pop(dialogContext);
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
                        imageBytes,
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
      ),
    );

    // Paso 4: Ejecutar detección
    await multipleDetectionCubit.detectMultipleProducts(
      imageBytes: imageBytes,
      imageName: imageName,
      source: 'SALE',
    );

    if (!context.mounted) return;

    // Paso 5: Manejar resultado
    final state = multipleDetectionCubit.state;

    if (state is MultipleDetectionSuccess) {
      // Auto-confirmar si todos tienen alta confianza (≥60%)
      final allHighConfidence = state.result.productGroups.every(
        (group) => group.averageConfidence >= 0.6,
      );

      if (allHighConfidence) {
        // Agregar productos automáticamente
        await _addMultipleProductsToCart(
          context,
          state.result,
          cartCubit,
        );
      } else {
        // Navegar a pantalla de edición
        await _navigateToMultipleDetectionEditing(
          context,
          multipleDetectionCubit,
          cartCubit,
          imageBytes,
        );
      }
    } else if (state is MultipleDetectionEditingSelection) {
      // Navegar a pantalla de edición
      await _navigateToMultipleDetectionEditing(
        context,
        multipleDetectionCubit,
        cartCubit,
        imageBytes,
      );
    } else if (state is MultipleDetectionError) {
      if (context.mounted) {
        NotificationHelper.showError(context, state.message);
      }
    }

    // Resetear el cubit después de usarlo
    multipleDetectionCubit.reset();
  }

  /// Navega a la pantalla de edición de detección múltiple
  Future<void> _navigateToMultipleDetectionEditing(
    BuildContext context,
    MultipleDetectionCubit multipleDetectionCubit,
    CartSaleCubit cartCubit,
    Uint8List imageBytes,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: multipleDetectionCubit,
          child: MultipleDetectionScreen(
            initialImageBytes: imageBytes,
            onConfirm: (result) async {
              await _addMultipleProductsToCart(context, result, cartCubit);
            },
          ),
        ),
      ),
    );
  }

  /// Agrega múltiples productos al carrito
  Future<void> _addMultipleProductsToCart(
    BuildContext context,
    MultipleProductDetectionResult result,
    CartSaleCubit cartCubit,
  ) async {
    int addedCount = 0;

    for (final group in result.productGroups) {
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
        if (context.mounted) {
          NotificationHelper.showError(
            context,
            'Error al agregar ${group.product.name}: $e',
          );
        }
      }
    }

    if (context.mounted && addedCount > 0) {
      NotificationHelper.showSuccess(
        context,
        'Se agregaron $addedCount productos al carrito',
      );

      await context.push('/home/cart_sale');

      if (mounted) {
        await _loadSales();
      }
    }
  }

  Widget _buildSearchSection(BuildContext context, ThemeData theme) {
    return HomeSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Buscar Ventas',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: HomeLayoutTokens.smallSpacing),
          TextField(
            controller: _searchController,
            onChanged: _filterSales,
            decoration: InputDecoration(
              hintText: 'Buscar por ID, cliente, monto, método de pago...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        _filterSales('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(ThemeData theme) {
    final totalSales = _allSales.length;
    final totalItems = _allSales.fold<int>(
      0,
      (sum, sale) => sum + sale.saleItems.length,
    );
    final totalAmount = _allSales.fold<double>(
      0,
      (sum, sale) => sum + sale.sale.totalAmount,
    );

    return HomeSectionCard(
      addShadow: false,
      child: Row(
        children: [
          Expanded(
            child: HomeSummaryChip(
              icon: Icons.receipt_long_rounded,
              label: 'Ventas',
              value: '$totalSales',
            ),
          ),
          const SizedBox(width: HomeLayoutTokens.smallSpacing),
          Expanded(
            child: HomeSummaryChip(
              icon: Icons.shopping_bag_rounded,
              label: 'Productos',
              value: '$totalItems',
            ),
          ),
          const SizedBox(width: HomeLayoutTokens.smallSpacing),
          Expanded(
            child: HomeSummaryChip(
              icon: Icons.attach_money_rounded,
              label: 'Ingresos',
              value: _currencyFormatter.format(totalAmount),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesListSection(BuildContext context, ThemeData theme) {
    return HomeSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lista de Ventas',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_filteredSales.length} ventas',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: HomeLayoutTokens.smallSpacing),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            _buildErrorWidget()
          else if (_filteredSales.isEmpty)
            _buildEmptyWidget()
          else
            ..._filteredSales
                .map((sale) => _buildSaleCard(context, sale, theme)),
        ],
      ),
    );
  }

  Widget _buildSaleCard(
      BuildContext context, CartSaleModel cartSale, ThemeData theme) {
    final sale = cartSale.sale;
    final itemsCount = cartSale.saleItems.length;
    final clientName = sale.personId != null
        ? _clientNames[sale.personId!] ?? 'Sin cliente'
        : 'Sin cliente';

    return Padding(
      padding: const EdgeInsets.only(bottom: HomeLayoutTokens.smallSpacing),
      child: InkWell(
        onTap: () => _showSaleDetail(context, cartSale),
        borderRadius: BorderRadius.circular(HomeLayoutTokens.cardRadius),
        child: HomeSectionCard(
          border: Border.all(color: Colors.grey[200]!),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getStateColor(sale.state),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      _getStateIcon(sale.state),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Venta #${sale.id} - $clientName',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${itemsCount} producto${itemsCount != 1 ? 's' : ''} • ${_currencyFormatter.format(sale.totalAmount)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${sale.payMethod ?? 'Sin método'} • ${sale.state ?? 'Sin estado'}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        sale.saleDate != null
                            ? DateFormat('dd/MM/yyyy HH:mm:ss')
                                .format(sale.saleDate!)
                            : 'Sin fecha',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.grey[400],
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return HomeEmptyState(
      icon: Icons.error_outline_rounded,
      title: 'Error al cargar las ventas',
      message: _errorMessage ?? 'Error desconocido',
      iconColor: Colors.red[400],
      action: HomeActionButton(
        icon: Icons.refresh_rounded,
        label: 'Reintentar',
        color: Colors.red.shade400,
        onPressed: _loadSales,
        fullWidth: false,
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return HomeEmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'No hay ventas registradas',
      message: 'Las ventas aparecerán aquí una vez que se registren',
      iconColor: Colors.grey[400],
    );
  }

  Color _getStateColor(String? state) {
    switch (state?.toLowerCase()) {
      case 'completed':
      case 'pagado':
        return Colors.green;
      case 'pending':
      case 'pendiente':
        return Colors.orange;
      case 'cancelled':
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStateIcon(String? state) {
    switch (state?.toLowerCase()) {
      case 'completed':
      case 'pagado':
        return Icons.check_circle_rounded;
      case 'pending':
      case 'pendiente':
        return Icons.pending_rounded;
      case 'cancelled':
      case 'cancelado':
        return Icons.cancel_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }

  Future<void> _showSaleDetail(
      BuildContext context, CartSaleModel cartSale) async {
    try {
      // Obtener información del cliente si existe
      String clientInfo = 'Sin cliente';
      if (cartSale.sale.personId != null) {
        try {
          final personService = getIt<PersonService>();
          final person = await personService.getById(cartSale.sale.personId!);
          clientInfo =
              '${person.name} (${person.identificationType}: ${person.identification})';
        } catch (e) {
          clientInfo = 'Cliente ID: ${cartSale.sale.personId}';
        }
      }

      // Obtener información del usuario
      String userInfo = 'Usuario ID: ${cartSale.sale.userId}';
      try {
        final userService = getIt<UserService>();
        final user = await userService.getById(cartSale.sale.userId);
        userInfo =
            '${user.firstName ?? ''} ${user.lastName ?? ''} (${user.username})'
                .trim();
      } catch (e) {
        // Mantener el ID si no se puede obtener el nombre
      }

      // Obtener información de productos
      Map<int, ProductModel> products = {};
      for (final item in cartSale.saleItems) {
        try {
          final productService = getIt<ProductService>();
          final product = await productService.getById(item.productId);
          products[item.productId] = product;
        } catch (e) {
          // Si no se puede obtener el producto, se mantendrá como null
        }
      }

      if (mounted) {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (context) {
            return SaleDetailSheet(
              cartSale: cartSale,
              clientInfo: clientInfo,
              userInfo: userInfo,
              products: products,
              currencyFormatter: _currencyFormatter,
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar detalles: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class SaleDetailSheet extends StatelessWidget {
  final CartSaleModel cartSale;
  final String clientInfo;
  final String userInfo;
  final Map<int, ProductModel> products;
  final NumberFormat currencyFormatter;

  const SaleDetailSheet({
    super.key,
    required this.cartSale,
    required this.clientInfo,
    required this.userInfo,
    required this.products,
    required this.currencyFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final sale = cartSale.sale;
    final items = cartSale.saleItems;

    final totalItems = items.length;
    final totalQuantity =
        items.fold<int>(0, (sum, item) => sum + item.quantity);
    final totalAmount = currencyFormatter.format(sale.totalAmount);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildHeader(context),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: HomeSummaryChip(
                      icon: Icons.list_alt_rounded,
                      label: 'Productos',
                      value: '$totalItems',
                    ),
                  ),
                  const SizedBox(width: HomeLayoutTokens.smallSpacing),
                  Expanded(
                    child: HomeSummaryChip(
                      icon: Icons.inventory_rounded,
                      label: 'Cantidad',
                      value: '$totalQuantity',
                    ),
                  ),
                  const SizedBox(width: HomeLayoutTokens.smallSpacing),
                  Expanded(
                    child: HomeSummaryChip(
                      icon: Icons.attach_money_rounded,
                      label: 'Total venta',
                      value: totalAmount,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildInfoSection(context, sale),
              const SizedBox(height: 24),
              _buildItemsSection(context, items),
              const SizedBox(height: 24),
              _buildTotalSection(context, sale),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final sale = cartSale.sale;
    final saleDate = sale.saleDate != null
        ? DateFormat('dd/MM/yyyy HH:mm:ss').format(sale.saleDate!)
        : 'Sin fecha';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: theme.primaryColor.withOpacity(0.12),
          child: Icon(
            Icons.receipt_long_rounded,
            color: theme.primaryColor,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Venta #${sale.id}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                clientInfo,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                saleDate,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${sale.payMethod ?? 'Sin método'} • ${sale.state ?? 'Sin estado'}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
          color: Colors.grey[600],
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, SaleModel sale) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información General',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
              'Fecha de Venta',
              sale.saleDate != null
                  ? DateFormat('dd/MM/yyyy HH:mm:ss').format(sale.saleDate!)
                  : 'Sin fecha'),
          _buildInfoRow('Método de Pago', sale.payMethod ?? 'Sin método'),
          _buildInfoRow('Estado', sale.state ?? 'Sin estado'),
          _buildInfoRow('Cliente', clientInfo),
          _buildInfoRow('Usuario', userInfo),
        ],
      ),
    );
  }

  Widget _buildItemsSection(BuildContext context, List<SaleItemModel> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Productos (${items.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _buildItemCard(context, item, index + 1);
        }).toList(),
      ],
    );
  }

  Widget _buildItemCard(BuildContext context, SaleItemModel item, int index) {
    final product = products[item.productId];
    final productName = product?.name ?? 'Producto ID: ${item.productId}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Número del item
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Información del producto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cantidad: ${item.quantity} • Precio: ${currencyFormatter.format(item.unitPrice)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (product?.description != null &&
                    product!.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    product.description!,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Total del item
          Text(
            currencyFormatter.format(item.totalPrice),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection(BuildContext context, SaleModel sale) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total de la Venta',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            currencyFormatter.format(sale.totalAmount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
