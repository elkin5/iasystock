import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logger/logger.dart';
// Imports condicionales para plataformas nativas
import 'package:path/path.dart' as path_lib;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:sqflite/sqflite.dart' as sqflite;

/// Servicio para persistir el historial de chat localmente
/// Usa SQLite en móvil/desktop y almacenamiento en memoria en web
class ChatHistoryDatabaseService {
  static final ChatHistoryDatabaseService _instance =
      ChatHistoryDatabaseService._internal();
  static sqflite.Database? _database;
  final _logger = Logger();

  // Almacenamiento en memoria para web
  static final List<Map<String, dynamic>> _webMessages = [];
  static int _webMessageIdCounter = 0;

  factory ChatHistoryDatabaseService() => _instance;

  ChatHistoryDatabaseService._internal();

  /// Obtiene la instancia de la base de datos (solo para plataformas nativas)
  Future<sqflite.Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite no está disponible en web');
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializa la base de datos (solo para plataformas nativas)
  Future<sqflite.Database> _initDatabase() async {
    final directory = await path_provider.getApplicationDocumentsDirectory();
    final dbPath = path_lib.join(directory.path, 'chat_history.db');

    _logger.d('Inicializando BD en: $dbPath');

    return await sqflite.openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
      onOpen: (db) {
        _logger.d('Base de datos abierta exitosamente: $dbPath');
      },
    );
  }

  /// Crea las tablas de la base de datos
  Future<void> _onCreate(sqflite.Database db, int version) async {
    await db.execute('''
      CREATE TABLE chat_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        session_id TEXT,
        author TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_user_timestamp
      ON chat_messages(user_id, timestamp DESC)
    ''');
  }

  /// Guarda un mensaje
  Future<int> saveMessage({
    required int userId,
    String? sessionId,
    required String author,
    required String content,
    required DateTime timestamp,
  }) async {
    if (kIsWeb) {
      return _saveMessageWeb(
        userId: userId,
        sessionId: sessionId,
        author: author,
        content: content,
        timestamp: timestamp,
      );
    }
    return _saveMessageNative(
      userId: userId,
      sessionId: sessionId,
      author: author,
      content: content,
      timestamp: timestamp,
    );
  }

  Future<int> _saveMessageWeb({
    required int userId,
    String? sessionId,
    required String author,
    required String content,
    required DateTime timestamp,
  }) async {
    final id = ++_webMessageIdCounter;
    _webMessages.add({
      'id': id,
      'user_id': userId,
      'session_id': sessionId,
      'author': author,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    _logger.d('[Web] Mensaje guardado: userId=$userId, author=$author, id=$id');
    return id;
  }

  Future<int> _saveMessageNative({
    required int userId,
    String? sessionId,
    required String author,
    required String content,
    required DateTime timestamp,
  }) async {
    try {
      final db = await database;
      final id = await db.insert('chat_messages', {
        'user_id': userId,
        'session_id': sessionId,
        'author': author,
        'content': content,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
      _logger.d('Mensaje guardado: userId=$userId, author=$author, id=$id');
      return id;
    } catch (e) {
      _logger.e('Error guardando mensaje: $e');
      rethrow;
    }
  }

  /// Obtiene el historial de mensajes de un usuario
  Future<List<Map<String, dynamic>>> getMessageHistory({
    required int userId,
    int limit = 50,
  }) async {
    if (kIsWeb) {
      return _getMessageHistoryWeb(userId: userId, limit: limit);
    }
    return _getMessageHistoryNative(userId: userId, limit: limit);
  }

  List<Map<String, dynamic>> _getMessageHistoryWeb({
    required int userId,
    int limit = 50,
  }) {
    final userMessages = _webMessages
        .where((m) => m['user_id'] == userId)
        .toList()
      ..sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
    final results = userMessages.take(limit).toList();
    _logger
        .d('[Web] Historial cargado: userId=$userId, count=${results.length}');
    return results;
  }

  Future<List<Map<String, dynamic>>> _getMessageHistoryNative({
    required int userId,
    int limit = 50,
  }) async {
    try {
      final db = await database;
      final results = await db.query(
        'chat_messages',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'id DESC',
        limit: limit,
      );
      _logger.d('Historial cargado: userId=$userId, count=${results.length}');
      return results;
    } catch (e) {
      _logger.e('Error cargando historial: $e');
      rethrow;
    }
  }

  /// Obtiene mensajes de una sesión específica
  Future<List<Map<String, dynamic>>> getSessionMessages({
    required int userId,
    required String sessionId,
  }) async {
    if (kIsWeb) {
      final results = _webMessages
          .where((m) => m['user_id'] == userId && m['session_id'] == sessionId)
          .toList()
        ..sort(
            (a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));
      return results;
    }
    final db = await database;
    return await db.query(
      'chat_messages',
      where: 'user_id = ? AND session_id = ?',
      whereArgs: [userId, sessionId],
      orderBy: 'timestamp ASC',
    );
  }

  /// Elimina mensajes antiguos (más de [daysToKeep] días)
  Future<int> cleanOldMessages({int daysToKeep = 30}) async {
    final cutoffDate = DateTime.now()
        .subtract(Duration(days: daysToKeep))
        .millisecondsSinceEpoch;

    if (kIsWeb) {
      final before = _webMessages.length;
      _webMessages.removeWhere((m) => (m['created_at'] as int) < cutoffDate);
      return before - _webMessages.length;
    }

    final db = await database;
    return await db.delete(
      'chat_messages',
      where: 'created_at < ?',
      whereArgs: [cutoffDate],
    );
  }

  /// Elimina todos los mensajes de un usuario
  Future<int> clearUserHistory({required int userId}) async {
    if (kIsWeb) {
      final before = _webMessages.length;
      _webMessages.removeWhere((m) => m['user_id'] == userId);
      return before - _webMessages.length;
    }

    final db = await database;
    return await db.delete(
      'chat_messages',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Obtiene el número total de mensajes almacenados
  Future<int> getMessageCount() async {
    if (kIsWeb) {
      return _webMessages.length;
    }
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM chat_messages');
    return sqflite.Sqflite.firstIntValue(result) ?? 0;
  }

  /// Debug: Obtiene todos los mensajes para diagnóstico
  Future<void> debugPrintAllMessages() async {
    try {
      List<Map<String, dynamic>> results;
      if (kIsWeb) {
        results = List.from(_webMessages)
          ..sort((a, b) =>
              (b['created_at'] as int).compareTo(a['created_at'] as int));
        results = results.take(50).toList();
      } else {
        final db = await database;
        results = await db.query('chat_messages',
            orderBy: 'created_at DESC', limit: 50);
      }
      _logger.d('=== DEBUG: Todos los mensajes en la BD ===');
      _logger.d('Total de mensajes: ${results.length}');
      for (final row in results) {
        final content = row['content'] as String;
        final preview =
            content.length > 30 ? '${content.substring(0, 30)}...' : content;
        _logger.d(
            'ID: ${row['id']}, UserID: ${row['user_id']}, Author: ${row['author']}, Content: $preview');
      }
      _logger.d('=== FIN DEBUG ===');
    } catch (e) {
      _logger.e('Error en debugPrintAllMessages: $e');
    }
  }

  /// Cierra la base de datos
  Future<void> close() async {
    if (kIsWeb) {
      // En web no hay nada que cerrar
      return;
    }
    final db = await database;
    await db.close();
    _database = null;
  }
}
