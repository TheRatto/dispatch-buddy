# Briefing Buddy: Requirements and Best Practices

## Requirements Summary

- **FAA EFB Guidance:** Weather and NOTAM apps are classified as Type B EFB applications (minor-failure-hazard)\(11\). FAA AC 120-76E explicitly lists "Weather and aeronautical information" and "Notices to Air Missions (NOTAM)" as approved Type B items\(68\)\(11\). Type B apps "have no certification requirements for installation under aircraft type design"\(5\). In practice, Briefing Buddy (weather/NOTAM briefing on a tablet) would not need FAA DO-178 certification to be deployed as an EFB tool.

- **ICAO/EASA/CASA Alignment:** ICAO Annex 6/15 require dispatchers and pilots to use up-to-date weather/NOTAM data, but do not mandate specific software approval. EASA and other regulators echo FAA’s approach. For example, EASA’s guidance for complex ops (AMC SPO.GEN.131) treats *in-flight weather apps* as non-safety-critical strategic aids\(23\). CASA’s AC 91-17 follows the same Type A/B framework. In all cases, portable EFB apps are approved via the operator’s procedures (e.g. OpsSpec A061 in US, Part-SPO approval in EU, AOC expositions in Australia) rather than aircraft STC. No RTCA/ED-12C (DO-178C) approval is *required* unless the software falls under Type C (functions affecting flight control or safety-critical avionics)\(24\)\(5\).

- **Key Standards:** RTCA DO-178C (EUROCAE ED-12C) is the accepted standard for certifying airborne software\(33\). In practice, Briefing Buddy is a dispatch/planning aid, not a certified avionics element, so DO-178C is *guidance* rather than a legal mandate. Other standards (RTCA DO-278A for ATM/ground systems, DO-200A/ED-76 for aeronautical data quality) can inform design of NOTAM and chart handling. EASA's AMC explicitly references ED-12C/DO-178C as an acceptable means of compliance for software\(33\), so its objectives should guide development to ensure reliability and traceability. Type C functions (active flight control, FMS-level nav) are out of scope; our app only provides advisory data.

## Implementation Guidance (Best Practices)

- **Dev Process (DO-178C/278A Objectives):** Follow rigorous software lifecycle processes even if not certifying. Plan requirements, design and code reviews, and verification to DO-178C standards\(33\). For example, treat weather/NOTAM modules at least as Software Level D (minor failure condition) and apply DO-178C objectives: requirements traceability, architecture design, structured coding standards, and systematic verification. Maintain a Configuration Management system and archive *change logs* (FAA recommends retaining EFB program changes for 3 months)\(5\)\(45\). Use tool qualification (DO-330) if automated tools generate critical outputs (e.g. parser generators for NOTAM).

- **Data Sources and Updates:** Only use certified/trusted data feeds. EASA stresses that meteorological information “should be based on data from certified meteorological service providers” and be consistent with dispatch center data\(23\). Always display data timestamps and source ID. AC 120-76E notes that Type B weather apps must clearly mark information age\(68\). Include versioning or timestamp on every aeronautical database (chart, NAV data, NOTAM list) and prompt users to update. Log update histories. If using live links (ADS-B weather, internet briefings), handle loss of connectivity gracefully (cache last data, warn user if outdated).

- **UI/UX Design:** Follow human factors guidelines for EFBs: clear layout, color consistency and unit labeling. EASA encourages colored graphical weather when practicable\(23\) and warns that IFW displays are for “strategic decisions” only. Label advisories (e.g. “*Advisory* – confirm with official source”) and emphasize that the app doesn’t replace certified systems. For NOTAMs, allow filtering and full-text display of ICAO-coded messages, and flag critical NOTAM categories. Enforce input validation (e.g. airport ICAO code formats, route logic) to prevent garbage data.

- **Error Handling & Reliability:** The app should fail “safe.” For any component (weather fetcher, NOTAM decoder, performance calculator) implement input validation and error traps. On failure, notify the user but allow other functions to run. For example, if weather service is down, the NOTAM module should still work independently. Include redundant checks (e.g. verify NOTAM decode against known ICAO formats). Implement automated self-tests at startup (e.g. checksum of database files). Document “fallback procedures” (how the operator can obtain needed data by alternate means).

- **Documentation & Training:** Even without formal certs, maintain comprehensive docs. Write concise requirement specifications (linking to regulatory needs like 14 CFR 91.103/92.3), design descriptions, and verification plans. For each safety-related feature (NOTAM logic, weather overlays, weight/balance), document assumptions and mitigations. Provide a user manual and quick-reference checklist aligned with recognized briefing checklists (see FAA AC 91-92\(45\)). Clearly note any limitations (e.g. offline data hours, unsupported flight phases). Train operators/pilots on correct use.

## Validation & Testing Checklist

- **Requirements Coverage:** Map each app feature to regulatory requirements (weather briefing, NOTAM review, weight & balance) and verify test cases exist. Include 14 CFR/CAO references (e.g. FAR 91.103 and 121.111 require using current wx and NOTAMs) in test plans.

- **Functional Tests:**

  - *NOTAM Handling:* Test with sample NOTAM bulletin files. Verify parsing accuracy (ICAO 5-letter codes, times, coordinates) and correct display. Include tests for expired, superseded, or TFR NOTAMs.
  - *Weather Data:* Test ingestion of METARs, TAFs, SIGMETs, PIREPs. Check graphical overlay if any. Include edge cases (e.g. missing data, extreme values).
  - *Calculations:* If app includes any perf calculations (fuel, winds, fuel cost index), validate against known formulas or datasets. Use unit tests to check boundary conditions.

- **Integration Tests:** Simulate a full dispatch scenario end-to-end. For a given flight plan, ensure all modules coordinate. Test with varying network conditions.

- **Data Currency & Versioning:** Confirm that all data sources include timestamps. Validate that the app flags or refuses stale data.

- **Fault Injection:** Deliberately introduce errors (malformed data, service timeouts) to test stability. For example, simulate GPS module failing or airplane being outside coverage.

- **Performance & Resource:** Verify the app performs well on target devices. Test under low-battery and poor connectivity conditions.

- **Compliance & Audit:** Keep test records and version logs. Include a review of third-party libraries and ensure they are up-to-date. Document how each regulatory note has been addressed.

## Development Comments & Prompts (Code Annotations)

```ts
// NOTE: This module handles **safety-critical data** (weather/NOTAM). Follow DO-178C objectives (traceability, code reviews, unit testing) even if not formally certifying.

// TODO: Tag NOTAM output with timestamp. Display “Ages-of-Data” per FAA guidance.

// FIXME: Ensure weight/balance calculation uses correct wind data (safety-critical). Cross-verify with reference solver.

// PROMPT: Before merging, double-check that all units (feet, knots, lb/kg) are correct – per human factors guidance on consistency.

// REMARK: EFB Type B app – if we ever add tactical nav info (own-ship position), reevaluate DO-178C compliance needs (Type C). Currently, this is advisory only.

// CHECK: Data validity checks in parseWeather(): missing fields should throw errors and alert user, not default to “zero” (which could mislead).

// NOTE: This software **is not FAA-certified**. Include disclaimers in UI (“For flight planning only. Verify all data with official sources.”).

// COMMENT: Each release must update the release notes with data currency. Maintain change log per AC guidelines.

// ALERT: Review human factors (font size, color) in mapOverlay(). EASA advises clear, intuitive display for safety-related info.
```

