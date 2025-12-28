import 'package:equatable/equatable.dart';

import '../../models/menu/person_model.dart';
import '../../models/product_stock/product_stock_model.dart';

abstract class ProductStockState extends Equatable {
  const ProductStockState();

  @override
  List<Object?> get props => [];
}

class ProductStockInitial extends ProductStockState {}

class ProductStockLoading extends ProductStockState {}

class ProductStockLoaded extends ProductStockState {
  final PersonModel? selectedProvider;
  final List<ProductStockEntry> entries;
  final bool isNewRecordMode;

  const ProductStockLoaded({
    required this.entries,
    this.selectedProvider,
    this.isNewRecordMode = true,
  });

  @override
  List<Object?> get props => [
        selectedProvider,
        entries,
        isNewRecordMode,
      ];

  ProductStockLoaded copyWith({
    PersonModel? selectedProvider,
    List<ProductStockEntry>? entries,
    bool? isNewRecordMode,
    bool clearProvider = false,
  }) {
    return ProductStockLoaded(
      selectedProvider:
          clearProvider ? null : (selectedProvider ?? this.selectedProvider),
      entries: entries ?? this.entries,
      isNewRecordMode: isNewRecordMode ?? this.isNewRecordMode,
    );
  }

  int get totalItems => entries.length;

  int get totalQuantity =>
      entries.fold<int>(0, (sum, entry) => sum + entry.stock.quantity);

  double get totalEntryValue => entries.fold<double>(
        0,
        (sum, entry) => sum + (entry.stock.entryPrice * entry.stock.quantity),
      );

  double get totalSaleValue => entries.fold<double>(
        0,
        (sum, entry) => sum + (entry.stock.salePrice * entry.stock.quantity),
      );

  bool get hasEntries => entries.isNotEmpty;

  bool get hasProvider => selectedProvider != null;
}

class ProductStockProcessing extends ProductStockState {}

class ProductStockProcessed extends ProductStockState {
  final ProductStockModel payload;

  const ProductStockProcessed({required this.payload});

  @override
  List<Object?> get props => [payload];
}

class ProductStockError extends ProductStockState {
  final String message;

  const ProductStockError(this.message);

  @override
  List<Object?> get props => [message];
}
