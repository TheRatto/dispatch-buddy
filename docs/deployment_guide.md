# Briefing Buddy - Deployment Guide

This guide provides step-by-step instructions for deploying Briefing Buddy to both iOS (TestFlight) and Android (APK) platforms.

## Prerequisites

### Required Software
- **Flutter SDK** (latest stable version)
- **Xcode** (for iOS deployment)
- **Android Studio** or **Android Command Line Tools** (for Android deployment)
- **Apple Developer Account** (for iOS TestFlight)
- **Java 17** (for Android builds - Java 24+ causes compatibility issues)

### Environment Setup
```bash
# Verify Flutter installation
flutter doctor

# Set Java 17 for Android builds
export JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home
flutter config --jdk-dir="/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home"
```

## iOS Deployment (TestFlight)

### Step 1: Update Version Number
```bash
# Edit pubspec.yaml
version: 1.0.1+2  # Format: version+build_number
```

### Step 2: Configure App Icons
```bash
# Run the icon generation script
chmod +x create_square_icons.sh
./create_square_icons.sh
```

### Step 3: Apple Developer Portal Setup
1. **Go to**: https://developer.apple.com/account
2. **Create App ID**:
   - Bundle ID: `com.paulrattigan.briefingbuddy`
   - Description: "Briefing Buddy - Aviation Preflight Briefing Assistant"
3. **Create App in App Store Connect**:
   - SKU: `briefing-buddy-ios`
   - Access Level: **Limited Access** (for testing)

### Step 4: Update Bundle Identifier
```bash
# Update iOS project bundle ID
sed -i '' 's/com.example.briefingBuddy/com.paulrattigan.briefingbuddy/g' ios/Runner.xcodeproj/project.pbxproj
```

### Step 5: Build and Archive
```bash
# Clean and build
flutter clean
flutter build ios --release

# Open Xcode and create archive
open ios/Runner.xcworkspace
```

### Step 6: Xcode Archive Process
1. **In Xcode**:
   - Select "Runner" scheme
   - Select "Any iOS Device (arm64)" as destination
   - Go to **Product** → **Archive**
2. **Upload to App Store Connect**:
   - Click **Distribute App**
   - Select **App Store Connect**
   - Select **Upload**
   - Follow prompts to upload

### Step 7: TestFlight Configuration
1. **Go to App Store Connect**: https://appstoreconnect.apple.com
2. **Navigate to your app** → **TestFlight** tab
3. **Configure Compliance**:
   - Select "None of the algorithms mentioned above" (no custom encryption)
4. **Create Test Group**:
   - Add internal testers
   - Assign build to test group
5. **Send Invitations**:
   - Testers receive email invitations
   - Install TestFlight app on iOS device
   - Accept invitation and install app

## Android Deployment (APK)

### Step 1: Create Android Project (if needed)
```bash
# Generate Android project files
flutter create --platforms android .
```

### Step 2: Configure Android App
```bash
# Update app name in AndroidManifest.xml
# Change android:label="briefing_buddy" to android:label="Briefing Buddy"
```

### Step 3: Generate Android App Icons
```bash
# Run the Android icon generation script
chmod +x create_android_icons.sh
./create_android_icons.sh
```

### Step 4: Install Required Android SDK Components
```bash
# Set Android SDK environment
export ANDROID_HOME=/opt/homebrew/share/android-commandlinetools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

# Accept licenses
yes | sdkmanager --licenses

# Install required components
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
```

### Step 5: Build APK
```bash
# Clean and build
flutter clean
flutter build apk --release
```

### Step 6: Install APK on Android Device

#### Option A: Direct Transfer
1. **Copy APK** to Android device:
   ```bash
   # APK location: build/app/outputs/flutter-apk/app-release.apk
   ```
2. **Enable Unknown Sources**:
   - Go to Settings → Security → Install unknown apps
   - Enable for your file manager/browser
3. **Install APK**:
   - Tap the APK file on your device
   - Follow installation prompts

#### Option B: ADB Install
```bash
# Connect Android device via USB
adb devices
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Troubleshooting

### Common iOS Issues

#### App Icon Transparency Error
```bash
# Fix: Regenerate icons without alpha channel
./create_square_icons.sh
```

#### Bundle Identifier Mismatch
```bash
# Verify bundle ID matches Apple Developer Portal
grep -r "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj
```

#### Archive Validation Failures
- Check app icon sizes and formats
- Verify all required metadata is filled
- Ensure compliance information is correct

### Common Android Issues

#### Java Version Compatibility
```bash
# Error: "Unsupported class file major version 68"
# Solution: Use Java 17 instead of Java 24+
brew install --cask temurin@17
export JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home
```

#### Android SDK Not Found
```bash
# Set environment variables
export ANDROID_HOME=/opt/homebrew/share/android-commandlinetools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools
```

#### Gradle Build Failures
```bash
# Clean and rebuild
flutter clean
cd android && ./gradlew clean && cd ..
flutter build apk --release
```

## File Locations

### iOS
- **Archive**: `build/ios/archive/Runner.xcarchive`
- **IPA**: `build/ios/ipa/*.ipa`
- **App Icons**: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

### Android
- **APK**: `build/app/outputs/flutter-apk/app-release.apk`
- **App Icons**: `android/app/src/main/res/mipmap-*/ic_launcher.png`

## Version Management

### iOS Versioning
- **Version**: `1.0.1` (user-facing version)
- **Build**: `2` (internal build number)
- **Format**: `version: 1.0.1+2` in `pubspec.yaml`

### Android Versioning
- **Version Name**: `1.0.1` (user-facing version)
- **Version Code**: `2` (internal build number)
- **Format**: `version: 1.0.1+2` in `pubspec.yaml`

## Security Notes

### iOS TestFlight
- Limited to 10,000 external testers
- 90-day expiration for external testing
- No expiration for internal testing
- Automatic crash reporting and analytics

### Android APK
- No distribution restrictions
- No expiration
- Manual distribution required
- Consider Google Play Store for wider distribution

## Quick Commands Reference

```bash
# iOS Deployment
flutter build ios --release
open ios/Runner.xcworkspace

# Android Deployment
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk

# Clean Build
flutter clean
flutter pub get

# Check Environment
flutter doctor --verbose
```

## Support

For issues specific to:
- **iOS**: Check Apple Developer documentation and Xcode logs
- **Android**: Check Android Studio logs and Gradle build output
- **Flutter**: Run `flutter doctor` and check Flutter documentation

---

*Last updated: January 2025*
*Briefing Buddy v1.0.1*
