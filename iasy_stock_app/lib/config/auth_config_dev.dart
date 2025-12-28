class AuthConfigDev {
  // Configuración de Keycloak para desarrollo
  static const String keycloakIssuer =
      'http://localhost:9083/realms/iasy-stock';
  static const String clientId = 'iasy-stock-flutter-client';
  static const String redirectUrl = 'com.iasystock.app://login-callback';
  static const String logoutRedirectUrl = 'com.iasystock.app://logout-callback';

  // URLs de la API para desarrollo
  static const String apiBaseUrl = 'http://localhost:8089';

  // URLs para web en desarrollo
  static const String webRedirectUrl = 'http://localhost:3000/login-callback';
  static const String webLogoutUrl = 'http://localhost:3000/logout-callback';
  static const String webBaseUrl = 'http://localhost:3000';

  // URLs adicionales para desarrollo móvil
  static const String androidEmulatorUrl = 'http://10.0.2.2:3000';
  static const String localhostUrl = 'http://127.0.0.1:3000';

  // Configuración de discovery
  static String get discoveryUrl {
    return '$keycloakIssuer/.well-known/openid-configuration';
  }

  // Scopes requeridos
  static const List<String> scopes = ['openid', 'profile', 'email', 'roles'];

  // Configuración de tokens para desarrollo
  static const int tokenRefreshThresholdMinutes = 5;
  static const int accessTokenExpiryHours = 1;
  static const int refreshTokenExpiryDays = 30;

  // Configuración de PKCE
  static const int codeVerifierLength = 128;
  static const String codeChallengeMethod = 'S256';

  // Configuración de almacenamiento
  static const String userStorageKey = 'auth_user_dev';
  static const String tokensStorageKey = 'auth_tokens_dev';

  // Configuración de logging para desarrollo
  static const bool enableDebugLogs = true;
  static const bool enableNetworkLogs = true;

  // Configuración de seguridad para desarrollo
  static const bool disableSecurity =
      bool.fromEnvironment('DISABLE_SECURITY', defaultValue: false);
}
