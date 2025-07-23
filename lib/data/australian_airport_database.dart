import '../models/airport_infrastructure.dart';

/// Australian Airport Database
/// Contains the list of initial Australian airports to ship with the app
/// Real airport data will be fetched from OpenAIP API on first use
class AustralianAirportDatabase {
  /// Initial Australian airports to ship with the app
  /// These will be loaded instantly on first use, then cached
  static const List<String> initialAirports = [
    'YSSY', // Sydney Kingsford Smith
    'YMML', // Melbourne Airport
    'YBBN', // Brisbane Airport
    'YPPH', // Perth Airport
    'YPAD', // Adelaide Airport
    'YPDN', // Darwin Airport
    'YMHB', // Hobart Airport
    'YMLT', // Launceston Airport
    'YSCB', // Canberra Airport
    'YBCG', // Gold Coast Airport
    'YMAV', // Avalon Airport
    'YSRI', // Richmond Airport
    'YPED', // Edinburgh Airport
    'YBCS', // Cairns Airport
    'YPTN', // Tindal Airport
    'YCFS', // Coffs Harbour Airport
    'YMAY', // Albury Airport
    'YBLN', // Busselton Airport
    'YAMB', // Amberley Airport
    'YWLM', // Williamtown Airport
  ];

  /// Get the list of initial airports
  static List<String> get airports => List.from(initialAirports);

  /// Check if an airport is in the initial Australian database
  static bool isInitialAirport(String icao) {
    return initialAirports.contains(icao.toUpperCase());
  }

  /// Get airport names for display purposes
  static Map<String, String> get airportNames {
    return {
      'YSSY': 'Sydney Kingsford Smith',
      'YMML': 'Melbourne Airport',
      'YBBN': 'Brisbane Airport',
      'YPPH': 'Perth Airport',
      'YPAD': 'Adelaide Airport',
      'YPDN': 'Darwin Airport',
      'YMHB': 'Hobart Airport',
      'YMLT': 'Launceston Airport',
      'YSCB': 'Canberra Airport',
      'YBCG': 'Gold Coast Airport',
      'YMAV': 'Avalon Airport',
      'YSRI': 'Richmond Airport',
      'YPED': 'Edinburgh Airport',
      'YBCS': 'Cairns Airport',
      'YPTN': 'Tindal Airport',
      'YCFS': 'Coffs Harbour Airport',
      'YMAY': 'Albury Airport',
      'YBLN': 'Busselton Airport',
      'YAMB': 'Amberley Airport',
      'YWLM': 'Williamtown Airport',
    };
  }

  /// Get display name for an airport
  static String getAirportName(String icao) {
    return airportNames[icao.toUpperCase()] ?? icao;
  }
} 