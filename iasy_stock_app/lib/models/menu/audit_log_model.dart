import 'package:freezed_annotation/freezed_annotation.dart';

import '../../utils/converters.dart';

part 'audit_log_model.freezed.dart';
part 'audit_log_model.g.dart';

@freezed
class AuditLogModel with _$AuditLogModel {
  const factory AuditLogModel({
    int? id,
    required int userId,
    required String action,
    String? description, // Changed from required String to String?
    @DateTimeConverter()
    DateTime? createdAt, // Changed from required DateTime to DateTime?
  }) = _AuditLogModel;

  factory AuditLogModel.fromJson(Map<String, dynamic> json) =>
      _$AuditLogModelFromJson(json);
}
