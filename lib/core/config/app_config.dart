/// Centralized release feature gating for Prism.
///
/// Use these flags to toggle major subsystems across release stages
/// (e.g. v1.0 Free Sandbox Release vs. v2.0 Pro / External Storage Release)
/// without deleting underlying architectural modules.
class AppConfig {
  /// Controls whether In-App Subscriptions and Pro gating (paywall, badges) are active.
  /// When `false`:
  /// - RevenueCat SDK initialization is bypassed.
  /// - Subscription paywalls (`/settings/paywall`) are disabled.
  /// - "Prism Pro" banners and "PRO" lock badges are hidden.
  /// - Pro-gated editorial themes and fonts are suppressed from selection.
  /// - Vault export displays only standard free JSON format.
  ///
  /// Set to `false` for v1.0 free launch.
  /// Set to `true` when launching Prism Pro in v1.1/v2.0.
  static bool enableSubscriptions = false;

  /// Controls whether custom external storage (`MANAGE_EXTERNAL_STORAGE`) is enabled.
  /// When `false`:
  /// - Android `MANAGE_EXTERNAL_STORAGE` permission check is bypassed at startup.
  /// - Onboarding skips device folder picking and initializes directly in the app sandbox.
  /// - Settings relocation restricts or hides device folder switching.
  ///
  /// Set to `false` for v1.0 sandbox launch.
  /// Set to `true` when re-introducing external storage and submitting declaration forms.
  static bool enableExternalStorage = false;
}
