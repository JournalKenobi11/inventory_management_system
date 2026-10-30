import 'dart:convert';
import 'labour_entry.dart';

class Service {
  final String id;
  final String customerId;
  final String? problemDesc;
  final double labourCharge;
  final String serviceDate;
  final String? invoiceId;
  final String? serviceReport;
  final String? labourEntriesJson;

  const Service({
    required this.id,
    required this.customerId,
    this.problemDesc,
    required this.labourCharge,
    required this.serviceDate,
    this.invoiceId,
    this.serviceReport,
    this.labourEntriesJson,
  });

  List<LabourEntry> get labourEntries {
    if (labourEntriesJson != null && labourEntriesJson!.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(labourEntriesJson!) as List;
        return decoded
            .map((e) => LabourEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    if (labourCharge > 0) {
      return [
        LabourEntry(
          description: 'Labour / Service Charges',
          charge: labourCharge,
        )
      ];
    }
    return const [];
  }

  Service copyWith({
    String? id,
    String? customerId,
    String? problemDesc,
    double? labourCharge,
    String? serviceDate,
    String? invoiceId,
    String? serviceReport,
    String? labourEntriesJson,
  }) {
    return Service(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      problemDesc: problemDesc ?? this.problemDesc,
      labourCharge: labourCharge ?? this.labourCharge,
      serviceDate: serviceDate ?? this.serviceDate,
      invoiceId: invoiceId ?? this.invoiceId,
      serviceReport: serviceReport ?? this.serviceReport,
      labourEntriesJson: labourEntriesJson ?? this.labourEntriesJson,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'problemDesc': problemDesc,
      'labourCharge': labourCharge,
      'serviceDate': serviceDate,
      'invoiceId': invoiceId,
      'serviceReport': serviceReport,
      'labourEntriesJson': labourEntriesJson,
    };
  }

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      problemDesc: json['problemDesc'] as String?,
      labourCharge: (json['labourCharge'] as num).toDouble(),
      serviceDate: json['serviceDate'] as String,
      invoiceId: json['invoiceId'] as String?,
      serviceReport: json['serviceReport'] as String?,
      labourEntriesJson: json['labourEntriesJson'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Service &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            customerId == other.customerId &&
            problemDesc == other.problemDesc &&
            labourCharge == other.labourCharge &&
            serviceDate == other.serviceDate &&
            invoiceId == other.invoiceId &&
            serviceReport == other.serviceReport &&
            labourEntriesJson == other.labourEntriesJson;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      customerId,
      problemDesc,
      labourCharge,
      serviceDate,
      invoiceId,
      serviceReport,
      labourEntriesJson,
    );
  }

  @override
  String toString() {
    return 'Service('
        'id: $id, '
        'customerId: $customerId, '
        'problemDesc: $problemDesc, '
        'labourCharge: $labourCharge, '
        'serviceDate: $serviceDate, '
        'invoiceId: $invoiceId, '
        'serviceReport: $serviceReport, '
        'labourEntriesJson: $labourEntriesJson'
        ')';
  }
}