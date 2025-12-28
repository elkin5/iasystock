import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../models/menu/warehouse_model.dart';

final Logger log = Logger();

class WarehouseService {
  final Dio _dio;

  WarehouseService(this._dio);

  Future<List<WarehouseModel>> getAll({int page = 0, int size = 10}) async {
    log.d('Servicio para obtener todos los almacenes');
    try {
      final response = await _dio.get('/api/warehouses',
          queryParameters: {'page': page, 'size': size});
      final data =
          response.data is List ? response.data : response.data['warehouses'];
      return (data as List).map((e) => WarehouseModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener almacenes');
      rethrow;
    }
  }

  Future<WarehouseModel> getById(int id) async {
    log.d('Servicio para obtener almacén por ID: $id');
    try {
      final response = await _dio.get('/api/warehouses/$id');
      return WarehouseModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener almacén por ID');
      rethrow;
    }
  }

  Future<WarehouseModel> create(WarehouseModel warehouse) async {
    log.d('Servicio para crear almacén: ${warehouse.toJson()}');
    try {
      final response =
          await _dio.post('/api/warehouses', data: warehouse.toJson());
      return WarehouseModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Crear almacén');
      rethrow;
    }
  }

  Future<WarehouseModel> update(int id, WarehouseModel warehouse) async {
    log.d('Servicio para actualizar almacén con ID: $id');
    try {
      final response =
          await _dio.put('/api/warehouses/$id', data: warehouse.toJson());
      return WarehouseModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Actualizar almacén');
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    log.d('Servicio para eliminar almacén con ID: $id');
    try {
      await _dio.delete('/api/warehouses/$id');
    } on DioException catch (e) {
      _logDioError(e, context: 'Eliminar almacén');
      rethrow;
    }
  }

  Future<List<WarehouseModel>> findByName(String name,
      {int page = 0, int size = 10}) async {
    log.d('Buscar almacenes por nombre: $name');
    try {
      final response = await _dio.get('/api/warehouses/search/by-name',
          queryParameters: {'name': name, 'page': page, 'size': size});
      final data =
          response.data is List ? response.data : response.data['warehouses'];
      return (data as List).map((e) => WarehouseModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar por nombre');
      rethrow;
    }
  }

  Future<List<WarehouseModel>> findByLocation(String location,
      {int page = 0, int size = 10}) async {
    log.d('Buscar almacenes por ubicación: $location');
    try {
      final response = await _dio.get('/api/warehouses/search/by-location',
          queryParameters: {'location': location, 'page': page, 'size': size});
      final data =
          response.data is List ? response.data : response.data['warehouses'];
      return (data as List).map((e) => WarehouseModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar por ubicación');
      rethrow;
    }
  }

  Future<List<WarehouseModel>> findByNameContaining(String name,
      {int page = 0, int size = 10}) async {
    log.d('Buscar almacenes por nombre que contenga: $name');
    try {
      final response = await _dio.get(
          '/api/warehouses/search/by-name-containing',
          queryParameters: {'name': name, 'page': page, 'size': size});
      final data =
          response.data is List ? response.data : response.data['warehouses'];
      return (data as List).map((e) => WarehouseModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar por nombre que contenga');
      rethrow;
    }
  }

  void _logDioError(DioException e, {String? context}) {
    final responseData = e.response?.data;
    if (context != null) log.e('[$context] Error: $responseData');
  }
}
