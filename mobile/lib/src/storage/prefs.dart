import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  Prefs(this._p);

  final SharedPreferences _p;

  static const _kBaseUrl = 'baseUrl';
  static const _kUserToken = 'userToken';
  static const _kAdminToken = 'adminToken';

  String? get baseUrl => _p.getString(_kBaseUrl);
  Future<void> setBaseUrl(String value) => _p.setString(_kBaseUrl, value);

  String? get userToken => _p.getString(_kUserToken);
  Future<void> setUserToken(String value) => _p.setString(_kUserToken, value);
  Future<void> clearUserToken() => _p.remove(_kUserToken);

  String? get adminToken => _p.getString(_kAdminToken);
  Future<void> setAdminToken(String value) => _p.setString(_kAdminToken, value);
  Future<void> clearAdminToken() => _p.remove(_kAdminToken);
}
