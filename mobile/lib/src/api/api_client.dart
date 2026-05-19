import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class ApiClient {
  ApiClient({required this.baseUrl, required this.userToken, required this.adminToken});

  final String baseUrl;
  final String? userToken;
  final String? adminToken;

  Uri _u(String path, [Map<String, String>? query]) {
    final b = baseUrl.trim().replaceAll(RegExp(r'\/+$'), '');
    return Uri.parse('$b$path').replace(queryParameters: query);
  }

  Map<String, String> _headers({bool auth = false, bool admin = false}) {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final t = userToken;
      if (t != null && t.isNotEmpty) h['Authorization'] = 'Bearer $t';
    }
    if (admin) {
      final t = adminToken;
      if (t != null && t.isNotEmpty) h['Authorization'] = 'Bearer $t';
    }
    return h;
  }

  Future<Map<String, dynamic>> _decode(http.Response r) async {
    if (r.body.isEmpty) return {};
    final v = jsonDecode(r.body);
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.cast<String, dynamic>();
    return {};
  }

  Never _throwApi(int statusCode, Map<String, dynamic> body) {
    final err = body['error'];
    throw ApiError(statusCode, err == null ? 'UNKNOWN_ERROR' : err.toString());
  }

  Future<void> requestOtp({required String name, required String phone}) async {
    final r = await http.post(
      _u('/auth/request-otp'),
      headers: _headers(),
      body: jsonEncode({'name': name, 'phone': phone}),
    );
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    _throwApi(r.statusCode, await _decode(r));
  }

  Future<VerifyOtpResponse> verifyOtp({required String phone, required String code}) async {
    final r = await http.post(
      _u('/auth/verify-otp'),
      headers: _headers(),
      body: jsonEncode({'phone': phone, 'code': code}),
    );
    final body = await _decode(r);
    if (r.statusCode >= 200 && r.statusCode < 300) return VerifyOtpResponse.fromJson(body);
    _throwApi(r.statusCode, body);
  }

  Future<UserMe> getMe() async {
    final r = await http.get(_u('/me'), headers: _headers(auth: true));
    final body = await _decode(r);
    if (r.statusCode >= 200 && r.statusCode < 300) return UserMe.fromJson(body);
    _throwApi(r.statusCode, body);
  }

  Future<SlotsResponse> getSlots(String dateYmd) async {
    final r = await http.get(_u('/slots', {'date': dateYmd}), headers: _headers(auth: true));
    final body = await _decode(r);
    if (r.statusCode >= 200 && r.statusCode < 300) return SlotsResponse.fromJson(body);
    _throwApi(r.statusCode, body);
  }

  Future<void> createDaily(String dateYmd, String startTime) async {
    final r = await http.post(
      _u('/bookings/daily'),
      headers: _headers(auth: true),
      body: jsonEncode({'date': dateYmd, 'startTime': startTime}),
    );
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    _throwApi(r.statusCode, await _decode(r));
  }

  Future<void> createWeekly(String startDateYmd, String startTime) async {
    final r = await http.post(
      _u('/bookings/weekly'),
      headers: _headers(auth: true),
      body: jsonEncode({'startDate': startDateYmd, 'startTime': startTime}),
    );
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    _throwApi(r.statusCode, await _decode(r));
  }

  Future<MyBookingsResponse> getMyBookings() async {
    final r = await http.get(_u('/bookings/my'), headers: _headers(auth: true));
    final body = await _decode(r);
    if (r.statusCode >= 200 && r.statusCode < 300) return MyBookingsResponse.fromJson(body);
    _throwApi(r.statusCode, body);
  }

  Future<void> cancelDaily(String bookingId) async {
    final r = await http.delete(_u('/bookings/$bookingId'), headers: _headers(auth: true));
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    _throwApi(r.statusCode, await _decode(r));
  }

  Future<void> cancelWeeklySeries(String seriesId) async {
    final r = await http.delete(_u('/bookings/weekly-series/$seriesId'), headers: _headers(auth: true));
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    _throwApi(r.statusCode, await _decode(r));
  }

  Future<AdminLoginResponse> adminLogin({required String phone, required String password}) async {
    final r = await http.post(
      _u('/admin/login'),
      headers: _headers(),
      body: jsonEncode({'phone': phone, 'password': password}),
    );
    final body = await _decode(r);
    if (r.statusCode >= 200 && r.statusCode < 300) return AdminLoginResponse.fromJson(body);
    _throwApi(r.statusCode, body);
  }

  Future<List<PenaltyItem>> getPenalties() async {
    final r = await http.get(_u('/admin/penalties'), headers: _headers(auth: false, admin: true));
    final body = await _decode(r);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      final list = (jsonDecode(r.body) as List?) ?? const [];
      return list.map((e) => PenaltyItem.fromJson((e as Map).cast<String, dynamic>())).toList();
    }
    _throwApi(r.statusCode, body);
  }
}
