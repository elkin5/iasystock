class AuthConfigProd {
  // Configuración de Keycloak para producción
  static const String keycloakIssuer =
      'https://auth.iasystock.lat/realms/iasy-stock';
  static const String clientId = 'iasy-stock-flutter-client';
  static const String redirectUrl = 'com.iasystock.app://login-callback';
  static const String logoutRedirectUrl = 'com.iasystock.app://logout-callback';

  // URLs de la API para producción
  static const String apiBaseUrl = 'https://api.iasystock.lat';

  // URLs para web en producción
  static const String webRedirectUrl =
      'https://app.iasystock.lat/auth/callback';
  static const String webLogoutUrl =
      'https://app.iasystock.lat/logout/callback';
  static const String webBaseUrl = 'https://app.iasystock.lat';

  // URLs alternativas de producción
  static const String altWebRedirectUrl = 'https://iasystock.lat/auth/callback';
  static const String altWebLogoutUrl = 'https://iasystock.lat/logout/callback';
  static const String altWebBaseUrl = 'https://iasystock.lat';

  // Configuración de discovery
  static String get discoveryUrl {
    return '$keycloakIssuer/.well-known/openid-configuration';
  }

  // Scopes requeridos
  static const List<String> scopes = ['openid', 'profile', 'email', 'roles'];

  // Configuración de tokens para producción (más restrictiva)
  static const int tokenRefreshThresholdMinutes = 10;
  static const int accessTokenExpiryHours = 1;
  static const int refreshTokenExpiryDays = 7; // Menos tiempo en producción

  // Configuración de PKCE
  static const int codeVerifierLength = 128;
  static const String codeChallengeMethod = 'S256';

  // Configuración de almacenamiento
  static const String userStorageKey = 'auth_user_prod';
  static const String tokensStorageKey = 'auth_tokens_prod';

  // Configuración de logging para producción
  static const bool enableDebugLogs = false;
  static const bool enableNetworkLogs = false;
}
