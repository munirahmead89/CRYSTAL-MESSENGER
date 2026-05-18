import 'package:flutter_contacts/flutter_contacts.dart';
import 'permission_service.dart';
import 'supabase_service.dart';
import '../models/models.dart';
import 'package:flutter/foundation.dart';

class ContactService {
  static final ContactService instance = ContactService._internal();
  ContactService._internal();

  Future<List<UserModel>> syncAppContacts() async {
    try {
      final hasPermission = await PermissionService.requestContactsPermission();
      if (!hasPermission) {
        debugPrint('[ContactService] Contacts permission denied');
        return [];
      }

      // Fetch contacts from device with phone numbers only.
      final contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.phone},
      );

      final phoneNumbers = <String>{};
      for (final contact in contacts) {
        for (final phone in contact.phones) {
          final normalized = phone.number.replaceAll(RegExp(r'[^+\d]'), '');
          if (normalized.isNotEmpty) {
            phoneNumbers.add(normalized);
          }
        }
      }

      if (phoneNumbers.isEmpty) {
        return [];
      }

      return await SupabaseService.syncContacts(phoneNumbers.toList());
    } catch (e) {
      debugPrint('[ContactService] Error syncing contacts: $e');
      return [];
    }
  }
}
