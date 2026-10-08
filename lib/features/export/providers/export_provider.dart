import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../models/export_models.dart';
import '../repositories/interfaces/backup_repository.dart';
import '../repositories/sqlite/sqlite_backup_repository.dart';
import '../services/backup_service.dart';
import '../services/pdf_service.dart';
import '../services/share_service.dart';

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SqliteBackupRepository(db);
});

final pdfServiceProvider = Provider<PdfService>((ref) {
  return PdfService();
});

final backupServiceProvider = Provider<BackupService>((ref) {
  final repo = ref.watch(backupRepositoryProvider);
  return BackupService(repo);
});

final shareServiceProvider = Provider<ShareService>((ref) {
  return ShareService();
});

final backupControllerProvider =
    AsyncNotifierProvider<BackupController, BackupSummary?>(
      BackupController.new,
    );

class BackupController extends AsyncNotifier<BackupSummary?> {
  @override
  Future<BackupSummary?> build() async {
    return null;
  }

  Future<BackupSummary> createBackup() async {
    state = const AsyncLoading();
    try {
      final summary = await ref.read(backupServiceProvider).createBackup();
      state = AsyncData(summary);
      return summary;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<RestoreResult> restoreFromFile(File file) async {
    state = const AsyncLoading();
    try {
      final result = await ref
          .read(backupServiceProvider)
          .restoreFromFile(file);
      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<RestoreResult> restoreFromJsonString(String jsonContent) async {
    state = const AsyncLoading();
    try {
      final result = await ref
          .read(backupServiceProvider)
          .restoreFromJson(jsonContent);
      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
