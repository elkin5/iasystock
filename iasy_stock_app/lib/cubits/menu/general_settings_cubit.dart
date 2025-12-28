import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/menu/general_settings_model.dart';
import '../../services/menu/general_settings_service.dart';

sealed class GeneralSettingsState {}

class GeneralSettingsInitial extends GeneralSettingsState {}

class GeneralSettingsLoading extends GeneralSettingsState {}

class GeneralSettingsLoaded extends GeneralSettingsState {
  final List<GeneralSettingsModel> settings;

  GeneralSettingsLoaded(this.settings);
}

class SingleGeneralSettingsLoaded extends GeneralSettingsState {
  final GeneralSettingsModel setting;

  SingleGeneralSettingsLoaded(this.setting);
}

class GeneralSettingsCubit extends Cubit<GeneralSettingsState> {
  final GeneralSettingsService generalSettingsService;
  List<GeneralSettingsModel> _settings = [];

  GeneralSettingsCubit(this.generalSettingsService)
      : super(GeneralSettingsInitial());

  Future<void> loadSettings({int page = 0, int size = 10}) async {
    emit(GeneralSettingsLoading());
    try {
      _settings = await generalSettingsService.getAll(page: page, size: size);
      emit(GeneralSettingsLoaded(List.unmodifiable(_settings)));
    } catch (e) {
      emit(GeneralSettingsInitial());
      rethrow;
    }
  }

  Future<void> createSetting(GeneralSettingsModel setting) async {
    await generalSettingsService.create(setting);
  }

  Future<void> updateSetting(GeneralSettingsModel setting) async {
    await generalSettingsService.update(setting.id!, setting);
  }

  Future<void> deleteSetting(int id) async {
    await generalSettingsService.delete(id);
  }

  Future<void> deleteByKey(String key) async {
    await generalSettingsService.deleteByKey(key);
  }

  Future<void> getSettingById(int id) async {
    emit(GeneralSettingsLoading());
    try {
      final setting = await generalSettingsService.getById(id);
      emit(SingleGeneralSettingsLoaded(setting));
    } catch (e) {
      emit(GeneralSettingsInitial());
      rethrow;
    }
  }

  Future<void> findByKey(String key) async {
    emit(GeneralSettingsLoading());
    try {
      final setting = await generalSettingsService.findByKey(key);
      emit(SingleGeneralSettingsLoaded(setting));
    } catch (e) {
      emit(GeneralSettingsInitial());
      rethrow;
    }
  }

  Future<void> findByKeyContaining(String keyword,
      {int page = 0, int size = 10}) async {
    emit(GeneralSettingsLoading());
    try {
      final result = await generalSettingsService.findByKeyContaining(keyword,
          page: page, size: size);
      emit(GeneralSettingsLoaded(List.unmodifiable(result)));
    } catch (e) {
      emit(GeneralSettingsInitial());
      rethrow;
    }
  }

  void resetState() {
    emit(GeneralSettingsInitial());
  }
}
