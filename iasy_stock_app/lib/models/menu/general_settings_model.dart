import 'package:freezed_annotation/freezed_annotation.dart';

part 'general_settings_model.freezed.dart';
part 'general_settings_model.g.dart';

@freezed
class GeneralSettingsModel with _$GeneralSettingsModel {
  const factory GeneralSettingsModel({
    int? id,
    required String key,
    required String value,
    String? description, // Changed from required String to String?
  }) = _GeneralSettingsModel;

  factory GeneralSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$GeneralSettingsModelFromJson(json);
}
