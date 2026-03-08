# App Store Review Guidelines Reference

Rejection reasons ordered by frequency (Apple 2024 Transparency Report: 1.93M rejections out of 7.77M submissions).

## Table of Contents

1. [2.1 App Completeness (~40% of rejections)](#21-app-completeness)
2. [5.1 Privacy](#51-privacy)
3. [2.3 Accurate Metadata](#23-accurate-metadata)
4. [3.1 In-App Purchase](#31-in-app-purchase)
5. [4.0 Design](#40-design)
6. [Platform-Specific: React Native](#react-native-specific)
7. [2026 New Requirements](#2026-requirements)

---

## 2.1 App Completeness

The #1 rejection reason. Apple tests on physical devices.

### What reviewers check

- App launches without crash on all supported devices
- All buttons, links, and navigation paths work
- No placeholder text ("Lorem ipsum", "TODO", "Coming soon")
- No broken images or missing assets
- No dead-end screens or unfinished flows
- Deep links and universal links resolve correctly
- Backend services are running and not blocking Apple's IP ranges

### Code signals to scan for

```
# Placeholder / incomplete content
TODO, FIXME, XXX, HACK, placeholder, lorem ipsum, "coming soon"
"test", "dummy", "sample" in user-visible strings

# Debug / dev artifacts
console.log, print(), debugPrint(), NSLog (excessive)
#if DEBUG blocks that affect user-visible behavior
.env files with development URLs bundled in release

# Crash risks
force unwrap (!) without guard
try! without error handling
implicitly unwrapped optionals in view controllers
fatalError() in production paths
```

### React Native specific signals

```
# Debug artifacts
__DEV__ checks that affect UI
console.warn, console.error left in production
react-native-debugger references
Flipper imports in release builds

# Common crash sources
Missing null checks on native module bridge calls
Unhandled promise rejections
```

---

## 5.1 Privacy

Second most common rejection reason.

### Required elements

- [ ] Privacy policy URL — must be set in App Store Connect AND accessible in-app (Settings or onboarding)
- [ ] NSPrivacy manifest (PrivacyInfo.xcprivacy) — required since Spring 2024
- [ ] Purpose strings for ALL used permissions (camera, location, photos, microphone, contacts, tracking, etc.)
- [ ] Account deletion — if app supports account creation, must offer account deletion (in-app, not just "email us")
- [ ] ATT prompt (AppTrackingTransparency) — required before accessing IDFA
- [ ] If using third-party AI services: consent modal specifying provider and data types before personal data is shared

### Code signals to scan for

```
# Missing purpose strings — check Info.plist for these keys
NSCameraUsageDescription
NSPhotoLibraryUsageDescription
NSLocationWhenInUseUsageDescription
NSLocationAlwaysUsageDescription
NSMicrophoneUsageDescription
NSContactsUsageDescription
NSCalendarsUsageDescription
NSFaceIDUsageDescription
NSUserTrackingUsageDescription

# Privacy manifest
PrivacyInfo.xcprivacy existence and completeness

# Account deletion
Look for signup/register flow → verify delete account flow exists
deleteAccount, removeAccount, accountDeletion
```

### React Native specific

```
# Check react-native permissions library usage
react-native-permissions configuration
# Verify Info.plist has all required usage descriptions
# Check if expo-permissions or expo-* plugins declare permissions correctly
```

---

## 2.3 Accurate Metadata

### What reviewers compare

- Screenshots match actual app UI (no fake/mockup screenshots)
- App description matches actual functionality
- App category is appropriate
- Age rating questionnaire is accurate (must be updated by Jan 31, 2026)
- Demo account credentials provided in App Review Notes (if login required)
- What's New text is relevant (not copy-pasted from previous version)

### Code signals to scan for

```
# Check for features mentioned in metadata but gated/hidden
feature flags that hide functionality
A/B test variants that change core behavior
Geofenced features (reviewer may be in any location)
```

---

## 3.1 In-App Purchase

### Apple IAP rules

- [ ] All digital content/features must use Apple IAP (no Stripe/PayPal for digital goods)
- [ ] Exact pricing displayed before purchase button
- [ ] "Restore Purchases" button — visible and functional (Settings, Paywall, or both)
- [ ] Subscription terms clearly displayed: title, duration, price, renewal info
- [ ] Free trial terms explicitly stated
- [ ] No references to pricing on other platforms
- [ ] All IAP products submitted with the app build (not separately)
- [ ] No charging for OS-level features (push notifications, iCloud storage)

### RevenueCat specific checks

```
# Verify configuration
Purchases.configure() called with correct API key
Offerings fetched and displayed correctly
restorePurchases() implemented and accessible

# Common RC rejection causes
- Products in App Store Connect not matching RC dashboard
- Sandbox testing not working (reviewer uses sandbox)
- Missing error handling when offerings fail to load
- Paywall shows loading state indefinitely when products unavailable
```

### Code signals to scan for

```
# Restore purchases
restorePurchases, restoreTransactions, "Restore"
# Pricing display
localizedPrice, priceString, formattedPrice
# Subscription terms
subscriptionPeriod, introductoryPrice, freeTrialPeriod
# External payment (rejection risk)
stripe, paypal, braintree (for digital goods)
```

---

## 4.0 Design

### Minimum bar

- App provides meaningful functionality (not a "thin wrapper" around a website)
- UI is not broken on any supported device size
- No WebView-only apps that replicate website functionality
- Supports current device notch/Dynamic Island/safe areas
- Keyboard does not cover input fields
- Accessibility: VoiceOver labels on interactive elements (recommended, not always required)

### Code signals to scan for

```
# WebView-only check
WKWebView or react-native-webview as primary content (vs supplementary)

# Layout issues
hardcoded frame sizes without safe area consideration
safeAreaInsets not used
Fixed dimensions that don't adapt to screen sizes
```

---

## React Native Specific

Additional checks for React Native projects:

### Build & Configuration

```
# Verify release build configuration
- Release scheme configured in Xcode
- Bundle signing with distribution certificate (not development)
- Correct bundle identifier matching App Store Connect
- Minimum deployment target meets Apple requirements

# Hermes engine (if used)
- Hermes enabled for iOS release builds
- No Hermes-specific crashes in release mode

# CodePush / OTA updates
- If using CodePush: ensure it doesn't change app's primary purpose (guideline 3.3.2)
- OTA updates should not bypass App Review for significant changes
```

### Native Modules

```
# Check for native module issues
- All native dependencies properly linked
- Pod install completed without errors
- No missing native module implementations
- Bridging headers configured correctly
```

---

## 2026 Requirements

As of 2026, these are additionally enforced:

- Apps must be built with SDKs for iOS 18+ (as of April 2025)
- Updated age rating questionnaire required (deadline Jan 31, 2026)
- AI service consent modal required when sharing personal data with third-party AI
- Privacy manifests required for all apps and third-party SDKs
