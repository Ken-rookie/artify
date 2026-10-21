import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  List<Map<String, dynamic>> _addresses = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  SupabaseClient get _client => Supabase.instance.client;
  String? get _userId => _client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final userId = _userId;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Sign in to manage your saved delivery addresses.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final rows = await _client
          .from('user_addresses')
          .select('id, recipient_name, phone, address, is_default')
          .eq('user_id', userId)
          .order('is_default', ascending: false)
          .order('created_at');
      if (!mounted) return;
      setState(() {
        _addresses = List<Map<String, dynamic>>.from(rows);
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Loading saved addresses failed: $error');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Could not load your saved addresses. Please try again.';
      });
    }
  }

  Future<void> _showAddressForm([Map<String, dynamic>? existing]) async {
    final formData = await showDialog<_AddressFormData>(
      context: context,
      builder: (_) => _AddressFormDialog(
        existing: existing,
        makeDefault: existing?['is_default'] as bool? ?? _addresses.isEmpty,
      ),
    );
    if (formData == null || !mounted) return;
    await _saveAddress(
      name: formData.name,
      phone: formData.phone,
      address: formData.address,
      isDefault: formData.isDefault || _addresses.isEmpty,
      existing: existing,
    );
  }

  Future<void> _saveAddress({
    required String name,
    required String phone,
    required String address,
    required bool isDefault,
    required Map<String, dynamic>? existing,
  }) async {
    final userId = _userId;
    if (userId == null) {
      _showMessage('Sign in to save a delivery address.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (isDefault) {
        await _client
            .from('user_addresses')
            .update({'is_default': false})
            .eq('user_id', userId)
            .eq('is_default', true);
      }

      final values = {
        'user_id': userId,
        'recipient_name': name,
        'phone': phone,
        'address': address,
        'is_default': isDefault,
      };
      if (existing == null) {
        await _client.from('user_addresses').insert(values);
      } else {
        await _client
            .from('user_addresses')
            .update(values)
            .eq('id', existing['id'])
            .eq('user_id', userId);
      }
      await _loadAddresses();
      if (mounted) _showMessage('Address saved.');
    } catch (error) {
      debugPrint('Saving address failed: $error');
      if (mounted) {
        _showMessage('Could not save the address. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _setDefault(Map<String, dynamic> address) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _client
          .from('user_addresses')
          .update({'is_default': false})
          .eq('user_id', userId)
          .eq('is_default', true);
      await _client
          .from('user_addresses')
          .update({'is_default': true})
          .eq('id', address['id'])
          .eq('user_id', userId);
      await _loadAddresses();
    } catch (error) {
      debugPrint('Setting default address failed: $error');
      if (mounted) _showMessage('Could not update the default address.');
    }
  }

  Future<void> _deleteAddress(Map<String, dynamic> address) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _client
          .from('user_addresses')
          .delete()
          .eq('id', address['id'])
          .eq('user_id', userId);
      if (address['is_default'] == true) {
        final remaining =
            _addresses.where((item) => item['id'] != address['id']).toList();
        if (remaining.isNotEmpty) {
          await _client
              .from('user_addresses')
              .update({'is_default': true})
              .eq('id', remaining.first['id'])
              .eq('user_id', userId);
        }
      }
      await _loadAddresses();
      if (mounted) _showMessage('Address removed.');
    } catch (error) {
      debugPrint('Deleting saved address failed: $error');
      if (mounted) _showMessage('Could not remove the address.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Addresses')),
        floatingActionButton: _error?.startsWith('Sign in') == true
            ? null
            : FloatingActionButton.extended(
                backgroundColor: AppColors.orange,
                foregroundColor: AppColors.ink,
                onPressed: _isSaving ? null : () => _showAddressForm(),
                icon: const Icon(Icons.add),
                label: const Text('Add address'),
              ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _MessageState(
                    message: _error!,
                    onRetry:
                        _error!.startsWith('Sign in') ? null : _loadAddresses,
                  )
                : _addresses.isEmpty
                    ? const _MessageState(
                        icon: Icons.location_on_outlined,
                        message:
                            'No saved addresses yet. Add one to speed up checkout.',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAddresses,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                          children: [
                            Text(
                              'Saved to your account and ready to use at checkout.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.muted),
                            ),
                            const SizedBox(height: 12),
                            for (final address in _addresses)
                              _AddressCard(
                                address: address,
                                onEdit: () => _showAddressForm(address),
                                onDelete: () => _deleteAddress(address),
                                onMakeDefault: () => _setDefault(address),
                              ),
                          ],
                        ),
                      ),
      );
}

class _AddressCard extends StatelessWidget {
  final Map<String, dynamic> address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMakeDefault;

  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onMakeDefault,
  });

  @override
  Widget build(BuildContext context) {
    final isDefault = address['is_default'] as bool? ?? false;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 3),
              child: Icon(Icons.location_on_outlined, color: AppColors.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          address['recipient_name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (isDefault)
                        const Chip(
                          label: Text('Default'),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(address['phone'] as String),
                  const SizedBox(height: 4),
                  Text(address['address'] as String),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: [
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 17),
                        label: const Text('Edit'),
                      ),
                      if (!isDefault)
                        TextButton(
                          onPressed: onMakeDefault,
                          child: const Text('Set default'),
                        ),
                      IconButton(
                        tooltip: 'Delete address',
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressFormData {
  final String name;
  final String phone;
  final String address;
  final bool isDefault;

  const _AddressFormData({
    required this.name,
    required this.phone,
    required this.address,
    required this.isDefault,
  });
}

class _AddressFormDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final bool makeDefault;

  const _AddressFormDialog({
    required this.existing,
    required this.makeDefault,
  });

  @override
  State<_AddressFormDialog> createState() => _AddressFormDialogState();
}

class _AddressFormDialogState extends State<_AddressFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late bool _makeDefault;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existing?['recipient_name'] as String? ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.existing?['phone'] as String? ?? '',
    );
    _addressController = TextEditingController(
      text: widget.existing?['address'] as String? ?? '',
    );
    _makeDefault = widget.makeDefault;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _validate(String? value, String label,
      {required int min, required int max}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$label is required';
    if (text.length < min) return '$label must be at least $min characters';
    if (text.length > max) return '$label must be $max characters or fewer';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _AddressFormData(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        isDefault: _makeDefault,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.existing == null ? 'Add address' : 'Edit address'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Recipient name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) =>
                      _validate(value, 'Name', min: 2, max: 120),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) =>
                      _validate(value, 'Phone number', min: 5, max: 40),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Complete delivery address',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (value) =>
                      _validate(value, 'Address', min: 5, max: 500),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _makeDefault,
                  title: const Text('Use as default address'),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (value) =>
                      setState(() => _makeDefault = value ?? false),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _submit,
            child: const Text('Save'),
          ),
        ],
      );
}

class _MessageState extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;

  const _MessageState({
    required this.message,
    this.icon = Icons.info_outline,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: AppColors.muted),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                TextButton(onPressed: onRetry, child: const Text('Try again')),
              ],
            ],
          ),
        ),
      );
}
