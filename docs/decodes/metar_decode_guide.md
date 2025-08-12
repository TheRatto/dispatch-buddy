# METAR Decode Guide for Dispatch Buddy

This document consolidates key reference material for decoding METAR and SPECI weather reports. It includes official abbreviations, definitions, structure breakdowns, and decoder keys. This guide supports automated and manual decoding within the Dispatch Buddy application.

---

## 1. METAR Abbreviations and Acronyms

| Code  | Meaning                                     |
| ----- | ------------------------------------------- |
| +     | Heavy intensity                             |
| -     | Light intensity                             |
| AUTO  | Fully automated report                      |
| AO1   | Automated station w/o precip discriminator  |
| AO2   | Automated station with precip discriminator |
| BKN   | Broken cloud cover (5-7 oktas)              |
| CLR   | Sky clear                                   |
| CIG   | Ceiling                                     |
| FEW   | Few clouds (1-2 oktas)                      |
| FG    | Fog                                         |
| FM    | From (used in TAF)                          |
| G     | Gust indicator                              |
| KT    | Knots (wind speed)                          |
| M     | Minus (temperature)                         |
| METAR | Routine aviation weather report             |
| OVC   | Overcast (8 oktas)                          |
| R     | Runway prefix (e.g. R16)                    |
| RA    | Rain                                        |
| RMK   | Remarks section                             |
| SCT   | Scattered clouds (3-4 oktas)                |
| SLP   | Sea-level pressure                          |
| SM    | Statute miles (visibility)                  |
| SN    | Snow                                        |
| SPECI | Special report due to changes               |
| SKC   | Sky clear (manual reports)                  |
| TS    | Thunderstorm                                |
| VV    | Vertical visibility                         |
| Z     | Zulu time (UTC)                             |

---

## 2. METAR Format Breakdown

Example:

```
METAR YMML 221945Z 14003KT 0600 R16/0600D R27/0550N FG ////// 08/08 Q1026 RMK RF00.0/001.8
```

| Section      | Meaning                                          |
| ------------ | ------------------------------------------------ |
| METAR        | Type of report                                   |
| YMML         | Station (ICAO code)                              |
| 221945Z      | Date/time in UTC                                 |
| 14003KT      | Wind direction/speed (140 deg at 3 kt)           |
| 0600         | Visibility in metres                             |
| R16/0600D    | RVR on RWY 16, 600 m, downward trend             |
| FG           | Weather: fog                                     |
| //////       | Cloud not observed due to obscuration            |
| 08/08        | Temp/dewpoint (°C)                               |
| Q1026        | QNH pressure (hPa)                               |
| RMK          | Remarks begin                                    |
| RF00.0/001.8 | Rainfall: none in 10min / 1.8mm since 0900 local |

---

## 3. Cloud Codes

| Code | Oktas | Description                    |
| ---- | ----- | ------------------------------ |
| FEW  | 1–2   | Few                            |
| SCT  | 3–4   | Scattered                      |
| BKN  | 5–7   | Broken                         |
| OVC  | 8     | Overcast                       |
| NSC  | -     | Nil significant cloud          |
| SKC  | -     | Sky clear (no cloud observed) |
| NCD  | -     | Nil cloud detected (auto only) |

---

## 4. Weather Phenomena

| Code | Description           |
| ---- | --------------------- |
| BR   | Mist                  |
| DZ   | Drizzle               |
| FG   | Fog                   |
| HZ   | Haze                  |
| RA   | Rain                  |
| SN   | Snow                  |
| SQ   | Squall                |
| TS   | Thunderstorm          |
| UP   | Unknown precipitation |
| VC   | In the vicinity       |

**Intensity prefix**: `-` = light, no symbol = moderate, `+` = heavy.

---

## 5. Runway Visual Range (RVR)

Format: `RYY/XXXXFT`

- YY: Runway number
- XXXX: Distance in feet
- Prefix `P` for greater than, `M` for less than
- e.g. `R16/P6000FT` = RVR for RWY 16 is more than 6000 ft

---

## 6. SPECI Trigger Criteria

- Visibility falls below 5,000 m or alternate minima
- BKN/OVC below 1500 ft or alternate minima
- Weather begins/ends/changes intensity (e.g. TS, FG, +RA)
- Wind shifts by ≥30° with speed ≥20 KT
- Temp changes by ≥5°C
- QNH changes by ≥2 hPa

---

## 7. Decoding Remarks (RMK) Section

| Code            | Meaning                                  |
| --------------- | ---------------------------------------- |
| AO2             | Auto station w/ precip discriminator     |
| PK WND 20032/25 | Peak wind: 200° at 32 KT at 25 past hour |
| WSHFT 1715      | Wind shift at 1715Z                      |
| VIS 3/4V1 1/2   | Variable visibility from ¾ to 1½ miles   |
| RAB07           | Rain began at 07 past hour               |
| CIG 013V017     | Ceiling variable between 1300–1700 ft    |
| PRESFR          | Pressure falling rapidly                 |
| SLP125          | Sea-level pressure: 1012.5 hPa           |
| P0003           | 0.03 in of rain since last METAR         |
| 60009           | 6-hr precip total: 0.09 in               |
| T00640036       | Temp/dewpoint: 6.4°C / 3.6°C             |
| 10066           | 6-hr max temp: 6.6°C                     |
| 21012           | 6-hr min temp: 1.2°C                     |

---

## 8. References

- Bureau of Meteorology (AU): [www.bom.gov.au](http://www.bom.gov.au)
- NOAA/NWS/FAA ASOS Guidelines
- Federal Meteorological Handbook No.1

---

This markdown file is intended for integration in Dispatch Buddy’s internal reference system and LLM decoding prompts. Further expansion modules may include TAF codes, risk scoring rubrics, and decoded UI templates.

