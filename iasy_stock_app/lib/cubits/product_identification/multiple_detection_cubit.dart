import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../models/product_identification/product_identification_models.dart';
import '../../services/product_identification/product_identification_service.dart';
import 'multiple_detection_state.dart';

final Logger _cubitLog = Logger();

/// Cubit para manejar el estado de detección múltiple de productos
///
/// Funcionalidades:
/// - Detectar múltiples productos en una sola imagen usando YOLO + CLIP
/// - Permitir edición de selección y cantidades
/// - Confirmar productos detectados para agregar a stock/venta
class MultipleDetectionCubit extends Cubit<MultipleDetectionState> {
  final ProductIdentificationService _service;

  MultipleDetectionCubit({
    required ProductIdentificationService service,
  })  : _service = service,
        super(MultipleDetectionInitial());

  /// Detecta múltiples productos en una imagen
  ///
  /// Flujo:
  /// 1. Backend usa YOLO para detectar objetos
  /// 2. Para cada objeto detectado, identifica el producto
  /// 3. Agrupa productos por ID y calcula cantidades
  /// 4. Retorna lista con bounding boxes y confianzas
  ///
  /// [imageBytes] - Bytes de la imagen (compatible con web y móvil)
  /// [imageName] - Nombre del archivo de imagen (para detectar formato)
  /// [source] - Fuente de la detección (default: MOBILE_APP)
  /// [userId] - ID del usuario (opcional)
  /// [groupByProduct] - Agrupar productos del mismo tipo (default: true)
  /// [minConfidence] - Confianza mínima para aceptar (opcional)
  Future<void> detectMultipleProducts({
    required Uint8List imageBytes,
    String imageName = 'image.jpg',
    String source = 'MOBILE_APP',
    int? userId,
    bool groupByProduct = true,
    double? minConfidence,
  }) async {
    _cubitLog.d(
      'Iniciando detección múltiple desde imagen: $imageName',
    );

    emit(const MultipleDetectionProcessing(
      message: 'Detectando productos en la imagen...',
    ));

    try {
      final result = await _service.identifyMultipleProducts(
        imageBytes: imageBytes,
        imageName: imageName,
        source: source,
        userId: userId,
        groupByProduct: groupByProduct,
        minConfidence: minConfidence,
      );

      _cubitLog.i(
        '✅ Detección múltiple completada: '
        'totalDetections=${result.totalDetections}, '
        'uniqueProducts=${result.uniqueProducts}',
      );

      // Log de cada producto detectado
      for (final group in result.productGroups) {
        _cubitLog.d(
          '   📦 ${group.product.name}: '
          'cantidad=${group.quantity}, '
          'confianza=${(group.averageConfidence * 100).toStringAsFixed(1)}%, '
          'confirmado=${group.isConfirmed}',
        );
      }

      emit(MultipleDetectionSuccess(result: result));
    } catch (e, stackTrace) {
      _cubitLog.e(
        '❌ Error en detección múltiple: $e',
        error: e,
        stackTrace: stackTrace,
      );

      final errorMessage = _extractErrorMessage(e);

      emit(MultipleDetectionError(
        message: errorMessage,
        error: e,
      ));
    }
  }

  /// Permite al usuario editar la selección de productos detectados
  ///
  /// Cambia el estado a modo edición donde el usuario puede:
  /// - Marcar/desmarcar productos
  /// - Modificar cantidades
  /// - Confirmar o rechazar detecciones
  void startEditingSelection() {
    if (state is MultipleDetectionSuccess) {
      final successState = state as MultipleDetectionSuccess;

      // Por defecto, seleccionar solo los productos confirmados
      final selectedGroups = successState.confirmedProducts;

      // Inicializar cantidades modificadas con las cantidades originales
      final modifiedQuantities = successState.result.productGroups
          .map((group) => group.quantity)
          .toList();

      _cubitLog.d('Iniciando edición de selección');

      emit(MultipleDetectionEditingSelection(
        result: successState.result,
        selectedGroups: selectedGroups,
        modifiedQuantities: modifiedQuantities,
      ));
    }
  }

  /// Alterna la selección de un grupo de productos
  ///
  /// [group] - Grupo a marcar/desmarcar
  void toggleGroupSelection(DetectedProductGroup group) {
    if (state is! MultipleDetectionEditingSelection) return;

    final editState = state as MultipleDetectionEditingSelection;

    final isCurrentlySelected = editState.isGroupSelected(group);
    final newSelectedGroups = List<DetectedProductGroup>.from(
      editState.selectedGroups,
    );

    if (isCurrentlySelected) {
      // Desmarcar: remover de la lista
      newSelectedGroups.removeWhere(
        (selected) => selected.product.id == group.product.id,
      );
      _cubitLog.d('Producto desmarcado: ${group.product.name}');
    } else {
      // Marcar: agregar a la lista
      newSelectedGroups.add(group);
      _cubitLog.d('Producto marcado: ${group.product.name}');
    }

    emit(editState.copyWith(selectedGroups: newSelectedGroups));
  }

  /// Actualiza la cantidad de un grupo de productos
  ///
  /// [group] - Grupo a modificar
  /// [newQuantity] - Nueva cantidad (debe ser >= 0)
  void updateGroupQuantity(DetectedProductGroup group, int newQuantity) {
    if (state is! MultipleDetectionEditingSelection) return;
    if (newQuantity < 0) return;

    final editState = state as MultipleDetectionEditingSelection;
    final groupIndex = editState.result.productGroups.indexOf(group);

    if (groupIndex < 0) return;

    final newModifiedQuantities = List<int>.from(
      editState.modifiedQuantities,
    );

    // Asegurar que la lista tenga el tamaño correcto
    while (newModifiedQuantities.length <= groupIndex) {
      newModifiedQuantities.add(0);
    }

    newModifiedQuantities[groupIndex] = newQuantity;

    _cubitLog.d(
      'Cantidad modificada para ${group.product.name}: $newQuantity',
    );

    emit(editState.copyWith(modifiedQuantities: newModifiedQuantities));
  }

  /// Incrementa la cantidad de un producto
  ///
  /// [group] - Grupo a incrementar
  void incrementQuantity(DetectedProductGroup group) {
    if (state is! MultipleDetectionEditingSelection) return;

    final editState = state as MultipleDetectionEditingSelection;
    final currentQuantity = editState.getQuantityForGroup(group);

    updateGroupQuantity(group, currentQuantity + 1);
  }

  /// Decrementa la cantidad de un producto
  ///
  /// [group] - Grupo a decrementar
  void decrementQuantity(DetectedProductGroup group) {
    if (state is! MultipleDetectionEditingSelection) return;

    final editState = state as MultipleDetectionEditingSelection;
    final currentQuantity = editState.getQuantityForGroup(group);

    if (currentQuantity > 0) {
      updateGroupQuantity(group, currentQuantity - 1);
    }
  }

  /// Confirma la selección editada y vuelve al estado de éxito
  ///
  /// Los productos seleccionados y sus cantidades modificadas están listos
  /// para ser usados en el siguiente paso (agregar a stock/venta)
  void confirmSelection() {
    if (state is! MultipleDetectionEditingSelection) return;

    final editState = state as MultipleDetectionEditingSelection;

    _cubitLog.i(
      '✅ Selección confirmada: ${editState.selectedGroups.length} productos, '
      'total: ${editState.totalSelectedQuantity} items',
    );

    // Crear un nuevo resultado con solo los grupos seleccionados y cantidades modificadas
    final updatedGroups = editState.selectedGroups.map((group) {
      final quantity = editState.getQuantityForGroup(group);
      return DetectedProductGroup(
        product: group.product,
        quantity: quantity,
        averageConfidence: group.averageConfidence,
        detections: group.detections,
        isConfirmed: group.isConfirmed,
      );
    }).toList();

    final updatedResult = MultipleProductDetectionResult(
      status: editState.result.status,
      productGroups: updatedGroups,
      totalDetections: editState.result.totalDetections,
      uniqueProducts: updatedGroups.length,
      requiresValidation: updatedGroups.any((g) => !g.isConfirmed),
      processingTimeMs: editState.result.processingTimeMs,
      metadata: editState.result.metadata,
    );

    emit(MultipleDetectionSuccess(result: updatedResult));
  }

  /// Cancela la edición y vuelve al estado de éxito original
  void cancelEditing() {
    if (state is! MultipleDetectionEditingSelection) return;

    final editState = state as MultipleDetectionEditingSelection;

    _cubitLog.d('Edición cancelada');

    emit(MultipleDetectionSuccess(result: editState.result));
  }

  /// Selecciona todos los productos detectados
  void selectAll() {
    if (state is! MultipleDetectionEditingSelection) return;

    final editState = state as MultipleDetectionEditingSelection;

    _cubitLog.d('Seleccionando todos los productos');

    emit(editState.copyWith(
      selectedGroups: List.from(editState.result.productGroups),
    ));
  }

  /// Deselecciona todos los productos
  void deselectAll() {
    if (state is! MultipleDetectionEditingSelection) return;

    final editState = state as MultipleDetectionEditingSelection;

    _cubitLog.d('Deseleccionando todos los productos');

    emit(editState.copyWith(selectedGroups: []));
  }

  /// Resetea el cubit al estado inicial
  void reset() {
    _cubitLog.d('Reseteando cubit');
    emit(MultipleDetectionInitial());
  }

  /// Extrae un mensaje de error legible desde una excepción
  String _extractErrorMessage(dynamic error) {
    if (error is Exception) {
      final message = error.toString();
      if (message.contains('Exception:')) {
        return message.split('Exception:').last.trim();
      }
      return message;
    }
    return 'Error inesperado en detección múltiple';
  }
}
