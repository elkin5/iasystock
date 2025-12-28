/// Constantes de la aplicación
class AppConstants {
  // URLs
  static const String baseUrl = 'http://localhost:8089';
  static const String apiPrefix = '/api';

  // Paginación
  static const int defaultPageSize = 10;
  static const int defaultPage = 0;

  // Timeouts
  static const Duration requestTimeout = Duration(seconds: 120); // Aumentado para operaciones de IA
  static const Duration connectTimeout = Duration(seconds: 10);

  // Timeouts específicos para operaciones pesadas (IA, reconocimiento de imágenes)
  static const Duration aiOperationTimeout = Duration(seconds: 120);

  // Storage Keys
  static const String userStorageKey = 'auth_user';
  static const String tokensStorageKey = 'auth_tokens';
  static const String themeStorageKey = 'theme_mode';

  // Roles
  static const String roleSudo = 'sudo';
  static const String roleAdmin = 'admin';
  static const String roleSales = 'ventas';
  static const String roleWarehouse = 'almacenista';
  static const String roleUser = 'user';

  // Estados de venta
  static const String saleStatePending = 'PENDING';
  static const String saleStateCompleted = 'COMPLETED';
  static const String saleStateCancelled = 'CANCELLED';

  // Métodos de pago
  static const String paymentMethodCash = 'CASH';
  static const String paymentMethodCard = 'CARD';
  static const String paymentMethodTransfer = 'TRANSFER';

  // Configuración de imágenes
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];

  // Configuración de tokens
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);

  // Mensajes de error comunes
  static const String errorNetworkConnection = 'Error de conexión de red';
  static const String errorServerError = 'Error del servidor';
  static const String errorUnauthorized = 'No autorizado';
  static const String errorForbidden = 'Acceso denegado';
  static const String errorNotFound = 'Recurso no encontrado';
  static const String errorValidation = 'Error de validación';

  // Mensajes de éxito comunes
  static const String successCreated = 'Creado exitosamente';
  static const String successUpdated = 'Actualizado exitosamente';
  static const String successDeleted = 'Eliminado exitosamente';
  static const String successSaved = 'Guardado exitosamente';
}
