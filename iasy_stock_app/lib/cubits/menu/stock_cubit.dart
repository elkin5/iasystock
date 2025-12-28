import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/menu/stock_model.dart';
import '../../services/menu/stock_service.dart';

sealed class StockState {}

class StockInitial extends StockState {}

class StockLoading extends StockState {}

class StockLoaded extends StockState {
  final List<StockModel> stocks;
  final int currentPage;
  final bool hasMoreData;
  final bool isLoadingMore;

  StockLoaded(
    this.stocks, {
    this.currentPage = 0,
    this.hasMoreData = true,
    this.isLoadingMore = false,
  });

  StockLoaded copyWith({
    List<StockModel>? stocks,
    int? currentPage,
    bool? hasMoreData,
    bool? isLoadingMore,
  }) {
    return StockLoaded(
      stocks ?? this.stocks,
      currentPage: currentPage ?? this.currentPage,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class SingleStockLoaded extends StockState {
  final StockModel stock;

  SingleStockLoaded(this.stock);
}

class StockCubit extends Cubit<StockState> {
  final StockService stockService;
  List<StockModel> _stocks = [];
  int _currentPage = 0;
  static const int _pageSize = 20;

  StockCubit(this.stockService) : super(StockInitial());

  Future<void> loadStocks({bool refresh = false}) async {
    if (refresh || state is StockInitial) {
      _currentPage = 0;
      _stocks.clear();
      emit(StockLoading());
    }

    try {
      final newStocks =
          await stockService.getAll(page: _currentPage, size: _pageSize);

      if (refresh || _stocks.isEmpty) {
        _stocks = newStocks;
      } else {
        _stocks.addAll(newStocks);
      }

      final hasMoreData = newStocks.length >= _pageSize;
      emit(StockLoaded(
        List.unmodifiable(_stocks),
        currentPage: _currentPage,
        hasMoreData: hasMoreData,
        isLoadingMore: false,
      ));
    } catch (e) {
      if (!isClosed) {
        emit(StockInitial());
      }
      rethrow;
    }
  }

  Future<void> loadMoreStocks() async {
    final currentState = state;
    if (currentState is StockLoaded &&
        !currentState.isLoadingMore &&
        currentState.hasMoreData) {
      emit(currentState.copyWith(isLoadingMore: true));

      try {
        _currentPage++;
        final newStocks =
            await stockService.getAll(page: _currentPage, size: _pageSize);

        _stocks.addAll(newStocks);
        final hasMoreData = newStocks.length >= _pageSize;

        emit(StockLoaded(
          List.unmodifiable(_stocks),
          currentPage: _currentPage,
          hasMoreData: hasMoreData,
          isLoadingMore: false,
        ));
      } catch (e) {
        _currentPage--;
        if (!isClosed) {
          emit(currentState.copyWith(isLoadingMore: false));
        }
        rethrow;
      }
    }
  }

  Future<void> createStock(StockModel stock) async {
    await stockService.create(stock);
  }

  Future<void> updateStock(int id, StockModel stock) async {
    await stockService.update(id, stock);
  }

  Future<void> deleteStock(int id) async {
    await stockService.delete(id);
  }

  Future<void> findByPersonId(int personId,
      {int page = 0, int size = 10}) async {
    emit(StockLoading());
    try {
      final result =
          await stockService.findByPersonId(personId, page: page, size: size);
      emit(StockLoaded(List.unmodifiable(result)));
    } catch (e) {
      if (!isClosed) {
        emit(StockInitial());
      }
      rethrow;
    }
  }

  Future<void> getStockById(int id) async {
    emit(StockLoading());
    try {
      final stock = await stockService.getById(id);
      emit(SingleStockLoaded(stock));
    } catch (e) {
      if (!isClosed) {
        emit(StockInitial());
      }
      rethrow;
    }
  }

  Future<void> findByProductId(int productId,
      {int page = 0, int size = 10}) async {
    emit(StockLoading());
    try {
      final result =
          await stockService.findByProductId(productId, page: page, size: size);
      emit(StockLoaded(List.unmodifiable(result)));
    } catch (e) {
      if (!isClosed) {
        emit(StockInitial());
      }
      rethrow;
    }
  }

  Future<void> findByWarehouseId(int warehouseId,
      {int page = 0, int size = 10}) async {
    emit(StockLoading());
    try {
      final result = await stockService.findByWarehouseId(warehouseId,
          page: page, size: size);
      emit(StockLoaded(List.unmodifiable(result)));
    } catch (e) {
      if (!isClosed) {
        emit(StockInitial());
      }
      rethrow;
    }
  }

  Future<void> findByUserId(int userId, {int page = 0, int size = 10}) async {
    emit(StockLoading());
    try {
      final result =
          await stockService.findByUserId(userId, page: page, size: size);
      emit(StockLoaded(List.unmodifiable(result)));
    } catch (e) {
      if (!isClosed) {
        emit(StockInitial());
      }
      rethrow;
    }
  }

  Future<void> findByEntryDate(String entryDate,
      {int page = 0, int size = 10}) async {
    emit(StockLoading());
    try {
      final result =
          await stockService.findByEntryDate(entryDate, page: page, size: size);
      emit(StockLoaded(List.unmodifiable(result)));
    } catch (e) {
      if (!isClosed) {
        emit(StockInitial());
      }
      rethrow;
    }
  }

  Future<void> findByQuantityGreaterThan(int quantity,
      {int page = 0, int size = 10}) async {
    emit(StockLoading());
    try {
      final result = await stockService.findByQuantityGreaterThan(quantity,
          page: page, size: size);
      emit(StockLoaded(List.unmodifiable(result)));
    } catch (e) {
      if (!isClosed) {
        emit(StockInitial());
      }
      rethrow;
    }
  }

  void resetState() {
    emit(StockInitial());
  }
}
