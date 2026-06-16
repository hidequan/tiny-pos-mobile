/// Central app identity & support metadata.
///
/// Single source of truth for the developer name, support contact and privacy
/// URL shown in the in-app "Giới thiệu & Hỗ trợ" sheet and store metadata.
/// Keep [version]/[build] in sync with `pubspec.yaml` (currently 0.3.2+10).
class AppInfo {
  static const String name = 'Tiny POS';
  static const String version = '0.3.2';
  static const String build = '10';

  /// Developer / company name (shown on the store listing & privacy policy).
  static const String developer = 'LP Tech';
  static const String supportEmail = 'hidequan@gmail.com';
  static const String privacyUrl = 'https://hidequan.github.io/tiny-pos-privacy/';
}
