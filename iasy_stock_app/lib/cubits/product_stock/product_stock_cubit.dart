import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/menu/person_model.dart';
import '../../models/menu/product_model.dart';
import '../../models/menu/stock_model.dart';
import '../../models/product_stock/product_stock_model.dart';
import '../../services/product_stock/product_stock_service.dart';
import 'product_stock_state.dart';

class ProductStockCubit extends Cubit<ProductStockState> {
  ProductStockCubit({required ProductStockService service})
      : _service = service,
        super(_initialState());

  final ProductStockService _service;
  static const int _defaultUserId = 1; // TODO: leer del usuario autenticado

  static ProductStockState _initialState() => const ProductStockLoaded(
        entries: [],
        selectedProvider: null,
        isNewRecordMode: true,
      );

  void startNewRecord() {
    emit(_initialState());
  }

  void selectProvider(PersonModel provider) {
    if (state is ProductStockLoaded) {
      final current = state as ProductStockLoaded;

      final updatedEntries = current.entries
          .map((entry) => entry.copyWith(
                stock: entry.stock.copyWith(personId: provider.id),
              ))
          .toList();

      emit(current.copyWith(
        selectedProvider: provider,
        entries: updatedEntries,
      ));
    }
  }

  void clearProvider() {
    if (state is ProductStockLoaded) {
      final current = state as ProductStockLoaded;
      final updatedEntries = current.entries
          .map((entry) => entry.copyWith(
                stock: entry.stock.copyWith(personId: null),
              ))
          .toList();

      emit(current.copyWith(
        clearProvider: true,
        entries: updatedEntries,
      ));
    }
  }

  void addProductStockEntry({
    required ProductModel product,
    required int quantity,
    required double entryPrice,
    required double salePrice,
    required int warehouseId,
    DateTime? entryDate,
  }) {
    if (state is! ProductStockLoaded) return;
    final current = state as ProductStockLoaded;

    if (product.id == null) {
      emit(const ProductStockError('Producto inválido'));
      return;
    }

    final stock = StockModel(
      quantity: quantity,
      entryPrice: entryPrice,
      salePrice: salePrice,
      productId: product.id!,
      userId: _defaultUserId,
      warehouseId: warehouseId,
      personId: current.selectedProvider?.id,
      entryDate: entryDate ?? DateTime.now(),
      createdAt: DateTime.now(),
    );

    final entry = ProductStockEntry(product: product, stock: stock);
    final updatedEntries = [...current.entries, entry];

    emit(current.copyWith(entries: updatedEntries));
  }

  void updateProductStockEntry(
    int index, {
    ProductModel? product,
    int? quantity,
    double? entryPrice,
    double? salePrice,
    int? warehouseId,
    DateTime? entryDate,
  }) {
    if (state is! ProductStockLoaded) return;
    final current = state as ProductStockLoaded;

    if (index < 0 || index >= current.entries.length) return;

    final currentEntry = current.entries[index];
    final updatedStock = currentEntry.stock.copyWith(
      quantity: quantity ?? currentEntry.stock.quantity,
      entryPrice: entryPrice ?? currentEntry.stock.entryPrice,
      salePrice: salePrice ?? currentEntry.stock.salePrice,
      productId: product?.id ?? currentEntry.stock.productId,
      warehouseId: warehouseId ?? currentEntry.stock.warehouseId,
      entryDate: entryDate ?? currentEntry.stock.entryDate,
      personId: current.selectedProvider?.id ?? currentEntry.stock.personId,
      userId: currentEntry.stock.userId == 0
          ? _defaultUserId
          : currentEntry.stock.userId,
    );

    final updatedEntry = ProductStockEntry(
      product: product ?? currentEntry.product,
      stock: updatedStock,
    );

    final updatedEntries = List<ProductStockEntry>.from(current.entries);
    updatedEntries[index] = updatedEntry;

    emit(current.copyWith(entries: updatedEntries));
  }

  void removeEntry(int index) {
    if (state is! ProductStockLoaded) return;
    final current = state as ProductStockLoaded;

    if (index < 0 || index >= current.entries.length) return;

    final updatedEntries = List<ProductStockEntry>.from(current.entries)
      ..removeAt(index);

    emit(current.copyWith(entries: updatedEntries));
  }

  void clearEntries() {
    if (state is ProductStockLoaded) {
      final current = state as ProductStockLoaded;
      emit(current.copyWith(entries: const []));
    }
  }

  Future<void> processProductStock() async {
    if (state is! ProductStockLoaded) return;
    final current = state as ProductStockLoaded;

    if (current.entries.isEmpty) {
      emit(const ProductStockError('Agregue al menos un registro de stock'));
      return;
    }

    emit(ProductStockProcessing());

    try {
      // Agrupar por producto para enviar al backend
      final Map<int, List<ProductStockEntry>> groupedByProduct = {};

      for (var entry in current.entries) {
        final productId = entry.product.id!;
        if (!groupedByProduct.containsKey(productId)) {
          groupedByProduct[productId] = [];
        }
        groupedByProduct[productId]!.add(entry);
      }

      // Procesar cada grupo de producto
      for (var productEntries in groupedByProduct.values) {
        final product = productEntries.first.product;
        final stocks = productEntries.map((e) => e.stock).toList();

        final payload = ProductStockModel(
          product: product,
          stocks: stocks,
        );

        final validation = payload.validateForBackend();
        if (!validation.isValid) {
          emit(ProductStockError(validation.errorMessage));
          return;
        }

        await _service.processProductStock(payload: payload);
      }

      if (isClosed) return;

      emit(ProductStockProcessed(
        payload: ProductStockModel(
          product: current.entries.first.product,
          stocks: current.entries.map((e) => e.stock).toList(),
        ),
      ));

      await Future.delayed(const Duration(milliseconds: 350));
      if (!isClosed) {
        startNewRecord();
      }
    } catch (e) {
      if (!isClosed) {
        emit(ProductStockError('Error al procesar el stock: $e'));
      }
    }
  }

  Future<List<StockModel>> loadStockHistory(int productId) =>
      _service.getStockHistoryByProduct(productId);
}
