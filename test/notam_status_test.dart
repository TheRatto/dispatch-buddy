import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dispatch_buddy/services/notam_status_service.dart';
import 'package:dispatch_buddy/models/notam.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('NotamStatusService Tests', () {
    late NotamStatusService statusService;

    setUp(() {
      statusService = NotamStatusService();
    });

    tearDown(() async {
      // Clear all statuses after each test
      await statusService.clearAllStatuses();
    });

    test('should save and retrieve NOTAM status', () async {
      const notamId = 'TEST001';
      const flightContext = 'flight_123';
      
      // Create a status
      final status = NotamStatus(
        notamId: notamId,
        isHidden: true,
        isFlagged: false,
        flightContext: flightContext,
      );
      
      // Save status
      await statusService.saveStatus(status);
      
      // Retrieve status
      final retrievedStatus = await statusService.getStatus(notamId);
      
      expect(retrievedStatus, isNotNull);
      expect(retrievedStatus!.notamId, equals(notamId));
      expect(retrievedStatus.isHidden, isTrue);
      expect(retrievedStatus.isFlagged, isFalse);
      expect(retrievedStatus.flightContext, equals(flightContext));
    });

    test('should hide and unhide NOTAMs', () async {
      const notamId = 'TEST002';
      const flightContext = 'flight_456';
      
      // Hide NOTAM
      await statusService.hideNotam(notamId, flightContext: flightContext);
      
      // Check if hidden
      final status = await statusService.getStatus(notamId);
      expect(status?.isHidden, isTrue);
      expect(status?.flightContext, equals(flightContext));
      
      // Unhide NOTAM
      await statusService.unhideNotam(notamId);
      
      // Check if unhidden
      final updatedStatus = await statusService.getStatus(notamId);
      expect(updatedStatus?.isHidden, isFalse);
    });

    test('should flag and unflag NOTAMs', () async {
      const notamId = 'TEST003';
      const flightContext = 'flight_789';
      
      // Flag NOTAM
      await statusService.flagNotam(notamId, flightContext: flightContext);
      
      // Check if flagged
      final status = await statusService.getStatus(notamId);
      expect(status?.isFlagged, isTrue);
      expect(status?.flightContext, equals(flightContext));
      
      // Unflag NOTAM
      await statusService.unflagNotam(notamId);
      
      // Check if unflagged
      final updatedStatus = await statusService.getStatus(notamId);
      expect(updatedStatus?.isFlagged, isFalse);
    });

    test('should get hidden NOTAM IDs for flight context', () async {
      const flightContext = 'flight_abc';
      
      // Hide some NOTAMs
      await statusService.hideNotam('NOTAM1', flightContext: flightContext);
      await statusService.hideNotam('NOTAM2', flightContext: flightContext);
      await statusService.hideNotam('NOTAM3', flightContext: null); // Permanent
      
      // Get hidden NOTAMs for flight context
      final hiddenIds = await statusService.getHiddenNotamIds(flightContext: flightContext);
      
      expect(hiddenIds.length, equals(2));
      expect(hiddenIds, contains('NOTAM1'));
      expect(hiddenIds, contains('NOTAM2'));
      expect(hiddenIds, isNot(contains('NOTAM3')));
    });

    test('should get flagged NOTAM IDs for flight context', () async {
      const flightContext = 'flight_def';
      
      // Flag some NOTAMs
      await statusService.flagNotam('NOTAM1', flightContext: flightContext);
      await statusService.flagNotam('NOTAM2', flightContext: flightContext);
      await statusService.flagNotam('NOTAM3', flightContext: null); // Permanent
      
      // Get flagged NOTAMs for flight context
      final flaggedIds = await statusService.getFlaggedNotamIds(flightContext: flightContext);
      
      expect(flaggedIds.length, equals(2));
      expect(flaggedIds, contains('NOTAM1'));
      expect(flaggedIds, contains('NOTAM2'));
      expect(flaggedIds, isNot(contains('NOTAM3')));
    });

    test('should get permanently hidden NOTAM IDs', () async {
      // Hide some NOTAMs permanently
      await statusService.hideNotam('NOTAM1', flightContext: null);
      await statusService.hideNotam('NOTAM2', flightContext: null);
      await statusService.hideNotam('NOTAM3', flightContext: 'flight_xyz'); // Per-flight
      
      // Get permanently hidden NOTAMs
      final permanentHiddenIds = await statusService.getPermanentlyHiddenNotamIds();
      
      expect(permanentHiddenIds.length, equals(2));
      expect(permanentHiddenIds, contains('NOTAM1'));
      expect(permanentHiddenIds, contains('NOTAM2'));
      expect(permanentHiddenIds, isNot(contains('NOTAM3')));
    });

    test('should get permanently flagged NOTAM IDs', () async {
      // Flag some NOTAMs permanently
      await statusService.flagNotam('NOTAM1', flightContext: null);
      await statusService.flagNotam('NOTAM2', flightContext: null);
      await statusService.flagNotam('NOTAM3', flightContext: 'flight_xyz'); // Per-flight
      
      // Get permanently flagged NOTAMs
      final permanentFlaggedIds = await statusService.getPermanentlyFlaggedNotamIds();
      
      expect(permanentFlaggedIds.length, equals(2));
      expect(permanentFlaggedIds, contains('NOTAM1'));
      expect(permanentFlaggedIds, contains('NOTAM2'));
      expect(permanentFlaggedIds, isNot(contains('NOTAM3')));
    });

    test('should get hidden count for flight context', () async {
      const flightContext = 'flight_count';
      
      // Hide some NOTAMs
      await statusService.hideNotam('NOTAM1', flightContext: flightContext);
      await statusService.hideNotam('NOTAM2', flightContext: flightContext);
      await statusService.hideNotam('NOTAM3', flightContext: null); // Permanent
      
      // Get hidden count
      final hiddenCount = await statusService.getHiddenCount(flightContext: flightContext);
      
      expect(hiddenCount, equals(2));
    });

    test('should get flagged count for flight context', () async {
      const flightContext = 'flight_count';
      
      // Flag some NOTAMs
      await statusService.flagNotam('NOTAM1', flightContext: flightContext);
      await statusService.flagNotam('NOTAM2', flightContext: flightContext);
      await statusService.flagNotam('NOTAM3', flightContext: null); // Permanent
      
      // Get flagged count
      final flaggedCount = await statusService.getFlaggedCount(flightContext: flightContext);
      
      expect(flaggedCount, equals(2));
    });

    test('should clear all statuses', () async {
      // Create some statuses
      await statusService.hideNotam('NOTAM1', flightContext: 'flight1');
      await statusService.flagNotam('NOTAM2', flightContext: 'flight2');
      
      // Clear all
      await statusService.clearAllStatuses();
      
      // Verify all cleared
      final status1 = await statusService.getStatus('NOTAM1');
      final status2 = await statusService.getStatus('NOTAM2');
      
      expect(status1, isNull);
      expect(status2, isNull);
    });
  });
} 