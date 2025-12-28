import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_user_model.freezed.dart';
part 'auth_user_model.g.dart';

@freezed
class AuthUser with _$AuthUser {
  const factory AuthUser({
    required String id,
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required List<String> roles,
    required String accessToken,
    required String refreshToken,
    required DateTime tokenExpiry,
    required String idToken,
  }) = _AuthUser;

  factory AuthUser.fromJson(Map<String, dynamic> json) =>
      _$AuthUserFromJson(json);
}

@freezed
class AuthTokens with _$AuthTokens {
  const factory AuthTokens({
    required String accessToken,
    required String refreshToken,
    required String idToken,
    required DateTime accessTokenExpiry,
    required DateTime refreshTokenExpiry,
  }) = _AuthTokens;

  factory AuthTokens.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensFromJson(json);
}

@freezed
class KeycloakConfig with _$KeycloakConfig {
  const factory KeycloakConfig({
    required String issuer,
    required String clientId,
    required String redirectUrl,
    required String discoveryUrl,
    required List<String> scopes,
  }) = _KeycloakConfig;

  factory KeycloakConfig.fromJson(Map<String, dynamic> json) =>
      _$KeycloakConfigFromJson(json);
}
