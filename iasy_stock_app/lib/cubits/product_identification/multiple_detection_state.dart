import 'package:equatable/equatable.dart';

import '../../models/product_identification/product_identification_models.dart';

/// Estados para el Cubit de detección múltiple de productos
abstract class MultipleDetectionState extends Equatable {
  const MultipleDetectionState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class MultipleDetectionInitial extends MultipleDetectionState {}

/// Procesando imagen para detección múltiple
class MultipleDetectionProcessing extends MultipleDetectionState {
  final String message;

  const MultipleDetectionProcessing({
    this.message = 'Detectando productos en la imagen...',
  });

  @override
  List<Object?> get props => [message];
}

/// Detección múltiple exitosa
class MultipleDetectionSuccess extends MultipleDetectionState {
  final MultipleProductDetectionResult result;

  const MultipleDetectionSuccess({
    required this.result,
  });

  @override
  List<Object?> get props => [result];

  // Helpers para acceso rápido
  bool get hasProducts => result.productGroups.isNotEmpty;

  bool get requiresValidation => result.requiresValidation;

  int get totalDetections => result.totalDetections;

  int get uniqueProducts => result.uniqueProducts;

  List<DetectedProductGroup> get productGroups => result.productGroups;

  /// Obtiene productos confirmados (confianza >= 60%)
  List<DetectedProductGroup> get confirmedProducts =>
      result.productGroups.where((group) => group.isConfirmed).toList();

  /// Obtiene productos que requieren validación manual
  List<DetectedProductGroup> get unconfirmedProducts =>
      result.productGroups.where((group) => !group.isConfirmed).toList();

  /// Calcula el total de productos (suma de cantidades)
  int get totalQuantity =>
      result.productGroups.fold(0, (sum, group) => sum + group.quantity);

  /// Verifica si hay productos sin confirmar
  bool get hasUnconfirmedProducts => unconfirmedProducts.isNotEmpty;

  /// Obtiene el tiempo de procesamiento en segundos
  double get processingTimeSeconds => result.processingTimeMs / 1000.0;
}

/// Error en detección múltiple
class MultipleDetectionError extends MultipleDetectionState {
  final String message;
  final dynamic error;

  const MultipleDetectionError({
    required this.message,
    this.error,
  });

  @override
  List<Object?> get props => [message, error];
}

/// Estado cuando el usuario está modificando la selección de productos
class MultipleDetectionEditingSelection extends MultipleDetectionState {
  final MultipleProductDetectionResult result;
  final List<DetectedProductGroup> selectedGroups;
  final List<int> modifiedQuantities;

  const MultipleDetectionEditingSelection({
    required this.result,
    required this.selectedGroups,
    this.modifiedQuantities = const [],
  });

  @override
  List<Object?> get props => [result, selectedGroups, modifiedQuantities];

  /// Copia el estado con nuevos valores
  MultipleDetectionEditingSelection copyWith({
    MultipleProductDetectionResult? result,
    List<DetectedProductGroup>? selectedGroups,
    List<int>? modifiedQuantities,
  }) {
    return MultipleDetectionEditingSelection(
      result: result ?? this.result,
      selectedGroups: selectedGroups ?? this.selectedGroups,
      modifiedQuantities: modifiedQuantities ?? this.modifiedQuantities,
    );
  }

  /// Verifica si un grupo está seleccionado
  bool isGroupSelected(DetectedProductGroup group) {
    return selectedGroups.any(
      (selected) => selected.product.id == group.product.id,
    );
  }

  /// Obtiene la cantidad modificada para un grupo (o la original)
  int getQuantityForGroup(DetectedProductGroup group) {
    final index = result.productGroups.indexOf(group);
    if (index >= 0 && index < modifiedQuantities.length) {
      return modifiedQuantities[index];
    }
    return group.quantity;
  }

  /// Calcula el total de productos seleccionados
  int get totalSelectedQuantity => selectedGroups.fold(
        0,
        (sum, group) => sum + getQuantityForGroup(group),
      );
}
