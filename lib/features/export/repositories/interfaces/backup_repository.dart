import 'dart:io';

abstract class BackupRepository {
  Future<Map<String, List<Map<String, dynamic>>>> exportAllTables();
  Future<void> restoreAllTables(
    Map<String, List<Map<String, dynamic>>> tablesData,
  );
  Future<File> getDatabaseFile();

  /// Seeds tracked extreme fake data prefixed with `fake_` / `[FAKE]`.
  Future<int> seedExtremeFakeData();

  /// Deletes all tracked fake data with ID matching `fake_%`.
  Future<int> deleteFakeData();
}
