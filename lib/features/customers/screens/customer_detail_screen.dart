import 'package:flutter/material.dart';

import '../models/customer.dart';

class CustomerDetailScreen extends StatelessWidget {
  final Customer customer;

  const CustomerDetailScreen({
    super.key,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customer.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            Text(
              'Mobile: ${customer.mobile}',
            ),

            const SizedBox(height: 8),

            Text(
              'Vehicle: ${customer.vehicleName ?? 'Not provided'}',
            ),

            const SizedBox(height: 8),

            Text(
              'Created: ${customer.createdDate}',
            ),
          ],
        ),
      ),
    );
  }
}