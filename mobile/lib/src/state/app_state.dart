import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../config/app_config.dart';
import '../notifications/notification_service.dart';
import '../storage/prefs.dart';

class AppState extends ChangeNotifier {
  AppState(this._prefs);

  final Prefs _prefs;
  Timer? _penaltyTimer;

  String? _baseUrl;
  String? _userToken;
  String? _adminToken;
  UserMe? _me;
  AppLatestRelease? _update;
  bool _updateDismissed = false;

  String? get baseUrl => _baseUrl;
  bool get hasBaseUrl => (_baseUrl ?? '').isNotEmpty;

  String? get userToken => _userToken;
  bool get isUserLoggedIn => (_userToken ?? '').isNotEmpty;

  String? get adminToken => _adminToken;
  bool get isAdminLoggedIn => (_adminToken ?? '').isNotEmpty;

  UserMe? get me => _me;
  AppLatestRelease? get update => _updateDismissed ? null : _update;

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
    if (isAdminLoggedIn) {
      _startPenaltyPolling();
    }
    await checkUpdate(silent: true);
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
    _stopPenaltyPolling();
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
    _startPenaltyPolling(resetBaseline: true);
  }

  Future<List<PenaltyItem>> getPenalties() => api.getPenalties();
  Future<AdminScheduleResponse> getAdminSchedule(String startDateYmd) => api.getAdminSchedule(startDateYmd);

  Future<void> checkUpdate({bool silent = false}) async {
    try {
      final p = defaultTargetPlatform;
      final platform = p == TargetPlatform.android
          ? 'android'
          : p == TargetPlatform.iOS
              ? 'ios'
              : '';
      if (platform.isEmpty) return;

      final latest = await api.getLatestRelease(platform);
      if (latest.versionCode <= 0) return;
      if (latest.url.isEmpty) return;

      final info = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(info.buildNumber) ?? 0;
      if (latest.versionCode <= currentCode) return;

      if (_prefs.lastUpdatePromptCode == latest.versionCode) return;

      _update = latest;
      _updateDismissed = false;
      notifyListeners();
    } catch (e) {
      if (!silent) rethrow;
    }
  }

  void dismissUpdate() {
    if (_update == null) return;
    _updateDismissed = true;
    notifyListeners();
  }

  Future<void> startUpdate() async {
    final u = _update;
    if (u == null) return;
    if (u.url.isEmpty) return;
    await _prefs.setLastUpdatePromptCode(u.versionCode);
    _updateDismissed = true;
    notifyListeners();
    await launchUrl(Uri.parse(u.url), mode: LaunchMode.externalApplication);
  }

  void _stopPenaltyPolling() {
    _penaltyTimer?.cancel();
    _penaltyTimer = null;
  }

  void _startPenaltyPolling({bool resetBaseline = false}) {
    _stopPenaltyPolling();
    if (!isAdminLoggedIn) return;

    // Bir marta darhol tekshiramiz, keyin periodik.
    _checkPenalties(resetBaseline: resetBaseline);
    _penaltyTimer = Timer.periodic(const Duration(seconds: 30), (_) => _checkPenalties());
  }

  Future<void> _checkPenalties({bool resetBaseline = false}) async {
    if (!isAdminLoggedIn) return;
    try {
      final items = await getPenalties();
      if (items.isEmpty) return;
      final newest = items.first;

      final lastId = _prefs.lastPenaltyId;
      if (resetBaseline || lastId == null || lastId.isEmpty) {
        await _prefs.setLastPenaltyId(newest.id);
        return;
      }

      if (newest.id != lastId) {
        await _prefs.setLastPenaltyId(newest.id);
        final u = newest.user;
        final who = u == null ? '' : '${u.name} ${u.phone}';
        await NotificationService.showPenalty(
          title: 'Yangi jarima: ${newest.amount} so‘m',
          body: '${newest.date} ${newest.startTime} $who',
        );
      }
    } catch (_) {
      // polling xatolari UI'ni buzmasin
    }
  }

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
