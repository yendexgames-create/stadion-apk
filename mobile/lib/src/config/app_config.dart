/// Ilova konfiguratsiyasi.
///
/// `BASE_URL` ni build paytida berish mumkin:
/// `flutter build apk --dart-define=BASE_URL=https://xxx.up.railway.app`
///
/// Agar berilmasa, `defaultBaseUrl` ishlaydi.
class AppConfig {
  static const String defaultBaseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://stadion-apk-production.up.railway.app',
  );
}

