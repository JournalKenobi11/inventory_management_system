import '../../parts/models/part.dart';

class DashboardPartSales {
  final String partId;
  final String partName;
  final int quantitySold;
  final double revenue;

  const DashboardPartSales({
    required this.partId,
    required this.partName,
    required this.quantitySold,
    required this.revenue,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DashboardPartSales &&
            runtimeType == other.runtimeType &&
            partId == other.partId &&
            partName == other.partName &&
            quantitySold == other.quantitySold &&
            revenue == other.revenue;
  }

  @override
  int get hashCode {
    return Object.hash(
      partId,
      partName,
      quantitySold,
      revenue,
    );
  }
}

class DashboardSummary {
  final double totalSales;
  final double totalExpenses;
  final double profit;
  final int servicesCompleted;
  final double inventoryValue;
  final List<Part> lowStockParts;
  final List<DashboardPartSales> topSellingParts;

  const DashboardSummary({
    required this.totalSales,
    required this.totalExpenses,
    required this.profit,
    required this.servicesCompleted,
    required this.inventoryValue,
    required this.lowStockParts,
    required this.topSellingParts,
  });

  const DashboardSummary.empty()
      : totalSales = 0,
        totalExpenses = 0,
        profit = 0,
        servicesCompleted = 0,
        inventoryValue = 0,
        lowStockParts = const [],
        topSellingParts = const [];

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DashboardSummary &&
            runtimeType == other.runtimeType &&
            totalSales == other.totalSales &&
            totalExpenses == other.totalExpenses &&
            profit == other.profit &&
            servicesCompleted == other.servicesCompleted &&
            inventoryValue == other.inventoryValue &&
            _listEquals(
              lowStockParts,
              other.lowStockParts,
            ) &&
            _listEquals(
              topSellingParts,
              other.topSellingParts,
            );
  }

  @override
  int get hashCode {
    return Object.hash(
      totalSales,
      totalExpenses,
      profit,
      servicesCompleted,
      inventoryValue,
      Object.hashAll(lowStockParts),
      Object.hashAll(topSellingParts),
    );
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }

  if (a.length != b.length) {
    return false;
  }

  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }

  return true;
}