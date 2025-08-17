import '../models/notam.dart';
import '../models/airport_infrastructure.dart';

/// Service that maps NOTAMs to specific airport facilities
/// This enables facility-specific status analysis instead of system-level analysis
class FacilityNotamMapper {
  
  /// Map NOTAMs to a specific runway
  /// 
  /// [allNotams] - All NOTAMs for the airport
  /// [runwayId] - Runway identifier (e.g., "03/21", "16L/34R")
  /// 
  /// Returns list of NOTAMs that affect this specific runway
  List<Notam> getRunwayNotams(List<Notam> allNotams, String runwayId) {
    return allNotams.where((notam) {
      // Must be a runway-related NOTAM
      if (notam.group != NotamGroup.runways) return false;
      
      // Check if NOTAM text mentions this specific runway
      return _affectsSpecificRunway(notam, runwayId);
    }).toList();
  }
  
  /// Map ALL NOTAMs that affect a specific runway (across all groups)
  /// 
  /// [allNotams] - All NOTAMs for the airport
  /// [runwayId] - Runway identifier (e.g., "03/21", "16L/34R")
  /// 
  /// Returns list of NOTAMs that affect this specific runway from any group
  List<Notam> getAllRunwayAffectingNotams(List<Notam> allNotams, String runwayId) {
    return allNotams.where((notam) {
      // Check if NOTAM text mentions this specific runway, regardless of group
      return _affectsSpecificRunway(notam, runwayId);
    }).toList();
  }
  
  /// Map NOTAMs to a specific NAVAID
  /// 
  /// [allNotams] - All NOTAMs for the airport
  /// [navaidId] - NAVAID identifier (e.g., "ILS 07", "VOR PH", "DME PH")
  /// 
  /// Returns list of NOTAMs that affect this specific NAVAID
  List<Notam> getNavaidNotams(List<Notam> allNotams, String navaidId) {
    return allNotams.where((notam) {
      // Must be an instrument procedure NOTAM
      if (notam.group != NotamGroup.instrumentProcedures) return false;
      
      // Check if NOTAM text mentions this specific NAVAID
      return _affectsSpecificNavaid(notam, navaidId);
    }).toList();
  }
  
  /// Map NOTAMs to a specific lighting system
  /// 
  /// [allNotams] - All NOTAMs for the airport
  /// [lightingId] - Lighting system identifier (e.g., "PAPI", "HIRL", "REIL")
  /// 
  /// Returns list of NOTAMs that affect this specific lighting system
  List<Notam> getLightingNotams(List<Notam> allNotams, String lightingId) {
    return allNotams.where((notam) {
      // Must be a lighting-related NOTAM (could be in runways or airport services)
      if (notam.group != NotamGroup.runways && 
          notam.group != NotamGroup.airportServices) return false;
      
      // Check if NOTAM text mentions this specific lighting system
      return _affectsSpecificLighting(notam, lightingId);
    }).toList();
  }
  
  /// Map NOTAMs to a specific taxiway
  /// 
  /// [allNotams] - All NOTAMs for the airport
  /// [taxiwayId] - Taxiway identifier (e.g., "A", "B", "C")
  /// 
  /// Returns list of NOTAMs that affect this specific taxiway
  List<Notam> getTaxiwayNotams(List<Notam> allNotams, String taxiwayId) {
    return allNotams.where((notam) {
      // Must be a taxiway-related NOTAM
      if (notam.group != NotamGroup.taxiways) return false;
      
      // Check if NOTAM text mentions this specific taxiway
      return _affectsSpecificTaxiway(notam, taxiwayId);
    }).toList();
  }
  
  /// Check if a NOTAM affects a specific runway
  bool _affectsSpecificRunway(Notam notam, String runwayId) {
    final text = notam.rawText.toUpperCase();
    final runwayIdUpper = runwayId.toUpperCase();
    
    // Common runway identifiers in NOTAMs
    final runwayPatterns = [
      'RWY $runwayIdUpper',
      'RUNWAY $runwayIdUpper',
    ];
    
    // For single direction runways, add direct match
    if (!runwayIdUpper.contains('/')) {
      runwayPatterns.add('RWY $runwayIdUpper');
    }
    
    // Check if any pattern matches
    final directMatch = runwayPatterns.any((pattern) => text.contains(pattern));
    
    // If we're looking for a single direction, also check if it's part of a dual-direction runway
    bool dualDirectionMatch = false;
    if (!runwayIdUpper.contains('/')) {
      // Look for patterns like "RWY 07/25" or "RWY 16L/34R" where single direction is part of the identifier
      final dualRunwayPattern = RegExp(r'RWY (\w+)/(\w+)');
      final match = dualRunwayPattern.firstMatch(text);
      if (match != null) {
        final direction1 = match.group(1);
        final direction2 = match.group(2);
        if (direction1 == runwayIdUpper || direction2 == runwayIdUpper) {
          dualDirectionMatch = true;
        }
      }
    }
    
    return directMatch || dualDirectionMatch;
  }
  
  /// Check if a NOTAM affects a specific NAVAID
  bool _affectsSpecificNavaid(Notam notam, String navaidId) {
    final text = notam.rawText.toUpperCase();
    final navaidIdUpper = navaidId.toUpperCase();
    
    // Common NAVAID identifiers in NOTAMs
    final navaidPatterns = [
      navaidIdUpper, // Direct match
    ];
    
    // Add type-specific patterns if NAVAID ID contains type
    if (navaidIdUpper.startsWith('ILS ')) {
      final runwayId = navaidIdUpper.substring(4); // Remove "ILS " prefix
      navaidPatterns.addAll([
        'ILS $runwayId',
        'INSTRUMENT LANDING SYSTEM $runwayId',
        'ILS RWY $runwayId',
        'RWY $runwayId ILS',
      ]);
    } else if (navaidIdUpper.startsWith('VOR ')) {
      final navaidName = navaidIdUpper.substring(4); // Remove "VOR " prefix
      navaidPatterns.addAll([
        'VOR $navaidName',
        '$navaidName VOR',
      ]);
    } else if (navaidIdUpper.startsWith('DME ')) {
      final navaidName = navaidIdUpper.substring(4); // Remove "DME " prefix
      navaidPatterns.addAll([
        'DME $navaidName',
        '$navaidName DME',
      ]);
    } else if (navaidIdUpper.startsWith('NDB ')) {
      final navaidName = navaidIdUpper.substring(4); // Remove "NDB " prefix
      navaidPatterns.addAll([
        'NDB $navaidName',
        '$navaidName NDB',
      ]);
    }
    
    // Check if any pattern matches
    return navaidPatterns.any((pattern) => text.contains(pattern));
  }
  
  /// Check if a NOTAM affects a specific lighting system
  bool _affectsSpecificLighting(Notam notam, String lightingId) {
    final text = notam.rawText.toUpperCase();
    final lightingIdUpper = lightingId.toUpperCase();
    
    // Common lighting identifiers in NOTAMs
    final lightingPatterns = [
      lightingIdUpper, // Direct match
      'PAPI $lightingIdUpper',
      'VASI $lightingIdUpper',
      'REIL $lightingIdUpper',
      'HIRL $lightingIdUpper',
      'MIRL $lightingIdUpper',
      'LIRL $lightingIdUpper',
      'APPROACH LIGHTING $lightingIdUpper',
      'RUNWAY LIGHTING $lightingIdUpper',
    ];
    
    // Check if any pattern matches
    return lightingPatterns.any((pattern) => text.contains(pattern));
  }
  
  /// Check if a NOTAM affects a specific taxiway
  bool _affectsSpecificTaxiway(Notam notam, String taxiwayId) {
    final text = notam.rawText.toUpperCase();
    final taxiwayIdUpper = taxiwayId.toUpperCase();
    
    // Common taxiway identifiers in NOTAMs
    final taxiwayPatterns = [
      'TAXIWAY $taxiwayIdUpper',
      'TWY $taxiwayIdUpper',
      taxiwayIdUpper, // Direct match
    ];
    
    // Check if any pattern matches
    return taxiwayPatterns.any((pattern) => text.contains(pattern));
  }
  
  /// Get all NOTAMs that affect a specific facility by type
  /// 
  /// [allNotams] - All NOTAMs for the airport
  /// [facilityType] - Type of facility ("runway", "navaid", "lighting", "taxiway")
  /// [facilityId] - Facility identifier
  /// 
  /// Returns list of NOTAMs that affect this specific facility
  List<Notam> getFacilityNotams(List<Notam> allNotams, String facilityType, String facilityId) {
    switch (facilityType.toLowerCase()) {
      case 'runway':
        return getRunwayNotams(allNotams, facilityId);
      case 'navaid':
        return getNavaidNotams(allNotams, facilityId);
      case 'lighting':
        return getLightingNotams(allNotams, facilityId);
      case 'taxiway':
        return getTaxiwayNotams(allNotams, facilityId);
      default:
        return [];
    }
  }
  
  /// Get facility-specific NOTAMs for an entire airport infrastructure
  /// 
  /// [allNotams] - All NOTAMs for the airport
  /// [infrastructure] - Airport infrastructure data
  /// 
  /// Returns map of facility ID to affecting NOTAMs
  Map<String, List<Notam>> getAllFacilityNotams(
    List<Notam> allNotams, 
    AirportInfrastructure infrastructure
  ) {
    final facilityNotams = <String, List<Notam>>{};
    
    // Map runway NOTAMs
    for (final runway in infrastructure.runways) {
      facilityNotams['runway_${runway.identifier}'] = getRunwayNotams(allNotams, runway.identifier);
    }
    
    // Map NAVAID NOTAMs
    for (final navaid in infrastructure.navaids) {
      final key = 'navaid_${navaid.type}_${navaid.runway}';
      facilityNotams[key] = getNavaidNotams(allNotams, '${navaid.type} ${navaid.runway}');
    }
    
    // Map taxiway NOTAMs
    for (final taxiway in infrastructure.taxiways) {
      facilityNotams['taxiway_${taxiway.identifier}'] = getTaxiwayNotams(allNotams, taxiway.identifier);
    }
    
    // Map lighting NOTAMs (for runways with lighting)
    for (final runway in infrastructure.runways) {
      if (runway.hasLighting) {
        facilityNotams['lighting_${runway.identifier}'] = getLightingNotams(allNotams, 'HIRL');
      }
    }
    
    return facilityNotams;
  }
}
