import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildSectionHeader('Account'),
          ListTile(
            leading: const CircleAvatar(
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
            ),
            title: const Text('John Doe'),
            subtitle: const Text('john.doe@example.com'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          _buildSectionHeader('Preferences'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            secondary: const Icon(Icons.dark_mode_outlined),
            value: false,
            onChanged: (value) {},
          ),
          SwitchListTile(
            title: const Text('Notifications'),
            secondary: const Icon(Icons.notifications_outlined),
            value: true,
            onChanged: (value) {},
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('English'),
                Icon(Icons.chevron_right),
              ],
            ),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Currency'),
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('USD (\$)'),
                Icon(Icons.chevron_right),
              ],
            ),
            onTap: () {},
          ),
          const Divider(),
          _buildSectionHeader('Data & Export'),
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined),
            title: const Text('Export Data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('Import Data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          _buildSectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version'),
            trailing: const Text('1.0.0'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: OutlinedButton(
              onPressed: () {
                // Logout logic
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Log Out'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}
