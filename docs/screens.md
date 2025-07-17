# Dispatch Buddy – Screen Specifications

## Current Implementation (Hybrid Approach)

### 1. 📥 Flight Plan Input Page
- **Title**: "New Briefing"
- **Sections**:
  - Upload PDF (ForeFlight/NAIPS)
  - Paste text input
  - ETD, FL, route fields (optional backup)
  - Upload NOTAM/weather pack (PDF)
- **Actions**:
  - Button: "Generate Briefing"

### 2. 🧭 Flight Summary Page
- **Title**: "Dispatch Summary"
- **Route**: e.g., "YPPH → YSSY"
- **Cards**:
  - Departure Summary
  - Enroute Summary
  - Arrival Summary
- Each includes:
  - Risk summary (icons, colors)
  - "View Details" button → Airport Page
- Bottom nav: Summary, Airports, Raw, Settings

### 3. 🛫 Airport Status Page (Updated)
- **Title**: "YPPH Airport (YPPH)"
- **Systems list**:
  - Runways
  - Taxiways
  - Instrument Procedures
  - Airport Services
  - Hazards
  - Admin
  - Other
- Each shows:
  - Icon + Label
  - Color-coded status (🟢🟡🔴)
  - Tap to navigate to System-Specific Page
- **No embedded NOTAM details** - clean status overview only

### 4. 🔧 System-Specific Pages (New)
- **Title**: "YPPH - Runway Status" (example)
- **System status summary**:
  - Individual component status (e.g., "Runway 03: Operational")
  - Key operational impacts
  - Human-readable summaries
- **Actions**:
  - "View All NOTAMs" → Raw Data filtered by system
  - "Back to Airport" → Airport Status Page

### 5. 📑 Raw Data Page
- **Title**: "YPPH - Raw Data"
- **Full NOTAM and weather data**
- **Filtering by system** (when navigated from system page)
- **Toggle**: Decoded | Raw

### 6. 🗺 Airport Diagram View
- **Title**: "YMML – Diagram"
- **Visual**: Airport map with overlays
  - Red = closed
  - Yellow = near time impact
  - Green = unaffected
- Tap elements (RWY, TWY, etc.) to see NOTAM summary
- Include legend and optional preview card

## Bottom Navigation (Global)
- Summary
- Airports
- Raw Data
- Settings

## Information Architecture (4-Layer Abstraction)
1. **Summary** (Highest abstraction) - Flight overview with risk indicators
2. **Airport Status** (System overview) - Quick status of all systems
3. **System-Specific Pages** (Middle abstraction) - Operational impacts by system
4. **Raw Data** (Lowest abstraction) - Full NOTAM and weather details

---

## Original Plan (Reference)

### 3. 🛫 Airport Detail Page (Original)
- **Title**: "Melbourne (YMML) – Departure"
- **Systems list**:
  - Runways
  - Navaids
  - Taxiways
  - Lighting
  - Procedures
- Each shows:
  - Icon + Label
  - Color-coded status (🟢🟡🔴)
  - Tap to go to decoded data

### 4. 📑 Decoded Data Page (Original)
- **Title**: "YMML – Weather & NOTAMs"
- **Tabs or sections**:
  - Weather:
    - Wind, cloud, vis, QNH, temp/dew, forecast trends
  - NOTAMs:
    - Title, risk icon, human-readable text
    - Button: "See Full Text"
- **Toggle**: Decoded | Raw

