# Dispatch Buddy – AI Preflight Briefing Assistant

## 🎨 Design System & Color Palette

- **Primary (Deep Blue):** #1E3A8A
- **Secondary (Sky Blue):** #3B82F6
- **Accent (Orange):** #F97316
- **Success (Emerald):** #10B981
- **Warning (Amber):** #F59E0B
- **Danger (Red):** #EF4444
- **Typography:** SF Pro (system font)
- **Icons:** SF Symbols (Apple)
- **Design Principles:**
  - Clean, modern aviation-inspired UI
  - Layered abstraction: summary → airport → decoded → raw
  - Clear color-coded status and icons for operational clarity
  - Large, touch-friendly controls and readable text

You are working on an iOS app called **Dispatch Buddy**. The goal of the app is to assist pilots during preflight planning by parsing flight plan documents (e.g., ForeFlight PDFs), retrieving weather and NOTAMs, and providing a summarised, visually clear operational briefing.

## 🎯 Objective

Create a clean, intuitive iOS app that:
- Accepts a flight plan PDF as input
- Extracts route and operational data from the document
- Retrieves live NOTAMs and METAR/TAF for involved airports
- Displays a human-readable summary of key operational concerns
- Allows toggling between decoded and raw views
- Provides visual airport diagram overlays to highlight affected runways/taxiways
- Stores the generated briefing locally for offline access

## 🧱 App Structure (MVP)

The app consists of the following 5 main screens:

1. **Input Page** – Accepts PDF or text-based flight plan input
2. **Flight Summary Page** – AI-generated high-level operational overview
3. **Airport Detail Page** – Visual dashboard of per-airport status (Rwy, TWY, Navaids)
4. **Decoded View Page** – Weather and NOTAMs in clean human-readable format
5. **Raw Data View Page** – Verbatim NOTAM/METAR text view

## 🧠 AI Integration

- Use on-device LLM (Apple Intelligence preferred) to summarise NOTAMs and weather.
- Generate briefing text, holding fuel recommendations, arrival/departure expectations, and operational flags.
- All parsing and analysis must work offline if possible.

## 🔧 Tech Notes

- App built in **SwiftUI**
- Uses on-device file parsing, LLM summarisation, and local storage
- External APIs: FAA NOTAM/METAR (JSON), optional NAIPS (XML)
- Include "Save Briefing" feature for offline recall

## 📄 Reference Docs (linked in /docs/)
- PRD.md – Product requirements and goals
- screens.md – UI structure and screen specs
- integrations.md – Data pipeline and API access plan
