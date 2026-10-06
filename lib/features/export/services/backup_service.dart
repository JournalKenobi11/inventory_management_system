import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/errors/app_exceptions.dart';
import '../models/export_models.dart';
import '../repositories/interfaces/backup_repository.dart';

class BackupService {
  final BackupRepository backupRepository;

  BackupService(this.backupRepository);

  static const int currentBackupVersion = 1;
  static const String appIdentifier = 'inventory_management_system';

  Future<BackupSummary> createBackup({String? customDirectoryPath}) async {
    final tablesData = await backupRepository.exportAllTables();
    final now = DateTime.now();
    final nowIso = now.toIso8601String();

    int totalRecords = 0;
    final tableCounts = <String, int>{};

    for (final entry in tablesData.entries) {
      final count = entry.value.length;
      tableCounts[entry.key] = count;
      totalRecords += count;
    }

    final payload = {
      'app': appIdentifier,
      'version': currentBackupVersion,
      'exportDate': nowIso,
      'data': tablesData,
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(payload);

    final dirPath = customDirectoryPath ??
        (await getApplicationDocumentsDirectory()).path;
    final timestamp =
        '${now.year}${_two(now.month)}${_two(now.day)}_${_two(now.hour)}${_two(now.minute)}${_two(now.second)}';
    final fileName = 'backup_$timestamp.json';
    final file = File(p.join(dirPath, fileName));

    await file.writeAsString(jsonString);
    final size = await file.length();

    return BackupSummary(
      exportDate: nowIso,
      version: currentBackupVersion,
      totalRecords: totalRecords,
      tableCounts: tableCounts,
      filePath: file.path,
      fileSizeBytes: size,
    );
  }

  Future<String> exportBackupJsonString() async {
    final tablesData = await backupRepository.exportAllTables();
    final nowIso = DateTime.now().toIso8601String();

    final payload = {
      'app': appIdentifier,
      'version': currentBackupVersion,
      'exportDate': nowIso,
      'data': tablesData,
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<RestoreResult> restoreFromJson(String jsonContent) async {
    final trimmed = jsonContent.trim();
    if (trimmed.isEmpty) {
      throw ValidationException('Backup content is empty.');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(trimmed);
    } catch (e) {
      throw ValidationException('Invalid JSON format in backup content.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw ValidationException('Backup root must be a JSON object.');
    }

    if (decoded['app'] != appIdentifier) {
      throw ValidationException(
        'Incompatible backup: app identifier does not match $appIdentifier.',
      );
    }

    final rawData = decoded['data'];
    if (rawData is! Map<String, dynamic>) {
      throw ValidationException('Backup missing valid data section.');
    }

    final typedTables = <String, List<Map<String, dynamic>>>{};
    final counts = <String, int>{};

    for (final entry in rawData.entries) {
      if (entry.value is List) {
        final rows = <Map<String, dynamic>>[];
        for (final item in entry.value as List) {
          if (item is Map) {
            rows.add(Map<String, dynamic>.from(item));
          }
        }
        typedTables[entry.key] = rows;
        counts[entry.key] = rows.length;
      }
    }

    await backupRepository.restoreAllTables(typedTables);

    return RestoreResult(
      success: true,
      restoredCounts: counts,
      message: 'Database restored successfully with ${counts.values.fold<int>(0, (a, b) => a + b)} records.',
    );
  }

  Future<RestoreResult> restoreFromFile(File file) async {
    if (!await file.exists()) {
      throw NotFoundException('Backup file', file.path);
    }

    final content = await file.readAsString();
    return restoreFromJson(content);
  }

  Future<File> exportDatabaseFile({String? destinationPath}) async {
    final sourceDb = await backupRepository.getDatabaseFile();
    if (!await sourceDb.exists()) {
      throw NotFoundException('SQLite Database file', sourceDb.path);
    }

    final dir = destinationPath != null
        ? Directory(destinationPath)
        : await getApplicationDocumentsDirectory();

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final targetFile = File(p.join(dir.path, 'database_backup_$timestamp.sqlite'));

    return sourceDb.copy(targetFile.path);
  }

  static String _two(int val) => val.toString().padLeft(2, '0');
}
