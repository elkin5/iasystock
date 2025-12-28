import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/menu/sale_item_model.dart';
import '../../services/menu/sale_item_service.dart';

sealed class SaleItemState {}

class SaleItemInitial extends SaleItemState {}

class SaleItemLoading extends SaleItemState {}

class SaleItemLoaded extends SaleItemState {
  final List<SaleItemModel> saleItems;

  SaleItemLoaded(this.saleItems);
}

class SingleSaleItemLoaded extends SaleItemState {
  final SaleItemModel saleItem;

  SingleSaleItemLoaded(this.saleItem);
}

class SaleItemCubit extends Cubit<SaleItemState> {
  final SaleItemService saleItemService;
  List<SaleItemModel> _saleItems = [];

  SaleItemCubit(this.saleItemService) : super(SaleItemInitial());

  Future<void> loadSaleItems({int page = 0, int size = 10}) async {
    emit(SaleItemLoading());
    try {
      _saleItems = await saleItemService.getAll(page: page, size: size);
      emit(SaleItemLoaded(List.unmodifiable(_saleItems)));
    } catch (e) {
      emit(SaleItemInitial());
      rethrow;
    }
  }

  Future<void> createSaleItem(SaleItemModel item) async {
    await saleItemService.create(item);
  }

  Future<void> updateSaleItem(int id, SaleItemModel item) async {
    await saleItemService.update(id, item);
  }

  Future<void> deleteSaleItem(int id) async {
    await saleItemService.delete(id);
  }

  Future<void> getSaleItemById(int id) async {
    emit(SaleItemLoading());
    try {
      final saleItem = await saleItemService.getById(id);
      emit(SingleSaleItemLoaded(saleItem));
    } catch (e) {
      emit(SaleItemInitial());
      rethrow;
    }
  }

  Future<void> findBySaleId(int saleId, {int page = 0, int size = 10}) async {
    emit(SaleItemLoading());
    try {
      final result =
          await saleItemService.findBySaleId(saleId, page: page, size: size);
      emit(SaleItemLoaded(List.unmodifiable(result)));
    } catch (e) {
      emit(SaleItemInitial());
      rethrow;
    }
  }

  Future<void> findByProductId(int productId,
      {int page = 0, int size = 10}) async {
    emit(SaleItemLoading());
    try {
      final result = await saleItemService.findByProductId(productId,
          page: page, size: size);
      emit(SaleItemLoaded(List.unmodifiable(result)));
    } catch (e) {
      emit(SaleItemInitial());
      rethrow;
    }
  }

  void resetState() {
    emit(SaleItemInitial());
  }
}
