import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/menu/sale_model.dart';
import '../../services/menu/sale_service.dart';

sealed class SaleState {}

class SaleInitial extends SaleState {}

class SaleLoading extends SaleState {}

class SaleLoaded extends SaleState {
  final List<SaleModel> sales;

  SaleLoaded(this.sales);
}

class SingleSaleLoaded extends SaleState {
  final SaleModel sale;

  SingleSaleLoaded(this.sale);
}

class SaleCubit extends Cubit<SaleState> {
  final SaleService saleService;
  List<SaleModel> _sales = [];

  SaleCubit(this.saleService) : super(SaleInitial());

  Future<void> loadSales({int page = 0, int size = 10}) async {
    emit(SaleLoading());
    try {
      _sales = await saleService.getAll(page: page, size: size);
      emit(SaleLoaded(List.unmodifiable(_sales)));
    } catch (e) {
      emit(SaleInitial());
      rethrow;
    }
  }

  Future<void> createSale(SaleModel sale) async {
    await saleService.create(sale);
  }

  Future<void> updateSale(SaleModel sale) async {
    await saleService.update(sale.id!, sale);
  }

  Future<void> deleteSale(int id) async {
    await saleService.delete(id);
  }

  Future<void> getSaleById(int id) async {
    emit(SaleLoading());
    try {
      final sale = await saleService.getById(id);
      emit(SingleSaleLoaded(sale));
    } catch (e) {
      emit(SaleInitial());
      rethrow;
    }
  }

  Future<void> findByUserId(int userId, {int page = 0, int size = 10}) async {
    emit(SaleLoading());
    try {
      final result =
          await saleService.findByUserId(userId, page: page, size: size);
      emit(SaleLoaded(List.unmodifiable(result)));
    } catch (e) {
      emit(SaleInitial());
      rethrow;
    }
  }

  Future<void> findByPersonId(int personId,
      {int page = 0, int size = 10}) async {
    emit(SaleLoading());
    try {
      final result =
          await saleService.findByPersonId(personId, page: page, size: size);
      emit(SaleLoaded(List.unmodifiable(result)));
    } catch (e) {
      emit(SaleInitial());
      rethrow;
    }
  }

  Future<void> findBySaleDate(DateTime saleDate,
      {int page = 0, int size = 10}) async {
    emit(SaleLoading());
    try {
      final result =
          await saleService.findBySaleDate(saleDate, page: page, size: size);
      emit(SaleLoaded(List.unmodifiable(result)));
    } catch (e) {
      emit(SaleInitial());
      rethrow;
    }
  }

  Future<void> findByTotalAmountGreaterThan(double amount,
      {int page = 0, int size = 10}) async {
    emit(SaleLoading());
    try {
      final result = await saleService.findByTotalAmountGreaterThan(amount,
          page: page, size: size);
      emit(SaleLoaded(List.unmodifiable(result)));
    } catch (e) {
      emit(SaleInitial());
      rethrow;
    }
  }

  Future<void> findByState(String state, {int page = 0, int size = 10}) async {
    emit(SaleLoading());
    try {
      final result =
          await saleService.findByState(state, page: page, size: size);
      emit(SaleLoaded(List.unmodifiable(result)));
    } catch (e) {
      emit(SaleInitial());
      rethrow;
    }
  }

  void resetState() {
    emit(SaleInitial());
  }
}
