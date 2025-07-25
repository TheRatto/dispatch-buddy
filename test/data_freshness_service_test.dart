import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/services/data_freshness_service.dart';

void main() {
  group('DataFreshnessService Tests', () {
    test('should calculate age in hours correctly', () {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final twoHoursAgo = now.subtract(const Duration(hours: 2));
      
      expect(DataFreshnessService.calculateAgeInHours(oneHourAgo), equals(1));
      expect(DataFreshnessService.calculateAgeInHours(twoHoursAgo), equals(2));
    });

    test('should return fresh status for data less than 12 hours old', () {
      final now = DateTime.now();
      final freshData = now.subtract(const Duration(hours: 6));
      
      expect(DataFreshnessService.getFreshnessStatus(freshData), equals(DataFreshness.fresh));
    });

    test('should return stale status for data 12-24 hours old', () {
      final now = DateTime.now();
      final staleData = now.subtract(const Duration(hours: 18));
      
      expect(DataFreshnessService.getFreshnessStatus(staleData), equals(DataFreshness.stale));
    });

    test('should return expired status for data 24-36 hours old', () {
      final now = DateTime.now();
      final expiredData = now.subtract(const Duration(hours: 30));
      
      expect(DataFreshnessService.getFreshnessStatus(expiredData), equals(DataFreshness.expired));
    });

    test('should return very expired status for data over 36 hours old', () {
      final now = DateTime.now();
      final veryExpiredData = now.subtract(const Duration(hours: 48));
      
      expect(DataFreshnessService.getFreshnessStatus(veryExpiredData), equals(DataFreshness.veryExpired));
    });

    test('should return correct colors for different freshness levels', () {
      final now = DateTime.now();
      final freshData = now.subtract(const Duration(hours: 6));
      final staleData = now.subtract(const Duration(hours: 18));
      final expiredData = now.subtract(const Duration(hours: 30));
      final veryExpiredData = now.subtract(const Duration(hours: 48));
      
      expect(DataFreshnessService.getFreshnessColor(freshData), equals(Colors.green));
      expect(DataFreshnessService.getFreshnessColor(staleData), equals(Colors.orange));
      expect(DataFreshnessService.getFreshnessColor(expiredData), equals(Colors.red));
      expect(DataFreshnessService.getFreshnessColor(veryExpiredData), equals(Colors.red.shade900));
    });

    test('should return correct icons for different freshness levels', () {
      final now = DateTime.now();
      final freshData = now.subtract(const Duration(hours: 6));
      final staleData = now.subtract(const Duration(hours: 18));
      final expiredData = now.subtract(const Duration(hours: 30));
      
      expect(DataFreshnessService.getFreshnessIcon(freshData), equals(Icons.check_circle));
      expect(DataFreshnessService.getFreshnessIcon(staleData), equals(Icons.warning));
      expect(DataFreshnessService.getFreshnessIcon(expiredData), equals(Icons.error));
    });

    test('should generate correct age strings', () {
      final now = DateTime.now();
      final justNow = now.subtract(const Duration(seconds: 30));
      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));
      final thirtyMinutesAgo = now.subtract(const Duration(minutes: 30));
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final threeHoursAgo = now.subtract(const Duration(hours: 3));
      final oneDayAgo = now.subtract(const Duration(hours: 24));
      final twoDaysAgo = now.subtract(const Duration(hours: 48));
      
      expect(DataFreshnessService.getAgeString(justNow), equals('Just now'));
      expect(DataFreshnessService.getAgeString(fiveMinutesAgo), equals('5 minutes ago'));
      expect(DataFreshnessService.getAgeString(thirtyMinutesAgo), equals('30 minutes ago'));
      expect(DataFreshnessService.getAgeString(oneHourAgo), equals('1 hour ago'));
      expect(DataFreshnessService.getAgeString(threeHoursAgo), equals('3 hours ago'));
      expect(DataFreshnessService.getAgeString(oneDayAgo), equals('1 day ago'));
      expect(DataFreshnessService.getAgeString(twoDaysAgo), equals('2 days ago'));
    });

    test('should return correct freshness descriptions', () {
      final now = DateTime.now();
      final freshData = now.subtract(const Duration(hours: 6));
      final staleData = now.subtract(const Duration(hours: 18));
      final expiredData = now.subtract(const Duration(hours: 30));
      final veryExpiredData = now.subtract(const Duration(hours: 48));
      
      expect(DataFreshnessService.getFreshnessDescription(freshData), equals('Fresh'));
      expect(DataFreshnessService.getFreshnessDescription(staleData), equals('Stale'));
      expect(DataFreshnessService.getFreshnessDescription(expiredData), equals('Expired'));
      expect(DataFreshnessService.getFreshnessDescription(veryExpiredData), equals('Very Expired'));
    });

    test('should show warning for expired data', () {
      final now = DateTime.now();
      final freshData = now.subtract(const Duration(hours: 6));
      final expiredData = now.subtract(const Duration(hours: 30));
      final veryExpiredData = now.subtract(const Duration(hours: 48));
      
      expect(DataFreshnessService.shouldShowWarning(freshData), isFalse);
      expect(DataFreshnessService.shouldShowWarning(expiredData), isTrue);
      expect(DataFreshnessService.shouldShowWarning(veryExpiredData), isTrue);
    });

    test('should return appropriate warning messages', () {
      final now = DateTime.now();
      final freshData = now.subtract(const Duration(hours: 6));
      final expiredData = now.subtract(const Duration(hours: 30));
      final veryExpiredData = now.subtract(const Duration(hours: 48));
      
      expect(DataFreshnessService.getWarningMessage(freshData), equals(''));
      expect(DataFreshnessService.getWarningMessage(expiredData), contains('over 24 hours old'));
      expect(DataFreshnessService.getWarningMessage(veryExpiredData), contains('over 36 hours old'));
    });

    test('should determine reliability for offline use', () {
      final now = DateTime.now();
      final reliableData = now.subtract(const Duration(hours: 24));
      final unreliableData = now.subtract(const Duration(hours: 60));
      
      expect(DataFreshnessService.isReliableForOffline(reliableData), isTrue);
      expect(DataFreshnessService.isReliableForOffline(unreliableData), isFalse);
    });
  });
} 