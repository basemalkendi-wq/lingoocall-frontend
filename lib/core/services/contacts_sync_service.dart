import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:lingoocall/core/services/backend_api_service.dart';
import 'package:lingoocall/features/contacts/domain/models/contact_item.dart';

class ContactsSyncService {
  ContactsSyncService._();

  static final ContactsSyncService instance = ContactsSyncService._();

  Future<List<ContactItem>> syncDeviceContacts() async {
    final granted = await FlutterContacts.requestPermission(readonly: true);
    if (!granted) {
      return const [];
    }

    final localContacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: false,
    );

    final normalizedContacts = localContacts
        .map((contact) {
          final primaryPhone = contact.phones.isNotEmpty
              ? contact.phones.first.number.replaceAll(RegExp(r'[^0-9+]'), '')
              : '';
          if (primaryPhone.length < 7) {
            return null;
          }

          return {
            'name': contact.displayName,
            'phone': primaryPhone,
          };
        })
        .whereType<Map<String, String>>()
        .toList(growable: false);

    if (normalizedContacts.isEmpty) {
      return const [];
    }

    return BackendApiService.instance.syncContacts(contacts: normalizedContacts);
  }
}