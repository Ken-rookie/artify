import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class OrderTrackingScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderTrackingScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final orderNumber =
        order['order_number']?.toString() ?? order['id']?.toString() ?? 'Order';
    final status = order['status']?.toString() ?? 'unknown';
    final paymentStatus = order['payment_status']?.toString() ?? 'unknown';
    final items = (order['items'] as List?)
            ?.whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList() ??
        [];
    final total = (order['total'] as num?)?.toStringAsFixed(0) ??
        order['total_amount']?.toString() ??
        '0';
    final placedAt = DateTime.tryParse(order['placed_at']?.toString() ?? '');

    return Scaffold(
      appBar: AppBar(title: const Text('Order details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Order #$orderNumber',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            placedAt == null
                ? 'Date unavailable'
                : 'Placed ${placedAt.toLocal().toString().substring(0, 16)}',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PAYMENT',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  _DetailRow(
                    'Payment method',
                    order['payment_method']?.toString() == 'paymongo'
                        ? 'QRPH'
                        : 'Cash on delivery',
                  ),
                  _DetailRow(
                    'Payment status',
                    _paymentLabel(paymentStatus),
                    valueColor: paymentStatus == 'paid'
                        ? Colors.green
                        : paymentStatus == 'failed'
                            ? Theme.of(context).colorScheme.error
                            : AppColors.orange,
                  ),
                  _DetailRow('Order status', _prettyStatus(status)),
                  _DetailRow('Total', '₱$total', bold: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('ORDER PROGRESS',
              style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          if (status == 'cancelled')
            const _ProgressRow(
              title: 'Order cancelled',
              description:
                  'This order was cancelled. No successful payment is recorded.',
              complete: true,
              last: true,
              failed: true,
            )
          else
            ..._progressFor(status, paymentStatus),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('ITEMS', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    ListTile(
                      title:
                          Text(items[i]['product_name']?.toString() ?? 'Item'),
                      subtitle: Text('Quantity: ${items[i]['quantity'] ?? 0}'),
                      trailing: Text(
                          '₱${(items[i]['line_total'] as num?)?.toStringAsFixed(0) ?? '0'}'),
                    ),
                    if (i < items.length - 1) const Divider(height: 1),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

List<Widget> _progressFor(String status, String paymentStatus) {
  final currentStep = switch (status) {
    'pending_payment' => 0,
    'processing' => 1,
    'shipped' => 2,
    'delivered' || 'completed' => 3,
    _ => 0,
  };
  final steps = [
    (
      'Order placed',
      paymentStatus == 'pending'
          ? 'Order received. Payment confirmation is still pending.'
          : paymentStatus == 'failed'
              ? 'Payment was not completed.'
              : 'We received your order.'
    ),
    ('Processing', 'Your order is being prepared.'),
    ('Shipped', 'Your order is on its way.'),
    ('Delivered', 'Your order has been delivered.'),
  ];
  return [
    for (var i = 0; i < steps.length; i++)
      _ProgressRow(
        title: steps[i].$1,
        description: steps[i].$2,
        complete: i <= currentStep,
        last: i == steps.length - 1,
        failed: i == 0 && paymentStatus == 'failed',
      ),
  ];
}

String _paymentLabel(String status) => switch (status) {
      'paid' => 'Paid',
      'pending' => 'Awaiting payment',
      'failed' => 'Failed',
      'unpaid' => 'Pay on delivery',
      _ => _prettyStatus(status),
    };

String _prettyStatus(String status) => status
    .split('_')
    .map((word) =>
        word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
    .join(' ');

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _DetailRow(this.label, this.value,
      {this.valueColor, this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
                child: Text(label,
                    style: const TextStyle(color: AppColors.muted))),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}

class _ProgressRow extends StatelessWidget {
  final String title;
  final String description;
  final bool complete;
  final bool last;
  final bool failed;

  const _ProgressRow({
    required this.title,
    required this.description,
    required this.complete,
    required this.last,
    this.failed = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Icon(
                  failed
                      ? Icons.cancel_outlined
                      : complete
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                  color: failed
                      ? Theme.of(context).colorScheme.error
                      : complete
                          ? AppColors.orange
                          : AppColors.muted,
                ),
                if (!last)
                  Container(width: 2, height: 32, color: AppColors.line),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(description,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
}
