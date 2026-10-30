class BillTerms {
  static const List<String> standardTerms = [
    'All services, inspections, and repairs are performed with standard professional care.',
    'Warranty on replaced parts is strictly governed by manufacturer terms. No warranty on electrical items or consumables.',
    'Customers are advised to inspect the vehicle upon delivery. Any operational concerns must be reported within 24 hours.',
    'The workshop does not accept liability for loss or damage to personal valuables left inside the vehicle.',
    'Full settlement of the bill is required upon completion of service and vehicle delivery.',
    'Vehicles not collected within 7 days of service completion notice may be subject to parking and storage charges.',
  ];

  static String get formattedSingleString =>
      standardTerms.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n');
}
