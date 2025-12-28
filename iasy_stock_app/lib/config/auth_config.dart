import 'package:flutter/foundation.dart';

import 'auth_config_dev.dart';
import 'auth_config_prod.dart';

class AuthConfig {
  // Detectar ambiente de ejecución
  static const bool isProduction =
      bool.fromEnvironment('PRODUCTION', defaultValue: false);
  static const bool isStaging =
      bool.fromEnvironment('STAGING', defaultValue: false);

  // Permite sobreescribir el host en desarrollo (útil para dispositivo físico)
  static const String devHostOverride =
      String.fromEnvironment('DEV_HOST', defaultValue: '');
  static const String devMinioPort =
      String.fromEnvironment('DEV_MINIO_PORT', defaultValue: '9000');

  // Configuración dinámica basada en el ambiente
  static String get keycloakIssuer {
    String issuer = isProduction
        ? AuthConfigProd.keycloakIssuer
        : AuthConfigDev.keycloakIssuer;
    if (!isProduction && !kIsWeb) {
      final host = _resolveDevHost();
      issuer = issuer.replaceFirst('http://localhost', 'http://$host');
    }
    return issuer;
  }

  static String get clientId {
    if (isProduction) {
      return AuthConfigProd.clientId;
    } else {
      return AuthConfigDev.clientId;
    }
  }

  static String get redirectUrl {
    if (isProduction) {
      return AuthConfigProd.redirectUrl;
    } else {
      return AuthConfigDev.redirectUrl;
    }
  }

  static String get logoutRedirectUrl {
    if (isProduction) {
      return AuthConfigProd.logoutRedirectUrl;
    } else {
      return AuthConfigDev.logoutRedirectUrl;
    }
  }

  static String get apiBaseUrl {
    String base =
        isProduction ? AuthConfigProd.apiBaseUrl : AuthConfigDev.apiBaseUrl;
    if (!isProduction && !kIsWeb) {
      final host = _resolveDevHost();
      base = base.replaceFirst('http://localhost', 'http://$host');
      print(
          '🔧 AuthConfig: Platform=${defaultTargetPlatform.name}, Host=$host, API URL=$base');
    }
    return base;
  }

  /// URL base para MinIO - mantiene localhost para evitar problemas de red
  static String get minioBaseUrl {
    // Para MinIO, siempre usar localhost en desarrollo ya que las URLs firmadas
    // se generan en el backend y deben ser accesibles desde el dispositivo
    if (isProduction) {
      return 'https://minio.iasystock.lat'; // URL de producción
    } else {
      final host = _resolveDevHost();
      final port = _resolveMinioPort();
      return 'http://$host:$port';
    }
  }

  static String get webRedirectUrl {
    if (isProduction) {
      return AuthConfigProd.webRedirectUrl;
    } else {
      return AuthConfigDev.webRedirectUrl;
    }
  }

  static String get webLogoutUrl {
    if (isProduction) {
      return AuthConfigProd.webLogoutUrl;
    } else {
      return AuthConfigDev.webLogoutUrl;
    }
  }

  static String get webBaseUrl {
    if (isProduction) {
      return AuthConfigProd.webBaseUrl;
    } else {
      return AuthConfigDev.webBaseUrl;
    }
  }

  // Configuración de discovery
  static String get discoveryUrl {
    // Endpoint estándar OIDC
    return '$keycloakIssuer/.well-known/openid-configuration';
  }

  // Scopes requeridos
  static const List<String> scopes = ['openid', 'profile', 'email', 'roles'];

  // Configuración de tokens
  static int get tokenRefreshThresholdMinutes {
    if (isProduction) {
      return AuthConfigProd.tokenRefreshThresholdMinutes;
    } else {
      return AuthConfigDev.tokenRefreshThresholdMinutes;
    }
  }

  static int get accessTokenExpiryHours {
    if (isProduction) {
      return AuthConfigProd.accessTokenExpiryHours;
    } else {
      return AuthConfigDev.accessTokenExpiryHours;
    }
  }

  static int get refreshTokenExpiryDays {
    if (isProduction) {
      return AuthConfigProd.refreshTokenExpiryDays;
    } else {
      return AuthConfigDev.refreshTokenExpiryDays;
    }
  }

  // Configuración de PKCE
  static const int codeVerifierLength = 128;
  static const String codeChallengeMethod = 'S256';

  // Configuración de almacenamiento
  static String get userStorageKey {
    if (isProduction) {
      return AuthConfigProd.userStorageKey;
    } else {
      return AuthConfigDev.userStorageKey;
    }
  }

  static String get tokensStorageKey {
    if (isProduction) {
      return AuthConfigProd.tokensStorageKey;
    } else {
      return AuthConfigDev.tokensStorageKey;
    }
  }

  // Configuración de logging
  static bool get enableDebugLogs {
    if (isProduction) {
      return AuthConfigProd.enableDebugLogs;
    } else {
      return AuthConfigDev.enableDebugLogs;
    }
  }

  static bool get enableNetworkLogs {
    if (isProduction) {
      return AuthConfigProd.enableNetworkLogs;
    } else {
      return AuthConfigDev.enableNetworkLogs;
    }
  }

  // Configuración de seguridad
  static bool get disableSecurity {
    if (isProduction) {
      return false; // Nunca desactivar seguridad en producción
    } else {
      return AuthConfigDev.disableSecurity;
    }
  }

  // Métodos de utilidad
  static String get currentEnvironment {
    return isProduction ? 'production' : 'development';
  }

  static bool get isDevelopment {
    return !isProduction && !isStaging;
  }

  static String get defaultLocalHost => _resolveDevHost();

  static int get minioPort => _resolveMinioPort();

  static String _resolveDevHost() {
    if (devHostOverride.isNotEmpty) {
      return devHostOverride;
    }

    if (kIsWeb) {
      return 'localhost';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return '10.0.2.2';
      case TargetPlatform.iOS:
        return '127.0.0.1';
      default:
        return 'localhost';
    }
  }

  static int _resolveMinioPort() {
    final parsed = int.tryParse(devMinioPort);
    if (parsed != null && parsed > 0) {
      return parsed;
    }
    return 9000;
  }

  static List<String> getAllowedRedirectUris() {
    if (isProduction) {
      return [
        AuthConfigProd.redirectUrl,
        AuthConfigProd.logoutRedirectUrl,
        AuthConfigProd.webRedirectUrl,
        AuthConfigProd.webLogoutUrl,
        AuthConfigProd.altWebRedirectUrl,
        AuthConfigProd.altWebLogoutUrl,
      ];
    } else {
      return [
        AuthConfigDev.redirectUrl,
        AuthConfigDev.logoutRedirectUrl,
        AuthConfigDev.webRedirectUrl,
        AuthConfigDev.webLogoutUrl,
        AuthConfigDev.androidEmulatorUrl,
        AuthConfigDev.localhostUrl,
      ];
    }
  }
}
