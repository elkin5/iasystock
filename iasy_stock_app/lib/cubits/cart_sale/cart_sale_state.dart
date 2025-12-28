import 'package:equatable/equatable.dart';

import '../../models/menu/person_model.dart';
import '../../models/menu/product_model.dart';
import '../../models/menu/sale_item_model.dart';
import '../../models/menu/sale_model.dart';

/// Estado del carrito de compras que maneja la venta en progreso
abstract class CartSaleState extends Equatable {
  const CartSaleState();

  @override
  List<Object?> get props => [];
}

class CartSaleInitial extends CartSaleState {}

class CartSaleLoading extends CartSaleState {}

class CartSaleLoaded extends CartSaleState {
  final SaleModel sale;
  final List<SaleItemModel> saleItems;
  final Map<int, ProductModel> products; // Mapa de productos por ID
  final PersonModel? selectedClient;
  final bool isNewSaleMode;
  final bool isResumeSaleMode;

  const CartSaleLoaded({
    required this.sale,
    required this.saleItems,
    required this.products,
    this.selectedClient,
    this.isNewSaleMode = false,
    this.isResumeSaleMode = false,
  });

  @override
  List<Object?> get props => [
        sale,
        saleItems,
        products,
        selectedClient,
        isNewSaleMode,
        isResumeSaleMode,
      ];

  CartSaleLoaded copyWith({
    SaleModel? sale,
    List<SaleItemModel>? saleItems,
    Map<int, ProductModel>? products,
    PersonModel? selectedClient,
    bool? isNewSaleMode,
    bool? isResumeSaleMode,
  }) {
    return CartSaleLoaded(
      sale: sale ?? this.sale,
      saleItems: saleItems ?? this.saleItems,
      products: products ?? this.products,
      selectedClient: selectedClient ?? this.selectedClient,
      isNewSaleMode: isNewSaleMode ?? this.isNewSaleMode,
      isResumeSaleMode: isResumeSaleMode ?? this.isResumeSaleMode,
    );
  }

  // Propiedades calculadas
  int get totalItems => saleItems.length;

  int get totalQuantity =>
      saleItems.fold<int>(0, (sum, item) => sum + item.quantity);

  double get totalValue => sale.totalAmount;

  bool get hasItems => saleItems.isNotEmpty;

  bool get hasClient => selectedClient != null;
}

class CartSaleError extends CartSaleState {
  final String message;

  const CartSaleError({required this.message});

  @override
  List<Object> get props => [message];
}

class CartSaleSaving extends CartSaleState {}

class CartSaleSaved extends CartSaleState {
  final SaleModel savedSale;
  final List<SaleItemModel> savedItems;

  const CartSaleSaved({
    required this.savedSale,
    required this.savedItems,
  });

  @override
  List<Object> get props => [savedSale, savedItems];
}

class CartSalePaymentProcessing extends CartSaleState {}

class CartSalePaymentCompleted extends CartSaleState {
  final SaleModel completedSale;
  final String transactionId;

  const CartSalePaymentCompleted({
    required this.completedSale,
    required this.transactionId,
  });

  @override
  List<Object> get props => [completedSale, transactionId];
}
