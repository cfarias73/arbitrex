# 🦊 Polyfox - Session Handover Guide

## 🚀 Current State
The application has been fully rebranded from "Arbitrex" to **Polyfox**. The visual identity is premium, featuring a dark theme with orange accents, glassmorphism, and smooth animations.

### Completed in this session:
- **Splash Screen:** Pure white with `polyfoxgif.gif` (5s duration).
- **Onboarding:** Premium 3-step PageView with AI-generated illustrations.
- **Login/Register:** Updated with the new transparent logo (`Logos.png`).
- **Stats Screen:** Real-time summary integration and Pro-gate logic for periods > 1 day.
- **Paywall Screen:** Compacted, 1-view design with Trader Pro/Plus selector and marketing features.
- **Deep Linking:** Configured `polyfox://` scheme for iOS and Android.
- **Marketing SDKs:** `facebook_app_events` and `tiktok_sdk` installed and centralized in `AnalyticsService`.
- **UI Cleanup:** Removed non-functional "Alerts" features (navbar icon and detail screen button).

## 🛠 Next Steps (RevenueCat & Stores)

### 1. RevenueCat Integration
- **Dependency:** Add `purchases_flutter`.
- **Paywall Logic:** Connect the current `PaywallScreen` UI to RevenueCat offerings.
- **Entitlements:** Map "Pro" and "Plus" tiers to enable/disable features (Stats history, etc.).
- **Receipts:** Ensure `AnalyticsService.logPurchase` triggers after successful payment.

### 2. App Store Submission (iOS)
- **Metadata:** App Store Connect setup.
- **Assets:** User has screenshots ready.
- **IAP Products:** Configure subscriptions in App Store Connect to match RevenueCat.
- **Privacy:** Update with Meta/TikTok tracking disclosure.

### 3. Google Play Submission (Android)
- **Play Console:** Initial setup and APK/AAB generation.
- **IAP Products:** Synchronize with RevenueCat and App Store.

## 📝 Pending Information
- **Marketing IDs:** Need actual `Facebook App ID`, `Client Token`, and `TikTok App ID` to finalize `AnalyticsService`.
- **RevenueCat Keys:** Need the Public SDK Keys for iOS and Android.

---
**Status:** Ready for RevenueCat implementation. 🚀
