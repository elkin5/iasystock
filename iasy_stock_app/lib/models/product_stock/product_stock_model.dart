import '../menu/product_model.dart';
import '../menu/stock_model.dart';

/// Representa una entrada individual de producto + stock en la UI
class ProductStockEntry {
  final ProductModel product;
  final StockModel stock;

  const ProductStockEntry({
    required this.product,
    required this.stock,
  });

  ProductStockEntry copyWith({
    ProductModel? product,
    StockModel? stock,
  }) {
    return ProductStockEntry(
      product: product ?? this.product,
      stock: stock ?? this.stock,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductStockEntry &&
          runtimeType == other.runtimeType &&
          product == other.product &&
          stock == other.stock;

  @override
  int get hashCode => product.hashCode ^ stock.hashCode;
}

class ProductStockModel {
  final ProductModel product;
  final List<StockModel> stocks;

  const ProductStockModel({
    required this.product,
    required this.stocks,
  });

  factory ProductStockModel.fromJson(Map<String, dynamic> json) {
    final productJson = json['product'] as Map<String, dynamic>?;
    if (productJson == null) {
      throw ArgumentError('product no encontrado en la respuesta del backend');
    }
    final stocksJson = json['stocks'] as List<dynamic>? ?? [];

    return ProductStockModel(
      product: ProductModel.fromJson(productJson),
      stocks: stocksJson
          .map((item) => StockModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'stocks': stocks.map((s) => s.toJson()).toList(),
      };

  ValidationResult validateForBackend() {
    final errors = <String>[];

    if (product.id == null || product.id! <= 0) {
      errors.add('El producto seleccionado es inválido');
    }

    if (stocks.isEmpty) {
      errors.add('Debe registrar al menos un movimiento de stock');
    }

    for (int i = 0; i < stocks.length; i++) {
      final stock = stocks[i];
      final prefix = 'Registro ${i + 1}';

      if (stock.quantity <= 0) {
        errors.add('$prefix: la cantidad debe ser mayor a cero');
      }

      if (stock.entryPrice <= 0) {
        errors.add('$prefix: el precio de entrada debe ser mayor a cero');
      }

      if (stock.salePrice <= stock.entryPrice) {
        errors.add(
            '$prefix: el precio de venta debe ser mayor al precio de entrada');
      }

      if (stock.productId <= 0) {
        errors.add('$prefix: el identificador del producto es requerido');
      }

      if (stock.userId <= 0) {
        errors.add('$prefix: el usuario responsable es requerido');
      }

      if (stock.warehouseId == null || stock.warehouseId! <= 0) {
        errors.add('$prefix: debe seleccionar un almacén');
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;

  const ValidationResult({
    required this.isValid,
    required this.errors,
  });

  String get errorMessage => errors.isNotEmpty ? errors.first : '';

  String get allErrorsMessage => errors.join('\n');
}
