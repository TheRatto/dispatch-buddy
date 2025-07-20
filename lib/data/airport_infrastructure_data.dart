import '../models/airport_infrastructure.dart';

/// Airport infrastructure database with detailed facility information
class AirportInfrastructureData {
  static final Map<String, Map<String, dynamic>> _airportData = {
    'YSSY': {
      'icao': 'YSSY',
      'runways': [
        {
          'identifier': '07/25',
          'length': 3962.0,
          'surface': 'Asphalt',
          'approaches': [
            {'identifier': 'ILS 07', 'type': 'ILS', 'runway': '07/25', 'minimums': 200.0, 'status': 'OPERATIONAL'},
            {'identifier': 'ILS 25', 'type': 'ILS', 'runway': '07/25', 'minimums': 200.0, 'status': 'OPERATIONAL'},
            {'identifier': 'VOR 07', 'type': 'VOR', 'runway': '07/25', 'minimums': 300.0, 'status': 'OPERATIONAL'},
            {'identifier': 'VOR 25', 'type': 'VOR', 'runway': '07/25', 'minimums': 300.0, 'status': 'OPERATIONAL'},
          ],
          'hasLighting': true,
          'width': 60.0,
          'status': 'OPERATIONAL',
          'isPrimary': true,
        },
        {
          'identifier': '16L/34R',
          'length': 2438.0,
          'surface': 'Asphalt',
          'approaches': [
            {'identifier': 'ILS 16L', 'type': 'ILS', 'runway': '16L/34R', 'minimums': 200.0, 'status': 'OPERATIONAL'},
            {'identifier': 'VOR 16L', 'type': 'VOR', 'runway': '16L/34R', 'minimums': 300.0, 'status': 'OPERATIONAL'},
            {'identifier': 'VOR 34R', 'type': 'VOR', 'runway': '16L/34R', 'minimums': 300.0, 'status': 'OPERATIONAL'},
          ],
          'hasLighting': true,
          'width': 45.0,
          'status': 'OPERATIONAL',
          'isPrimary': false,
        },
        {
          'identifier': '16R/34L',
          'length': 2438.0,
          'surface': 'Asphalt',
          'approaches': [
            {'identifier': 'ILS 16R', 'type': 'ILS', 'runway': '16R/34L', 'minimums': 200.0, 'status': 'OPERATIONAL'},
            {'identifier': 'VOR 16R', 'type': 'VOR', 'runway': '16R/34L', 'minimums': 300.0, 'status': 'OPERATIONAL'},
            {'identifier': 'VOR 34L', 'type': 'VOR', 'runway': '16R/34L', 'minimums': 300.0, 'status': 'OPERATIONAL'},
          ],
          'hasLighting': true,
          'width': 45.0,
          'status': 'OPERATIONAL',
          'isPrimary': false,
        },
      ],
      'taxiways': [
        {
          'identifier': 'A',
          'connections': ['07/25', '16L/34R'],
          'width': 23.0,
          'hasLighting': true,
          'status': 'OPERATIONAL',
        },
        {
          'identifier': 'B',
          'connections': ['07/25', '16R/34L'],
          'width': 23.0,
          'hasLighting': true,
          'status': 'OPERATIONAL',
        },
        {
          'identifier': 'C',
          'connections': ['16L/34R', '16R/34L'],
          'width': 23.0,
          'hasLighting': true,
          'status': 'OPERATIONAL',
        },
        {
          'identifier': 'D',
          'connections': ['07/25'],
          'width': 18.0,
          'hasLighting': true,
          'status': 'OPERATIONAL',
        },
      ],
      'navaids': [
        {
          'identifier': 'ILS 07',
          'frequency': '110.3',
          'runway': '07/25',
          'type': 'ILS',
          'isPrimary': true,
          'isBackup': false,
          'status': 'OPERATIONAL',
        },
        {
          'identifier': 'ILS 25',
          'frequency': '109.1',
          'runway': '07/25',
          'type': 'ILS',
          'isPrimary': true,
          'isBackup': false,
          'status': 'OPERATIONAL',
        },
        {
          'identifier': 'ILS 16L',
          'frequency': '110.5',
          'runway': '16L/34R',
          'type': 'ILS',
          'isPrimary': true,
          'isBackup': false,
          'status': 'OPERATIONAL',
        },
        {
          'identifier': 'ILS 16R',
          'frequency': '110.7',
          'runway': '16R/34L',
          'type': 'ILS',
          'isPrimary': true,
          'isBackup': false,
          'status': 'OPERATIONAL',
        },
        {
          'identifier': 'VOR SYD',
          'frequency': '113.1',
          'runway': '07/25',
          'type': 'VOR',
          'isPrimary': false,
          'isBackup': true,
          'status': 'OPERATIONAL',
        },
      ],
      'approaches': [
        {'identifier': 'ILS 07', 'type': 'ILS', 'runway': '07/25', 'minimums': 200.0, 'status': 'OPERATIONAL'},
        {'identifier': 'ILS 25', 'type': 'ILS', 'runway': '07/25', 'minimums': 200.0, 'status': 'OPERATIONAL'},
        {'identifier': 'ILS 16L', 'type': 'ILS', 'runway': '16L/34R', 'minimums': 200.0, 'status': 'OPERATIONAL'},
        {'identifier': 'ILS 16R', 'type': 'ILS', 'runway': '16R/34L', 'minimums': 200.0, 'status': 'OPERATIONAL'},
        {'identifier': 'VOR 07', 'type': 'VOR', 'runway': '07/25', 'minimums': 300.0, 'status': 'OPERATIONAL'},
        {'identifier': 'VOR 25', 'type': 'VOR', 'runway': '07/25', 'minimums': 300.0, 'status': 'OPERATIONAL'},
        {'identifier': 'VOR 16L', 'type': 'VOR', 'runway': '16L/34R', 'minimums': 300.0, 'status': 'OPERATIONAL'},
        {'identifier': 'VOR 16R', 'type': 'VOR', 'runway': '16R/34L', 'minimums': 300.0, 'status': 'OPERATIONAL'},
      ],
      'routes': [
        {
          'identifier': 'A-B',
          'taxiways': ['A', 'B'],
          'startPoint': 'Terminal',
          'endPoint': 'RWY 07/25',
          'status': 'OPERATIONAL',
        },
        {
          'identifier': 'A-C',
          'taxiways': ['A', 'C'],
          'startPoint': 'Terminal',
          'endPoint': 'RWY 16L/34R',
          'status': 'OPERATIONAL',
        },
      ],
      'facilityStatus': {
        'RWY 07/25': 'OPERATIONAL',
        'RWY 16L/34R': 'OPERATIONAL',
        'RWY 16R/34L': 'OPERATIONAL',
        'Taxiway A': 'OPERATIONAL',
        'Taxiway B': 'OPERATIONAL',
        'Taxiway C': 'OPERATIONAL',
        'Taxiway D': 'OPERATIONAL',
        'ILS 07': 'OPERATIONAL',
        'ILS 25': 'OPERATIONAL',
        'ILS 16L': 'OPERATIONAL',
        'ILS 16R': 'OPERATIONAL',
        'VOR SYD': 'OPERATIONAL',
      },
    },
    'YPPH': {
      'icao': 'YPPH',
      'runways': [
        {
          'identifier': '03/21',
          'length': 3444.0,
          'surface': 'Asphalt',
          'approaches': [
            {'identifier': 'ILS 03', 'type': 'ILS', 'runway': '03/21', 'minimums': 200.0, 'status': 'OPERATIONAL'},
            {'identifier': 'ILS 21', 'type': 'ILS', 'runway': '03/21', 'minimums': 200.0, 'status': 'OPERATIONAL'},
            {'identifier': 'VOR 03', 'type': 'VOR', 'runway': '03/21', 'minimums': 300.0, 'status': 'OPERATIONAL'},
            {'identifier': 'VOR 21', 'type': 'VOR', 'runway': '03/21', 'minimums': 300.0, 'status': 'OPERATIONAL'},
          ],
          'hasLighting': true,
          'width': 60.0,
          'status': 'OPERATIONAL',
          'isPrimary': true,
        },
        {
          'identifier': '06/24',
          'length': 2164.0,
          'surface': 'Asphalt',
          'approaches': [
            {'identifier': 'VOR 06', 'type': 'VOR', 'runway': '06/24', 'minimums': 300.0, 'status': 'OPERATIONAL'},
            {'identifier': 'VOR 24', 'type': 'VOR', 'runway': '06/24', 'minimums': 300.0, 'status': 'OPERATIONAL'},
          ],
          'hasLighting': true,
          'width': 45.0,
          'status': 'OPERATIONAL',
          'isPrimary': false,
        },
      ],
      'taxiways': [
        {
          'identifier': 'A',
          'connections': ['03/21', '06/24'],
          'width': 23.0,
          'hasLighting': true,
          'status': 'OPERATIONAL',
        },
        {
          'identifier': 'B',
          'connections': ['03/21'],
          'width': 23.0,
          'hasLighting': true,
          'status': 'OPERATIONAL',
        },
        {
          'identifier': 'C',
          'connections': ['06/24'],
          'width': 18.0,
          'hasLighting': true,
          'status': 'OPERATIONAL',
        },
      ],
      'navaids': [
        {
          'identifier': 'ILS 03',
          'frequency': '110.3',
          'runway': '03/21',
          'type': 'ILS',
          'isPrimary': true,
          'isBackup': false,
          'status': 'OPERATIONAL',
        },
        {
          'identifier': 'ILS 21',
          'frequency': '109.1',
          'runway': '03/21',
          'type': 'ILS',
          'isPrimary': true,
          'isBackup': false,
          'status': 'OPERATIONAL',
        },
        {
          'identifier': 'VOR PER',
          'frequency': '113.1',
          'runway': '03/21',
          'type': 'VOR',
          'isPrimary': false,
          'isBackup': true,
          'status': 'OPERATIONAL',
        },
      ],
      'approaches': [
        {'identifier': 'ILS 03', 'type': 'ILS', 'runway': '03/21', 'minimums': 200.0, 'status': 'OPERATIONAL'},
        {'identifier': 'ILS 21', 'type': 'ILS', 'runway': '03/21', 'minimums': 200.0, 'status': 'OPERATIONAL'},
        {'identifier': 'VOR 03', 'type': 'VOR', 'runway': '03/21', 'minimums': 300.0, 'status': 'OPERATIONAL'},
        {'identifier': 'VOR 21', 'type': 'VOR', 'runway': '03/21', 'minimums': 300.0, 'status': 'OPERATIONAL'},
        {'identifier': 'VOR 06', 'type': 'VOR', 'runway': '06/24', 'minimums': 300.0, 'status': 'OPERATIONAL'},
        {'identifier': 'VOR 24', 'type': 'VOR', 'runway': '06/24', 'minimums': 300.0, 'status': 'OPERATIONAL'},
      ],
      'routes': [
        {
          'identifier': 'A-B',
          'taxiways': ['A', 'B'],
          'startPoint': 'Terminal',
          'endPoint': 'RWY 03/21',
          'status': 'OPERATIONAL',
        },
        {
          'identifier': 'A-C',
          'taxiways': ['A', 'C'],
          'startPoint': 'Terminal',
          'endPoint': 'RWY 06/24',
          'status': 'OPERATIONAL',
        },
      ],
      'facilityStatus': {
        'RWY 03/21': 'OPERATIONAL',
        'RWY 06/24': 'OPERATIONAL',
        'Taxiway A': 'OPERATIONAL',
        'Taxiway B': 'OPERATIONAL',
        'Taxiway C': 'OPERATIONAL',
        'ILS 03': 'OPERATIONAL',
        'ILS 21': 'OPERATIONAL',
        'VOR PER': 'OPERATIONAL',
      },
    },
    'YBBN': {
      'icao': 'YBBN',
      'runways': [
        {
          'identifier': '01/19',
          'length': 3500.0,
          'surface': 'Asphalt',
          'approaches': [
            {'identifier': 'ILS 01', 'type': 'ILS', 'runway': '01/19', 'minimums': 200.0, 'status': 'OPERATIONAL'},
            {'identifier': 'ILS 19', 'type': 'ILS', 'runway': '01/19', 'minimums': 200.0, 'status': 'OPERATIONAL'},
            {'identifier': 'VOR 01', 'type': 'VOR', 'runway': '01/19', 'minimums': 300.0, 'status': 'OPERATIONAL'},
            {'identifier': 'VOR 19', 'type': 'VOR', 'runway': '01/19', 'minimums': 300.0, 'status': 'OPERATIONAL'},
          ],
          'hasLighting': true,
          'width': 60.0,
          'status': 'OPERATIONAL',
          'isPrimary': true,
        },
        {
          'identifier': '14/32',
          'length': 1700.0,
          'surface': 'Asphalt',
          'approaches': [
            {'identifier': 'VOR 14', 'type': 'VOR', 'runway': '14/32', 'minimums': 300.0, 'status': 'OPERATIONAL'},
            {'identifier': 'VOR 32', 'type': 'VOR', 'runway': '14/32', 'minimums': 300.0, 'status': 'OPERATIONAL'},
          ],
          'hasLighting': true,
          'width': 45.0,
          'status': 'OPERATIONAL',
          'isPrimary': false,
        },
      ],
      'taxiways': [
        {
          'identifier': 'A',
          'connections': ['01/19', '14/32'],
          'width': 23.0,
          'hasLighting': true,
          'status': 'OPERATIONAL',
        },
        {
          'identifier': 'B',
          'connections': ['01/19'],
          'width': 23.0,
          'hasLighting': true,
          'status': 'OPERATIONAL',
        },
        {
          'identifier': 'C',
          'connections': ['14/32'],
          'width': 18.0,
          'hasLighting': true,
          'status': 'OPERATIONAL',
        },
      ],
      'navaids': [
        {
          'identifier': 'ILS 01',
          'frequency': '110.3',
          'runway': '01/19',
          'type': 'ILS',
          'isPrimary': true,
          'isBackup': false,
          'status': 'OPERATIONAL',
        },
        {
          'identifier': 'ILS 19',
          'frequency': '109.1',
          'runway': '01/19',
          'type': 'ILS',
          'isPrimary': true,
          'isBackup': false,
          'status': 'OPERATIONAL',
        },
        {
          'identifier': 'VOR BNE',
          'frequency': '113.1',
          'runway': '01/19',
          'type': 'VOR',
          'isPrimary': false,
          'isBackup': true,
          'status': 'OPERATIONAL',
        },
      ],
      'approaches': [
        {'identifier': 'ILS 01', 'type': 'ILS', 'runway': '01/19', 'minimums': 200.0, 'status': 'OPERATIONAL'},
        {'identifier': 'ILS 19', 'type': 'ILS', 'runway': '01/19', 'minimums': 200.0, 'status': 'OPERATIONAL'},
        {'identifier': 'VOR 01', 'type': 'VOR', 'runway': '01/19', 'minimums': 300.0, 'status': 'OPERATIONAL'},
        {'identifier': 'VOR 19', 'type': 'VOR', 'runway': '01/19', 'minimums': 300.0, 'status': 'OPERATIONAL'},
        {'identifier': 'VOR 14', 'type': 'VOR', 'runway': '14/32', 'minimums': 300.0, 'status': 'OPERATIONAL'},
        {'identifier': 'VOR 32', 'type': 'VOR', 'runway': '14/32', 'minimums': 300.0, 'status': 'OPERATIONAL'},
      ],
      'routes': [
        {
          'identifier': 'A-B',
          'taxiways': ['A', 'B'],
          'startPoint': 'Terminal',
          'endPoint': 'RWY 01/19',
          'status': 'OPERATIONAL',
        },
        {
          'identifier': 'A-C',
          'taxiways': ['A', 'C'],
          'startPoint': 'Terminal',
          'endPoint': 'RWY 14/32',
          'status': 'OPERATIONAL',
        },
      ],
      'facilityStatus': {
        'RWY 01/19': 'OPERATIONAL',
        'RWY 14/32': 'OPERATIONAL',
        'Taxiway A': 'OPERATIONAL',
        'Taxiway B': 'OPERATIONAL',
        'Taxiway C': 'OPERATIONAL',
        'ILS 01': 'OPERATIONAL',
        'ILS 19': 'OPERATIONAL',
        'VOR BNE': 'OPERATIONAL',
      },
    },
  };

  /// Get airport infrastructure data for a specific ICAO code
  static AirportInfrastructure? getAirportInfrastructure(String icao) {
    final data = _airportData[icao.toUpperCase()];
    if (data == null) return null;
    
    return AirportInfrastructure.fromJson(data);
  }

  /// Get list of all available airports
  static List<String> getAvailableAirports() {
    return _airportData.keys.toList();
  }

  /// Check if airport infrastructure data exists
  static bool hasAirportInfrastructure(String icao) {
    return _airportData.containsKey(icao.toUpperCase());
  }

  /// Get total number of airports with infrastructure data
  static int get databaseSize => _airportData.length;

  /// Get sample airport data for testing
  static Map<String, dynamic> getSampleAirportData(String icao) {
    return _airportData[icao.toUpperCase()] ?? {};
  }
} 