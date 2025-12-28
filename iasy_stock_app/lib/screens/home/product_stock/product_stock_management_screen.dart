import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../config/get_it_config.dart';
import '../../../cubits/invoice_scan/invoice_scan_cubit.dart';
import '../../../cubits/invoice_scan/invoice_scan_state.dart';
import '../../../cubits/product_identification/multiple_detection_cubit.dart';
import '../../../cubits/product_identification/multiple_detection_state.dart';
import '../../../cubits/product_identification/product_identification_cubit.dart';
import '../../../cubits/product_identification/product_identification_state.dart';
import '../../../cubits/product_stock/product_stock_cubit.dart';
import '../../../models/menu/product_model.dart';
import '../../../models/menu/stock_model.dart';
import '../../../models/product_identification/product_identification_models.dart';
import '../../../models/product_stock/product_stock_model.dart';
import '../../../services/menu/person_service.dart';
import '../../../services/menu/warehouse_service.dart';
import '../../../services/product_stock/product_stock_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/home_layout_tokens.dart';
import '../../../widgets/home/general_sliver_app_bar.dart';
import '../../../widgets/home/home_ui_components.dart';
import '../../../widgets/menu/secure_network_image.dart';
import '../../../widgets/notification_helper.dart';
import '../../product_identification/multiple_detection_screen.dart';
import '../../product_identification/product_identification_confirmation_screen.dart';

class ProductStockManagementScreen extends StatefulWidget {
  const ProductStockManagementScreen({super.key});

  @override
  State<ProductStockManagementScreen> createState() =>
      _ProductStockManagementScreenState();
}

class _ProductStockManagementScreenState
    extends State<ProductStockManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _currencyFormatter =
      NumberFormat.currency(locale: 'es_CO', symbol: r'$');

  List<ProductStockModel> _allRecords = [];
  List<ProductStockModel> _filteredRecords = [];
  Map<int, String> _providerNames = {};
  Map<int, String> _warehouseNames = {};

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = getIt<ProductStockService>();
      final records = await service.getAll(page: 0, size: 100);
      final sortedRecords = List<ProductStockModel>.from(records)
        ..sort(_compareByLatestStock);
      await _loadSupplementaryData(sortedRecords);

      setState(() {
        _allRecords = sortedRecords;
        _filteredRecords = List<ProductStockModel>.from(sortedRecords);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar registros: $e';
        _isLoading = false;
      });
    }
  }

  int _compareByLatestStock(ProductStockModel a, ProductStockModel b) {
    final dateA = _getLatestStockDate(a);
    final dateB = _getLatestStockDate(b);
    return dateB.compareTo(dateA);
  }

  DateTime _getLatestStockDate(ProductStockModel record) {
    DateTime latest =
        record.product.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

    for (final stock in record.stocks) {
      final candidate = stock.createdAt ??
          stock.entryDate ??
          DateTime.fromMillisecondsSinceEpoch(0);
      if (candidate.isAfter(latest)) {
        latest = candidate;
      }
    }

    return latest;
  }

  Future<void> _loadSupplementaryData(List<ProductStockModel> records) async {
    final personService = getIt<PersonService>();
    final warehouseService = getIt<WarehouseService>();

    final providerIds = <int>{};
    final warehouseIds = <int>{};

    for (final record in records) {
      for (final stock in record.stocks) {
        if (stock.personId != null &&
            !_providerNames.containsKey(stock.personId)) {
          providerIds.add(stock.personId!);
        }
        if (stock.warehouseId != null &&
            !_warehouseNames.containsKey(stock.warehouseId)) {
          warehouseIds.add(stock.warehouseId!);
        }
      }
    }

    for (final providerId in providerIds) {
      try {
        final person = await personService.getById(providerId);
        _providerNames[providerId] = person.name;
      } catch (_) {
        _providerNames[providerId] = 'Proveedor #$providerId';
      }
    }

    for (final warehouseId in warehouseIds) {
      try {
        final warehouse = await warehouseService.getById(warehouseId);
        _warehouseNames[warehouseId] = warehouse.name;
      } catch (_) {
        _warehouseNames[warehouseId] = 'Almacén #$warehouseId';
      }
    }
  }

  void _filterRecords(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredRecords = _allRecords;
        return;
      }

      final lower = query.toLowerCase();
      _filteredRecords = _allRecords.where((record) {
        final product = record.product;
        final productMatch = product.name.toLowerCase().contains(lower) ||
            (product.description ?? '').toLowerCase().contains(lower);

        final providerMatch = record.stocks.any((stock) {
          final providerName = _providerNames[stock.personId] ?? '';
          return providerName.toLowerCase().contains(lower);
        });

        return productMatch || providerMatch;
      }).toList();
    });
  }

  /// Maneja el registro de stock con imagen (identificación inteligente)
  Future<void> _showImageRegistrationNotice() async {
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
      source: 'STOCK',
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
                source: 'STOCK',
                capturedImageBytes: imageBytes,
              ),
            ),
          ),
        );
      }

      if (confirmedProduct != null && context.mounted) {
        // Paso 4: Agregar el producto al registro de stock
        final productStockCubit = getIt<ProductStockCubit>();

        // Iniciar nuevo registro si es necesario
        productStockCubit.startNewRecord();

        // Crear el ProductModel desde el ProductSummary
        final productToAdd = ProductModel(
          id: confirmedProduct.id,
          name: confirmedProduct.name,
          description: confirmedProduct.description,
          imageUrl: confirmedProduct.imageUrl,
          categoryId: confirmedProduct.categoryId,
          stockQuantity: confirmedProduct.stockQuantity,
          createdAt: confirmedProduct.createdAt ?? DateTime.now(),
        );

        // Agregar al registro de stock (usuario completará precios después)
        productStockCubit.addProductStockEntry(
          product: productToAdd,
          quantity: 1,
          // Cantidad por defecto, usuario podrá cambiar
          entryPrice: 0,
          // Usuario deberá ingresar precio de entrada
          salePrice: 0,
          // Usuario deberá ingresar precio de venta
          warehouseId: 1,
          // Almacén por defecto, usuario podrá cambiar
          entryDate: DateTime.now(),
        );

        // Mostrar mensaje de éxito
        NotificationHelper.showSuccess(
          context,
          'Producto ${confirmedProduct.name} agregado. Complete los datos de stock.',
        );

        // Paso 5: Navegar a la pantalla de registro de stock para completar información
        if (context.mounted) {
          await context.push('/home/product_stock');

          // Recargar registros cuando regrese
          if (mounted) {
            await _loadRecords();
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

  Widget _buildActionSection(BuildContext context) {
    final theme = Theme.of(context);

    return HomeSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Opciones de registro',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: HomeLayoutTokens.smallSpacing),
          Row(
            children: [
              Expanded(
                child: HomeActionButton(
                  icon: Icons.add_box_rounded,
                  label: 'Registrar stock manualmente',
                  color: theme.primaryColor,
                  onPressed: () => _openManualStockRegistration(context),
                ),
              ),
              const SizedBox(width: HomeLayoutTokens.smallSpacing),
              Expanded(
                child: HomeActionButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Registrar stock individual con imagen',
                  color: theme.primaryColor,
                  onPressed: _showImageRegistrationNotice,
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
                  label: 'Registrar stock múltiple con imagen',
                  color: theme.primaryColor,
                  onPressed: _handleMultipleDetection,
                ),
              ),
              const SizedBox(width: HomeLayoutTokens.smallSpacing),
              Expanded(
                child: HomeActionButton(
                  icon: Icons.receipt_long_rounded,
                  label: 'Registrar stock con escáner de factura',
                  color: theme.primaryColor,
                  onPressed: _handleInvoiceScan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openManualStockRegistration(BuildContext context) async {
    await context.push('/home/product_stock');
    if (!mounted) return;
    await _loadRecords();
  }

  /// Maneja el escaneo de factura/documento con OCR
  Future<void> _handleInvoiceScan() async {
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
              Text(
                'Extrayendo productos de la factura...',
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

    // Paso 6: Manejar resultado - Cargar productos directamente en la pantalla de stock
    final state = invoiceScanCubit.state;

    if (state is InvoiceScanEditing) {
      final productStockCubit = getIt<ProductStockCubit>();
      final products = state.editedProducts;
      int productosAgregados = 0;
      int productosNoVinculados = 0;

      // Agregar cada producto con match a la lista de registros de stock
      for (final item in products) {
        if (item.matchedProduct != null) {
          // Crear ProductModel desde el MatchedProduct
          final product = ProductModel(
            id: item.matchedProduct!.id,
            name: item.matchedProduct!.name,
            description: item.matchedProduct!.description,
            categoryId: item.matchedProduct!.categoryId ?? 1,
            imageUrl: item.matchedProduct!.imageUrl,
            stockQuantity: item.matchedProduct!.stockQuantity,
            createdAt: item.matchedProduct!.createdAt ?? DateTime.now(),
          );

          // Agregar al cubit de stock
          productStockCubit.addProductStockEntry(
            product: product,
            quantity: item.quantity,
            entryPrice: item.unitPrice,
            salePrice: item.salePrice,
            warehouseId: 1, // Almacén por defecto, usuario podrá cambiar
          );
          productosAgregados++;
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
              '$productosAgregados producto(s) agregado(s) desde la factura';
          if (productosNoVinculados > 0) {
            mensaje += '\n$productosNoVinculados producto(s) no vinculados';
          }
          NotificationHelper.showSuccess(context, mensaje);

          // Navegar a la pantalla de registro de stock para completar información
          await context.push('/home/product_stock');

          // Recargar registros cuando regrese
          if (mounted) {
            await _loadRecords();
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

  /// Maneja la detección múltiple de productos para agregar a stock
  Future<void> _handleMultipleDetection() async {
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
    final productStockCubit = getIt<ProductStockCubit>();

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
                    Text(
                      'Esto puede tomar unos segundos...',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted(context),
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
      source: 'STOCK',
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
        // Agregar productos automáticamente al stock
        await _addMultipleProductsToStock(
          context,
          state.result,
          productStockCubit,
        );
      } else {
        // Navegar a pantalla de edición
        await _navigateToMultipleDetectionEditing(
          context,
          multipleDetectionCubit,
          productStockCubit,
          imageBytes,
        );
      }
    } else if (state is MultipleDetectionEditingSelection) {
      // Navegar a pantalla de edición
      await _navigateToMultipleDetectionEditing(
        context,
        multipleDetectionCubit,
        productStockCubit,
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
    ProductStockCubit productStockCubit,
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
              await _addMultipleProductsToStock(
                  context, result, productStockCubit);
            },
          ),
        ),
      ),
    );
  }

  /// Agrega múltiples productos al registro de stock
  Future<void> _addMultipleProductsToStock(
    BuildContext context,
    MultipleProductDetectionResult result,
    ProductStockCubit productStockCubit,
  ) async {
    // Iniciar nuevo registro de stock
    productStockCubit.startNewRecord();

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
          createdAt: group.product.createdAt ?? DateTime.now(),
        );

        // Agregar al registro de stock (usuario completará precios después)
        productStockCubit.addProductStockEntry(
          product: productToAdd,
          quantity: group.quantity,
          entryPrice: 0,
          // Usuario deberá ingresar precio de entrada
          salePrice: 0,
          // Usuario deberá ingresar precio de venta
          warehouseId: 1,
          // Almacén por defecto, usuario podrá cambiar
          entryDate: DateTime.now(),
        );

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
        'Se agregaron $addedCount productos. Complete los datos de stock.',
      );

      // Navegar a la pantalla de registro de stock para completar información
      await context.push('/home/product_stock');

      // Recargar registros cuando regrese
      if (mounted) {
        await _loadRecords();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadRecords,
        child: CustomScrollView(
          slivers: [
            GeneralSliverAppBar(
              title: 'Gestión de Stock',
              subtitle: 'Consulta los movimientos registrados',
              icon: Icons.inventory_rounded,
              primaryColor: theme.primaryColor,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildActionSection(context),
                    const SizedBox(height: HomeLayoutTokens.sectionSpacing),
                    _buildSearchSection(context),
                    const SizedBox(height: HomeLayoutTokens.sectionSpacing),
                    _buildSummarySection(context),
                    const SizedBox(height: HomeLayoutTokens.sectionSpacing),
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_errorMessage != null)
                      _buildErrorState()
                    else if (_filteredRecords.isEmpty)
                      _buildEmptyState()
                    else
                      HomeSectionCard(
                        addShadow: false,
                        child: _buildRecordsList(),
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

  Widget _buildSearchSection(BuildContext context) {
    final theme = Theme.of(context);

    return HomeSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Buscar registros',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: _filterRecords,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search_rounded,
                  color: AppColors.textMuted(context)),
              hintText: 'Busca por producto, proveedor o almacén',
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _filterRecords('');
                      },
                      icon: Icon(Icons.clear_rounded,
                          color: AppColors.textMuted(context)),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.surfaceBorder(context)),
              ),
              filled: true,
              fillColor: AppColors.surfaceEmphasis(context),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.surfaceBorder(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    final totalRecords = _allRecords.length;
    final totalEntries =
        _allRecords.fold<int>(0, (sum, record) => sum + record.stocks.length);
    final totalQuantity = _allRecords.fold<int>(
      0,
      (sum, record) =>
          sum +
          record.stocks
              .fold<int>(0, (subtotal, stock) => subtotal + stock.quantity),
    );

    return HomeSectionCard(
      addShadow: false,
      child: Row(
        children: [
          Expanded(
            child: HomeSummaryChip(
              icon: Icons.inventory_2_rounded,
              label: 'Productos',
              value: '$totalRecords',
            ),
          ),
          const SizedBox(width: HomeLayoutTokens.smallSpacing),
          Expanded(
            child: HomeSummaryChip(
              icon: Icons.list_alt_rounded,
              label: 'Registros',
              value: '$totalEntries',
            ),
          ),
          const SizedBox(width: HomeLayoutTokens.smallSpacing),
          Expanded(
            child: HomeSummaryChip(
              icon: Icons.format_list_numbered_rounded,
              label: 'Unidades',
              value: '$totalQuantity',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return HomeSectionCard(
      addShadow: false,
      child: HomeEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Error al cargar registros',
        message: _errorMessage ?? 'Error desconocido',
        iconColor: AppColors.danger(context),
        action: HomeActionButton(
          icon: Icons.refresh_rounded,
          label: 'Reintentar',
          color: AppColors.danger(context),
          onPressed: _loadRecords,
          fullWidth: false,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return HomeSectionCard(
      addShadow: false,
      child: HomeEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No hay registros de stock',
        message: 'Registra movimientos de stock desde el flujo manual.',
        iconColor: AppColors.iconMuted(context),
      ),
    );
  }

  Widget _buildRecordsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredRecords.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final record = _filteredRecords[index];
        return _buildRecordCard(record);
      },
    );
  }

  Widget _buildRecordCard(ProductStockModel record) {
    final product = record.product;
    final totalEntries = record.stocks.length;
    final totalQuantity = record.stocks.fold<int>(
      0,
      (sum, stock) => sum + stock.quantity,
    );
    final totalEntryValue = record.stocks.fold<double>(
      0,
      (sum, stock) => sum + stock.entryPrice * stock.quantity,
    );
    final lastEntry = record.stocks.isNotEmpty
        ? record.stocks.reduce((a, b) => (a.entryDate ?? DateTime.now())
                .isAfter(b.entryDate ?? DateTime.now())
            ? a
            : b)
        : null;

    return InkWell(
      borderRadius: BorderRadius.circular(HomeLayoutTokens.cardRadius),
      onTap: () => _showRecordDetail(record),
      child: HomeSectionCard(
        addShadow: false,
        border: Border.all(color: AppColors.surfaceBorder(context)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? SecureNetworkImage(
                      imageUrl: product.imageUrl,
                      productId: product.id,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 72,
                      height: 72,
                      color: AppColors.surfaceEmphasis(context),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.iconMuted(context),
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (product.description != null &&
                      product.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.textMuted(context)),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _buildBadge(
                        icon: Icons.list_alt_rounded,
                        label: '$totalEntries registros',
                      ),
                      _buildBadge(
                        icon: Icons.inventory_rounded,
                        label: '$totalQuantity unidades',
                      ),
                      _buildBadge(
                        icon: Icons.attach_money_rounded,
                        label: _currencyFormatter.format(totalEntryValue),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (lastEntry?.entryDate != null)
                  Text(
                    'Última entrada\n${DateFormat('dd/MM/yyyy').format(lastEntry!.entryDate!)}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted(context),
                    ),
                  ),
                const SizedBox(height: 8),
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.iconMuted(context), size: 28),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.surfaceEmphasis(context),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted(context)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showRecordDetail(ProductStockModel record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
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
                        color: AppColors.surfaceBorder(context),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailHeader(record),
                  const SizedBox(height: 20),
                  _buildDetailSummary(record),
                  const SizedBox(height: 24),
                  const Text(
                    'Registros asociados',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...record.stocks.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildDetailStockCard(entry.key, entry.value),
                        ),
                      ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailHeader(ProductStockModel record) {
    final product = record.product;

    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: product.imageUrl != null && product.imageUrl!.isNotEmpty
              ? SecureNetworkImage(
                  imageUrl: product.imageUrl,
                  productId: product.id,
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 96,
                  height: 96,
                  color: AppColors.surfaceEmphasis(context),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 36,
                    color: AppColors.iconMuted(context),
                  ),
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (product.description != null &&
                  product.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  product.description!,
                  style: TextStyle(color: AppColors.textMuted(context)),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
          color: theme.iconTheme.color ?? AppColors.textMuted(context),
        ),
      ],
    );
  }

  Widget _buildDetailSummary(ProductStockModel record) {
    final totalQuantity =
        record.stocks.fold<int>(0, (sum, stock) => sum + stock.quantity);
    final totalEntryValue = record.stocks.fold<double>(
      0,
      (sum, stock) => sum + stock.entryPrice * stock.quantity,
    );
    final totalSaleValue = record.stocks.fold<double>(
      0,
      (sum, stock) => sum + stock.salePrice * stock.quantity,
    );

    return Row(
      children: [
        Expanded(
          child: _buildDetailSummaryCard(
            icon: Icons.inventory_rounded,
            title: 'Unidades recibidas',
            value: '$totalQuantity',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDetailSummaryCard(
            icon: Icons.attach_money_rounded,
            title: 'Valor total entrada',
            value: _currencyFormatter.format(totalEntryValue),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDetailSummaryCard(
            icon: Icons.trending_up_rounded,
            title: 'Valor total venta',
            value: _currencyFormatter.format(totalSaleValue),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSummaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[700]),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailStockCard(int index, StockModel stock) {
    final providerName = stock.personId != null
        ? _providerNames[stock.personId]
        : 'Sin proveedor';
    final warehouseName = stock.warehouseId != null
        ? _warehouseNames[stock.warehouseId]
        : 'Sin almacén';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.surfaceBase,
        border: Border.all(color: AppColors.surfaceBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.info(context).withOpacity(0.12),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: AppColors.info(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                DateFormat('dd/MM/yyyy')
                    .format(stock.entryDate ?? DateTime.now()),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildDetailChip(
                label: 'Cantidad',
                value: '${stock.quantity} unidades',
                icon: Icons.inventory_2_rounded,
              ),
              _buildDetailChip(
                label: 'Precio entrada',
                value: _currencyFormatter.format(stock.entryPrice),
                icon: Icons.request_quote_rounded,
              ),
              _buildDetailChip(
                label: 'Precio venta',
                value: _currencyFormatter.format(stock.salePrice),
                icon: Icons.point_of_sale_rounded,
              ),
              _buildDetailChip(
                label: 'Almacén',
                value: warehouseName ?? 'Sin información',
                icon: Icons.store_mall_directory_rounded,
              ),
              _buildDetailChip(
                label: 'Proveedor',
                value: providerName ?? 'Sin información',
                icon: Icons.storefront_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.surfaceEmphasis(context),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted(context)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted(context),
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
}
