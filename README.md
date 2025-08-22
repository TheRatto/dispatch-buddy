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

You are working on a **Flutter app** called **Dispatch Buddy**. The goal of the app is to assist pilots during preflight planning by parsing flight plan documents (e.g., ForeFlight PDFs), retrieving weather and NOTAMs, and providing a summarised, visually clear operational briefing.

## 🎯 Objective

Create a clean, intuitive Flutter app that:
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

- Use placeholder AI summarisation for now
- Generate briefing text, holding fuel recommendations, arrival/departure expectations, and operational flags
- All parsing and analysis must work offline if possible

## 🔧 Tech Notes

- App built in **Flutter/Dart**
- Uses on-device file parsing, placeholder AI summarisation, and local storage
- External APIs: FAA NOTAM/METAR (JSON), AviationWeather.gov, optional NAIPS (XML)
- Include "Save Briefing" feature for offline recall

## 📄 Reference Docs (linked in /docs/)

### Product & Design
- **PRD.md** – Product requirements and goals
- **screens.md** – UI structure and screen specs
- **integrations.md** – Data pipeline and API access plan

### Development & Architecture
- **refactoring_roadmap.md** – Strategic refactoring plan and architectural improvements
- **current_sprint_tasks.md** – Current sprint tasks and priorities
- **development_guidelines.md** – Coding standards, patterns, and best practices

### Technical Documentation
- **decodes/** – Weather decoding guides and reference materials
  - **metar_decode_guide.md** – METAR decoding reference
  - **TAF BOM** – Bureau of Meteorology TAF format
  - **TAF FAA** – FAA TAF format

## 🚀 Getting Started

### For New Developers
1. Read `docs/development_guidelines.md` for coding standards
2. Check `docs/current_sprint_tasks.md` for current priorities
3. Review `docs/refactoring_roadmap.md` for architectural context

### For AI Assistance
- Follow patterns in `docs/development_guidelines.md`
- Reference `docs/refactoring_roadmap.md` for architectural decisions
- Use `docs/current_sprint_tasks.md` to understand current priorities

## 🔄 Current Development Status

- **Phase**: Architectural Refactoring
- **Focus**: Service extraction and UI component separation
- **Priority**: Performance optimization and code maintainability
- **Next Sprint**: TafDisplayService extraction and widget separation

See `docs/current_sprint_tasks.md` for detailed current tasks and priorities.

## 🚀 Development Workflow & AI Collaboration

### Daily Development Routine
- **Morning Planning (9:00 AM)**: Review yesterday's progress, plan today's tasks
- **Development Sessions**: 2-3 hour focused coding blocks with breaks
- **End-of-Day Review (3:00 PM)**: Document accomplishments, plan tomorrow

### AI Collaboration Templates
- **`docs/development_workflow_template.md`** - Comprehensive development planning
- **`docs/daily_development_log.md`** - Daily progress tracking and AI context
- **`docs/ai_collaboration_guidelines.md`** - How to work effectively with AI
- **`docs/quick_start_template.md`** - Copy-paste templates for daily use

### Best Practices for AI Sessions
1. **Start with context**: What file/feature you're working on
2. **Be specific**: Describe the problem, not just "help me"
3. **Show your code**: Paste relevant code snippets
4. **Ask for explanations**: Understand why approaches work
5. **Use templates**: Follow established workflow patterns

### Quick Start for AI Sessions
```
I'm working on: [File/Feature Name]
Current sprint goal: [What you're trying to achieve this week]
Today's priority: [What you want to accomplish in this session]
Time available: [How much time you have to work on this]
```
