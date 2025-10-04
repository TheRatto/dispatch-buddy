import 'package:flutter/foundation.dart';

/// NAIPS Test Account Manager
/// 
/// Manages rotation of test NAIPS accounts to avoid rate limits
/// and provide reliable service without requiring user credentials
class NAIPSAccountManager {
  static final NAIPSAccountManager _instance = NAIPSAccountManager._internal();
  factory NAIPSAccountManager() => _instance;
  NAIPSAccountManager._internal();

  // Test accounts from the attached file
  static const List<TestAccount> _accounts = [
    TestAccount(username: 'jamesmitchell111', password: 'naIpsnaIps1'),
    TestAccount(username: 'SARAHTHOMPSON', password: 'naIpsnaIps1'),
    TestAccount(username: 'michaelchen', password: 'naIpsnaIps1'),
    TestAccount(username: 'emmawilliams', password: 'naIpsnaIps1'),
    TestAccount(username: 'davidpines', password: 'naIpsnaIps1'),
    TestAccount(username: 'lisadavis', password: 'naIpsnaIps1'),
    TestAccount(username: 'robertwilson', password: 'naIpsnaIps1'),
    TestAccount(username: 'testpilot008', password: 'naIpsnaIps1'),
    TestAccount(username: 'christopheranderson', password: 'naIpsnaIps1'),
    TestAccount(username: 'amandawhite', password: 'naIpsnaIps1'),
  ];

  int _currentIndex = 0;
  int _requestCount = 0;
  
  /// Get the next available test account for authentication
  /// Rotates every 2-3 requests to distribute load
  TestAccount getNextAccount() {
    _requestCount++;
    
    // Rotate every 2-3 requests
    if (_requestCount >= 2) {
      _requestCount = 0;
      _currentIndex = (_currentIndex + 1) % _accounts.length;
      debugPrint('DEBUG: 🔄 NAIPSAccountManager - Rotating to account index $_currentIndex (${_accounts[_currentIndex].username})');
    }
    
    final account = _accounts[_currentIndex];
    debugPrint('DEBUG: 🔑 NAIPSAccountManager - Using account: ${account.username} (request $_requestCount)');
    
    return account;
  }
  
  /// Get current account for debugging/monitoring
  TestAccount getCurrentAccount() {
    return _accounts[_currentIndex];
  }
  
  /// Get total number of available accounts
  int get accountCount => _accounts.length;
  
  /// Reset rotation (useful for testing)
  void resetRotation() {
    _currentIndex = 0;
    _requestCount = 0;
    debugPrint('DEBUG: 🔄 NAIPSAccountManager - Rotation reset');
  }
}

/// Test account data structure
class TestAccount {
  final String username;
  final String password;
  
  const TestAccount({
    required this.username,
    required this.password,
  });
  
  @override
  String toString() => 'TestAccount(username: $username)';
}
