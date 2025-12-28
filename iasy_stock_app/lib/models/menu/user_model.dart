import 'package:freezed_annotation/freezed_annotation.dart';

import '../../utils/converters.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    int? id,
    String? keycloakId,
    required String username, // Changed from String? to required String
    String? password,
    String? email,
    String? firstName,
    String? lastName,
    required String role, // Changed from String? to required String
    bool? isActive,
    @DateTimeConverter() DateTime? lastLoginAt,
    @DateTimeConverter() DateTime? createdAt,
    @DateTimeConverter() DateTime? updatedAt,
    // Removed calculated fields: isAdmin, isManager, isUser, isOidcUser, isLocalUser, fullName
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
