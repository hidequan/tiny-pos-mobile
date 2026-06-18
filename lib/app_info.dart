/// Central app identity & support metadata.
///
/// Single source of truth for the developer name, support contact and privacy
/// URL shown in the in-app "Giới thiệu & Hỗ trợ" sheet and store metadata.
/// Keep [version]/[build] in sync with `pubspec.yaml` (currently 0.3.3+13).
class AppInfo {
  static const String name = 'Tiny POS';
  static const String version = '0.3.3';
  static const String build = '13';

  /// Developer / company name (shown on the store listing & privacy policy).
  static const String developer = 'LP Tech';
  static const String supportEmail = 'technology.lamphongtech@gmail.com';
  static const String privacyUrl = 'https://hidequan.github.io/tiny-pos-privacy/';
}
