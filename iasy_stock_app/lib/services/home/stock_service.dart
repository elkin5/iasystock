import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../config/auth_config.dart';
import '../../models/menu/stock_model.dart';

class StockService {
  static String get _baseUrl => AuthConfig.apiBaseUrl;
  static const String _stocksEndpoint = '/api/stocks';

  /// Registra stock con reconocimiento inteligente
  static Future<Map<String, dynamic>> registerStockWithRecognition({
    required int? productId,
    required String? productName,
    required String? productDescription,
    required int? categoryId,
    required int quantity,
    required double entryPrice,
    required double salePrice,
    required int? warehouseId,
    required int? personId,
    required DateTime? entryDate,
    required File? imageFile,
    required Map<String, dynamic>? recognitionData,
    required String token,
  }) async {
    try {
      final url =
          Uri.parse('$_baseUrl$_stocksEndpoint/register-with-recognition');

      // Preparar datos de la imagen si existe
      String? imageData;
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        imageData = base64Encode(bytes);
      }

      final requestData = {
        'productId': productId,
        'productName': productName,
        'productDescription': productDescription,
        'categoryId': categoryId,
        'quantity': quantity,
        'entryPrice': entryPrice,
        'salePrice': salePrice,
        'warehouseId': warehouseId,
        'personId': personId,
        'entryDate': entryDate?.toIso8601String().split('T')[0],
        // Formato YYYY-MM-DD
        'imageData': imageData,
        'recognitionData': recognitionData,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Error al registrar stock: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error en la comunicación con el servidor: $e');
    }
  }

  /// Obtiene datos necesarios para el formulario de registro de stock
  static Future<Map<String, dynamic>> getStockFormData(String token) async {
    try {
      final url = Uri.parse('$_baseUrl$_stocksEndpoint/form-data');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Error al obtener datos del formulario: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en la comunicación con el servidor: $e');
    }
  }

  /// Reconocimiento de producto desde imagen
  static Future<Map<String, dynamic>> recognizeProduct({
    required File imageFile,
    required String token,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl$_stocksEndpoint/recognize-product');

      final bytes = await imageFile.readAsBytes();
      final imageData = base64Encode(bytes);

      final requestData = {
        'imageData': imageData,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Error en reconocimiento: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error en la comunicación con el servidor: $e');
    }
  }

  /// Obtiene la lista de stock existente
  static Future<List<StockModel>> getStockList({
    int page = 0,
    int size = 10,
    required String token,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl$_stocksEndpoint?page=$page&size=$size');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => StockModel.fromJson(json)).toList();
      } else {
        throw Exception(
            'Error al obtener lista de stock: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en la comunicación con el servidor: $e');
    }
  }

  /// Crea stock de forma tradicional (sin reconocimiento)
  static Future<StockModel> createStock({
    required StockModel stock,
    required String token,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl$_stocksEndpoint');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(stock.toJson()),
      );

      if (response.statusCode == 201) {
        return StockModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
            'Error al crear stock: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error en la comunicación con el servidor: $e');
    }
  }

  /// Actualiza stock existente
  static Future<StockModel> updateStock({
    required int stockId,
    required StockModel stock,
    required String token,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl$_stocksEndpoint/$stockId');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(stock.toJson()),
      );

      if (response.statusCode == 200) {
        return StockModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
            'Error al actualizar stock: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error en la comunicación con el servidor: $e');
    }
  }

  /// Elimina stock
  static Future<void> deleteStock({
    required int stockId,
    required String token,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl$_stocksEndpoint/$stockId');

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 204) {
        throw Exception('Error al eliminar stock: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en la comunicación con el servidor: $e');
    }
  }

  /// Busca stock por ID de producto
  static Future<List<StockModel>> getStockByProductId({
    required int productId,
    int page = 0,
    int size = 10,
    required String token,
  }) async {
    try {
      final url = Uri.parse(
          '$_baseUrl$_stocksEndpoint/search/by-product?productId=$productId&page=$page&size=$size');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => StockModel.fromJson(json)).toList();
      } else {
        throw Exception(
            'Error al buscar stock por producto: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en la comunicación con el servidor: $e');
    }
  }

  /// Busca stock por ID de almacén
  static Future<List<StockModel>> getStockByWarehouseId({
    required int warehouseId,
    int page = 0,
    int size = 10,
    required String token,
  }) async {
    try {
      final url = Uri.parse(
          '$_baseUrl$_stocksEndpoint/search/by-warehouse?warehouseId=$warehouseId&page=$page&size=$size');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => StockModel.fromJson(json)).toList();
      } else {
        throw Exception(
            'Error al buscar stock por almacén: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en la comunicación con el servidor: $e');
    }
  }
}
