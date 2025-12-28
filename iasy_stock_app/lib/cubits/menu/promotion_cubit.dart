import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/menu/promotion_model.dart';
import '../../services/menu/promotion_service.dart';

sealed class PromotionState {}

class PromotionInitial extends PromotionState {}

class PromotionLoading extends PromotionState {}

class PromotionLoaded extends PromotionState {
  final List<PromotionModel> promotions;

  PromotionLoaded(this.promotions);
}

class SinglePromotionLoaded extends PromotionState {
  final PromotionModel promotion;

  SinglePromotionLoaded(this.promotion);
}

class PromotionCubit extends Cubit<PromotionState> {
  final PromotionService promotionService;
  List<PromotionModel> _promotions = [];

  PromotionCubit(this.promotionService) : super(PromotionInitial());

  Future<void> loadPromotions({int page = 0, int size = 10}) async {
    emit(PromotionLoading());
    try {
      _promotions = await promotionService.getAll(page: page, size: size);
      emit(PromotionLoaded(List.unmodifiable(_promotions)));
    } catch (e) {
      emit(PromotionInitial());
      rethrow;
    }
  }

  Future<void> createPromotion(PromotionModel promotion) async {
    await promotionService.create(promotion);
  }

  Future<void> updatePromotion(PromotionModel promotion) async {
    await promotionService.update(promotion.id!, promotion);
  }

  Future<void> deletePromotion(int id) async {
    await promotionService.delete(id);
  }

  Future<void> getPromotionById(int id) async {
    emit(PromotionLoading());
    try {
      final promotion = await promotionService.getById(id);
      emit(SinglePromotionLoaded(promotion));
    } catch (e) {
      emit(PromotionInitial());
      rethrow;
    }
  }

  Future<void> findByDescription(String description,
      {int page = 0, int size = 10}) async {
    emit(PromotionLoading());
    try {
      final result = await promotionService.findByDescription(description,
          page: page, size: size);
      emit(PromotionLoaded(List.unmodifiable(result)));
    } catch (e) {
      emit(PromotionInitial());
      rethrow;
    }
  }

  Future<void> findByDiscountRateGreaterThan(double rate,
      {int page = 0, int size = 10}) async {
    emit(PromotionLoading());
    try {
      final result = await promotionService.findByDiscountRateGreaterThan(rate,
          page: page, size: size);
      emit(PromotionLoaded(List.unmodifiable(result)));
    } catch (e) {
      emit(PromotionInitial());
      rethrow;
    }
  }

  Future<void> findByDateRange(DateTime start, DateTime end,
      {int page = 0, int size = 10}) async {
    emit(PromotionLoading());
    try {
      final result = await promotionService.findByDateRange(start, end,
          page: page, size: size);
      emit(PromotionLoaded(List.unmodifiable(result)));
    } catch (e) {
      emit(PromotionInitial());
      rethrow;
    }
  }

  Future<void> findByProductId(int productId,
      {int page = 0, int size = 10}) async {
    emit(PromotionLoading());
    try {
      final result = await promotionService.findByProductId(productId,
          page: page, size: size);
      emit(PromotionLoaded(List.unmodifiable(result)));
    } catch (e) {
      emit(PromotionInitial());
      rethrow;
    }
  }

  Future<void> findByCategoryId(int categoryId,
      {int page = 0, int size = 10}) async {
    emit(PromotionLoading());
    try {
      final result = await promotionService.findByCategoryId(categoryId,
          page: page, size: size);
      emit(PromotionLoaded(List.unmodifiable(result)));
    } catch (e) {
      emit(PromotionInitial());
      rethrow;
    }
  }

  void resetState() {
    emit(PromotionInitial());
  }
}
