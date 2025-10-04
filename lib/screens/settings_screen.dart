import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/api_service.dart';
import '../widgets/version_info_dialog.dart';
import '../screens/terms_of_service_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/help_support_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
                    
                    // Units Settings Section
                    _buildSectionHeader('Units'),
                    _buildUnitsSettings(),
                    const SizedBox(height: 32),
                    
                    
                    // About Section
                    _buildSectionHeader('About'),
                    _buildAboutSettings(),
                    const SizedBox(height: 32),
                    
                    // Debug Tools Section (only in debug mode)
                    if (kDebugMode) ...[
                      _buildSectionHeader('Debug Tools'),
                      _buildDebugTools(),
                      const SizedBox(height: 40),
                    ] else
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

  Widget _buildUnitsSettings() {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.straighten),
                title: const Text('Runway Length Units'),
                subtitle: Text(settingsProvider.runwayUnits == Units.feet ? 'Feet (Width always in meters)' : 'Meters (Width always in meters)'),
                trailing: Switch(
                  value: settingsProvider.runwayUnits == Units.meters,
                  onChanged: (value) {
                    settingsProvider.setRunwayUnits(
                      value ? Units.meters : Units.feet,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildAboutSettings() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Version'),
            subtitle: const Text('1.0.1'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const VersionInfoDialog(),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TermsOfServiceScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const HelpSupportScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDebugTools() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.wifi_find, color: Colors.orange),
            title: const Text('Network Test'),
            subtitle: const Text('Test internet connectivity and API access'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _runNetworkDiagnostics(),
          ),
          ListTile(
            leading: const Icon(Icons.science, color: Colors.purple),
            title: const Text('FAA API Test'),
            subtitle: const Text('Test FAA NOTAM API parameters'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _testFaaApiParameters(),
          ),
        ],
      ),
    );
  }

  void _runNetworkDiagnostics() async {
    try {
      final apiService = ApiService();
      
      // Test basic connectivity
      final basicConnectivity = await apiService.testNetworkConnectivity();
      
      // Test FAA API access
      final faaAccess = await apiService.testFaaApiAccess();
      
      // Test a simple NOTAM fetch
      final testNotams = await apiService.fetchNotamsWithSatcomFallback('KJFK');
      
      String message = 'Network Diagnostics Results:\n\n';
      message += 'Basic Internet: ${basicConnectivity ? "✅ Working" : "❌ Failed"}\n';
      message += 'FAA API Health: ${faaAccess ? "✅ Accessible" : "❌ Blocked/Unreachable"}\n';
      message += 'NOTAM Fetch: ${testNotams.isNotEmpty ? "✅ Success (${testNotams.length} NOTAMs)" : "❌ Failed"}\n\n';
      
      if (!basicConnectivity) {
        message += 'SATCOM Issue: No basic internet connectivity detected.\n';
      } else if (!faaAccess) {
        message += 'SATCOM Issue: FAA API is blocked or unreachable via SATCOM.\n';
      } else if (testNotams.isEmpty) {
        message += 'SATCOM Issue: NOTAM API accessible but no data returned.\n';
      } else {
        message += '✅ All systems working normally!\n';
      }
      
      _showDebugResult(basicConnectivity && faaAccess, message);
    } catch (e) {
      _showDebugResult(false, 'Diagnostic failed: $e');
    }
  }

  void _testFaaApiParameters() async {
    try {
      final apiService = ApiService();
      
      // Test FAA NOTAM API parameters with a known airport
      final results = await apiService.testFaaNotamApiParameters('YPPH');
      
      String message = 'FAA API Parameter Test Results:\n\n';
      
      for (final entry in results.entries) {
        final testName = entry.key;
        final result = entry.value as Map<String, dynamic>;
        
        if (result['status'] == 'success') {
          message += '✅ $testName: ${result['notamCount']} NOTAMs (total: ${result['totalCount']})\n';
        } else {
          message += '❌ $testName: ${result['error']}\n';
        }
      }
      
      message += '\nCheck console for detailed logs.';
      
      _showDebugResult(true, message);
    } catch (e) {
      _showDebugResult(false, 'Parameter test failed: $e');
    }
  }

  void _showDebugResult(bool success, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(success ? 'Debug Test Results' : 'Debug Test Failed'),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
} 