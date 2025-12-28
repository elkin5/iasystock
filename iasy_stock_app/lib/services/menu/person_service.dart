import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../models/menu/person_model.dart';

final Logger log = Logger();

class PersonService {
  final Dio _dio;

  PersonService(this._dio);

  Future<List<PersonModel>> getAll({int page = 0, int size = 10}) async {
    log.d('Servicio para obtener todas las personas');
    try {
      final response = await _dio.get(
        '/api/persons',
        queryParameters: {'page': page, 'size': size},
      );
      final data =
          response.data is List ? response.data : response.data['persons'];
      return (data as List).map((e) => PersonModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener personas');
      rethrow;
    }
  }

  Future<PersonModel> getById(int id) async {
    log.d('Servicio para obtener persona con ID: $id');
    try {
      final response = await _dio.get('/api/persons/$id');
      return PersonModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener persona por ID');
      rethrow;
    }
  }

  Future<PersonModel> create(PersonModel person) async {
    log.d('Servicio para crear persona: ${person.toJson()}');
    try {
      final response = await _dio.post('/api/persons', data: person.toJson());
      return PersonModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Crear persona');
      rethrow;
    }
  }

  Future<PersonModel> update(int id, PersonModel person) async {
    log.d(
        'Servicio para actualizar persona con ID: $id, datos: ${person.toJson()}');
    try {
      final response =
          await _dio.put('/api/persons/$id', data: person.toJson());
      return PersonModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Actualizar persona');
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    log.d('Servicio para eliminar persona con ID: $id');
    try {
      await _dio.delete('/api/persons/$id');
    } on DioException catch (e) {
      _logDioError(e, context: 'Eliminar persona');
      rethrow;
    }
  }

  Future<List<PersonModel>> findByName(String name,
      {int page = 0, int size = 10}) async {
    log.d('Servicio para buscar personas por nombre: $name');
    try {
      final response = await _dio.get(
        '/api/persons/search/by-name',
        queryParameters: {'name': name, 'page': page, 'size': size},
      );
      final data =
          response.data is List ? response.data : response.data['persons'];
      return (data as List).map((e) => PersonModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar personas por nombre');
      rethrow;
    }
  }

  Future<List<PersonModel>> findByNameContaining(String keyword,
      {int page = 0, int size = 10}) async {
    log.d('Servicio para buscar personas cuyo nombre contenga: $keyword');
    try {
      final response = await _dio.get(
        '/api/persons/search/by-name-containing',
        queryParameters: {'keyword': keyword, 'page': page, 'size': size},
      );
      final data =
          response.data is List ? response.data : response.data['persons'];
      return (data as List).map((e) => PersonModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar por fragmento de nombre');
      rethrow;
    }
  }

  Future<List<PersonModel>> findByType(String type,
      {int page = 0, int size = 10}) async {
    log.d('Servicio para buscar personas por tipo: $type');
    try {
      final response = await _dio.get(
        '/api/persons/search/by-type',
        queryParameters: {'type': type, 'page': page, 'size': size},
      );
      final data =
          response.data is List ? response.data : response.data['persons'];
      return (data as List).map((e) => PersonModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar por tipo');
      rethrow;
    }
  }

  Future<PersonModel> findByIdentification(int identification) async {
    log.d('Servicio para buscar persona por identificación: $identification');
    try {
      final response = await _dio.get(
        '/api/persons/search/by-identification',
        queryParameters: {'identification': identification},
      );
      return PersonModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar por identificación');
      rethrow;
    }
  }

  Future<PersonModel> findByEmail(String email) async {
    log.d('Servicio para buscar persona por email: $email');
    try {
      final response = await _dio.get(
        '/api/persons/search/by-email',
        queryParameters: {'email': email},
      );
      return PersonModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar por email');
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
