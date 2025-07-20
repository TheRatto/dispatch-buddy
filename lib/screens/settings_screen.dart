import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 1.0, // Full screen
      minChildSize: 0.6,
      maxChildSize: 1.0,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar and close button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close button (X)
                    IconButton(
                      icon: const Icon(Icons.close, size: 24),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Spacer to balance the layout
                    const SizedBox(width: 48), // Same width as close button
                  ],
                ),
              ),
              // Settings content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Header
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Theme Settings Section
                    _buildSectionHeader('Appearance'),
                    _buildThemeSettings(),
                    const SizedBox(height: 32),
                    
                    // User Profile Section
                    _buildSectionHeader('Profile'),
                    _buildProfileSettings(),
                    const SizedBox(height: 32),
                    
                    // Privacy Settings Section
                    _buildSectionHeader('Privacy & Data'),
                    _buildPrivacySettings(),
                    const SizedBox(height: 32),
                    
                    // About Section
                    _buildSectionHeader('About'),
                    _buildAboutSettings(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildThemeSettings() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.brightness_4),
            title: const Text('Theme'),
            subtitle: const Text('Light, Dark, or System'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Show theme picker
            },
          ),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Font Size'),
            subtitle: const Text('Medium'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Show font size picker
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSettings() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Name'),
            subtitle: const Text('Not set'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Edit name
            },
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email'),
            subtitle: const Text('Not set'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Edit email
            },
          ),
          ListTile(
            leading: const Icon(Icons.work),
            title: const Text('Organization'),
            subtitle: const Text('Not set'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Edit organization
            },
          ),
          ListTile(
            leading: const Icon(Icons.flight),
            title: const Text('Pilot License'),
            subtitle: const Text('Not set'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Edit license type
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettings() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analytics'),
            subtitle: const Text('Help improve the app'),
            trailing: Switch(
              value: true, // TODO: Get from settings provider
              onChanged: (value) {
                // TODO: Update analytics setting
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Crash Reporting'),
            subtitle: const Text('Send crash reports'),
            trailing: Switch(
              value: true, // TODO: Get from settings provider
              onChanged: (value) {
                // TODO: Update crash reporting setting
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Location Services'),
            subtitle: const Text('Use location for weather'),
            trailing: Switch(
              value: false, // TODO: Get from settings provider
              onChanged: (value) {
                // TODO: Update location setting
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Data Sharing'),
            subtitle: const Text('Share usage data'),
            trailing: Switch(
              value: false, // TODO: Get from settings provider
              onChanged: (value) {
                // TODO: Update data sharing setting
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSettings() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
            onTap: () {
              // TODO: Show version info
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Show terms of service
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Show privacy policy
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Show help and support
            },
          ),
        ],
      ),
    );
  }
} 