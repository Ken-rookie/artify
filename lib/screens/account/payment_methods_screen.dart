import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Payment Methods')), body: ListView(padding: const EdgeInsets.all(18), children: const [
    Card(child: ListTile(leading: Icon(Icons.account_balance_wallet_outlined, color: AppColors.orange), title: Text('GCash'), subtitle: Text('Available at checkout'))),
    Card(child: ListTile(leading: Icon(Icons.credit_card_outlined), title: Text('Credit / Debit Card'), subtitle: Text('Provider integration required'))),
    Card(child: ListTile(leading: Icon(Icons.account_balance_outlined), title: Text('Bank Transfer'), subtitle: Text('Instructions shown at checkout'))),
    Card(child: ListTile(leading: Icon(Icons.payments_outlined), title: Text('Cash on Delivery'), subtitle: Text('If supported for your address'))),
  ]));
}
