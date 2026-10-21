import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/supabase_config.dart';
import '../../data/product_catalog.dart';
import '../../models/product.dart';
import '../../models/saved_address.dart';
import '../../state/cart_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';
import '../account/addresses_screen.dart';

class CheckoutShippingScreen extends StatefulWidget {
  final Map<Product, int> items;
  final bool removeFromCart;

  const CheckoutShippingScreen({
    super.key,
    required this.items,
    this.removeFromCart = false,
  });

  int get subtotal => items.entries
      .fold(0, (sum, entry) => sum + entry.key.price * entry.value);

  @override
  State<CheckoutShippingScreen> createState() => _CheckoutShippingScreenState();
}

class _CheckoutShippingScreenState extends State<CheckoutShippingScreen> {
  static const _deliveryFee = 1;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  List<SavedAddress> _savedAddresses = [];
  String? _selectedSavedAddressId;
  bool _isLoadingAddresses = false;
  String? _addressLoadError;
  String _paymentMethod = 'cod';
  bool _isSubmitting = false;
  String? _submitError;

  bool get _isDemoCheckout =>
      kDebugMode &&
      widget.items.isNotEmpty &&
      widget.items.keys.every((product) => product.id.startsWith('demo-'));

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const shipping = _deliveryFee;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            if (_isDemoCheckout)
              _buildNotice(
                icon: Icons.science_outlined,
                message:
                    'Demo checkout only. No order will be saved or payment taken.',
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Secure checkout',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.items.length} ${widget.items.length == 1 ? 'item' : 'items'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                  ),
                ],
              ),
            ),
            if (_submitError != null) ...[
              _buildNotice(
                icon: Icons.error_outline,
                message: _submitError!,
                isError: true,
              ),
              const SizedBox(height: 16),
            ],
            _buildSectionCard(
              icon: Icons.local_shipping_outlined,
              title: 'Delivery details',
              caption: 'Where should we send your order?',
              child: Column(
                children: [
                  if (_isLoadingAddresses)
                    const LinearProgressIndicator(minHeight: 2),
                  if (_savedAddresses.isNotEmpty) ...[
                    _buildSavedAddressSelector(),
                    const SizedBox(height: 14),
                  ] else if (!_isLoadingAddresses &&
                      !_isDemoCheckout &&
                      SupabaseConfig.isInitialized &&
                      Supabase.instance.client.auth.currentUser != null) ...[
                    _buildSavedAddressHint(),
                    const SizedBox(height: 14),
                  ],
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      hintText: 'Enter your name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    onChanged: (_) => _onDeliveryFieldChanged(),
                    validator: (value) => _validateLength(
                      value,
                      'Full name',
                      min: 2,
                      max: 120,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      hintText: 'e.g. 0917 123 4567',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    onChanged: (_) => _onDeliveryFieldChanged(),
                    validator: (value) => _validateLength(
                      value,
                      'Phone number',
                      min: 5,
                      max: 40,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _addressController,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 2,
                    maxLines: 3,
                    autofillHints: const [AutofillHints.fullStreetAddress],
                    decoration: const InputDecoration(
                      labelText: 'Delivery address',
                      hintText: 'House / unit, street, barangay, city',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    onChanged: (_) => _onDeliveryFieldChanged(),
                    validator: (value) => _validateLength(
                      value,
                      'Delivery address',
                      min: 5,
                      max: 500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              icon: Icons.payment_outlined,
              title: 'Payment method',
              caption: 'Choose how you would like to pay.',
              child: Column(
                children: [
                  _buildPaymentOption(
                    value: 'cod',
                    title: 'Cash on delivery',
                    description: 'Pay when your order arrives.',
                    icon: Icons.local_shipping_outlined,
                  ),
                  const SizedBox(height: 10),
                  _buildPaymentOption(
                    value: 'paymongo',
                    title: 'QRPH via PayMongo',
                    description:
                        'Scan a QR code with your banking or wallet app.',
                    icon: Icons.qr_code_2,
                    badge: 'QRPH',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              icon: Icons.receipt_long_outlined,
              title: 'Order summary',
              caption: 'Review your items and total.',
              child: Column(
                children: [
                  for (var index = 0; index < widget.items.length; index++) ...[
                    _buildItemRow(
                      widget.items.keys.elementAt(index),
                      widget.items.values.elementAt(index),
                    ),
                    if (index < widget.items.length - 1)
                      const Divider(height: 20),
                  ],
                  const Divider(height: 24),
                  _SummaryRow('Subtotal', widget.subtotal),
                  const _SummaryRow('Shipping', shipping),
                  const SizedBox(height: 4),
                  _SummaryRow(
                    'Total',
                    widget.subtotal + shipping,
                    bold: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: AppColors.line)),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: .05),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('Total'),
                  const Spacer(),
                  Text(
                    '₱ ${widget.subtotal + shipping}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: _isSubmitting
                    ? 'Submitting...'
                    : _paymentMethod == 'cod'
                        ? 'Place COD order'
                        : 'Continue to QRPH payment',
                icon: _isSubmitting
                    ? Icons.hourglass_top
                    : _paymentMethod == 'cod'
                        ? Icons.check_circle_outline
                        : Icons.qr_code_2,
                onPressed: _isSubmitting ? null : _placeOrder,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String caption,
    required Widget child,
  }) =>
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: AppColors.ink, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        caption,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.muted,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      );

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required String description,
    required IconData icon,
    String? badge,
  }) {
    final selected = _paymentMethod == value;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: () => setState(() {
          _paymentMethod = value;
          _submitError = null;
        }),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.orange.withValues(alpha: .12)
                : const Color(0xFFFAF9F6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.orange : AppColors.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.ink, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.orange : AppColors.muted,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemRow(Product product, int quantity) => Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: product.tint.withValues(alpha: .35),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(product.icon, color: AppColors.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  'Qty $quantity · ₱ ${product.price} each',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '₱ ${product.price * quantity}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      );

  Widget _buildNotice({
    required IconData icon,
    required String message,
    bool isError = false,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isError
              ? const Color(0xFFFFEEEE)
              : AppColors.orange.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isError ? const Color(0xFFE6B8B8) : AppColors.line,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 20,
              color: isError ? const Color(0xFF9B3434) : AppColors.ink,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      );

  void _onDeliveryFieldChanged() {
    if (_submitError != null || _selectedSavedAddressId != null) {
      setState(() {
        _submitError = null;
        _selectedSavedAddressId = null;
      });
    }
  }

  String? _validateLength(
    String? value,
    String label, {
    required int min,
    required int max,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'This field is required';
    if (trimmed.length < min) {
      return '$label must be at least $min characters';
    }
    if (trimmed.length > max) {
      return '$label must be $max characters or fewer';
    }
    return null;
  }

  Future<void> _loadSavedAddresses() async {
    if (_isDemoCheckout || !SupabaseConfig.isInitialized) return;
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingAddresses = true;
      _addressLoadError = null;
    });
    try {
      final rows = await client
          .from('user_addresses')
          .select('id, recipient_name, phone, address, is_default')
          .eq('user_id', user.id)
          .order('is_default', ascending: false)
          .order('created_at');
      final addresses = (rows as List)
          .map(
            (row) => SavedAddress.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();
      if (!mounted) return;

      final defaultAddress = addresses.where((address) => address.isDefault);
      final selected = defaultAddress.isNotEmpty
          ? defaultAddress.first
          : addresses.isNotEmpty
              ? addresses.first
              : null;
      setState(() {
        _savedAddresses = addresses;
        _selectedSavedAddressId = selected?.id;
        _isLoadingAddresses = false;
      });

      if (selected != null) {
        _applySavedAddress(selected);
      } else {
        _nameController.text = user.userMetadata?['full_name'] as String? ?? '';
        _phoneController.text = user.phone ?? '';
      }
    } catch (error) {
      debugPrint('Loading checkout addresses failed: $error');
      if (!mounted) return;
      setState(() {
        _isLoadingAddresses = false;
        _addressLoadError = 'Saved addresses could not be loaded.';
      });
    }
  }

  Widget _buildSavedAddressSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            key: ValueKey(_selectedSavedAddressId),
            initialValue: _selectedSavedAddressId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Use a saved address',
              prefixIcon: Icon(Icons.bookmark_outline),
            ),
            items: [
              for (final address in _savedAddresses)
                DropdownMenuItem(
                  value: address.id,
                  child: Text(
                    '${address.recipientName}${address.isDefault ? ' · Default' : ''}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (id) {
              SavedAddress? address;
              for (final savedAddress in _savedAddresses) {
                if (savedAddress.id == id) {
                  address = savedAddress;
                  break;
                }
              }
              if (address != null) {
                setState(() {
                  _selectedSavedAddressId = id;
                  _submitError = null;
                });
                _applySavedAddress(address);
              }
            },
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: _manageSavedAddresses,
            icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
            label: const Text('Manage saved addresses'),
          ),
        ],
      );

  Widget _buildSavedAddressHint() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 19),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _addressLoadError ??
                    'Save your delivery details once and use them for faster checkout next time.',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: _manageSavedAddresses,
              child: const Text('Manage'),
            ),
          ],
        ),
      );

  void _applySavedAddress(SavedAddress address) {
    _nameController.text = address.recipientName;
    _phoneController.text = address.phone;
    _addressController.text = address.address;
  }

  Future<void> _manageSavedAddresses() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const AddressesScreen()),
    );
    if (mounted) await _loadSavedAddresses();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isDemoCheckout &&
        SupabaseConfig.isConfigured &&
        Supabase.instance.client.auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in before placing an order so it can be saved.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      if (_isDemoCheckout) {
        if (widget.removeFromCart) CartStore.instance.clear();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DemoCheckoutResultScreen(
              customerName: _nameController.text.trim(),
              paymentMethod: _paymentMethod,
              total: widget.subtotal + _deliveryFee,
            ),
          ),
        );
        return;
      }

      final response = await Supabase.instance.client.functions.invoke(
        'create-checkout',
        body: {
          'customerName': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'paymentMethod': _paymentMethod,
          'items': [
            for (final entry in widget.items.entries)
              {'productId': entry.key.id, 'quantity': entry.value},
          ],
        },
      );
      if (response.status >= 400 || response.data is! Map) {
        throw StateError('The order service could not create this order.');
      }

      final result = Map<String, dynamic>.from(response.data as Map);
      final orderId = result['orderId'] as String?;
      if (orderId == null) {
        throw StateError('The order service returned no order ID.');
      }

      if (widget.removeFromCart) CartStore.instance.clear();
      await ProductCatalog.instance.refresh();

      if (_paymentMethod == 'cod') {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderSuccessScreen(
              customerName: _nameController.text.trim(),
              orderId: orderId,
              totalAmount: (result['totalAmount'] as num?)?.toInt(),
            ),
          ),
        );
        return;
      }

      final checkoutUrl = result['checkoutUrl'] as String?;
      final accessToken = result['accessToken'] as String?;
      if (checkoutUrl == null || accessToken == null) {
        throw StateError('PayMongo did not return a checkout session.');
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentPendingScreen(
            orderId: orderId,
            accessToken: accessToken,
            checkoutUrl: checkoutUrl,
            customerName: _nameController.text.trim(),
            totalAmount: (result['totalAmount'] as num?)?.toInt() ?? 0,
          ),
        ),
      );
    } catch (error) {
      debugPrint('Checkout submission failed: $error');
      if (mounted) {
        setState(() {
          _submitError =
              "We couldn't place your order. Please check your connection and try again.";
        });
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class DemoCheckoutResultScreen extends StatefulWidget {
  final String customerName;
  final String paymentMethod;
  final int total;

  const DemoCheckoutResultScreen({
    super.key,
    required this.customerName,
    required this.paymentMethod,
    required this.total,
  });

  @override
  State<DemoCheckoutResultScreen> createState() =>
      _DemoCheckoutResultScreenState();
}

class _DemoCheckoutResultScreenState extends State<DemoCheckoutResultScreen> {
  bool _paymentSimulated = false;

  @override
  Widget build(BuildContext context) {
    final isPayMongo = widget.paymentMethod == 'paymongo';
    final isComplete = !isPayMongo || _paymentSimulated;

    return Scaffold(
      appBar: AppBar(title: const Text('Demo checkout')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isComplete ? Icons.check_circle_outline : Icons.payment,
                size: 72,
                color: AppColors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                isComplete ? 'Demo checkout complete' : 'Demo payment session',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Thanks, ${widget.customerName}. Total: ₱ ${widget.total}.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isComplete
                    ? 'This was a simulation only. No order was saved and no payment was taken.'
                    : 'No real PayMongo session was created. Simulate a successful payment to test the next step.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (!isComplete)
                FilledButton(
                  onPressed: () => setState(() => _paymentSimulated = true),
                  child: const Text('Simulate successful payment'),
                ),
              TextButton(
                onPressed: () => Navigator.popUntil(
                  context,
                  (route) => route.isFirst,
                ),
                child: const Text('Return to shop'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentPendingScreen extends StatefulWidget {
  final String orderId;
  final String accessToken;
  final String checkoutUrl;
  final String customerName;
  final int totalAmount;

  const PaymentPendingScreen({
    super.key,
    required this.orderId,
    required this.accessToken,
    required this.checkoutUrl,
    required this.customerName,
    required this.totalAmount,
  });

  @override
  State<PaymentPendingScreen> createState() => _PaymentPendingScreenState();
}

class _PaymentPendingScreenState extends State<PaymentPendingScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _checking = false;
  String _status = 'pending';
  String? _checkError;
  DateTime? _lastChecked;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refreshStatus());
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => unawaited(_refreshStatus()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshStatus());
    }
  }

  Future<void> _refreshStatus() async {
    if (_checking) return;
    _checking = true;
    if (mounted) setState(() => _checkError = null);
    try {
      final result = await Supabase.instance.client.rpc(
        'get_order_status',
        params: {
          'p_order_id': widget.orderId,
          'p_access_token': widget.accessToken,
        },
      );
      if (result is! Map) {
        throw const FormatException('Invalid payment status response.');
      }
      final paymentStatus = result['payment_status'] as String?;
      final orderStatus = result['status'] as String?;
      if (paymentStatus == null || orderStatus == null) {
        throw const FormatException(
            'Payment status was missing from response.');
      }
      if (!mounted) return;
      setState(() {
        _status = orderStatus == 'cancelled'
            ? 'cancelled'
            : paymentStatus == 'failed'
                ? 'failed'
                : paymentStatus;
        _lastChecked = DateTime.now();
      });
      if (paymentStatus == 'paid' && mounted) {
        _timer?.cancel();
        await _refreshCatalog();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderSuccessScreen(
              customerName: widget.customerName,
              orderId: widget.orderId,
              totalAmount: widget.totalAmount,
              paymentMethod: 'QRPH',
            ),
          ),
        );
      } else if ((orderStatus == 'cancelled' || paymentStatus == 'failed') &&
          mounted) {
        _timer?.cancel();
        await _refreshCatalog();
      }
    } catch (error) {
      debugPrint('Payment status check failed: $error');
      if (mounted) {
        setState(() {
          _checkError =
              'We could not reach the payment status service. Your payment is not confirmed yet. Check again when your connection is available.';
        });
      }
    } finally {
      _checking = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _refreshCatalog() async {
    try {
      await ProductCatalog.instance.refresh();
    } catch (error) {
      debugPrint('Refreshing catalog after payment status failed: $error');
    }
  }

  Future<void> _openCheckout() async {
    final opened = await launchUrl(
      Uri.parse(widget.checkoutUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open PayMongo checkout.')),
      );
    }
  }

  String get _statusTitle => switch (_status) {
        'cancelled' => 'Payment session expired',
        'failed' => 'Payment was not completed',
        'pending' || 'awaiting_payment' => 'Waiting for payment confirmation',
        _ => 'Checking payment status',
      };

  IconData get _statusIcon => switch (_status) {
        'cancelled' || 'failed' => Icons.error_outline,
        'paid' => Icons.check_circle_outline,
        _ => Icons.hourglass_top_rounded,
      };

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Payment status')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    Icon(_statusIcon, size: 58, color: AppColors.orange),
                    const SizedBox(height: 12),
                    Text(
                      _statusTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status == 'failed' || _status == 'cancelled'
                          ? 'This order was not paid. Its PayMongo session is no longer active; start a new order to try again.'
                          : 'We only mark this order as paid after PayMongo confirms it and the order record is updated.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ORDER DETAILS',
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 14),
                    _PaymentDetailRow('Order reference', widget.orderId),
                    const _PaymentDetailRow('Payment method', 'QRPH'),
                    _PaymentDetailRow(
                      'Order total',
                      '₱${widget.totalAmount}',
                      emphasize: true,
                    ),
                    _PaymentDetailRow(
                      'Payment status',
                      _status == 'pending' || _status == 'awaiting_payment'
                          ? 'Awaiting confirmation'
                          : _status[0].toUpperCase() + _status.substring(1),
                    ),
                  ],
                ),
              ),
            ),
            if (_checkError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _checkError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (_lastChecked != null)
              Text(
                'Last checked ${_lastChecked!.hour.toString().padLeft(2, '0')}:${_lastChecked!.minute.toString().padLeft(2, '0')}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
            const SizedBox(height: 12),
            if (_status != 'cancelled' && _status != 'failed')
              FilledButton.icon(
                onPressed: _openCheckout,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open PayMongo checkout'),
              ),
            OutlinedButton.icon(
              onPressed: _checking ? null : _refreshStatus,
              icon: _checking
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(_checking ? 'Checking…' : 'Check payment status'),
            ),
            if (_status == 'cancelled' || _status == 'failed')
              TextButton(
                onPressed: () => Navigator.popUntil(
                  context,
                  (route) => route.isFirst,
                ),
                child: const Text('Continue shopping'),
              ),
            const SizedBox(height: 8),
            const Text(
              'Keep this screen open or return to it after paying. A redirect by itself is not proof of payment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      );
}

class OrderSuccessScreen extends StatelessWidget {
  final String customerName;
  final String? orderId;
  final int? totalAmount;
  final String paymentMethod;

  const OrderSuccessScreen({
    super.key,
    required this.customerName,
    this.orderId,
    this.totalAmount,
    this.paymentMethod = 'Cash on delivery',
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Order confirmed')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded,
                    size: 72, color: AppColors.orange),
                const SizedBox(height: 16),
                Text(
                  paymentMethod == 'QRPH'
                      ? 'Payment confirmed, $customerName!'
                      : 'Order confirmed, $customerName!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  paymentMethod == 'QRPH'
                      ? 'PayMongo confirmed your QRPH payment and your order is now being processed.'
                      : 'Your order has been placed. Payment is due when your order is delivered.',
                  textAlign: TextAlign.center,
                ),
                if (orderId != null) ...[
                  const SizedBox(height: 20),
                  _PaymentDetailRow('Order reference', orderId!),
                  _PaymentDetailRow('Payment method', paymentMethod),
                  if (totalAmount != null)
                    _PaymentDetailRow(
                        paymentMethod == 'QRPH' ? 'Amount paid' : 'Order total',
                        '₱$totalAmount',
                        emphasize: true),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.popUntil(
                    context,
                    (route) => route.isFirst,
                  ),
                  child: const Text('Continue shopping'),
                ),
              ],
            ),
          ),
        ),
      );
}

class _PaymentDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _PaymentDetailRow(this.label, this.value, {this.emphasize = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child:
                  Text(label, style: const TextStyle(color: AppColors.muted)),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontWeight: emphasize ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final int amount;
  final bool bold;

  const _SummaryRow(this.label, this.amount, {this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Text(label,
                style: TextStyle(fontWeight: bold ? FontWeight.bold : null)),
            const Spacer(),
            Text(
              '₱ $amount',
              style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
            ),
          ],
        ),
      );
}
