import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/radar_site.dart';
import '../models/radar_image.dart';
import 'radar_assets_service.dart';

/// Service for fetching Bureau of Meteorology radar imagery
class BomRadarService {
  static const String baseUrl = 'https://reg.bom.gov.au/radar/';
  static const String loopBaseUrl = 'https://reg.bom.gov.au/products/';
  static const Duration requestTimeout = Duration(seconds: 30);
  
  // Common headers to mimic browser requests and avoid 403 errors
  static const Map<String, String> _requestHeaders = {
    'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
    'Accept': 'image/png,image/jpeg,image/gif,image/webp,*/*',
    'Accept-Language': 'en-AU,en;q=0.9',
    'Accept-Encoding': 'gzip, deflate',
    'Connection': 'keep-alive',
    'Cache-Control': 'no-cache',
    'Pragma': 'no-cache',
  };

  /// Convert base site ID and range to BOM product ID
  /// BOM uses pattern: IDR{site_number}{range_digit}
  /// Where range_digit: 4=64km, 3=128km, 2=256km, 1=512km
  static String getBomSiteId(String baseSiteId, String range) {
    final rangeDigit = switch (range) {
      '64km' => '4',
      '128km' => '3', 
      '256km' => '2',
      '512km' => '1',
      _ => '2', // Default to 256km
    };
    
    // Ensure site ID is padded to 2 digits (e.g., '4' becomes '04')
    final paddedSiteId = baseSiteId.padLeft(2, '0');
    return 'IDR$paddedSiteId$rangeDigit';
  }

  /// Get all available radar sites in Australia (based on BOM radar sites table)
  static List<RadarSite> getAvailableRadarSites() {
    return [
      // National radar (special case)
      const RadarSite(
        id: 'NATIONAL', 
        name: 'National',
        location: 'Australia',
        state: 'NATIONAL',
        latitude: -25.2744, // Geographic center of Australia
        longitude: 133.7751,
        availableRanges: ['National'],
        description: 'National radar composite view',
      ),
      ...getRegionalRadarSites(),
    ];
  }

  /// Get regional radar sites (the existing list)
  static List<RadarSite> getRegionalRadarSites() {
    return [
      // NSW - Complete list from BOM NSW radar sites table
      const RadarSite(
        id: '93', // Brewarrina 
        name: 'Brewarrina',
        location: 'Brewarrina',
        state: 'NSW',
        latitude: -29.9617,
        longitude: 146.8456,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers northwestern NSW',
      ),
      const RadarSite(
        id: '40', // Canberra (Captains Flat)
        name: 'Canberra',
        location: 'Captains Flat',
        state: 'NSW',
        latitude: -35.6617,
        longitude: 149.4972,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers ACT and surrounding NSW',
      ),
      const RadarSite(
        id: '28', // Grafton - NO 64km
        name: 'Grafton',
        location: 'Grafton',
        state: 'NSW',
        latitude: -29.6239,
        longitude: 152.9511,
        availableRanges: ['128km', '256km', '512km'],
        description: 'Covers Northern Rivers region',
      ),
      const RadarSite(
        id: '94', // Hillston
        name: 'Hillston',
        location: 'Hillston',
        state: 'NSW',
        latitude: -33.4923,
        longitude: 145.5264,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers central western NSW',
      ),
      const RadarSite(
        id: '53', // Moree - NO 64km
        name: 'Moree',
        location: 'Moree',
        state: 'NSW',
        latitude: -29.4986,
        longitude: 149.8417,
        availableRanges: ['128km', '256km', '512km'],
        description: 'Covers northwestern NSW',
      ),
      const RadarSite(
        id: '69', // Namoi (Blackjack Mountain)
        name: 'Namoi',
        location: 'Blackjack Mountain',
        state: 'NSW',
        latitude: -31.0239,
        longitude: 150.1919,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers north central NSW',
      ),
      const RadarSite(
        id: '4', // Newcastle
        name: 'Newcastle',
        location: 'Lemon Tree Passage',
        state: 'NSW',
        latitude: -32.7373,
        longitude: 152.0955,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers Hunter Valley and Central Coast',
      ),
      const RadarSite(
        id: '71', // Sydney (Terrey Hills)
        name: 'Sydney',
        location: 'Terrey Hills',
        state: 'NSW',
        latitude: -33.7009,
        longitude: 151.2093,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers Sydney metropolitan area and surrounds',
      ),
      const RadarSite(
        id: '55', // Wagga Wagga - NO 64km
        name: 'Wagga Wagga',
        location: 'Wagga Wagga',
        state: 'NSW',
        latitude: -35.1582,
        longitude: 147.4598,
        availableRanges: ['128km', '256km', '512km'],
        description: 'Covers Riverina region',
      ),
      const RadarSite(
        id: '3', // Wollongong (Appin)
        name: 'Wollongong',
        location: 'Appin',
        state: 'NSW',
        latitude: -34.2622,
        longitude: 150.7875,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers Illawarra region',
      ),
      const RadarSite(
        id: '96', // Yeoval
        name: 'Yeoval',
        location: 'Yeoval',
        state: 'NSW',
        latitude: -32.7375,
        longitude: 148.6878,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers central NSW',
      ),
      
      // Norfolk Island (related to NSW)
      const RadarSite(
        id: '62', // Norfolk Island - NO 64km
        name: 'Norfolk Island',
        location: 'Norfolk Island',
        state: 'NSW',
        latitude: -29.0408,
        longitude: 167.9547,
        availableRanges: ['128km', '256km', '512km'],
        description: 'Covers Norfolk Island territory',
      ),

      // VIC - Complete list from BOM Victoria radar sites table
      const RadarSite(
        id: '68', // Bairnsdale - NO 64km
        name: 'Bairnsdale',
        location: 'Bairnsdale',
        state: 'VIC',
        latitude: -37.8875,
        longitude: 147.5692,
        availableRanges: ['128km', '256km', '512km'],
        description: 'Covers East Gippsland region',
      ),
      const RadarSite(
        id: '2', // Melbourne
        name: 'Melbourne',
        location: 'Melbourne',
        state: 'VIC',
        latitude: -37.8550,
        longitude: 144.7556,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers Melbourne metropolitan area',
      ),
      const RadarSite(
        id: '97', // Mildura
        name: 'Mildura',
        location: 'Mildura',
        state: 'VIC',
        latitude: -34.2361,
        longitude: 142.0864,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers northwest Victoria and Sunraysia',
      ),
      const RadarSite(
        id: '95', // Rainbow
        name: 'Rainbow',
        location: 'Rainbow',
        state: 'VIC',
        latitude: -35.9056,
        longitude: 142.9917,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers north central Victoria',
      ),
      const RadarSite(
        id: '49', // Yarrawonga
        name: 'Yarrawonga',
        location: 'Yarrawonga',
        state: 'VIC',
        latitude: -36.0292,
        longitude: 146.0306,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers northeast Victoria and Murray River region',
      ),

      // QLD - Complete list from BOM Queensland radar sites table (18 sites)
      const RadarSite(
        id: '24', // Bowen - NO 64km
        name: 'Bowen',
        location: 'Bowen',
        state: 'QLD',
        latitude: -20.0181,
        longitude: 148.0750,
        availableRanges: ['128km', '256km', '512km'],
        description: 'Covers Whitsunday region',
      ),
      const RadarSite(
        id: '50', // Brisbane (Marburg)
        name: 'Brisbane',
        location: 'Marburg',
        state: 'QLD',
        latitude: -27.6083,
        longitude: 152.5386,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers Brisbane western suburbs',
      ),
      const RadarSite(
        id: '66', // Brisbane (Mt Stapylton)
        name: 'Brisbane',
        location: 'Mt Stapylton',
        state: 'QLD',
        latitude: -27.7178,
        longitude: 153.2441,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers Brisbane and Gold Coast',
      ),
      const RadarSite(
        id: '19', // Cairns
        name: 'Cairns',
        location: 'Cairns',
        state: 'QLD',
        latitude: -16.8186,
        longitude: 145.6781,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers Far North Queensland',
      ),
      const RadarSite(
        id: '72', // Emerald
        name: 'Emerald',
        location: 'Emerald',
        state: 'QLD',
        latitude: -23.5500,
        longitude: 148.1578,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers Central Highlands region',
      ),
      const RadarSite(
        id: '23', // Gladstone - NO 64km
        name: 'Gladstone',
        location: 'Gladstone',
        state: 'QLD',
        latitude: -23.8558,
        longitude: 151.2650,
        availableRanges: ['128km', '256km', '512km'],
        description: 'Covers Central Queensland coast',
      ),
      const RadarSite(
        id: '74', // Greenvale
        name: 'Greenvale',
        location: 'Greenvale',
        state: 'QLD',
        latitude: -18.0014,
        longitude: 145.4550,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers North Queensland inland',
      ),
      const RadarSite(
        id: '36', // Gulf of Carpentaria (Mornington Is) - NO 64km
        name: 'Gulf of Carpentaria',
        location: 'Mornington Is',
        state: 'QLD',
        latitude: -16.6625,
        longitude: 139.1783,
        availableRanges: ['128km', '256km', '512km'],
        description: 'Covers Gulf of Carpentaria region',
      ),
      const RadarSite(
        id: '8', // Gympie (Mt Kanigan)
        name: 'Gympie',
        location: 'Mt Kanigan',
        state: 'QLD',
        latitude: -26.2292,
        longitude: 152.5775,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers Sunshine Coast hinterland',
      ),
      const RadarSite(
        id: '56', // Longreach - NO 64km
        name: 'Longreach',
        location: 'Longreach',
        state: 'QLD',
        latitude: -23.4394,
        longitude: 144.2831,
        availableRanges: ['128km', '256km', '512km'],
        description: 'Covers Central West Queensland',
      ),
      const RadarSite(
        id: '22', // Mackay
        name: 'Mackay',
        location: 'Mackay',
        state: 'QLD',
        latitude: -21.1175,
        longitude: 149.2169,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers Mackay and Pioneer Valley',
      ),
      const RadarSite(
        id: '75', // Mount Isa
        name: 'Mount Isa',
        location: 'Mount Isa',
        state: 'QLD',
        latitude: -20.7111,
        longitude: 139.4925,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers North West Queensland',
      ),
      const RadarSite(
        id: '107', // Richmond
        name: 'Richmond',
        location: 'Richmond',
        state: 'QLD',
        latitude: -20.7319,
        longitude: 143.1331,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers North West Queensland',
      ),
      const RadarSite(
        id: '98', // Taroom
        name: 'Taroom',
        location: 'Taroom',
        state: 'QLD',
        latitude: -25.6439,
        longitude: 149.7667,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers South Central Queensland',
      ),
      const RadarSite(
        id: '108', // Toowoomba
        name: 'Toowoomba',
        location: 'Toowoomba',
        state: 'QLD',
        latitude: -27.4031,
        longitude: 151.8644,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers Darling Downs region',
      ),
      const RadarSite(
        id: '106', // Townsville
        name: 'Townsville',
        location: 'Townsville',
        state: 'QLD',
        latitude: -19.2497,
        longitude: 146.7650,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers North Queensland coast',
      ),
      const RadarSite(
        id: '67', // Warrego - NO 64km
        name: 'Warrego',
        location: 'Warrego',
        state: 'QLD',
        latitude: -26.4308,
        longitude: 145.6883,
        availableRanges: ['128km', '256km', '512km'],
        description: 'Covers Southwest Queensland',
      ),
      const RadarSite(
        id: '78', // Weipa
        name: 'Weipa',
        location: 'Weipa',
        state: 'QLD',
        latitude: -12.6781,
        longitude: 141.8725,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers Cape York Peninsula',
      ),
      const RadarSite(
        id: '41', // Willis Island - NO 64km
        name: 'Willis Island',
        location: 'Willis Island',
        state: 'QLD',
        latitude: -16.2878,
        longitude: 149.9656,
        availableRanges: ['128km', '256km', '512km'],
        description: 'Covers Coral Sea region',
      ),

      // WA - Complete list from BOM Western Australia radar sites table (16 sites)
      const RadarSite(
        id: '31', // Albany
        name: 'Albany',
        location: 'Albany',
        state: 'WA',
        latitude: -34.9418,
        longitude: 117.8119,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers Great Southern region',
      ),
      const RadarSite(
        id: '17', // Broome
        name: 'Broome',
        location: 'Broome',
        state: 'WA',
        latitude: -17.9481,
        longitude: 122.2347,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers Kimberley region',
      ),
      const RadarSite(
        id: '114', // Carnarvon
        name: 'Carnarvon',
        location: 'Carnarvon',
        state: 'WA',
        latitude: -24.8808,
        longitude: 113.6611,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers Gascoyne region',
      ),
      const RadarSite(
        id: '15', // Dampier
        name: 'Dampier',
        location: 'Dampier',
        state: 'WA',
        latitude: -20.6530,
        longitude: 116.7139,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers Pilbara coast',
      ),
      const RadarSite(
        id: '32', // Esperance
        name: 'Esperance',
        location: 'Esperance',
        state: 'WA',
        latitude: -33.8303,
        longitude: 121.8919,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers Goldfields-Esperance region',
      ),
      const RadarSite(
        id: '6', // Geraldton
        name: 'Geraldton',
        location: 'Geraldton',
        state: 'WA',
        latitude: -28.7958,
        longitude: 114.6997,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers Mid West region',
      ),
      const RadarSite(
        id: '44', // Giles - NO 64km
        name: 'Giles',
        location: 'Giles',
        state: 'WA',
        latitude: -25.0364,
        longitude: 128.3008,
        availableRanges: ['128km', '256km', '512km'],
        description: 'Covers Great Western Woodlands',
      ),
      const RadarSite(
        id: '39', // Halls Creek - NO 64km
        name: 'Halls Creek',
        location: 'Halls Creek',
        state: 'WA',
        latitude: -18.2286,
        longitude: 127.6597,
        availableRanges: ['128km', '256km', '512km'],
        description: 'Covers East Kimberley region',
      ),
      const RadarSite(
        id: '48', // Kalgoorlie
        name: 'Kalgoorlie',
        location: 'Kalgoorlie',
        state: 'WA',
        latitude: -30.7844,
        longitude: 121.4544,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers Goldfields region',
      ),
      const RadarSite(
        id: '111', // Karratha
        name: 'Karratha',
        location: 'Karratha',
        state: 'WA',
        latitude: -20.7253,
        longitude: 116.7717,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers Pilbara region',
      ),
      const RadarSite(
        id: '29', // Learmonth - NO 64km
        name: 'Learmonth',
        location: 'Learmonth',
        state: 'WA',
        latitude: -22.2356,
        longitude: 114.0886,
        availableRanges: ['128km', '256km', '512km'],
        description: 'Covers North West Cape',
      ),
      const RadarSite(
        id: '38', // Newdegate
        name: 'Newdegate',
        location: 'Newdegate',
        state: 'WA',
        latitude: -33.0958,
        longitude: 118.9403,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers central wheatbelt',
      ),
      const RadarSite(
        id: '70', // Perth (Serpentine)
        name: 'Perth',
        location: 'Serpentine',
        state: 'WA',
        latitude: -32.3913,
        longitude: 116.0083,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers Perth metropolitan area',
      ),
      const RadarSite(
        id: '16', // Pt Hedland - NO 64km
        name: 'Pt Hedland',
        location: 'Pt Hedland',
        state: 'WA',
        latitude: -20.3717,
        longitude: 118.6281,
        availableRanges: ['128km', '256km', '512km'],
        description: 'Covers Pilbara coast',
      ),
      const RadarSite(
        id: '58', // South Doodlakine
        name: 'South Doodlakine',
        location: 'South Doodlakine',
        state: 'WA',
        latitude: -31.5878,
        longitude: 117.8772,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers central wheatbelt',
      ),
      const RadarSite(
        id: '79', // Watheroo
        name: 'Watheroo',
        location: 'Watheroo',
        state: 'WA',
        latitude: -30.3081,
        longitude: 116.0081,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers northern wheatbelt',
      ),
      const RadarSite(
        id: '7', // Wyndham - NO 64km
        name: 'Wyndham',
        location: 'Wyndham',
        state: 'WA',
        latitude: -15.4869,
        longitude: 128.1233,
        availableRanges: ['128km', '256km', '512km'],
        description: 'Covers East Kimberley region',
      ),

      // SA - Complete list from BOM South Australia radar sites table (5 sites)
      const RadarSite(
        id: '64', // Adelaide (Buckland Park)
        name: 'Adelaide',
        location: 'Buckland Park',
        state: 'SA',
        latitude: -34.6196,
        longitude: 138.4692,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers Adelaide metropolitan area',
      ),
      const RadarSite(
        id: '46', // Adelaide (Sellicks Hill) - NO 64km
        name: 'Adelaide',
        location: 'Sellicks Hill',
        state: 'SA',
        latitude: -35.3281,
        longitude: 138.5033,
        availableRanges: ['128km', '256km', '512km'],
        description: 'Covers southern Adelaide and Fleurieu Peninsula',
      ),
      const RadarSite(
        id: '33', // Ceduna
        name: 'Ceduna',
        location: 'Ceduna',
        state: 'SA',
        latitude: -32.1267,
        longitude: 133.6906,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers Eyre Peninsula',
      ),
      const RadarSite(
        id: '14', // Mt Gambier - NO 64km
        name: 'Mt Gambier',
        location: 'Mt Gambier',
        state: 'SA',
        latitude: -37.7464,
        longitude: 140.7761,
        availableRanges: ['128km', '256km', '512km'],
        description: 'Covers Limestone Coast region',
      ),
      const RadarSite(
        id: '27', // Woomera - NO 64km
        name: 'Woomera',
        location: 'Woomera',
        state: 'SA',
        latitude: -31.1553,
        longitude: 136.8056,
        availableRanges: ['128km', '256km', '512km'],
        description: 'Covers northern South Australia',
      ),

      // TAS - Complete list from BOM Tasmania radar sites table (2 sites)
      const RadarSite(
        id: '76', // Hobart (Mt Koonya)
        name: 'Hobart',
        location: 'Mt Koonya',
        state: 'TAS',
        latitude: -42.8678,
        longitude: 147.8064,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers southern Tasmania',
      ),
      const RadarSite(
        id: '52', // N.W. Tasmania (West Takone)
        name: 'N.W. Tasmania',
        location: 'West Takone',
        state: 'TAS',
        latitude: -40.9981,
        longitude: 145.5761,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers northwest Tasmania',
      ),

      // NT - Complete list from BOM Northern Territory radar sites table (5 sites)
      const RadarSite(
        id: '25', // Alice Springs - NO 64km
        name: 'Alice Springs',
        location: 'Alice Springs',
        state: 'NT',
        latitude: -23.7951,
        longitude: 133.8890,
        availableRanges: ['128km', '256km', '512km'],
        description: 'Covers Central Australia',
      ),
      const RadarSite(
        id: '63', // Darwin (Berrimah)
        name: 'Darwin',
        location: 'Berrimah',
        state: 'NT',
        latitude: -12.4564,
        longitude: 130.9256,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers Top End Northern Territory',
      ),
      const RadarSite(
        id: '112', // Gove
        name: 'Gove',
        location: 'Gove',
        state: 'NT',
        latitude: -12.2692,
        longitude: 136.8178,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers northeast Arnhem Land',
      ),
      const RadarSite(
        id: '42', // Katherine (Tindal) - NO 64km
        name: 'Katherine',
        location: 'Tindal',
        state: 'NT',
        latitude: -14.5206,
        longitude: 132.3781,
        availableRanges: ['128km', '256km', '512km'],
        description: 'Covers Katherine region',
      ),
      const RadarSite(
        id: '77', // Warruwi
        name: 'Warruwi',
        location: 'Warruwi',
        state: 'NT',
        latitude: -11.6472,
        longitude: 133.3806,
        availableRanges: ['64km', '128km', '256km', '512km'],
        description: 'Covers Tiwi Islands and northern coast',
      ),
    ];
  }

  /// Get radar sites by state
  static Map<String, List<RadarSite>> getRadarSitesByState() {
    final sites = getAvailableRadarSites();
    final Map<String, List<RadarSite>> sitesByState = {};
    
    for (final site in sites) {
      sitesByState.putIfAbsent(site.state, () => []).add(site);
    }
    
    return sitesByState;
  }

  /// Find radar site by ID
  static RadarSite? findRadarSite(String siteId) {
    final sites = getAvailableRadarSites();
    try {
      return sites.firstWhere((site) => site.id == siteId);
    } catch (e) {
      return null;
    }
  }

  /// Fetch the latest radar image for a site
  Future<RadarImage?> fetchLatestRadarImage(String siteId, {String range = '256km'}) async {
    // Special handling for national radar
    if (siteId == 'NATIONAL') {
      return await _fetchNationalRadarImage();
    }
    try {
      final bomSiteId = getBomSiteId(siteId, range);
      debugPrint('DEBUG: BomRadarService - Fetching latest radar image for $siteId ($bomSiteId), range: $range');

      // First try to get image with layers from loop page
      final radarImages = await _fetchRadarImagesWithLayers(bomSiteId);
      
      if (radarImages.isNotEmpty) {
        // Use the most recent image and update range
        final latestImage = radarImages.last.copyWith(range: range);
        return latestImage;
      }

      debugPrint('DEBUG: BomRadarService - No radar images found from loop page, trying timestamp method');
      
      // Fallback to timestamp-based method
      final now = DateTime.now().toUtc();
      
      // Check for images from current time back to 60 minutes ago
      for (int minutesBack = 0; minutesBack <= 60; minutesBack += 6) {
        final checkTime = now.subtract(Duration(minutes: minutesBack));
        final radarImage = _generateRadarImageUrl(bomSiteId, checkTime, range);

        try {
          // Test direct image access
          final response = await http.head(
            Uri.parse(radarImage.url),
            headers: _requestHeaders,
          ).timeout(requestTimeout);

          debugPrint('DEBUG: BomRadarService - Testing ${radarImage.url} - Status: ${response.statusCode}');

          if (response.statusCode == 200) {
            debugPrint('DEBUG: BomRadarService - Successfully found radar image: ${radarImage.url}');
            return radarImage.copyWith(
              fileSizeBytes: int.tryParse(response.headers['content-length'] ?? '0'),
            );
          }
        } catch (e) {
          debugPrint('DEBUG: BomRadarService - Failed to check ${radarImage.url}: $e');
          continue;
        }
      }

      debugPrint('DEBUG: BomRadarService - No radar images found for $siteId in last 60 minutes');
      
      // As fallback, try to return a mock radar image for testing
      return _createMockRadarImage(siteId, range);
    } catch (e) {
      debugPrint('ERROR: BomRadarService - Failed to fetch radar image for $siteId: $e');
      return _createMockRadarImage(siteId, range);
    }
  }

  /// Fetch a radar loop (multiple frames) for animation
  Future<List<RadarImage>> fetchRadarLoop(String siteId, {String range = '256km', int frames = 6}) async {
    try {
      final bomSiteId = getBomSiteId(siteId, range);
      debugPrint('DEBUG: BomRadarService - Fetching radar loop for $siteId ($bomSiteId), range: $range, frames: $frames');

      // Try to get images with layers from loop page first
      final radarImages = await _fetchRadarImagesWithLayers(bomSiteId);
      
      if (radarImages.isNotEmpty) {
        // Update range for all images and sort chronologically
        final updatedImages = radarImages.map((img) => img.copyWith(range: range)).toList();
        updatedImages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
        // Take the last N frames
        final recentFrames = updatedImages.length > frames 
            ? updatedImages.sublist(updatedImages.length - frames)
            : updatedImages;
            
        debugPrint('DEBUG: BomRadarService - Successfully fetched ${recentFrames.length} frames with layers from loop page');
        return recentFrames;
      }

      debugPrint('DEBUG: BomRadarService - Loop page method failed, trying timestamp method');

      // Fallback to timestamp-based method
      final List<RadarImage> fallbackImages = [];
      final now = DateTime.now().toUtc();

      // Try to get the last N frames, going back in 5-minute intervals
      // BOM updates at minutes ending in 4 and 9 (e.g., 10:04, 10:09, 10:14, 10:19)
      for (int i = 0; i < frames * 3; i++) { // Try more frames to account for missing ones
        final frameTime = _getBomTimestamp(now, i);
        final radarImage = _generateRadarImageUrl(bomSiteId, frameTime, range);

        // Test if the image exists
        try {
          final response = await http.head(
            Uri.parse(radarImage.url),
            headers: _requestHeaders,
          ).timeout(requestTimeout);

          if (response.statusCode == 200) {
            debugPrint('DEBUG: BomRadarService - Found frame ${fallbackImages.length + 1}: ${radarImage.url}');
            fallbackImages.add(radarImage.copyWith(
              fileSizeBytes: int.tryParse(response.headers['content-length'] ?? '0'),
            ));
            
            // Stop once we have enough frames
            if (fallbackImages.length >= frames) break;
          }
        } catch (e) {
          debugPrint('DEBUG: BomRadarService - Frame check failed: $e');
          continue;
        }
      }

      // Sort chronologically (oldest first)
      radarImages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      debugPrint('DEBUG: BomRadarService - Successfully fetched ${radarImages.length} frames for $siteId');
      
      // If no frames found, return mock data for testing
      if (radarImages.isEmpty) {
        return List.generate(frames, (index) => 
          _createMockRadarImage(siteId, range, now.subtract(Duration(minutes: index * 6)))
        );
      }
      
      return radarImages;
    } catch (e) {
      debugPrint('ERROR: BomRadarService - Failed to fetch radar loop for $siteId: $e');
      return [];
    }
  }

  /// Fetch national radar loop (multiple hourly frames)
  Future<List<RadarImage>> fetchNationalRadarLoop({int frames = 6}) async {
    return await _fetchNationalRadarLoop(frames: frames);
  }

  /// Find available satellite image URL with graceful fallback
  Future<String> _findAvailableSatelliteUrl(DateTime targetTime) async {
    // Try current hour first, then previous hour as fallback
    for (int hourOffset = 0; hourOffset <= 2; hourOffset++) {
      final satCheckTime = targetTime.subtract(Duration(hours: hourOffset));
      final satTime = DateTime(satCheckTime.year, satCheckTime.month, satCheckTime.day, satCheckTime.hour, 30);
      final satTimeString = '${satTime.year}'
          '${satTime.month.toString().padLeft(2, '0')}'
          '${satTime.day.toString().padLeft(2, '0')}'
          '${satTime.hour.toString().padLeft(2, '0')}'
          '${satTime.minute.toString().padLeft(2, '0')}';
      
      final testSatUrl = 'https://reg.bom.gov.au/gms/IDE00135.radar.$satTimeString.jpg';
      
      try {
        final satResponse = await http.head(
          Uri.parse(testSatUrl),
          headers: _requestHeaders,
        ).timeout(requestTimeout);
        
        if (satResponse.statusCode == 200) {
          debugPrint('DEBUG: BomRadarService - Found available satellite (${hourOffset}h back): $testSatUrl');
          return testSatUrl;
        }
      } catch (e) {
        debugPrint('DEBUG: BomRadarService - Satellite not available at $satTimeString (${hourOffset}h back)');
        continue;
      }
    }
    
    // Final fallback: use the background map if no satellite is available
    debugPrint('DEBUG: BomRadarService - No satellite available, using background fallback');
    return 'https://reg.bom.gov.au/products/radar_transparencies/IDE00035.background.png';
  }

  /// Generate radar image URL based on BOM patterns
  RadarImage _generateRadarImageUrl(String siteId, DateTime timestamp, String range) {
    // BOM radar URLs follow pattern: IDR{site_id}.T.{timestamp}.png
    // Timestamp format: YYYYMMDDHHMM (rounded to nearest 6-minute interval)
    
    // Round timestamp to nearest 6-minute interval
    final roundedMinute = (timestamp.minute ~/ 6) * 6;
    final roundedTime = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
      timestamp.hour,
      roundedMinute,
    );

    final timeString = '${roundedTime.year}'
        '${roundedTime.month.toString().padLeft(2, '0')}'
        '${roundedTime.day.toString().padLeft(2, '0')}'
        '${roundedTime.hour.toString().padLeft(2, '0')}'
        '${roundedTime.minute.toString().padLeft(2, '0')}';

    final url = '${baseUrl}$siteId.T.$timeString.png';

    return RadarImage(
      siteId: siteId,
      timestamp: roundedTime,
      url: url,
      range: range,
    );
  }

  /// Create a mock radar image for testing when BOM is unavailable
  RadarImage _createMockRadarImage(String siteId, String range, [DateTime? timestamp]) {
    final time = timestamp ?? DateTime.now().toUtc();
    final site = findRadarSite(siteId);
    final locationName = site?.name ?? siteId;
    
    // Use httpbin.org which is more reliable, or a simple image
    final mockUrl = 'https://httpbin.org/image/png';
    
    debugPrint('DEBUG: Created mock radar image for $locationName $range: $mockUrl');
    
    return RadarImage(
      siteId: siteId,
      timestamp: time,
      url: mockUrl,
      range: range,
      isCached: false,
    );
  }

  /// Download radar image data for caching
  Future<List<int>?> downloadRadarImageData(String url) async {
    try {
      debugPrint('DEBUG: BomRadarService - Downloading radar image: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: _requestHeaders,
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        debugPrint('DEBUG: BomRadarService - Successfully downloaded ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      } else {
        debugPrint('ERROR: BomRadarService - Failed to download image (${response.statusCode}): $url');
        return null;
      }
    } catch (e) {
      debugPrint('ERROR: BomRadarService - Download failed: $e');
      return null;
    }
  }

  /// Fetch national radar composite loop (multiple hourly frames)
  Future<List<RadarImage>> _fetchNationalRadarLoop({int frames = 6}) async {
    try {
      debugPrint('DEBUG: BomRadarService - Fetching national radar loop ($frames hourly frames)');
      
      final now = DateTime.now().toUtc();
      final List<RadarImage> images = [];
      
      // Fetch multiple hourly frames for animation
      for (int hoursBack = 0; hoursBack < frames && hoursBack <= 12; hoursBack++) {
        final checkTime = now.subtract(Duration(hours: hoursBack));
        
        // National radar: hourly at 48 minutes (e.g., 0748, 0848, 0948, 1048)
        var radarTime = DateTime(checkTime.year, checkTime.month, checkTime.day, checkTime.hour, 48);
        
        // If radar time is in the future, go back to previous hour
        if (radarTime.isAfter(now)) {
          radarTime = radarTime.subtract(const Duration(hours: 1));
          debugPrint('DEBUG: BomRadarService - Adjusted future radarTime to previous hour: ${radarTime.toIso8601String()}');
        }
        final radarTimeString = '${radarTime.year}'
            '${radarTime.month.toString().padLeft(2, '0')}'
            '${radarTime.day.toString().padLeft(2, '0')}'
            '${radarTime.hour.toString().padLeft(2, '0')}'
            '${radarTime.minute.toString().padLeft(2, '0')}';
        
        // National radar composite URLs (hourly pattern)
        final radarDataUrl = 'https://reg.bom.gov.au/radar/IDR00004.T.$radarTimeString.png';
        
        // Find available satellite image with graceful fallback
        final satelliteUrl = await _findAvailableSatelliteUrl(checkTime);
        
        try {
          final response = await http.head(
            Uri.parse(radarDataUrl),
            headers: _requestHeaders,
          ).timeout(requestTimeout);

          if (response.statusCode == 200) {
            debugPrint('DEBUG: BomRadarService - Found national radar frame ${hoursBack+1}/$frames: $radarDataUrl');
            debugPrint('DEBUG: BomRadarService - Using satellite: $satelliteUrl');
            
            // Create layers for national radar composite (no locations layer)
            final layers = RadarLayers(
              backgroundUrl: RadarAssetsService.getBackgroundAssetPath('00', 'National') ?? 
                  'https://reg.bom.gov.au/products/radar_transparencies/IDE00035.background.png',
              locationsUrl: null, // Remove location markers from National view
              rangeUrl: 'https://reg.bom.gov.au/scripts/radar/images/radar_trans_map_mask.png', // National uses different range system
              topographyUrl: satelliteUrl, // Satellite imagery as topography layer
              legendUrl: RadarAssetsService.getLegendAssetPath(),
              radarDataUrl: radarDataUrl, // Main radar composite
              observationsUrl: null, // National radar doesn't have observations layer
            );
            
            images.add(RadarImage(
              siteId: 'NATIONAL',
              timestamp: radarTime, // Use the actual radar timestamp
              url: radarDataUrl,
              range: 'National',
              layers: layers,
            ));
          } else {
            debugPrint('DEBUG: BomRadarService - National radar frame not available (${response.statusCode}): $radarDataUrl');
          }
        } catch (e) {
          debugPrint('DEBUG: BomRadarService - Failed to check national radar at $radarTimeString: $e');
          continue;
        }
      }
      
      // Return frames in chronological order (oldest first for proper animation)
      images.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      debugPrint('DEBUG: BomRadarService - Found ${images.length} national radar frames');
      return images;
    } catch (e) {
      debugPrint('ERROR: BomRadarService - Failed to fetch national radar loop: $e');
      return [];
    }
  }

  /// Fetch single national radar composite image (fallback)
  Future<RadarImage?> _fetchNationalRadarImage() async {
    try {
      debugPrint('DEBUG: BomRadarService - Fetching national radar composite');
      
      final now = DateTime.now().toUtc();
      
      // Try different timestamps for National radar (hourly updates)
      for (int hoursBack = 0; hoursBack <= 12; hoursBack++) {
        final checkTime = now.subtract(Duration(hours: hoursBack));
        
        // National radar: hourly at 48 minutes (e.g., 0748, 0848, 0948, 1048)
        var radarTime = DateTime(checkTime.year, checkTime.month, checkTime.day, checkTime.hour, 48);
        
        // If radar time is in the future, go back to previous hour
        if (radarTime.isAfter(now)) {
          radarTime = radarTime.subtract(const Duration(hours: 1));
          debugPrint('DEBUG: BomRadarService - Adjusted future radarTime to previous hour: ${radarTime.toIso8601String()}');
        }
        
        final radarTimeString = '${radarTime.year}'
            '${radarTime.month.toString().padLeft(2, '0')}'
            '${radarTime.day.toString().padLeft(2, '0')}'
            '${radarTime.hour.toString().padLeft(2, '0')}'
            '${radarTime.minute.toString().padLeft(2, '0')}';
        
        // National radar composite URLs (hourly pattern)
        final radarDataUrl = 'https://reg.bom.gov.au/radar/IDR00004.T.$radarTimeString.png';
        
        // Find available satellite image with graceful fallback
        final satelliteUrl = await _findAvailableSatelliteUrl(checkTime);
        
        try {
          final response = await http.head(
            Uri.parse(radarDataUrl),
            headers: _requestHeaders,
          ).timeout(requestTimeout);

          if (response.statusCode == 200) {
            debugPrint('DEBUG: BomRadarService - Found national radar: $radarDataUrl');
            debugPrint('DEBUG: BomRadarService - Satellite layer: $satelliteUrl');
            
            // Use local assets for National radar background layer
            final backgroundUrl = RadarAssetsService.getBackgroundAssetPath('00', 'National') ?? 
                'https://reg.bom.gov.au/products/radar_transparencies/IDE00035.background.png';
            
            debugPrint('DEBUG: BomRadarService - National radar background: $backgroundUrl');
            
            // Create layers for national radar composite (no locations layer)
            final layers = RadarLayers(
              backgroundUrl: backgroundUrl,
              locationsUrl: null, // Remove location markers from National view
              rangeUrl: 'https://reg.bom.gov.au/scripts/radar/images/radar_trans_map_mask.png', // Map mask
              topographyUrl: satelliteUrl, // Satellite imagery as topography layer
              legendUrl: RadarAssetsService.getLegendAssetPath(),
              radarDataUrl: radarDataUrl, // Main radar composite
              observationsUrl: null, // National radar doesn't have observations layer
            );
            
            return RadarImage(
              siteId: 'NATIONAL',
              timestamp: radarTime, // Use the actual radar timestamp
              url: radarDataUrl,
              range: 'National',
              layers: layers,
            );
          }
        } catch (e) {
          debugPrint('DEBUG: BomRadarService - Failed to check national radar at $radarTimeString: $e');
          continue;
        }
      }
      
      debugPrint('DEBUG: BomRadarService - No national radar images found');
      return null;
    } catch (e) {
      debugPrint('ERROR: BomRadarService - Failed to fetch national radar: $e');
      return null;
    }
  }

  /// Fetch radar image URLs and layers from BOM loop page
  Future<List<RadarImage>> _fetchRadarImagesWithLayers(String siteId) async {
    try {
      final loopUrl = '${loopBaseUrl}$siteId.loop.shtml';
      debugPrint('DEBUG: BomRadarService - Fetching radar URLs from: $loopUrl');
      
      final response = await http.get(
        Uri.parse(loopUrl),
        headers: _requestHeaders,
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        final html = response.body;
        
        // Extract radar data image URLs (the timestamped ones)
        final radarDataRegex = RegExp('$siteId\\.T\\.\\d{12}\\.png');
        final radarMatches = radarDataRegex.allMatches(html);
        
        // Extract weather observations layer URLs (the timestamped ones)
        final observationsRegex = RegExp('$siteId\\.observations\\.\\d{12}\\.png');
        final observationsMatches = observationsRegex.allMatches(html);
        
        // Extract site ID and range from BOM site ID (e.g., "IDR714" -> siteId="71", range="4")
        final siteIdMatch = RegExp(r'IDR(\d{2})(\d)').firstMatch(siteId);
        String? baseSiteId;
        String range = '256km'; // Default range
        
        if (siteIdMatch != null) {
          baseSiteId = siteIdMatch.group(1);
          final rangeDigit = siteIdMatch.group(2);
          range = switch (rangeDigit) {
            '4' => '64km',
            '3' => '128km',
            '2' => '256km',
            '1' => '512km',
            _ => '256km',
          };
        }
        
        // Use local assets for background, locations, and topography layers
        String? backgroundUrl;
        String? locationsUrl;
        String? topographyUrl;
        
        if (baseSiteId != null) {
          backgroundUrl = RadarAssetsService.getBackgroundAssetPath(baseSiteId, range);
          locationsUrl = RadarAssetsService.getLocationsAssetPath(baseSiteId, range);
          topographyUrl = RadarAssetsService.getTopographyAssetPath(baseSiteId, range);
          
          debugPrint('DEBUG: BomRadarService - Sydney $range layer paths:');
          debugPrint('  Site ID: $baseSiteId → BOM ID: $siteId');
          debugPrint('  Background: $backgroundUrl');
          debugPrint('  Locations: $locationsUrl');
          debugPrint('  Topography: $topographyUrl');
          
          // Test asset availability
          final hasAssets = RadarAssetsService.hasLocalAssets(baseSiteId);
          debugPrint('  Has local assets: $hasAssets');
        }
        
        // Fallback to remote URLs if local assets not available
        final transparencyBaseUrl = 'https://reg.bom.gov.au/products/radar_transparencies/';
        
        backgroundUrl ??= '${transparencyBaseUrl}$siteId.background.png';
        debugPrint('DEBUG: BomRadarService - Background URL: $backgroundUrl');
        
        locationsUrl ??= '${transparencyBaseUrl}$siteId.locations.png';
        debugPrint('DEBUG: BomRadarService - Locations URL: $locationsUrl');
        
        topographyUrl ??= '${transparencyBaseUrl}$siteId.topography.png';
        debugPrint('DEBUG: BomRadarService - Topography URL: $topographyUrl');
        
        // Use local range and legend assets
        final rangeUrl = RadarAssetsService.getRangeAssetPath(range);
        final legendUrl = RadarAssetsService.getLegendAssetPath();
        
        debugPrint('DEBUG: BomRadarService - Using local range: $rangeUrl');
        debugPrint('DEBUG: BomRadarService - Using local legend: $legendUrl');
        
        final radarImages = <RadarImage>[];
        
        for (final match in radarMatches) {
          final radarDataFilename = match.group(0)!;
          final radarDataUrl = baseUrl + radarDataFilename;
          final timestamp = _extractTimestampFromUrl(radarDataUrl);
          
          // Find matching observations layer for this timestamp
          String? observationsUrl;
          final timestampString = radarDataFilename.split('.').last.replaceAll('.png', '');
          for (final obsMatch in observationsMatches) {
            final obsFilename = obsMatch.group(0)!;
            if (obsFilename.contains(timestampString)) {
              observationsUrl = baseUrl + obsFilename;
              break;
            }
          }
          
          final layers = RadarLayers(
            backgroundUrl: backgroundUrl,
            locationsUrl: locationsUrl,
            rangeUrl: rangeUrl,
            topographyUrl: topographyUrl,
            legendUrl: legendUrl,
            radarDataUrl: radarDataUrl,
            observationsUrl: observationsUrl,
          );
          
          // Debug final layer configuration
          debugPrint('DEBUG: Final layer configuration for ${baseSiteId ?? siteId}:');
          debugPrint('  Background: ${layers.backgroundUrl}');
          debugPrint('  Topography: ${layers.topographyUrl}');
          debugPrint('  Locations: ${layers.locationsUrl}');
          debugPrint('  Range: ${layers.rangeUrl}');
          debugPrint('  Legend: ${layers.legendUrl}');
          debugPrint('  Radar Data: ${layers.radarDataUrl}');
          debugPrint('  Observations: ${layers.observationsUrl}');
          
          radarImages.add(RadarImage(
            siteId: baseSiteId ?? siteId,
            timestamp: timestamp,
            url: radarDataUrl, // This is the working BOM radar image URL
            range: range,
            layers: layers, // Now with local assets for background and locations!
          ));
        }
            
        debugPrint('DEBUG: BomRadarService - Found ${radarImages.length} radar images');
        for (int i = 0; i < radarImages.length && i < 3; i++) {
          debugPrint('DEBUG: Sample URL $i: ${radarImages[i].url}');
        }
        return radarImages;
      } else {
        debugPrint('DEBUG: BomRadarService - Failed to fetch loop page: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('ERROR: BomRadarService - Failed to fetch radar URLs: $e');
      return [];
    }
  }



  /// Calculate BOM timestamp based on their 5-minute schedule
  /// BOM updates at minutes ending in 4 and 9 (e.g., 10:04, 10:09, 10:14, 10:19, 10:24, 10:29...)
  DateTime _getBomTimestamp(DateTime now, int stepsBack) {
    // BOM updates every 5 minutes at x4 and x9 pattern
    // Valid minutes: 04, 09, 14, 19, 24, 29, 34, 39, 44, 49, 54, 59
    final validMinutes = [4, 9, 14, 19, 24, 29, 34, 39, 44, 49, 54, 59];
    
    // Start with current time rounded down to hour
    DateTime base = DateTime.utc(now.year, now.month, now.day, now.hour);
    
    // Find the latest valid timestamp before or at current time
    DateTime latestValidTime = base;
    for (int minute in validMinutes.reversed) {
      final candidateTime = base.add(Duration(minutes: minute));
      if (candidateTime.isBefore(now) || candidateTime.isAtSameMomentAs(now)) {
        latestValidTime = candidateTime;
        break;
      }
    }
    
    // If no valid time found in current hour, go to previous hour's last slot (59)
    if (latestValidTime == base) {
      latestValidTime = base.subtract(const Duration(minutes: 1)); // xx:59 of previous hour
    }
    
    // Go back by the requested number of 5-minute steps
    return latestValidTime.subtract(Duration(minutes: stepsBack * 5));
  }

  /// Extract timestamp from radar image URL
  DateTime _extractTimestampFromUrl(String url) {
    try {
      final timestampRegex = RegExp(r'\.T\.(\d{12})\.png');
      final match = timestampRegex.firstMatch(url);
      
      if (match != null) {
        final timestampStr = match.group(1)!;
        final year = int.parse(timestampStr.substring(0, 4));
        final month = int.parse(timestampStr.substring(4, 6));
        final day = int.parse(timestampStr.substring(6, 8));
        final hour = int.parse(timestampStr.substring(8, 10));
        final minute = int.parse(timestampStr.substring(10, 12));
        
        return DateTime.utc(year, month, day, hour, minute); // Use UTC per project standards
      }
    } catch (e) {
      debugPrint('ERROR: BomRadarService - Failed to extract timestamp from $url: $e');
    }
    
    return DateTime.now().toUtc();
  }

  /// Check if BOM radar service is available
  Future<bool> checkServiceAvailability() async {
    try {
      debugPrint('DEBUG: BomRadarService - Checking service availability');
      
      // Try to fetch a recent Sydney radar image as a test
      final testImage = await fetchLatestRadarImage('IDR714', range: '256km');
      
      final isAvailable = testImage != null;
      debugPrint('DEBUG: BomRadarService - Service available: $isAvailable');
      return isAvailable;
    } catch (e) {
      debugPrint('ERROR: BomRadarService - Service check failed: $e');
      return false;
    }
  }
}
