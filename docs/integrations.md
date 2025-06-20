# Dispatch Buddy – Data & Integration Plan

## Overview
Dispatch Buddy aims to operate entirely on-device where possible, with optional cloud or API integrations as fallback or enhancement layers.

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
### Primary: FAA NOTAM/METAR API
- Free, open access (JSON)
- Endpoint: `https://notamsapi.faa.gov/notamapi/v1/notams`
- Usage: ICAO lookup (e.g., `?icao=YSSY`)

### Optional: NAIPS XML Post (Airservices Australia)
- Requires approval + potential licensing fee
- XML SOAP-style interface
- Sample endpoint: `https://www.airservicesaustralia.com/NAIPS/naips-xml-data.asp`
- Can retrieve TAFs, METARs, NOTAMs by ICAO

## AI & LLM Integration
### Summarisation & Risk Analysis
- Performed on-device
- Prompt templates format decoded data into:
  - Operational summaries
  - Fuel recommendations
  - Runway/navaid usability

### Technology Options
- Use Apple Intelligence if available (iOS 18+)
- Fallback: On-device open model (e.g. Mistral, Gemma via Ollama)
- All LLM parsing must occur on-device (no internet requirement)

## Storage
- Data saved locally (SQLite or file-based)
- Save briefing feature stores JSON + rendered summary
- Option to re-render or refresh when re-opening saved brief

## Parsing Pipeline
- Step 1: Upload → read and clean text
- Step 2: Regex extract known fields (ICAO, NOTAM IDs, Q/A/B/E blocks)
- Step 3: Feed chunks to LLM with templated prompts
- Step 4: Render summaries + decoded views

## Future Integrations
- Apple MapKit overlay for airport diagrams (TBC)
- Cloud sync with iCloud or secure sync engine (optional)
- External APIs for deeper airport/airspace data (e.g. EUROCONTROL)

