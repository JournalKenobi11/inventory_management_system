import 'dart:io';

abstract class BackupRepository {
  Future<Map<String, List<Map<String, dynamic>>>> exportAllTables();
  Future<void> restoreAllTables(
    Map<String, List<Map<String, dynamic>>> tablesData,
  );
  Future<File> getDatabaseFile();
}
