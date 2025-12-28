import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/menu/product_model.dart';
import '../../services/menu/product_service.dart';

sealed class ProductState {}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final List<ProductModel> products;
  final int currentPage;
  final bool hasMoreData;
  final bool isLoadingMore;

  ProductLoaded(
    this.products, {
    this.currentPage = 0,
    this.hasMoreData = true,
    this.isLoadingMore = false,
  });

  ProductLoaded copyWith({
    List<ProductModel>? products,
    int? currentPage,
    bool? hasMoreData,
    bool? isLoadingMore,
  }) {
    return ProductLoaded(
      products ?? this.products,
      currentPage: currentPage ?? this.currentPage,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class SingleProductLoaded extends ProductState {
  final ProductModel product;

  SingleProductLoaded(this.product);
}

class ProductCubit extends Cubit<ProductState> {
  final ProductService productService;
  List<ProductModel> _products = [];
  int _currentPage = 0;
  static const int _pageSize = 20;

  ProductCubit(this.productService) : super(ProductInitial());

  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh || state is ProductInitial) {
      _currentPage = 0;
      _products.clear();
      emit(ProductLoading());
    }

    try {
      final newProducts =
          await productService.getAll(page: _currentPage, size: _pageSize);

      if (refresh || _products.isEmpty) {
        _products = newProducts;
      } else {
        _products.addAll(newProducts);
      }

      final hasMoreData = newProducts.length >= _pageSize;
      emit(ProductLoaded(
        List.unmodifiable(_products),
        currentPage: _currentPage,
        hasMoreData: hasMoreData,
        isLoadingMore: false,
      ));
    } catch (e) {
      if (!isClosed) {
        emit(ProductInitial());
      }
      rethrow;
    }
  }

  Future<void> loadMoreProducts() async {
    final currentState = state;
    if (currentState is ProductLoaded &&
        !currentState.isLoadingMore &&
        currentState.hasMoreData) {
      emit(currentState.copyWith(isLoadingMore: true));

      try {
        _currentPage++;
        final newProducts =
            await productService.getAll(page: _currentPage, size: _pageSize);

        _products.addAll(newProducts);
        final hasMoreData = newProducts.length >= _pageSize;

        emit(ProductLoaded(
          List.unmodifiable(_products),
          currentPage: _currentPage,
          hasMoreData: hasMoreData,
          isLoadingMore: false,
        ));
      } catch (e) {
        _currentPage--; // Revertir el incremento en caso de error
        if (!isClosed) {
          emit(currentState.copyWith(isLoadingMore: false));
        }
        rethrow;
      }
    }
  }

  /// Crea un producto usando el reconocimiento de imagen con form-data
  Future<void> createProductWithRecognition({
    required String name,
    String? description,
    Uint8List? imageBytes,
    required int categoryId,
    int? stockMinimum,
    DateTime? expirationDate,
  }) async {
    await productService.createWithRecognition(
      name: name,
      description: description,
      imageBytes: imageBytes,
      categoryId: categoryId,
      stockMinimum: stockMinimum,
      expirationDate: expirationDate,
    );
  }

  Future<void> updateProduct(ProductModel product) async {
    await productService.update(product.id!, product);
  }

  Future<void> deleteProduct(int id) async {
    await productService.delete(id);
  }

  Future<void> getProductById(int id) async {
    emit(ProductLoading());
    try {
      final product = await productService.getById(id);
      emit(SingleProductLoaded(product));
    } catch (e) {
      if (!isClosed) {
        emit(ProductInitial());
      }
      rethrow;
    }
  }

  Future<void> findByName(String name, {int page = 0, int size = 10}) async {
    emit(ProductLoading());
    try {
      final result =
          await productService.findByName(name, page: page, size: size);
      emit(ProductLoaded(List.unmodifiable(result)));
    } catch (e) {
      if (!isClosed) {
        emit(ProductInitial());
      }
      rethrow;
    }
  }

  Future<void> findByCategoryId(int categoryId,
      {int page = 0, int size = 10}) async {
    emit(ProductLoading());
    try {
      final result = await productService.findByCategoryId(categoryId,
          page: page, size: size);
      emit(ProductLoaded(List.unmodifiable(result)));
    } catch (e) {
      if (!isClosed) {
        emit(ProductInitial());
      }
      rethrow;
    }
  }

  Future<void> findByStockQuantityGreaterThan(int quantity,
      {int page = 0, int size = 10}) async {
    emit(ProductLoading());
    try {
      final result = await productService
          .findByStockQuantityGreaterThan(quantity, page: page, size: size);
      emit(ProductLoaded(List.unmodifiable(result)));
    } catch (e) {
      if (!isClosed) {
        emit(ProductInitial());
      }
      rethrow;
    }
  }

  Future<void> findByExpirationDateBefore(DateTime expirationDate,
      {int page = 0, int size = 10}) async {
    emit(ProductLoading());
    try {
      final result = await productService
          .findByExpirationDateBefore(expirationDate, page: page, size: size);
      emit(ProductLoaded(List.unmodifiable(result)));
    } catch (e) {
      if (!isClosed) {
        emit(ProductInitial());
      }
      rethrow;
    }
  }

  void resetState() {
    emit(ProductInitial());
  }
}
