import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../models/invoice_scan/invoice_scan_models.dart';
import '../../services/invoice_scan/invoice_scan_service.dart';
import 'invoice_scan_state.dart';

final Logger _cubitLog = Logger();
const _uuid = Uuid();

/// Cubit para manejar el estado de escaneo de facturas/documentos
///
/// Funcionalidades:
/// - Escanear factura con OCR
/// - Editar productos extraídos
/// - Buscar productos por nombre
/// - Confirmar y registrar productos
class InvoiceScanCubit extends Cubit<InvoiceScanState> {
  final InvoiceScanService _service;

  InvoiceScanCubit({
    required InvoiceScanService service,
  })  : _service = service,
        super(InvoiceScanInitial());

  /// Escanea una factura/documento y extrae los productos
  ///
  /// [imageBytes] - Bytes de la imagen de la factura
  /// [imageName] - Nombre del archivo de imagen
  /// [userId] - ID del usuario que escanea
  /// [defaultProfitMargin] - Porcentaje de ganancia por defecto
  Future<void> scanInvoice({
    required Uint8List imageBytes,
    String imageName = 'invoice.jpg',
    int? userId,
    int defaultProfitMargin = 30,
  }) async {
    _cubitLog.d('Iniciando escaneo de factura: $imageName');

    emit(const InvoiceScanProcessing(
      message: 'Analizando factura con IA...',
    ));

    try {
      final result = await _service.scanInvoice(
        imageBytes: imageBytes,
        imageName: imageName,
        userId: userId,
        defaultProfitMargin: defaultProfitMargin,
      );

      _cubitLog.i(
        '✅ Escaneo completado: status=${result.status}, '
        'productos=${result.totalProducts}, '
        'matched=${result.matchedProducts}',
      );

      emit(InvoiceScanSuccess(result: result));

      // Automáticamente pasar a modo edición si hay productos
      if (result.products.isNotEmpty) {
        _enterEditingMode(result);
      }
    } catch (e, stackTrace) {
      _cubitLog.e('❌ Error en escaneo: $e', error: e, stackTrace: stackTrace);

      final errorMessage = _extractErrorMessage(e);

      emit(InvoiceScanError(
        message: errorMessage,
        error: e,
      ));
    }
  }

  /// Entra en modo edición con los productos escaneados
  void _enterEditingMode(InvoiceScanResult result) {
    emit(InvoiceScanEditing(
      originalResult: result,
      editedProducts: List.from(result.products),
      selectedDate: result.invoiceDate ?? DateTime.now(),
      selectedWarehouseId: null,
      selectedPersonId: null,
    ));
  }

  /// Actualiza la fecha seleccionada
  void updateSelectedDate(DateTime date) {
    final currentState = state;
    if (currentState is InvoiceScanEditing) {
      emit(currentState.copyWith(selectedDate: date));
    }
  }

  /// Actualiza el almacén seleccionado
  void updateSelectedWarehouse(int warehouseId) {
    final currentState = state;
    if (currentState is InvoiceScanEditing) {
      emit(currentState.copyWith(selectedWarehouseId: warehouseId));
    }
  }

  /// Actualiza el proveedor seleccionado
  void updateSelectedPerson(int personId) {
    final currentState = state;
    if (currentState is InvoiceScanEditing) {
      emit(currentState.copyWith(selectedPersonId: personId));
    }
  }

  /// Confirma un producto individual
  void confirmProduct(String tempId) {
    final currentState = state;
    if (currentState is InvoiceScanEditing) {
      final updatedProducts = currentState.editedProducts.map((p) {
        if (p.tempId == tempId) {
          return p.copyWith(isConfirmed: true);
        }
        return p;
      }).toList();

      emit(currentState.copyWith(editedProducts: updatedProducts));
    }
  }

  /// Desconfirma un producto individual
  void unconfirmProduct(String tempId) {
    final currentState = state;
    if (currentState is InvoiceScanEditing) {
      final updatedProducts = currentState.editedProducts.map((p) {
        if (p.tempId == tempId) {
          return p.copyWith(isConfirmed: false);
        }
        return p;
      }).toList();

      emit(currentState.copyWith(editedProducts: updatedProducts));
    }
  }

  /// Confirma todos los productos
  void confirmAllProducts() {
    final currentState = state;
    if (currentState is InvoiceScanEditing) {
      final updatedProducts = currentState.editedProducts
          .map((p) => p.copyWith(isConfirmed: true))
          .toList();

      emit(currentState.copyWith(editedProducts: updatedProducts));
    }
  }

  /// Actualiza la cantidad de un producto
  void updateProductQuantity(String tempId, int quantity) {
    final currentState = state;
    if (currentState is InvoiceScanEditing) {
      final updatedProducts = currentState.editedProducts.map((p) {
        if (p.tempId == tempId) {
          return p.copyWith(quantity: quantity);
        }
        return p;
      }).toList();

      emit(currentState.copyWith(editedProducts: updatedProducts));
    }
  }

  /// Actualiza el precio de entrada de un producto
  void updateProductEntryPrice(String tempId, double price) {
    final currentState = state;
    if (currentState is InvoiceScanEditing) {
      final updatedProducts = currentState.editedProducts.map((p) {
        if (p.tempId == tempId) {
          // Recalcular precio de venta con el margen de ganancia
          final newSalePrice = price * (1 + p.profitMargin / 100);
          return p.copyWith(
            unitPrice: price,
            salePrice: newSalePrice,
          );
        }
        return p;
      }).toList();

      emit(currentState.copyWith(editedProducts: updatedProducts));
    }
  }

  /// Actualiza el precio de venta de un producto
  void updateProductSalePrice(String tempId, double price) {
    final currentState = state;
    if (currentState is InvoiceScanEditing) {
      final updatedProducts = currentState.editedProducts.map((p) {
        if (p.tempId == tempId) {
          return p.copyWith(salePrice: price);
        }
        return p;
      }).toList();

      emit(currentState.copyWith(editedProducts: updatedProducts));
    }
  }

  /// Actualiza el margen de ganancia de un producto
  void updateProductProfitMargin(String tempId, int margin) {
    final currentState = state;
    if (currentState is InvoiceScanEditing) {
      final updatedProducts = currentState.editedProducts.map((p) {
        if (p.tempId == tempId) {
          // Recalcular precio de venta con el nuevo margen
          final newSalePrice = p.unitPrice * (1 + margin / 100);
          return p.copyWith(
            profitMargin: margin,
            salePrice: newSalePrice,
          );
        }
        return p;
      }).toList();

      emit(currentState.copyWith(editedProducts: updatedProducts));
    }
  }

  /// Asigna un producto existente a un item extraído
  void assignMatchedProduct(String tempId, MatchedProduct matchedProduct) {
    final currentState = state;
    if (currentState is InvoiceScanEditing) {
      final updatedProducts = currentState.editedProducts.map((p) {
        if (p.tempId == tempId) {
          return p.copyWith(
            matchedProduct: matchedProduct,
            createAsNew: false,
          );
        }
        return p;
      }).toList();

      emit(currentState.copyWith(editedProducts: updatedProducts));
    }
  }

  /// Marca un producto para ser creado como nuevo
  void markAsNewProduct(String tempId) {
    final currentState = state;
    if (currentState is InvoiceScanEditing) {
      final updatedProducts = currentState.editedProducts.map((p) {
        if (p.tempId == tempId) {
          return p.copyWith(
            matchedProduct: null,
            createAsNew: true,
          );
        }
        return p;
      }).toList();

      emit(currentState.copyWith(editedProducts: updatedProducts));
    }
  }

  /// Elimina un producto de la lista
  void removeProduct(String tempId) {
    final currentState = state;
    if (currentState is InvoiceScanEditing) {
      final updatedProducts =
          currentState.editedProducts.where((p) => p.tempId != tempId).toList();

      emit(currentState.copyWith(editedProducts: updatedProducts));
    }
  }

  /// Agrega un producto manualmente a la lista
  void addManualProduct({
    required String name,
    int quantity = 1,
    double unitPrice = 0,
    int profitMargin = 30,
  }) {
    final currentState = state;
    if (currentState is InvoiceScanEditing) {
      final salePrice = unitPrice * (1 + profitMargin / 100);
      final newProduct = InvoiceProductItem(
        tempId: _uuid.v4(),
        extractedName: name,
        quantity: quantity,
        unitPrice: unitPrice,
        salePrice: salePrice,
        profitMargin: profitMargin,
        extractionConfidence: 1.0,
        // Manual = 100% confianza
        isConfirmed: false,
        createAsNew: true,
      );

      final updatedProducts = [...currentState.editedProducts, newProduct];
      emit(currentState.copyWith(editedProducts: updatedProducts));
    }
  }

  /// Busca productos por nombre
  Future<void> searchProducts(String query) async {
    if (query.isEmpty) return;

    _cubitLog.d('Buscando productos: "$query"');

    // Guardar el estado de edición actual antes de buscar
    final previousState = state;

    emit(InvoiceScanSearching(query: query));

    try {
      final results = await _service.searchProductsByName(
        query: query,
        limit: 10,
      );

      _cubitLog.i('✅ ${results.length} productos encontrados');

      emit(InvoiceScanSearchResults(
        query: query,
        results: results,
      ));

      // Si teníamos un estado de edición, restaurarlo después de un tiempo
      // para que la UI pueda mostrar los resultados
      if (previousState is InvoiceScanEditing) {
        await Future.delayed(const Duration(seconds: 5));
        if (state is InvoiceScanSearchResults) {
          emit(previousState);
        }
      }
    } catch (e, stackTrace) {
      _cubitLog.e('❌ Error buscando productos: $e',
          error: e, stackTrace: stackTrace);

      // Restaurar estado anterior en caso de error
      if (previousState is InvoiceScanEditing) {
        emit(previousState);
      }
    }
  }

  /// Confirma todos los productos y los registra en el stock
  Future<void> confirmAndRegisterAll({
    required int userId,
  }) async {
    final currentState = state;
    if (currentState is! InvoiceScanEditing) return;

    // Verificar que hay productos confirmados
    final confirmedProducts =
        currentState.editedProducts.where((p) => p.isConfirmed).toList();

    if (confirmedProducts.isEmpty) {
      emit(const InvoiceScanError(
        message: 'No hay productos confirmados para registrar',
      ));
      return;
    }

    // Verificar que se seleccionó un almacén
    if (currentState.selectedWarehouseId == null) {
      emit(const InvoiceScanError(
        message: 'Debe seleccionar un almacén',
      ));
      return;
    }

    _cubitLog.d(
      'Confirmando ${confirmedProducts.length} productos para registro',
    );

    emit(InvoiceScanConfirming(
      message: 'Registrando productos...',
      totalProducts: confirmedProducts.length,
      currentProduct: 0,
    ));

    try {
      // Convertir productos editados a formato de confirmación
      final productsToRegister = confirmedProducts.map((p) {
        return ConfirmedInvoiceProduct(
          productId: p.matchedProduct?.id,
          productName: p.matchedProduct?.name ?? p.extractedName,
          quantity: p.quantity,
          entryPrice: p.unitPrice,
          salePrice: p.salePrice,
          createAsNew: p.createAsNew,
          categoryId: p.matchedProduct?.categoryId,
        );
      }).toList();

      await _service.confirmAndRegister(
        products: productsToRegister,
        warehouseId: currentState.selectedWarehouseId!,
        personId: currentState.selectedPersonId,
        entryDate: currentState.selectedDate,
        userId: userId,
      );

      _cubitLog.i(
        '✅ ${confirmedProducts.length} productos registrados exitosamente',
      );

      emit(InvoiceScanConfirmationSuccess(
        registeredCount: confirmedProducts.length,
        message:
            '${confirmedProducts.length} productos registrados exitosamente',
      ));
    } catch (e, stackTrace) {
      _cubitLog.e('❌ Error registrando productos: $e',
          error: e, stackTrace: stackTrace);

      final errorMessage = _extractErrorMessage(e);

      emit(InvoiceScanError(
        message: errorMessage,
        error: e,
      ));
    }
  }

  /// Vuelve al estado de edición desde cualquier otro estado
  void returnToEditing() {
    final currentState = state;
    if (currentState is InvoiceScanSuccess) {
      _enterEditingMode(currentState.result);
    }
  }

  /// Resetea el estado a inicial
  void reset() {
    _cubitLog.d('Reseteando estado del cubit');
    emit(InvoiceScanInitial());
  }

  /// Extrae mensaje de error legible desde excepciones
  String _extractErrorMessage(dynamic error) {
    if (error == null) return 'Error desconocido';

    final errorString = error.toString();

    if (errorString.contains('Exception:')) {
      return errorString.split('Exception:').last.trim();
    }

    if (errorString.contains('Error:')) {
      return errorString.split('Error:').last.trim();
    }

    if (errorString.contains('SocketException') ||
        errorString.contains('Connection refused')) {
      return 'No se pudo conectar al servidor. Verifica tu conexión a internet.';
    }

    if (errorString.contains('TimeoutException')) {
      return 'La operación tardó demasiado. Intenta nuevamente.';
    }

    if (errorString.contains('401') || errorString.contains('Unauthorized')) {
      return 'No autorizado. Inicia sesión nuevamente.';
    }

    if (errorString.contains('404')) {
      return 'Recurso no encontrado.';
    }

    if (errorString.contains('500')) {
      return 'Error del servidor. Intenta más tarde.';
    }

    return errorString.length > 200
        ? '${errorString.substring(0, 200)}...'
        : errorString;
  }

  /// Obtiene la lista de productos confirmados (para integración con ProductStockScreen)
  List<InvoiceProductItem> getConfirmedProducts() {
    final currentState = state;
    if (currentState is InvoiceScanEditing) {
      return currentState.editedProducts.where((p) => p.isConfirmed).toList();
    }
    return [];
  }
}
