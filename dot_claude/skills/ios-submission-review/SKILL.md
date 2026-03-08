---
name: ios-submission-review
description: >
  Pre-submission review for iOS App Store. Scans the codebase for common
  rejection reasons and generates a pass/fail report with fixes.
  Use this skill when the user mentions App Store submission, review, release,
  審査, 提出, or phrases like "ready to submit", "before submitting to Apple",
  "submission review", "rejection check". Also trigger when the user is
  preparing a TestFlight build for external review or discussing App Store
  rejection issues. Supports Swift/SwiftUI, UIKit, and React Native projects
  with Apple IAP and RevenueCat.
---

# iOS Submission Review

Automated pre-submission review that catches the most common App Store rejection reasons before you submit. Modeled after the thoroughness of tools like Rork, but running entirely in CLI against your actual codebase.

Apple rejects ~25% of submissions (1.93M out of 7.77M in 2024). Over 40% of those are for easily avoidable issues. This skill checks for them systematically.

## How it works

When invoked, run all checks below against the current project. The user shouldn't need to provide any input beyond triggering the skill — detect the project type (Swift/RN) automatically and scan everything.

## Step 1: Detect Project Type

Determine the stack by checking for:
- `*.xcodeproj` / `*.xcworkspace` → Native iOS (Swift/ObjC)
- `package.json` with `react-native` → React Native
- `Podfile`, `Gemfile` → Additional native dependencies
- `app.json` / `app.config.js` → Expo (React Native)

Also detect IAP setup:
- `RevenueCatUI`, `Purchases`, `@revenuecat/purchases-react-native` → RevenueCat
- `StoreKit`, `SKPaymentQueue` → Native StoreKit
- Both can coexist

## Step 2: Run Checks by Guideline

Read `references/guidelines.md` for the full checklist and code signals per guideline. For each section, scan the codebase for the listed patterns and verify required elements exist.

### Check order (by rejection frequency):

1. **2.1 App Completeness** — Placeholder content, crash risks, debug artifacts, dead-end flows
2. **5.1 Privacy** — Privacy policy, permission purpose strings, PrivacyInfo.xcprivacy, account deletion, ATT
3. **2.3 Accurate Metadata** — Feature flags hiding functionality, demo account readiness
4. **3.1 In-App Purchase** — Restore button, pricing display, subscription terms, RevenueCat config
5. **4.0 Design** — WebView-only check, safe area usage, layout adaptability
6. **2026 Requirements** — SDK version, age rating, AI consent, privacy manifests

For each check:
- Scan relevant files using Grep/Glob
- Classify as PASS, WARN, or FAIL
- For FAIL/WARN: cite the specific file and line, explain why it's a problem, and state the fix

## Step 3: Generate Report

Output a structured report directly in the conversation:

```
# iOS Submission Review

Project: [name] | Stack: [Swift/React Native] | IAP: [Apple/RevenueCat/None]

## Summary
- X passes, Y warnings, Z failures
- Estimated review risk: LOW / MEDIUM / HIGH

## Failures (must fix before submission)

### [Guideline #] [Title]
- **File**: path/to/file.swift:42
- **Issue**: [what's wrong]
- **Fix**: [specific action to take]

## Warnings (review recommended)

### [Guideline #] [Title]
- **File**: path/to/file.swift:42
- **Issue**: [what's wrong]
- **Recommendation**: [suggested action]

## Passes
- [Guideline #] [Title] — OK

## Pre-Submission Reminders
- [ ] Demo account credentials in App Review Notes (if login required)
- [ ] Screenshots match current UI
- [ ] What's New text updated
- [ ] Backend services running and not blocking Apple IP ranges
- [ ] TestFlight build tested on physical device
```

## Step 4: Visual Verification (Chrome)

After the code scan, use Chrome (browser automation) to verify UI-level issues that static analysis can't catch:

- If a local dev server or Simulator build is available, launch the app and visually check:
  - Onboarding flow completes without dead ends
  - Paywall displays pricing, subscription terms, and Restore button
  - Privacy policy link is accessible from Settings or onboarding
  - Account deletion flow exists (if signup is present)
  - No placeholder text or broken images visible on screen
- If App Store Connect is accessible in the browser, verify:
  - Screenshots match the current app UI
  - Demo account credentials are filled in App Review Notes
  - IAP products are in "Ready to Submit" state and attached to the build
  - Age rating questionnaire is up to date

Skip this step if no browser automation is available or the user declines. Note in the report which visual checks were performed and which were skipped.

## Important behaviors

- Run all checks automatically — don't ask the user which guidelines to check
- Be specific: cite files and lines, not vague warnings
- Don't report PASS items in detail — just list them. Focus the user's attention on failures and warnings
- If IAP is detected, check RevenueCat/StoreKit configuration thoroughly — IAP rejections are painful because resubmission requires full re-review
- If the project has no iOS-specific files, say so and exit early
- When using Chrome for visual verification, follow the browser-automation rule: operate one field at a time, verify after each action
