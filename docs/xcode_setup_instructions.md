# Xcode 26 Setup Instructions for Apple Foundation Models

## **📋 Required Steps in Xcode**

Since you already have **Xcode 26 installed**, here are the specific steps to enable Foundation Models in your Flutter project:

### **🚀 Step 1: Update iOS Deployment Target**

1. **Open your project in Xcode 26**:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Select "Runner" project** in the left sidebar
   
3. **Go to Build Settings tab**
   - Search for "iOS Deployment Target"
   - Change from current version to **"26.0"**

### **🏗️ Step 2: Configure Project Settings**

1. **In Runner project settings**:
   - **Deployment Target**: iOS 26.0
   - **Swift Language Version**: 5.0 (default)
   - **Build System**: New Build System (default)

### **📱 Step 3: Enable Foundation Models Framework**

1. **In Runner.xcodeproj**:
   - Select "Runner" target
   - Go to **"General" tab**
   - Scroll to **"Frameworks, Libraries, and Embedded Content"**
   - Click **"+"** button
   - Search for **"FoundationModels"**
   - Add **FoundationModels.framework**

### **⚙️ Step 4: Update Info.plist**

Add Apple Intelligence capability requirements to `ios/Runner/Info.plist`:

```xml
<key>FoundationsModels</key>
<true/>
```

### **🔧 Step 5: Clean and Build**

1. **Clean project**:
   ```bash
   flutter clean
   flutter pub get
   cd ios && pod install && cd ..
   ```

2. **Build for device**:
   ```bash
   flutter build ios --device
   ```

### **📱 Step 6: Device Requirements**

#### **Hardware Requirements**
- iPhone with Apple Intelligence support
- iOS 26.0+ installed
- Apple Intelligence enabled in device Settings

#### **Enable Apple Intelligence**
On your iOS device:
1. **Settings** → **General** → **Software Update** (ensure iOS 26+)
2. **Settings** → **Apple Intelligence** → **Enable**
3. **Wait for model download** (may take time)

### **🧪 Step 7: Test Foundation Models**

Run your Briefing Buddy app and check debug output for:

```
DEBUG: AIBriefingService: iOS Version: 26.x
DEBUG: AIBriefingService: Apple Intelligence available: true
DEBUG: AIBriefingService: Foundation Models framework ready
```

### **🔧 Troubleshooting**

#### **Common Issues**

1. **"Foundation Models not available"**
   - Check iOS version is 26.0+
   - Verify Apple Intelligence is enabled
   - Ensure you're testing on physical device (not simulator)

2. **"Xcode version incompatible"**
   - Make sure you're using Xcode 26+
   - Check iOS SDK version in Xcode Preferences

3. **"Apple Intelligence disabled"**
   - Enable in device Settings → Apple Intelligence
   - Wait for on-device model download to complete

#### **Verification**

Run this test in your Flutter app:

```dart
// Test availability
final availability = await FoundationModelsFramework.instance.checkAvailability();
print('Available: ${availability.isAvailable}');
print('iOS Version: ${availability.osVersion}');

// Test brief session
if (availability.isAvailable) {
  final session = FoundationModelsFramework.instance.createSession();
  final response = await session.respond(prompt: 'Generate test aviation briefing');
  print('Response: ${response.content}');
}
```

### **🎯 Success Indicators**

✅ **Xcode 26** showing FoundationModels.framework  
✅ **iOS Deployment Target**: 26.0  
✅ **Physical device** with iOS 26+  
✅ **Apple Intelligence enabled** and downloaded  
✅ **Debug logs** showing Foundation Models availability  

Your aviation briefing app will then use real Apple Intelligence for generating professional flight briefings! 🚀

---

**Note**: The foundation_models_framework Flutter package handles all the complex Swift bridge work for you, making this much simpler than manual implementation.
