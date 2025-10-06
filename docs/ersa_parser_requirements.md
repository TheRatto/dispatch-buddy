# ERSA Parser Requirements for Briefing Buddy Integration

## 🎯 **Project Overview**

Create a parser for AirServices Australia ERSA PDF files that extracts airport infrastructure data and outputs individual JSON files for integration with Briefing Buddy.

## 📋 **Core Requirements**

### **Output Format: Individual JSON Files per Airport**

**File Structure**: `{ICAO_CODE}.json` (e.g., `YSSY.json`, `YPPH.json`)

**File Location**: `assets/ersa_data/airports/`

### **JSON Structure**

```json
{
  "metadata": {
    "icao": "YSSY",
    "name": "Sydney Kingsford Smith Airport",
    "lastUpdated": "2024-01-15T00:00:00Z",
    "validityPeriod": {
      "start": "2024-01-15T00:00:00Z",
      "end": "2024-04-15T00:00:00Z"
    },
    "dataSource": "ERSA",
    "version": "1.0"
  },
  "runways": [
    {
      "identifier": "07/25",
      "length": 3962,
      "width": 60,
      "surface": "Asphalt",
      "lighting": ["HIRL", "PAPI", "RCLL"],
      "status": "OPERATIONAL"
    }
  ],
  "navaids": [
    {
      "identifier": "SY VOR/DME",
      "frequency": "113.7",
      "type": "VOR/DME",
      "runway": "07/25",
      "status": "OPERATIONAL"
    },
    {
      "identifier": "ILS 07",
      "frequency": "109.5",
      "type": "ILS/DME",
      "runway": "07/25",
      "status": "OPERATIONAL"
    }
  ],
  "lighting": {
    "runway": ["HIRL", "PAPI", "RCLL"],
    "taxiway": ["HIAL"],
    "status": "OPERATIONAL"
  },
  "firefighting": {
    "category": "CAT 9",
    "operationalHours": "H24",
    "status": "OPERATIONAL"
  }
}
```

## 📁 **File Organization Structure**

```
assets/
  ersa_data/
    airports/
      YSSY.json
      YPPH.json
      YBBN.json
      YMML.json
      ...
    metadata/
      airport_index.json  # Index of all available airports
      validity_periods.json  # When each airport expires
    updates/
      changelog.json  # Track what changed in each update
```

## 🔄 **Update Process Requirements**

### **90-Day Update Cycle**

- **ERSA Release**: Every 90 days (typically 15th of month)
- **Validity Period**: 90 days from processing date
- **Update Process**: Full replacement of all airport files

### **Update Workflow**

```python
# Required update process
class ERSAUpdateManager:
    def process_new_ersa(self, ersa_pdf_path):
        """Process new ERSA and update all airport files"""
        
        # 1. Parse ERSA PDF
        airport_data = self.parse_ersa_pdf(ersa_pdf_path)
        
        # 2. Calculate validity period (90 days from now)
        validity_start = datetime.now()
        validity_end = validity_start + timedelta(days=90)
        
        # 3. Generate individual airport files
        for icao, data in airport_data.items():
            self.generate_airport_file(icao, data, validity_start, validity_end)
        
        # 4. Update index file
        self.update_airport_index(airport_data.keys(), validity_start, validity_end)
        
        # 5. Create backup of previous version
        self.create_backup()
```

### **Required Data Fields**

#### **Runways**
- `identifier`: "07/25", "16L/34R"
- `length`: in meters
- `width`: in meters  
- `surface`: "Asphalt", "Concrete", "Grass"
- `lighting`: Array of lighting types ["HIRL", "PAPI", "RCLL"]
- `status`: "OPERATIONAL", "CLOSED", "MAINTENANCE"

#### **NAVAIDs**
- `identifier`: "SY VOR/DME", "ILS 07"
- `frequency`: "113.7", "109.5"
- `type`: "VOR/DME", "ILS/DME", "NDB"
- `runway`: Associated runway "07/25"
- `status`: "OPERATIONAL", "U/S", "MAINTENANCE"

#### **Lighting**
- `runway`: Array of runway lighting ["HIRL", "PAPI", "RCLL"]
- `taxiway`: Array of taxiway lighting ["HIAL"]
- `status`: "OPERATIONAL", "U/S", "MAINTENANCE"

#### **Firefighting**
- `category`: "CAT 9", "CAT 7"
- `operationalHours`: "H24", "SR-SS", "SR-SS+30"
- `status`: "OPERATIONAL", "U/S"

## 🎯 **Parser Requirements**

### **Input Processing**
- Parse ERSA PDF files
- Extract data for hundreds of Australian airports
- Handle varying amounts of information per airport
- Validate data completeness and accuracy

### **Output Generation**
- Generate individual JSON file per airport
- Include comprehensive metadata
- Ensure consistent data structure
- Validate JSON format and schema

### **Error Handling**
- Handle missing or incomplete data gracefully
- Provide clear error messages for parsing failures
- Log parsing issues for debugging
- Continue processing other airports if one fails

### **Data Validation**
- Validate ICAO codes are correct
- Ensure required fields are present
- Check data types and formats
- Verify coordinate accuracy

## 🔧 **Technical Requirements**

### **File Naming Convention**
- **Use simple filenames**: `YSSY.json` (NOT `YSSY_12JUN2025.json`)
- **Consistent format**: All uppercase ICAO codes
- **No dates in filenames**: Validity dates go inside JSON metadata

### **Atomic Updates**
- Generate all files before replacing existing ones
- Use temporary files during generation
- Ensure atomic file replacement
- Create backups before updates

### **Backup Strategy**
```
assets/ersa_data/metadata/backup/
  2024-01-15/
    YSSY.json
    YPPH.json
    ...
  2024-04-15/
    YSSY.json
    YPPH.json
    ...
```

### **Index File Structure**
```json
{
  "lastUpdate": "2024-01-15T00:00:00Z",
  "nextUpdate": "2024-04-15T00:00:00Z",
  "airports": {
    "YSSY": {
      "lastUpdated": "2024-01-15T00:00:00Z",
      "validUntil": "2024-04-15T00:00:00Z",
      "status": "current"
    }
  }
}
```

## 🚀 **Integration with Briefing Buddy**

### **App Integration Points**
- Files will be read by `AirportCacheManager`
- Data will populate `AirportInfrastructure` models
- Used by `AirportSystemAnalyzer` for NOTAM impact analysis
- Integrated with existing airport database services

### **Performance Requirements**
- Individual files for selective loading
- Efficient caching support
- Memory-optimized for mobile devices
- Fast startup with embedded data

### **Update Frequency**
- **Primary**: Every 90 days with new ERSA
- **Emergency**: Individual airport updates for corrections
- **Grace period**: 7-day extension if new ERSA delayed

## 📊 **Data Sources to Extract**

### **From ERSA PDF**
- **Runway information**: Length, width, surface, lighting
- **NAVAID details**: Frequencies, types, runway associations
- **Lighting systems**: Runway and taxiway lighting
- **Firefighting services**: Categories and operational hours
- **Operational hours**: When facilities are available
- **Restrictions**: Weight limits, operational limitations

### **Example ERSA Sections to Parse**
```
RUNWAY 07/25
Length: 11,300ft (3,444m)
Width: 148ft (45m)
Surface: Asphalt
Lighting: HIRL, PAPI, RCLL

NAVAIDS
SY VOR/DME 113.7
ILS 07 109.5

FIRE FIGHTING
Category: CAT 9
Hours: H24
```

## 🧪 **Testing Requirements**

### **Parser Testing**
- Test with sample ERSA PDFs
- Validate output JSON structure
- Test error handling scenarios
- Performance testing with large datasets

### **Integration Testing**
- Test file generation process
- Validate metadata accuracy
- Test backup and rollback procedures
- Verify atomic update process

### **Data Quality Testing**
- Cross-reference with known airport data
- Validate coordinate accuracy
- Check for data completeness
- Test with edge cases (missing data, etc.)

## 📝 **Documentation Requirements**

### **Parser Documentation**
- Installation and setup instructions
- Usage examples and command-line options
- Error handling and troubleshooting
- Performance optimization tips

### **Output Documentation**
- JSON schema specification
- Field descriptions and data types
- Update process documentation
- Integration guidelines

### **Maintenance Documentation**
- Update procedures and scripts
- Backup and recovery procedures
- Monitoring and alerting setup
- Troubleshooting guide

## 🎯 **Success Criteria**

### **Functional Requirements**
- ✅ Parse ERSA PDF files accurately
- ✅ Generate individual JSON files per airport
- ✅ Include comprehensive metadata
- ✅ Support 90-day update cycle
- ✅ Handle hundreds of airports efficiently

### **Quality Requirements**
- ✅ 99%+ data accuracy
- ✅ Complete error handling
- ✅ Atomic update process
- ✅ Rollback capability
- ✅ Performance optimization

### **Integration Requirements**
- ✅ Compatible with Briefing Buddy architecture
- ✅ Support existing airport models
- ✅ Efficient caching integration
- ✅ Transparent update process

## 🔗 **Related Documentation**

- [Briefing Buddy PRD](docs/prd.md)
- [Airport Infrastructure Models](lib/models/airport_infrastructure.dart)
- [Airport Cache Manager](lib/services/airport_cache_manager.dart)
- [Australian Airport Database](lib/data/australian_airport_database.dart)

---

**Note**: This parser will be a critical component of Briefing Buddy's airport infrastructure analysis system. The output format and update process are designed to integrate seamlessly with the existing Flutter app architecture while providing reliable, up-to-date airport data for pilots. 