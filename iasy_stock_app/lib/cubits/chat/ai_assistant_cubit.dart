import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../services/assistant/ai_assistant_service.dart';
import '../../services/assistant/chat_history_database_service.dart';
import '../../services/menu/user_service.dart';
import 'ai_assistant_state.dart';

class AiAssistantCubit extends Cubit<AiAssistantState> {
  AiAssistantCubit({
    required AiAssistantService assistantService,
    required ChatHistoryDatabaseService chatHistoryService,
    required UserService userService,
  })  : _assistantService = assistantService,
        _chatHistoryService = chatHistoryService,
        _userService = userService,
        super(const AiAssistantStateInitial()) {
    _initialize();
  }

  final AiAssistantService _assistantService;
  final ChatHistoryDatabaseService _chatHistoryService;
  final UserService _userService;
  final Logger _logger = Logger();

  Timer? _elapsedTimer;

  static const List<String> _defaultSuggestions = [
    '¿Cuáles son los productos más vendidos?',
    '¿Qué productos están por vencer?',
    'Muéstrame el inventario actual',
  ];

  /// Inicializa el cubit cargando el usuario y el historial
  Future<void> _initialize() async {
    emit(const AiAssistantStateLoadingUser());

    try {
      final user = await _userService.getCurrentUser();
      emit(AiAssistantStateLoadingHistory(user));

      // Cargar historial
      final history = await _chatHistoryService.getMessageHistory(
        userId: user.id!,
        limit: 20,
      );

      final loadedMessages = history.reversed.map((row) {
        return ChatMessage.fromMap(row);
      }).toList();

      emit(AiAssistantStateLoaded(
        user: user,
        messages: loadedMessages,
        suggestions: _defaultSuggestions,
      ));

      _logger.i(
          'Asistente inicializado. Usuario: ${user.username}, Mensajes: ${loadedMessages.length}');
    } catch (error, stackTrace) {
      _logger.e('Error inicializando asistente',
          error: error, stackTrace: stackTrace);
      emit(const AiAssistantStateError(
        message: 'No pudimos cargar el asistente. Intenta nuevamente.',
      ));
    }
  }

  /// Envía un mensaje al asistente
  Future<void> sendMessage(String message) async {
    final currentState = state;
    if (currentState is! AiAssistantStateLoaded) {
      _logger.w(
          'Intento de enviar mensaje en estado inválido: ${state.runtimeType}');
      return;
    }

    if (message.trim().isEmpty || currentState.isSending) {
      return;
    }

    // Haptic feedback
    unawaited(HapticFeedback.lightImpact());

    final userMessage = ChatMessage(
      author: MessageAuthor.user,
      content: message.trim(),
      timestamp: DateTime.now(),
    );

    // Actualizar estado a "enviando"
    emit(currentState.copyWith(
      messages: [...currentState.messages, userMessage],
      isSending: true,
      elapsedSeconds: 0,
    ));

    // Guardar mensaje en DB (sin esperar)
    unawaited(_saveMessageToDatabase(userMessage, currentState.user.id!));

    // Iniciar timer
    _startElapsedTimer();

    try {
      final response = await _assistantService.sendMessage(
        userId: currentState.user.id!,
        message: message.trim(),
        sessionId: currentState.sessionId,
      );

      final assistantMessage = ChatMessage(
        author: MessageAuthor.assistant,
        content: response.message,
        timestamp: response.timestamp ?? DateTime.now(),
      );

      // Actualizar con respuesta
      final newState = (state as AiAssistantStateLoaded).copyWith(
        messages: [
          ...(state as AiAssistantStateLoaded).messages,
          assistantMessage
        ],
        suggestions: response.suggestions.isNotEmpty
            ? response.suggestions
            : _defaultSuggestions,
        sessionId: response.sessionId,
        isSending: false,
        elapsedSeconds: 0,
      );

      emit(newState);

      // Guardar respuesta en DB
      unawaited(
          _saveMessageToDatabase(assistantMessage, currentState.user.id!));

      // Haptic feedback al recibir respuesta
      unawaited(HapticFeedback.selectionClick());

      _stopElapsedTimer();
    } catch (error, stackTrace) {
      _logger.e('Error enviando mensaje', error: error, stackTrace: stackTrace);
      _stopElapsedTimer();

      emit(AiAssistantStateError(
        message:
            'Ocurrió un error al consultar el asistente. Por favor, intenta nuevamente.',
        user: currentState.user,
        messages: currentState.messages,
      ));
    }
  }

  /// Borra el historial de chat del usuario actual
  Future<void> clearHistory() async {
    final currentState = state;
    if (currentState is! AiAssistantStateLoaded) {
      _logger.w(
          'Intento de borrar historial en estado inválido: ${state.runtimeType}');
      return;
    }

    try {
      await _chatHistoryService.clearUserHistory(userId: currentState.user.id!);

      emit(currentState.copyWith(
        messages: [],
        suggestions: _defaultSuggestions,
        clearSessionId: true,
      ));

      _logger.i(
          'Historial borrado exitosamente para userId: ${currentState.user.id}');
    } catch (error, stackTrace) {
      _logger.e('Error borrando historial',
          error: error, stackTrace: stackTrace);
      // No emitir error, mantener el estado actual
    }
  }

  /// Inicia el timer para mostrar tiempo transcurrido
  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentState = state;
      if (currentState is AiAssistantStateLoaded && currentState.isSending) {
        emit(currentState.copyWith(
          elapsedSeconds: currentState.elapsedSeconds + 1,
        ));
      } else {
        timer.cancel();
      }
    });
  }

  /// Detiene el timer
  void _stopElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
  }

  /// Guarda un mensaje en la base de datos local
  Future<void> _saveMessageToDatabase(ChatMessage message, int userId) async {
    try {
      final currentState = state;
      String? sessionId;
      if (currentState is AiAssistantStateLoaded) {
        sessionId = currentState.sessionId;
      }

      await _chatHistoryService.saveMessage(
        userId: userId,
        sessionId: sessionId,
        author: message.author == MessageAuthor.user ? 'user' : 'assistant',
        content: message.content,
        timestamp: message.timestamp,
      );
      _logger.d('Mensaje guardado exitosamente en BD');
    } catch (error, stackTrace) {
      _logger.e('Error guardando mensaje en BD',
          error: error, stackTrace: stackTrace);
      // Fallar silenciosamente
    }
  }

  @override
  Future<void> close() {
    _stopElapsedTimer();
    return super.close();
  }
}
