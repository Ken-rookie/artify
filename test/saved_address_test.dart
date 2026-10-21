import 'package:flutter_test/flutter_test.dart';
import 'package:artify/models/saved_address.dart';

void main() {
  test('saved address maps Supabase row fields', () {
    final address = SavedAddress.fromJson({
      'id': 'address-1',
      'recipient_name': 'Juan Dela Cruz',
      'phone': '09171234567',
      'address': 'Bohol, Philippines',
      'is_default': true,
    });

    expect(address.id, 'address-1');
    expect(address.recipientName, 'Juan Dela Cruz');
    expect(address.phone, '09171234567');
    expect(address.address, 'Bohol, Philippines');
    expect(address.isDefault, isTrue);
  });
}
