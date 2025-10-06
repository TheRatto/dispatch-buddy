# Briefing Buddy – Data & Integration Plan

## Overview
Briefing Buddy aims to operate entirely on-device where possible, with cloud or API integrations as fallback or enhancement layers.

## Data Input
### ForeFlight / NAIPS PDF
- User uploads PDF of flight plan or NOTAM/weather pack
- Parsed using on-device PDF reader
- Regex and semantic patterns extract:
  - Route
  - ETD/FL
  - Alternates
  - Weather/NOTAM blocks

## Weather & NOTAM Sources
### Primary: AviationWeather.gov API
- Free, open access (JSON)
- Endpoint: `https://aviationweather.gov/cgi-bin/data/api.php`
- Usage: METAR and TAF data by ICAO

### Secondary: FAA NOTAM API
- Free, open access (JSON)
- Endpoint: `https://notamsapi.faa.gov/notamapi/v1/notams`
- Usage: ICAO lookup (e.g., `?icao=YSSY`)

### ✅ NAIPS Integration (Airservices Australia) - IMPLEMENTED
- ✅ **Authentication**: User-provided NAIPS credentials with secure storage
- ✅ **Session Management**: Multi-step browser simulation with cookie handling
- ✅ **Data Retrieval**: Location briefing requests returning HTML with structured data
- ✅ **Data Parsing**: TAF, METAR (including SPECI), ATIS, and NOTAM extraction
- ✅ **Integration**: Settings toggle to prioritize NAIPS over free APIs
- ✅ **Error Handling**: Comprehensive fallback to existing APIs
- **Data Format**: HTML response with embedded text in `<pre>` tags
- **Geographic Scope**: Primarily Australian domestic, with international capability

## AI & LLM Integration
### Primary: On-Device Placeholder
- Basic keyword and pattern matching
- Generates simple summaries from raw text
- No external API calls needed for now

### Future: Cloud-Based LLM (e.g., OpenAI/Gemini)
- Send concatenated raw text to a cloud function
- Use advanced LLM to parse, decode, and summarise
- Requires API keys and billing setup

## ATIS (Automatic Terminal Information Service)
### Status: Not Currently Available
- There is no simple, free, public REST API for ATIS data.
- The FAA provides Digital ATIS (D-ATIS) via its **System Wide Information Management (SWIM)** program, but this requires a formal approval process and a more complex integration than the other APIs.
- For now, ATIS retrieval is out of scope for the MVP.

## Storage
- Data saved locally (SQLite or file-based)
- Save briefing feature stores JSON + rendered summary
- Option to re-render or refresh when re-opening saved brief

## Parsing Pipeline
- Step 1: Upload → read and clean text
- Step 2: Regex extract known fields (ICAO, NOTAM IDs, Q/A/B/E blocks)
- Step 3: Feed chunks to placeholder AI with templated prompts
- Step 4: Render summaries + decoded views

## Future Integrations
- Apple MapKit overlay for airport diagrams (TBC)
- Cloud sync with iCloud or secure sync engine (optional)
- External APIs for deeper airport/airspace data (e.g. EUROCONTROL)

