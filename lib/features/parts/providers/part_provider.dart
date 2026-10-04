import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../models/part.dart';
import '../repositories/interfaces/part_repository.dart';
import '../repositories/sqlite/sqlite_part_repository.dart';
import '../services/part_service.dart';

final partRepositoryProvider = Provider<PartRepository>((ref) {
  return SqlitePartRepository(
    ref.read(appDatabaseProvider),
  );
});

final partServiceProvider = Provider<PartService>((ref) {
  return PartService(
    ref.read(partRepositoryProvider),
  );
});

final partsProvider =
    AsyncNotifierProvider<PartNotifier, List<Part>>(
  PartNotifier.new,
);

class PartNotifier extends AsyncNotifier<List<Part>> {
  PartService get service => ref.read(partServiceProvider);

  @override
  Future<List<Part>> build() async {
    return service.getAllParts();
  }

  Future<void> loadParts() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () => service.getAllParts(),
    );
  }

  Future<void> loadLowStockParts() async {
    state = await AsyncValue.guard(
      () => service.getLowStockParts(),
    );
  }

  Future<void> searchParts(String query) async {
    final parts = await service.getAllParts();

    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      state = AsyncData(parts);
      return;
    }

    final filtered = parts.where((part) {
      return part.partNumber.toLowerCase().contains(normalizedQuery) ||
          part.partName.toLowerCase().contains(normalizedQuery) ||
          (part.category?.toLowerCase().contains(normalizedQuery) ?? false);
    }).toList();

    state = AsyncData(filtered);
  }
}