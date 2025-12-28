import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../models/assistant/ai_chat_response_model.dart';

final Logger aiAssistantLogger = Logger();

class AiAssistantService {
  AiAssistantService(Dio dio) : _dio = dio;

  final Dio _dio;

  Future<AiChatResponseModel> sendMessage({
    required int userId,
    required String message,
    String? sessionId,
  }) async {
    aiAssistantLogger.d(
        'Enviando mensaje al asistente IA. userId=$userId, sessionId=$sessionId, contenido="$message"');
    try {
      final requestData = {
        'userId': userId,
        'message': message,
      };

      // Agregar sessionId solo si existe
      if (sessionId != null) {
        requestData['sessionId'] = sessionId;
      }

      final response = await _dio.post(
        '/api/chat/process',
        data: requestData,
      );

      if (response.data is! Map<String, dynamic>) {
        throw Exception(
            'La respuesta del asistente no tiene el formato esperado');
      }

      return AiChatResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      _logDioError(e);
      rethrow;
    } catch (e, stackTrace) {
      aiAssistantLogger.e(
        'Error inesperado al procesar la respuesta del asistente',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  void _logDioError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    aiAssistantLogger.e(
      'Error en la comunicación con el asistente IA',
      error: 'status=$status, data=$data, message=${e.message}',
    );
  }
}
