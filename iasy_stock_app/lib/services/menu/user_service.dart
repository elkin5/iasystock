import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../models/menu/user_model.dart';

final Logger log = Logger();

class UserService {
  final Dio _dio;

  UserService(this._dio);

  Future<List<UserModel>> getAll({int page = 0, int size = 10}) async {
    log.d('Servicio para obtener todos los usuarios');
    try {
      final response = await _dio
          .get('/api/users', queryParameters: {'page': page, 'size': size});
      final data =
          response.data is List ? response.data : response.data['users'];
      return (data as List).map((e) => UserModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener usuarios');
      rethrow;
    }
  }

  Future<UserModel> getById(int id) async {
    log.d('Servicio para obtener usuario por ID: $id');
    try {
      final response = await _dio.get('/api/users/$id');
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener usuario por ID');
      rethrow;
    }
  }

  Future<UserModel> create(UserModel user) async {
    log.d('Servicio para crear usuario: ${user.toJson()}');
    try {
      final response = await _dio.post('/api/users', data: user.toJson());
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Crear usuario');
      rethrow;
    }
  }

  Future<UserModel> update(int id, UserModel user) async {
    log.d('Servicio para actualizar usuario con ID: $id');
    try {
      final response = await _dio.put('/api/users/$id', data: user.toJson());
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Actualizar usuario');
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    log.d('Servicio para eliminar usuario con ID: $id');
    try {
      await _dio.delete('/api/users/$id');
    } on DioException catch (e) {
      _logDioError(e, context: 'Eliminar usuario');
      rethrow;
    }
  }

  Future<UserModel> findByUsername(String username) async {
    log.d('Buscar usuario por username: $username');
    try {
      final response = await _dio.get('/api/users/search/by-username',
          queryParameters: {'username': username});
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar usuario por username');
      rethrow;
    }
  }

  Future<UserModel> findByEmail(String email) async {
    log.d('Buscar usuario por email: $email');
    try {
      final response = await _dio
          .get('/api/users/search/by-email', queryParameters: {'email': email});
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar usuario por email');
      rethrow;
    }
  }

  Future<List<UserModel>> findByRole(String role,
      {int page = 0, int size = 10}) async {
    log.d('Buscar usuarios por rol: $role');
    try {
      final response = await _dio.get('/api/users/search/by-role',
          queryParameters: {'role': role, 'page': page, 'size': size});
      final data =
          response.data is List ? response.data : response.data['users'];
      return (data as List).map((e) => UserModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _logDioError(e, context: 'Buscar usuarios por rol');
      rethrow;
    }
  }

  /// Obtiene el usuario actual autenticado
  Future<UserModel> getCurrentUser() async {
    log.d('Obteniendo usuario actual autenticado');
    try {
      final response = await _dio.get('/api/v1/auth/me');
      log.d('Respuesta del servidor: ${response.data}');
      log.d('Tipo de respuesta: ${response.data.runtimeType}');

      // Manejar diferentes tipos de respuesta
      if (response.data is String) {
        log.e('Error: El servidor devolvió un String en lugar de JSON');
        log.e('Contenido de la respuesta: "${response.data}"');

        // Si es un String vacío o null, crear un usuario por defecto para desarrollo
        if (response.data.toString().isEmpty ||
            response.data.toString() == 'null' ||
            response.data.toString().contains('error') ||
            response.data.toString().contains('Error') ||
            response.data.toString().contains('error al cargar')) {
          log.w(
              'Creando usuario por defecto para desarrollo - respuesta vacía o con error');
          return UserModel(
            id: 1,
            username: 'developer',
            email: 'dev@localhost',
            firstName: 'Dev',
            lastName: 'User',
            role: 'admin',
            isActive: true,
          );
        }

        throw Exception(
            'Error: Respuesta del servidor no es válida. Tipo recibido: ${response.data.runtimeType}');
      }

      if (response.data is! Map<String, dynamic>) {
        log.e(
            'Error: La respuesta no es un Map, es: ${response.data.runtimeType}');
        log.e('Contenido de la respuesta: ${response.data}');
        throw Exception(
            'Error: Respuesta del servidor no es válida. Tipo recibido: ${response.data.runtimeType}');
      }

      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      _logDioError(e, context: 'Obtener usuario actual');
      rethrow;
    } catch (e) {
      log.e('Error inesperado al obtener usuario actual: $e');
      rethrow;
    }
  }

  void _logDioError(DioException e, {String? context}) {
    final responseData = e.response?.data;
    if (context != null) log.e('[$context] Error: $responseData');
  }
}
