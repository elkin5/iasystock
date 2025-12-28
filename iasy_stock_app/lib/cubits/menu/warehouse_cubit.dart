import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/menu/warehouse_model.dart';
import '../../services/menu/warehouse_service.dart';

sealed class WarehouseState {}

class WarehouseInitial extends WarehouseState {}

class WarehouseLoading extends WarehouseState {}

class WarehouseLoaded extends WarehouseState {
  final List<WarehouseModel> warehouses;

  WarehouseLoaded(this.warehouses);
}

class SingleWarehouseLoaded extends WarehouseState {
  final WarehouseModel warehouse;

  SingleWarehouseLoaded(this.warehouse);
}

class WarehouseCubit extends Cubit<WarehouseState> {
  final WarehouseService warehouseService;
  List<WarehouseModel> _warehouses = [];

  WarehouseCubit(this.warehouseService) : super(WarehouseInitial());

  Future<void> loadWarehouses({int page = 0, int size = 10}) async {
    emit(WarehouseLoading());
    try {
      _warehouses = await warehouseService.getAll(page: page, size: size);
      emit(WarehouseLoaded(List.unmodifiable(_warehouses)));
    } catch (e) {
      emit(WarehouseInitial());
      rethrow;
    }
  }

  Future<void> createWarehouse(WarehouseModel warehouse) async {
    await warehouseService.create(warehouse);
  }

  Future<void> updateWarehouse(WarehouseModel warehouse) async {
    await warehouseService.update(warehouse.id!, warehouse);
  }

  Future<void> deleteWarehouse(int id) async {
    await warehouseService.delete(id);
  }

  Future<void> getWarehouseById(int id) async {
    emit(WarehouseLoading());
    try {
      final warehouse = await warehouseService.getById(id);
      emit(SingleWarehouseLoaded(warehouse));
    } catch (e) {
      emit(WarehouseInitial());
      rethrow;
    }
  }

  Future<void> findByName(String name, {int page = 0, int size = 10}) async {
    emit(WarehouseLoading());
    try {
      final result =
          await warehouseService.findByName(name, page: page, size: size);
      emit(WarehouseLoaded(List.unmodifiable(result)));
    } catch (e) {
      emit(WarehouseInitial());
      rethrow;
    }
  }

  Future<void> findByLocation(String location,
      {int page = 0, int size = 10}) async {
    emit(WarehouseLoading());
    try {
      final result = await warehouseService.findByLocation(location,
          page: page, size: size);
      emit(WarehouseLoaded(List.unmodifiable(result)));
    } catch (e) {
      emit(WarehouseInitial());
      rethrow;
    }
  }

  Future<void> findByNameContaining(String name,
      {int page = 0, int size = 10}) async {
    emit(WarehouseLoading());
    try {
      final result = await warehouseService.findByNameContaining(name,
          page: page, size: size);
      emit(WarehouseLoaded(List.unmodifiable(result)));
    } catch (e) {
      emit(WarehouseInitial());
      rethrow;
    }
  }

  void resetState() {
    emit(WarehouseInitial());
  }
}
