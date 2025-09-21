import 'package:flutter/material.dart';
import '../screens/settings_screen.dart';

class GlobalDrawer extends StatelessWidget {
  final String currentScreen;
  const GlobalDrawer({super.key, required this.currentScreen});

  @override
  Widget build(BuildContext context) {
    void navigateToBriefingTab(int tabIndex) {
      if (currentScreen != '/briefing' || tabIndex != _getCurrentTabIndex()) {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamedAndRemoveUntil('/briefing', (route) => false, arguments: tabIndex);
      } else {
        Navigator.of(context).pop();
      }
    }

    void navigateToHome() {
      if (currentScreen != '/home') {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        Navigator.of(context).pop();
      }
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          width: 60,
                          height: 60,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Menu',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Briefing Buddy',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            subtitle: Text('Main dashboard'),
            onTap: () => navigateToHome(),
          ),
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Summary'),
            subtitle: Text('Flight overview'),
            onTap: () => navigateToBriefingTab(0),
          ),
          ListTile(
            leading: Icon(Icons.airplanemode_active),
            title: Text('Airports'),
            subtitle: Text('System status details'),
            onTap: () => navigateToBriefingTab(1),
          ),
          ListTile(
            leading: Icon(Icons.code),
            title: Text('Raw Data'),
            subtitle: Text('NOTAMs, METARs, TAFs'),
            onTap: () => navigateToBriefingTab(2),
          ),
          ListTile(
            leading: Icon(Icons.psychology),
            title: Text('AI Briefing'),
            subtitle: Text('AI-powered flight briefings'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/ai-briefing');
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            subtitle: Text('App preferences'),
            onTap: () {
              Navigator.of(context).pop();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const SettingsScreen(),
              );
            },
          ),
        ],
      ),
    );
  }

  int _getCurrentTabIndex() {
    switch (currentScreen) {
      case '/summary':
        return 0;
      case '/airports':
        return 1;
      case '/raw':
        return 2;
      default:
        return 0;
    }
  }
} 