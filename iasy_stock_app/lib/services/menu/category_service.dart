import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../models/menu/category_model.dart';

final Logger log = Logger();

class CategoryService {
  final Dio _dio;

  CategoryService(this._dio);

  Future<List<CategoryModel>> getAll({int page = 0, int size = 10}) async {
    log.d('Servicio para obtener todas las categorías');
    try {
      final response = await _dio.get(
        '/api/categories',
        queryParameters: {'page': page, 'size': size},
      );
      final data =
          response.data is List ? response.data : response.data['categories'];
      return (data as List).map((e) => CategoryModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener categorías');
      rethrow;
    }
  }

  Future<CategoryModel> getById(int id) async {
    log.d('Servicio para obtener categoría con ID: $id');
    try {
      final response = await _dio.get('/api/categories/$id');
      return CategoryModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener categoría por ID');
      rethrow;
    }
  }

  Future<CategoryModel> create(CategoryModel category) async {
    log.d('Servicio para crear categoría: ${category.toJson()}');
    try {
      final response =
          await _dio.post('/api/categories', data: category.toJson());
      return CategoryModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Crear categoría');
      rethrow;
    }
  }

  Future<CategoryModel> update(int id, CategoryModel category) async {
    log.d(
        'Servicio para actualizar categoría con ID: $id, datos: ${category.toJson()}');
    try {
      final response =
          await _dio.put('/api/categories/$id', data: category.toJson());
      return CategoryModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Actualizar categoría');
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    log.d('Servicio para eliminar categoría con ID: $id');
    try {
      await _dio.delete('/api/categories/$id');
    } on DioException catch (e) {
      _logDioError(e, context: 'Eliminar categoría');
      rethrow;
    }
  }

  Future<List<CategoryModel>> findByName(String name,
      {int page = 0, int size = 10}) async {
    log.d('Servicio para buscar categorías por nombre exacto: $name');
    try {
      final response = await _dio.get(
        '/api/categories/search/by-name',
        queryParameters: {'name': name, 'page': page, 'size': size},
      );
      final data =
          response.data is List ? response.data : response.data['categories'];
      return (data as List).map((e) => CategoryModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar categorías por nombre');
      rethrow;
    }
  }

  Future<List<CategoryModel>> findByNameContaining(String name,
      {int page = 0, int size = 10}) async {
    log.d('Servicio para buscar categorías que contienen: $name');
    try {
      final response = await _dio.get(
        '/api/categories/search/by-name-containing',
        queryParameters: {'name': name, 'page': page, 'size': size},
      );
      final data =
          response.data is List ? response.data : response.data['categories'];
      return (data as List).map((e) => CategoryModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar categorías por fragmento de nombre');
      rethrow;
    }
  }

  void _logDioError(DioException e, {String? context}) {
    final responseData = e.response?.data;
    if (context != null) {
      log.e('[$context] Error: $responseData');
    } else {
      log.e('Error: $responseData');
    }
  }
}
