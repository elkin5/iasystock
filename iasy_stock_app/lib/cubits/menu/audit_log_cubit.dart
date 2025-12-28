import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/menu/audit_log_model.dart';
import '../../services/menu/audit_log_service.dart';

sealed class AuditLogState {}

class AuditLogInitial extends AuditLogState {}

class AuditLogLoading extends AuditLogState {}

class AuditLogLoaded extends AuditLogState {
  final List<AuditLogModel> logs;

  AuditLogLoaded(this.logs);
}

class SingleAuditLogLoaded extends AuditLogState {
  final AuditLogModel log;

  SingleAuditLogLoaded(this.log);
}

class AuditLogCubit extends Cubit<AuditLogState> {
  final AuditLogService auditLogService;
  List<AuditLogModel> _logs = [];

  AuditLogCubit(this.auditLogService) : super(AuditLogInitial());

  Future<void> loadLogs({int page = 0, int size = 10}) async {
    emit(AuditLogLoading());
    try {
      _logs = await auditLogService.getAll(page: page, size: size);
      emit(AuditLogLoaded(List.unmodifiable(_logs)));
    } catch (e) {
      emit(AuditLogInitial());
      rethrow;
    }
  }

  Future<void> createLog(AuditLogModel log) async {
    await auditLogService.create(log);
  }

  Future<void> deleteLogById(int id) async {
    await auditLogService.deleteById(id);
  }

  Future<void> getLogById(int id) async {
    emit(AuditLogLoading());
    try {
      final log = await auditLogService.getById(id);
      emit(SingleAuditLogLoaded(log));
    } catch (e) {
      emit(AuditLogInitial());
      rethrow;
    }
  }

  Future<void> findByUserId(int userId, {int page = 0, int size = 10}) async {
    emit(AuditLogLoading());
    try {
      final result =
          await auditLogService.findByUserId(userId, page: page, size: size);
      emit(AuditLogLoaded(List.unmodifiable(result)));
    } catch (e) {
      emit(AuditLogInitial());
      rethrow;
    }
  }

  Future<void> findByAction(String action,
      {int page = 0, int size = 10}) async {
    emit(AuditLogLoading());
    try {
      final result =
          await auditLogService.findByAction(action, page: page, size: size);
      emit(AuditLogLoaded(List.unmodifiable(result)));
    } catch (e) {
      emit(AuditLogInitial());
      rethrow;
    }
  }

  Future<void> findByDateRange(DateTime start, DateTime end,
      {int page = 0, int size = 10}) async {
    emit(AuditLogLoading());
    try {
      final result = await auditLogService.findByCreatedAtBetween(start, end,
          page: page, size: size);
      emit(AuditLogLoaded(List.unmodifiable(result)));
    } catch (e) {
      emit(AuditLogInitial());
      rethrow;
    }
  }

  Future<void> deleteByUserId(int userId) async {
    await auditLogService.deleteByUserId(userId);
  }

  void resetState() {
    emit(AuditLogInitial());
  }
}
