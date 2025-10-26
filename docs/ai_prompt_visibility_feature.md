# AI Prompt Visibility Feature

## Overview
Enhanced the AI Test Chat to display the full prompts (including all airport, weather, and NOTAM data) that are sent to Apple Foundation Models. This provides complete transparency for debugging and understanding AI interactions.

## Implementation Date
October 10, 2025

## What Was Added

### 1. **ChatMessage Model Enhancement**
- Added `isPrompt` boolean flag to `ChatMessage` class
- Distinguishes prompt messages from regular user/AI messages
- Allows special rendering for prompt content

### 2. **AIChatProvider Enhancements**

#### New Methods:
- **`_addPromptMessage(String text)`** - Adds a prompt message to chat history
- **`_estimatePromptLength(String prompt)`** - Calculates prompt character count

#### Updated Methods:
All aviation AI methods now generate and display the full prompt before sending to AI:

**`loadFlightDataAndGenerateBriefing()`**:
```dart
// Generate the full prompt that will be sent to the AI
final fullPrompt = AviationPromptTemplate.generateBriefingPrompt(
  flightContext: flightContext,
  weatherData: weatherData,
  notams: notams,
  airports: airports,
  briefingStyle: BriefingStyle.comprehensive.name,
);

// Display the full prompt in chat
_addSystemMessage('📝 Full Prompt Generated (${_estimatePromptLength(fullPrompt)} chars)');
_addPromptMessage(fullPrompt);
```

**`generateQuickAviationResponse()`**:
- Shows prompt before quick aviation queries
- Includes relevant weather and NOTAM data

**`testBriefingStyles()`**:
- Shows prompt for each briefing style tested
- Allows comparison of prompts across styles

### 3. **UI Enhancements in AITestChatScreen**

#### New Widget: `_buildPromptBubble()`
A collapsible, styled prompt display with:

- **🎨 Amber Theme** - Distinctive color scheme (amber background, borders)
- **📋 ExpansionTile** - Collapsible to save screen space
- **💻 Monospace Display** - Code-like formatting with dark terminal theme
- **📊 Character Count** - Shows prompt size in subtitle
- **✂️ Selectable Text** - Can copy prompt text for analysis
- **📱 Horizontal Scroll** - Handles long lines without wrapping

```dart
Widget _buildPromptBubble(ChatMessage message) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.amber.shade50,
      border: Border.all(color: Colors.amber.shade300, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: ExpansionTile(
      leading: Icon(Icons.code, color: Colors.amber.shade700),
      title: Text('Full Prompt Sent to AI'),
      subtitle: Text('Tap to expand/collapse (${message.text.length} characters)'),
      children: [
        // Dark terminal-style code display
        Container(
          color: Colors.grey.shade900,
          child: SelectableText(
            message.text,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Colors.greenAccent,
            ),
          ),
        ),
      ],
    ),
  );
}
```

## Features

### 📝 **What You Can See:**
1. **Complete System Prompt** - Aviation AI assistant instructions
2. **Flight Context** - Departure, destination, times, aircraft type
3. **Weather Data** - Full METAR, TAF, ATIS reports
4. **NOTAM Data** - Complete NOTAM text and groupings
5. **Airport Information** - Facilities, runways, coordinates
6. **Briefing Style Instructions** - Specific formatting requirements
7. **Output Format** - Expected response structure

### 🔍 **Debugging Benefits:**
- Verify correct data is being sent to AI
- Understand why AI generates specific responses
- Compare prompts across different briefing styles
- Check data formatting and structure
- Identify missing or incorrect data
- Optimize prompt engineering

### 🎯 **Use Cases:**
1. **Development** - Debug prompt generation logic
2. **Testing** - Verify data integration works correctly
3. **Optimization** - Improve prompt structure for better AI responses
4. **Training** - Understand how to structure aviation prompts
5. **Documentation** - Create examples of effective prompts

## Visual Design

### Prompt Message Appearance:
```
┌─────────────────────────────────────────────┐
│ 📝 [Code Icon]  Full Prompt Sent to AI     │
│    Tap to expand/collapse (12,543 chars)    │
│                                              │
│ [Expanded State - Dark Terminal Theme]      │
│ ┌─────────────────────────────────────────┐ │
│ │ You are an AI assistant specialized...  │ │
│ │                                          │ │
│ │ FLIGHT CONTEXT:                          │ │
│ │ • Departure: YPPH (Perth)               │ │
│ │ • Destination: YSSY (Sydney)            │ │
│ │ • Weather: METAR YPPH 100800Z...        │ │
│ │ • NOTAMs: A0123/24...                   │ │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

### Message Flow:
```
1. 📊 System: Flight data loaded (Weather: 5, NOTAMs: 12)
2. 📝 System: Full Prompt Generated (12,543 chars)
3. 🔶 PROMPT: [Collapsible amber box with full prompt]
4. 🤖 System: Sending to Foundation Models...
5. 💬 AI: [Generated aviation briefing response]
```

## Testing the Feature

### Option 1: Load Flight Data & Generate Briefing
1. Tap **🛩️ Flight Data** button in app bar
2. See flight data summary
3. See **📝 Full Prompt Generated** message
4. Tap amber **Full Prompt Sent to AI** box to expand
5. Review complete prompt with all data
6. See AI response

### Option 2: Quick Aviation Query
1. Tap **💡 Test Prompts** button
2. Select a green aviation prompt
3. See **📝 Full Prompt** message
4. Expand to see query + context data
5. See AI response

### Option 3: Test All Briefing Styles
1. Tap **🎨 Style Testing** button
2. See prompt for each style (Quick, Standard, Comprehensive, etc.)
3. Compare prompts across styles
4. See AI responses for each style

## Technical Details

### Prompt Character Counts:
- **Quick Query**: ~2,000-5,000 chars
- **Standard Briefing**: ~8,000-15,000 chars
- **Comprehensive Briefing**: ~15,000-30,000 chars
- Varies based on number of weather reports and NOTAMs

### Data Included in Prompts:
- System prompt with AI instructions
- Flight context (6-8 fields)
- Weather data (METAR, TAF, ATIS) - varies by stations
- NOTAMs (raw text + groupings) - varies by route
- Airport data (facilities, runways) - varies by airports
- Briefing style instructions
- Output format specifications

## Benefits

### For Development:
✅ Transparent AI interactions  
✅ Easy debugging of data flow  
✅ Verify correct prompt generation  
✅ Identify data quality issues  

### For Testing:
✅ Validate data integration  
✅ Compare prompt variations  
✅ Test different scenarios  
✅ Document expected behavior  

### For Optimization:
✅ Improve prompt structure  
✅ Refine data formatting  
✅ Optimize prompt length  
✅ Enhance AI responses  

## Future Enhancements

### Potential Additions:
1. **Prompt Export** - Save prompts to file for analysis
2. **Prompt Comparison** - Side-by-side comparison of prompts
3. **Token Estimation** - Estimate token count for API costs
4. **Prompt Templates** - Save/load custom prompt templates
5. **Syntax Highlighting** - Highlight different prompt sections
6. **Search in Prompt** - Search for specific data in prompt
7. **Prompt History** - View previous prompts
8. **Prompt Analytics** - Track prompt effectiveness

## Related Files

### Modified Files:
- `lib/providers/ai_chat_provider.dart` - Prompt generation and display logic
- `lib/screens/ai_test_chat_screen.dart` - Prompt bubble UI component

### Dependencies:
- `lib/services/aviation_prompt_template.dart` - Generates prompts
- `lib/services/ai_briefing_service.dart` - Uses prompts for AI
- `lib/models/flight_context.dart` - Flight context data

## Notes

- Prompts are displayed **before** being sent to Foundation Models
- Prompts are **selectable** for copying and external analysis
- Prompts **collapse by default** to avoid cluttering chat
- Character count helps identify **unexpectedly large prompts**
- Dark terminal theme provides **code-like readability**
- Works with **all aviation AI features** (briefings, queries, style tests)

## Conclusion

This feature provides complete transparency into what data is being sent to Apple Foundation Models, making it invaluable for development, testing, and optimization of the aviation AI system. The collapsible design keeps the chat clean while providing easy access to detailed prompt information when needed.

