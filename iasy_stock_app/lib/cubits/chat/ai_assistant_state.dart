import '../../models/menu/user_model.dart';

sealed class AiAssistantState {
  const AiAssistantState();
}

/// Estado inicial
class AiAssistantStateInitial extends AiAssistantState {
  const AiAssistantStateInitial();
}

/// Cargando información del usuario
class AiAssistantStateLoadingUser extends AiAssistantState {
  const AiAssistantStateLoadingUser();
}

/// Cargando historial de chat
class AiAssistantStateLoadingHistory extends AiAssistantState {
  const AiAssistantStateLoadingHistory(this.user);

  final UserModel user;
}

/// Estado principal con datos cargados
class AiAssistantStateLoaded extends AiAssistantState {
  const AiAssistantStateLoaded({
    required this.user,
    required this.messages,
    required this.suggestions,
    this.sessionId,
    this.isSending = false,
    this.elapsedSeconds = 0,
  });

  final UserModel user;
  final List<ChatMessage> messages;
  final List<String> suggestions;
  final String? sessionId;
  final bool isSending;
  final int elapsedSeconds;

  AiAssistantStateLoaded copyWith({
    UserModel? user,
    List<ChatMessage>? messages,
    List<String>? suggestions,
    String? sessionId,
    bool? isSending,
    int? elapsedSeconds,
    bool clearSessionId = false,
  }) {
    return AiAssistantStateLoaded(
      user: user ?? this.user,
      messages: messages ?? this.messages,
      suggestions: suggestions ?? this.suggestions,
      sessionId: clearSessionId ? null : (sessionId ?? this.sessionId),
      isSending: isSending ?? this.isSending,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }
}

/// Estado de error
class AiAssistantStateError extends AiAssistantState {
  const AiAssistantStateError({
    required this.message,
    this.user,
    this.messages,
  });

  final String message;
  final UserModel? user;
  final List<ChatMessage>? messages;
}

/// Modelo de mensaje de chat
class ChatMessage {
  const ChatMessage({
    required this.author,
    required this.content,
    required this.timestamp,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      author: map['author'] == 'user'
          ? MessageAuthor.user
          : MessageAuthor.assistant,
      content: map['content'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }

  final MessageAuthor author;
  final String content;
  final DateTime timestamp;

  Map<String, dynamic> toMap() {
    return {
      'author': author == MessageAuthor.user ? 'user' : 'assistant',
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

enum MessageAuthor { user, assistant }
