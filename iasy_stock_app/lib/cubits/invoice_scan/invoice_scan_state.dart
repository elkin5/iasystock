import 'package:equatable/equatable.dart';

import '../../models/invoice_scan/invoice_scan_models.dart';

/// Estados para el Cubit de escaneo de facturas
abstract class InvoiceScanState extends Equatable {
  const InvoiceScanState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class InvoiceScanInitial extends InvoiceScanState {}

/// Procesando imagen de factura (OCR)
class InvoiceScanProcessing extends InvoiceScanState {
  final String message;

  const InvoiceScanProcessing({
    this.message = 'Escaneando factura...',
  });

  @override
  List<Object?> get props => [message];
}

/// Factura escaneada exitosamente
class InvoiceScanSuccess extends InvoiceScanState {
  final InvoiceScanResult result;

  const InvoiceScanSuccess({
    required this.result,
  });

  @override
  List<Object?> get props => [result];

  // Helpers para acceso rápido
  bool get requiresValidation => result.requiresValidation;

  int get totalProducts => result.totalProducts;

  int get matchedProducts => result.matchedProducts;

  int get unmatchedProducts => result.unmatchedProducts;

  double get totalAmount => result.totalAmount;

  List<InvoiceProductItem> get products => result.products;

  DateTime? get invoiceDate => result.invoiceDate;

  String? get invoiceNumber => result.invoiceNumber;

  String? get supplierName => result.supplierName;
}

/// Error en escaneo de factura
class InvoiceScanError extends InvoiceScanState {
  final String message;
  final dynamic error;

  const InvoiceScanError({
    required this.message,
    this.error,
  });

  @override
  List<Object?> get props => [message, error];
}

/// Estado de edición de productos extraídos
class InvoiceScanEditing extends InvoiceScanState {
  final InvoiceScanResult originalResult;
  final List<InvoiceProductItem> editedProducts;
  final DateTime? selectedDate;
  final int? selectedWarehouseId;
  final int? selectedPersonId;

  const InvoiceScanEditing({
    required this.originalResult,
    required this.editedProducts,
    this.selectedDate,
    this.selectedWarehouseId,
    this.selectedPersonId,
  });

  @override
  List<Object?> get props => [
        originalResult,
        editedProducts,
        selectedDate,
        selectedWarehouseId,
        selectedPersonId,
      ];

  /// Crea una copia con cambios
  InvoiceScanEditing copyWith({
    InvoiceScanResult? originalResult,
    List<InvoiceProductItem>? editedProducts,
    DateTime? selectedDate,
    int? selectedWarehouseId,
    int? selectedPersonId,
  }) {
    return InvoiceScanEditing(
      originalResult: originalResult ?? this.originalResult,
      editedProducts: editedProducts ?? this.editedProducts,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedWarehouseId: selectedWarehouseId ?? this.selectedWarehouseId,
      selectedPersonId: selectedPersonId ?? this.selectedPersonId,
    );
  }

  /// Total de productos en la lista editada
  int get totalProducts => editedProducts.length;

  /// Total de productos confirmados
  int get confirmedProducts =>
      editedProducts.where((p) => p.isConfirmed).length;

  /// Total de productos con match
  int get matchedProducts =>
      editedProducts.where((p) => p.matchedProduct != null).length;

  /// Monto total calculado
  double get totalAmount => editedProducts.fold(
        0.0,
        (sum, p) => sum + (p.unitPrice * p.quantity),
      );

  /// Verifica si todos los productos están confirmados
  bool get allConfirmed => editedProducts.every((p) => p.isConfirmed);
}

/// Buscando productos por nombre
class InvoiceScanSearching extends InvoiceScanState {
  final String query;

  const InvoiceScanSearching({
    required this.query,
  });

  @override
  List<Object?> get props => [query];
}

/// Resultados de búsqueda de productos
class InvoiceScanSearchResults extends InvoiceScanState {
  final String query;
  final List<MatchedProduct> results;

  const InvoiceScanSearchResults({
    required this.query,
    required this.results,
  });

  @override
  List<Object?> get props => [query, results];
}

/// Confirmando y registrando productos
class InvoiceScanConfirming extends InvoiceScanState {
  final String message;
  final int totalProducts;
  final int currentProduct;

  const InvoiceScanConfirming({
    this.message = 'Registrando productos...',
    this.totalProducts = 0,
    this.currentProduct = 0,
  });

  @override
  List<Object?> get props => [message, totalProducts, currentProduct];

  double get progress =>
      totalProducts > 0 ? currentProduct / totalProducts : 0.0;
}

/// Productos registrados exitosamente
class InvoiceScanConfirmationSuccess extends InvoiceScanState {
  final int registeredCount;
  final String message;

  const InvoiceScanConfirmationSuccess({
    required this.registeredCount,
    this.message = 'Productos registrados exitosamente',
  });

  @override
  List<Object?> get props => [registeredCount, message];
}
