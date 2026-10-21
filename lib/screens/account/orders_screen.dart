import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';
import 'order_tracking_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Supabase.instance.client.rpc('get_my_orders');
      if (result is! List) {
        throw const FormatException('Invalid order history response.');
      }
      final orders = result
          .whereType<Map>()
          .map((order) => Map<String, dynamic>.from(order))
          .toList();
      if (mounted) setState(() => _orders = orders);
    } catch (error) {
      debugPrint('Loading order history failed: $error');
      if (mounted) {
        setState(() {
          _error =
              'We could not load your orders. Check your connection and try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My Orders')),
        body: RefreshIndicator(
          onRefresh: _loadOrders,
          child: _loading && _orders.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 220),
                    Center(child: CircularProgressIndicator()),
                  ],
                )
              : _error != null && _orders.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 100),
                        const Icon(Icons.cloud_off_outlined,
                            size: 56, color: AppColors.muted),
                        const SizedBox(height: 16),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.muted)),
                        const SizedBox(height: 16),
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: _loadOrders,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try again'),
                          ),
                        ),
                      ],
                    )
                  : _orders.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(24),
                          children: const [
                            SizedBox(height: 100),
                            Icon(Icons.receipt_long_outlined,
                                size: 56, color: AppColors.muted),
                            SizedBox(height: 16),
                            Text(
                              'No orders yet',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 20),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Your orders and payment updates will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            const Text(
                              'Recent Orders',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 20),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Payment and delivery status comes from your order record.',
                              style: TextStyle(color: AppColors.muted),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(_error!,
                                  style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.error)),
                            ],
                            const SizedBox(height: 14),
                            for (final order in _orders)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _OrderCard(
                                  order: order,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          OrderTrackingScreen(order: order),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
        ),
      );
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final orderNumber =
        order['order_number']?.toString() ?? order['id']?.toString() ?? 'Order';
    final status = order['status']?.toString() ?? 'unknown';
    final paymentStatus = order['payment_status']?.toString() ?? 'unknown';
    final total = (order['total'] as num?)?.toStringAsFixed(0) ??
        order['total_amount']?.toString() ??
        '0';
    final placedAt = DateTime.tryParse(order['placed_at']?.toString() ?? '');
    final paymentLabel = switch (paymentStatus) {
      'paid' => 'Paid',
      'failed' => 'Payment failed',
      'pending' => 'Awaiting payment',
      'unpaid' => 'Cash on delivery',
      _ => paymentStatus,
    };
    final statusColor = paymentStatus == 'paid'
        ? Colors.green
        : paymentStatus == 'failed' || status == 'cancelled'
            ? Theme.of(context).colorScheme.error
            : AppColors.orange;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long_outlined,
                      color: AppColors.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Order #$orderNumber',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                placedAt == null
                    ? 'Date unavailable'
                    : 'Placed ${placedAt.toLocal().toString().substring(0, 16)}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const Divider(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _StatusChip(
                      icon: paymentStatus == 'paid'
                          ? Icons.verified_outlined
                          : Icons.payments_outlined,
                      text: paymentLabel,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('₱$total',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _prettyStatus(status),
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StatusChip(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(text,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}

String _prettyStatus(String status) => status
    .split('_')
    .map((word) =>
        word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
    .join(' ');
