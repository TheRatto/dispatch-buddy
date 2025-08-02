# Dispatch Buddy – Product Requirements Document (PRD)

## Overview
**Dispatch Buddy** is a pilot-focused mobile app designed to simplify preflight dispatch briefings. It extracts key operational data from flight plans, NOTAMs, and weather documents, providing a structured summary with visual overlays and risk cues.

## Goals
- Reduce briefing fatigue by summarising critical operational points
- Support long-haul and charter pilots with fast-access insights
- Run on iOS, Android, and Web using Flutter

## Target Users
- Pilots (particularly business jet, charter, and military operators)
- Preflight briefers or flight ops staff

## Platforms
- Flutter app (iOS, Android, Web via single codebase)

## Core Use Cases
1. Upload a flight plan (e.g., ForeFlight PDF)
2. Automatically extract departure/destination/route/ETD/alternates
3. Pull NOTAM and weather data (on-device or via APIs)
4. Analyse, decode, and summarise key operational impacts
5. Display in layered UI: summary → airport → decoded → raw
6. Allow save for offline reference

## Functional Requirements
### Input Methods
- Upload PDF (ForeFlight or NAIPS)
- Paste flight plan text

### Data Sources
- FAA NOTAM/METAR API (initial)
- AviationWeather.gov API
- ✅ NAIPS Integration (Airservices Australia) - IMPLEMENTED
  - User-provided credentials with secure storage
  - Toggle to prioritize NAIPS over free APIs
  - Comprehensive Australian aviation data (TAF, METAR, ATIS, NOTAMs)

### AI & LLM Integration
- Placeholder AI summarisation of operational impacts
- Highlights: weather risk, navaid/runway status, holding fuel recommendations

### Visualisation
- Airport detail views with symbol + color code overlays
- Static airport diagrams with affected areas shown in red/yellow/green

### Navigation Model
- Summary (entire flight)
- Airport Detail (each airport)
- Decoded View
- Raw Text View
- Diagram Overlay View

## Technical Requirements
- App built in Flutter (Dart)
- Runs locally on iOS, Android, and browser
- Local file and data storage for offline access

## MVP Feature Set
- See feature matrix (in separate doc)

## Future Considerations
- Account system for syncing briefings
- Advanced PDF/image parsing (OCR)
- Interactive airport diagrams
- Exporting briefing as PDF/AirDrop
- Enhanced AI integration when needed

## Out of Scope (MVP)
- Fuel planning
- Full map navigation
- Live aircraft tracking

## Success Metrics
- Time saved in preflight review
- Accuracy of summarised briefings
- Positive pilot feedback (clarity, usability)
