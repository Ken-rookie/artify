class SavedAddress {
  final String id;
  final String recipientName;
  final String phone;
  final String address;
  final bool isDefault;

  const SavedAddress({
    required this.id,
    required this.recipientName,
    required this.phone,
    required this.address,
    required this.isDefault,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
        id: json['id'] as String,
        recipientName: json['recipient_name'] as String,
        phone: json['phone'] as String,
        address: json['address'] as String,
        isDefault: json['is_default'] as bool? ?? false,
      );
}
