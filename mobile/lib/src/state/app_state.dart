import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../config/app_config.dart';
import '../storage/prefs.dart';

class AppState extends ChangeNotifier {
  AppState(this._prefs);

  final Prefs _prefs;

  String? _baseUrl;
  String? _userToken;
  String? _adminToken;
  UserMe? _me;

  String? get baseUrl => _baseUrl;
  bool get hasBaseUrl => (_baseUrl ?? '').isNotEmpty;

  String? get userToken => _userToken;
  bool get isUserLoggedIn => (_userToken ?? '').isNotEmpty;

  String? get adminToken => _adminToken;
  bool get isAdminLoggedIn => (_adminToken ?? '').isNotEmpty;

  UserMe? get me => _me;

  ApiClient get api => ApiClient(baseUrl: _baseUrl ?? '', userToken: _userToken, adminToken: _adminToken);

  Future<void> init() async {
    // Base URL endi foydalanuvchidan so‘ralmaydi.
    // Har doim build-time `--dart-define=BASE_URL=...` (yoki default) ishlaydi.
    //
    // Oldingi versiyalarda `baseUrl` lokal IP sifatida saqlanib qolgan bo‘lishi mumkin.
    // Shuni avtomatik tozalab yuboramiz, aks holda ilova doim lokal IP'ga urilib qoladi.
    final saved = _prefs.baseUrl?.trim();
    if (saved != null && saved.isNotEmpty && saved != AppConfig.defaultBaseUrl) {
      await _prefs.clearBaseUrl();
    }
    _baseUrl = AppConfig.defaultBaseUrl;
    _userToken = _prefs.userToken;
    _adminToken = _prefs.adminToken;
    notifyListeners();
    if (hasBaseUrl && isUserLoggedIn) {
      await refreshMe(silent: true);
    }
  }

  Future<void> setBaseUrl(String url) async {
    final v = url.trim();
    _baseUrl = v;
    await _prefs.setBaseUrl(v);
    notifyListeners();
  }

  Future<void> logoutUser() async {
    _userToken = null;
    _me = null;
    await _prefs.clearUserToken();
    notifyListeners();
  }

  Future<void> logoutAdmin() async {
    _adminToken = null;
    await _prefs.clearAdminToken();
    notifyListeners();
  }

  Future<void> requestOtp({required String name, required String phone}) async {
    await api.requestOtp(name: name, phone: phone);
  }

  Future<void> verifyOtp({required String phone, required String code}) async {
    final r = await api.verifyOtp(phone: phone, code: code);
    _userToken = r.token;
    await _prefs.setUserToken(r.token);
    notifyListeners();
    await refreshMe(silent: true);
  }

  Future<void> refreshMe({bool silent = false}) async {
    if (!isUserLoggedIn) return;
    try {
      _me = await api.getMe();
      notifyListeners();
    } catch (e) {
      if (!silent) rethrow;
    }
  }

  Future<SlotsResponse> getSlots(String dateYmd) => api.getSlots(dateYmd);
  Future<void> createDaily({required String dateYmd, required String startTime}) => api.createDaily(dateYmd, startTime);
  Future<void> createWeekly({required String startDateYmd, required String startTime}) =>
      api.createWeekly(startDateYmd, startTime);
  Future<MyBookingsResponse> getMyBookings() => api.getMyBookings();
  Future<void> cancelDaily(String bookingId) => api.cancelDaily(bookingId);
  Future<void> cancelWeeklySeries(String seriesId) => api.cancelWeeklySeries(seriesId);

  Future<void> adminLogin({required String phone, required String password}) async {
    final r = await api.adminLogin(phone: phone, password: password);
    _adminToken = r.token;
    await _prefs.setAdminToken(r.token);
    notifyListeners();
  }

  Future<List<PenaltyItem>> getPenalties() => api.getPenalties();

  String prettyError(Object e) {
    final s = e.toString();
    const prefix = 'ApiError(';
    if (!s.startsWith(prefix)) return s;
    final idx = s.indexOf('): ');
    if (idx < 0) return s;
    return s.substring(idx + 3);
  }

  String encodeJson(Object obj) => const JsonEncoder.withIndent('  ').convert(obj);
}
