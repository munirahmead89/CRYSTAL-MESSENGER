import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/hive_service.dart';
import '../../subscription/presentation/premium_dashboard.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(title: Text('Profile'), subtitle: Text('Privacy & Premium')),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.star, color: Colors.amber),
            title: const Text('Crystal Premium'),
            subtitle: const Text('Unlock custom ringtones & more'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PremiumDashboard()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Clear Chat Cache', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await HiveService.instance.messagesBox.clear();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache Cleared')));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => SupabaseService.auth.signOut(),
          ),
        ],
      ),
    );
  }
}
