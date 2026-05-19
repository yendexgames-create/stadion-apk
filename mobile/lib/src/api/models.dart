String s(dynamic v) => v == null ? '' : v.toString();

class ApiError implements Exception {
  ApiError(this.statusCode, this.error);

  final int statusCode;
  final String error;

  @override
  String toString() => 'ApiError($statusCode): $error';
}

class UserMe {
  UserMe({required this.id, required this.phone, required this.name, required this.gamesCount});

  final String id;
  final String phone;
  final String name;
  final int gamesCount;

  factory UserMe.fromJson(Map<String, dynamic> json) {
    return UserMe(
      id: s(json['id']),
      phone: s(json['phone']),
      name: s(json['name']),
      gamesCount: (json['gamesCount'] is int) ? json['gamesCount'] as int : int.tryParse('${json['gamesCount']}') ?? 0,
    );
  }
}

class VerifyOtpResponse {
  VerifyOtpResponse({required this.token, required this.user});

  final String token;
  final UserMeLite user;

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      token: s(json['token']),
      user: UserMeLite.fromJson((json['user'] as Map?)?.cast<String, dynamic>() ?? {}),
    );
  }
}

class UserMeLite {
  UserMeLite({required this.id, required this.phone, required this.name});

  final String id;
  final String phone;
  final String name;

  factory UserMeLite.fromJson(Map<String, dynamic> json) {
    return UserMeLite(
      id: s(json['id']),
      phone: s(json['phone']),
      name: s(json['name']),
    );
  }
}

class SlotsResponse {
  SlotsResponse({required this.date, required this.slots});

  final String date;
  final List<SlotItem> slots;

  factory SlotsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['slots'] as List?) ?? const [];
    return SlotsResponse(
      date: s(json['date']),
      slots: list.map((e) => SlotItem.fromJson((e as Map).cast<String, dynamic>())).toList(),
    );
  }
}

class SlotItem {
  SlotItem({
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.mine,
    required this.bookingType,
    required this.bookingId,
  });

  final String startTime;
  final String endTime;
  final String status;
  final bool mine;
  final String? bookingType;
  final String? bookingId;

  factory SlotItem.fromJson(Map<String, dynamic> json) {
    return SlotItem(
      startTime: s(json['startTime']),
      endTime: s(json['endTime']),
      status: s(json['status']),
      mine: json['mine'] == true,
      bookingType: json['bookingType'] == null ? null : s(json['bookingType']),
      bookingId: json['bookingId'] == null ? null : s(json['bookingId']),
    );
  }
}

class MyBookingsResponse {
  MyBookingsResponse({required this.daily, required this.weekly});

  final List<MyDailyBooking> daily;
  final List<MyWeeklySeries> weekly;

  factory MyBookingsResponse.fromJson(Map<String, dynamic> json) {
    final daily = (json['daily'] as List?) ?? const [];
    final weekly = (json['weekly'] as List?) ?? const [];
    return MyBookingsResponse(
      daily: daily.map((e) => MyDailyBooking.fromJson((e as Map).cast<String, dynamic>())).toList(),
      weekly: weekly.map((e) => MyWeeklySeries.fromJson((e as Map).cast<String, dynamic>())).toList(),
    );
  }
}

class MyDailyBooking {
  MyDailyBooking({required this.id, required this.date, required this.startTime, required this.endTime});

  final String id;
  final String date;
  final String startTime;
  final String endTime;

  factory MyDailyBooking.fromJson(Map<String, dynamic> json) {
    return MyDailyBooking(
      id: s(json['id']),
      date: s(json['date']),
      startTime: s(json['startTime']),
      endTime: s(json['endTime']),
    );
  }
}

class MyWeeklySeries {
  MyWeeklySeries({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.weekday,
    required this.startTime,
    required this.endTime,
  });

  final String id;
  final String startDate;
  final String endDate;
  final int weekday;
  final String startTime;
  final String endTime;

  factory MyWeeklySeries.fromJson(Map<String, dynamic> json) {
    return MyWeeklySeries(
      id: s(json['id']),
      startDate: s(json['startDate']),
      endDate: s(json['endDate']),
      weekday: (json['weekday'] is int) ? json['weekday'] as int : int.tryParse('${json['weekday']}') ?? 0,
      startTime: s(json['startTime']),
      endTime: s(json['endTime']),
    );
  }
}

class AdminLoginResponse {
  AdminLoginResponse({required this.token, required this.admin});

  final String token;
  final AdminMe admin;

  factory AdminLoginResponse.fromJson(Map<String, dynamic> json) {
    return AdminLoginResponse(
      token: s(json['token']),
      admin: AdminMe.fromJson((json['admin'] as Map?)?.cast<String, dynamic>() ?? {}),
    );
  }
}

class AdminMe {
  AdminMe({required this.id, required this.phone, required this.name});

  final String id;
  final String phone;
  final String name;

  factory AdminMe.fromJson(Map<String, dynamic> json) {
    return AdminMe(
      id: s(json['id']),
      phone: s(json['phone']),
      name: s(json['name']),
    );
  }
}

class PenaltyItem {
  PenaltyItem({
    required this.id,
    required this.amount,
    required this.date,
    required this.startTime,
    required this.createdAt,
    required this.user,
  });

  final String id;
  final int amount;
  final String date;
  final String startTime;
  final String createdAt;
  final PenaltyUser? user;

  factory PenaltyItem.fromJson(Map<String, dynamic> json) {
    return PenaltyItem(
      id: s(json['id']),
      amount: (json['amount'] is int) ? json['amount'] as int : int.tryParse('${json['amount']}') ?? 0,
      date: s(json['date']),
      startTime: s(json['startTime']),
      createdAt: s(json['createdAt']),
      user: json['user'] == null ? null : PenaltyUser.fromJson((json['user'] as Map).cast<String, dynamic>()),
    );
  }
}

class PenaltyUser {
  PenaltyUser({required this.name, required this.phone});

  final String name;
  final String phone;

  factory PenaltyUser.fromJson(Map<String, dynamic> json) {
    return PenaltyUser(
      name: s(json['name']),
      phone: s(json['phone']),
    );
  }
}
