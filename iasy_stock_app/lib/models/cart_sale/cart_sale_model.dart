import 'package:freezed_annotation/freezed_annotation.dart';

import '../menu/sale_item_model.dart';
import '../menu/sale_model.dart';

part 'cart_sale_model.freezed.dart';
part 'cart_sale_model.g.dart';

@freezed
class CartSaleModel with _$CartSaleModel {
  const factory CartSaleModel({
    required SaleModel sale,
    required List<SaleItemModel> saleItems,
  }) = _CartSaleModel;

  factory CartSaleModel.fromJson(Map<String, dynamic> json) =>
      _$CartSaleModelFromJson(json);

  const CartSaleModel._();

  /// Valida que el modelo esté completo y listo para enviar al backend
  ValidationResult validateForBackend() {
    final errors = <String>[];

    // Validar la venta
    if (sale.userId <= 0) {
      errors.add('El ID del usuario es requerido');
    }

    if (sale.totalAmount <= 0) {
      errors.add('El monto total debe ser mayor a cero');
    }

    if (sale.saleDate == null) {
      errors.add('La fecha de venta es requerida');
    }

    if (sale.payMethod == null || sale.payMethod!.isEmpty) {
      errors.add('El método de pago es requerido');
    }

    if (sale.state == null || sale.state!.isEmpty) {
      errors.add('El estado de la venta es requerido');
    }

    // Validar los items de venta
    if (saleItems.isEmpty) {
      errors.add('Debe haber al menos un producto en la venta');
    }

    for (int i = 0; i < saleItems.length; i++) {
      final item = saleItems[i];
      final itemPrefix = 'Item ${i + 1}';

      if (item.productId <= 0) {
        errors.add('$itemPrefix: El ID del producto es requerido');
      }

      if (item.quantity <= 0) {
        errors.add('$itemPrefix: La cantidad debe ser mayor a cero');
      }

      if (item.unitPrice <= 0) {
        errors.add('$itemPrefix: El precio unitario debe ser mayor a cero');
      }

      if (item.totalPrice <= 0) {
        errors.add('$itemPrefix: El precio total debe ser mayor a cero');
      }

      // Validar que el precio total sea consistente
      final calculatedTotal = item.unitPrice * item.quantity;
      if ((item.totalPrice - calculatedTotal).abs() > 0.01) {
        errors.add(
            '$itemPrefix: El precio total no coincide con cantidad × precio unitario');
      }
    }

    // Validar que el total de la venta coincida con la suma de los items
    final calculatedTotal =
        saleItems.fold<double>(0, (sum, item) => sum + item.totalPrice);
    if ((sale.totalAmount - calculatedTotal).abs() > 0.01) {
      errors.add('El total de la venta no coincide con la suma de los items');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Valida que el modelo esté listo para guardar como venta pendiente
  ValidationResult validateForPendingSave() {
    final errors = <String>[];

    // Para ventas pendientes, algunos campos pueden ser opcionales
    if (sale.userId <= 0) {
      errors.add('El ID del usuario es requerido');
    }

    if (saleItems.isEmpty) {
      errors.add('Debe haber al menos un producto en la venta');
    }

    // Validar items básicos
    for (int i = 0; i < saleItems.length; i++) {
      final item = saleItems[i];
      final itemPrefix = 'Item ${i + 1}';

      if (item.productId <= 0) {
        errors.add('$itemPrefix: El ID del producto es requerido');
      }

      if (item.quantity <= 0) {
        errors.add('$itemPrefix: La cantidad debe ser mayor a cero');
      }

      if (item.unitPrice <= 0) {
        errors.add('$itemPrefix: El precio unitario debe ser mayor a cero');
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}

/// Resultado de validación
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  const ValidationResult({
    required this.isValid,
    required this.errors,
  });

  /// Obtiene el mensaje de error principal
  String get errorMessage => errors.isNotEmpty ? errors.first : '';

  /// Obtiene todos los errores como un mensaje concatenado
  String get allErrorsMessage => errors.join('\n');
}
