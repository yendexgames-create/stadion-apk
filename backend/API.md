# Backend API

Base URL: `PUBLIC_BASE_URL`

## App

### GET /app/latest?platform=android|ios

Response:

```json
{
  "platform": "android",
  "versionName": "1.0.2",
  "versionCode": 2,
  "url": "https://.../app-release.apk",
  "sha256": "..."
}
```

## Auth (User)

### POST /auth/request-otp

Body:

```json
{ "name": "Ali", "phone": "+998901234567" }
```

Errors:

- `TELEGRAM_NOT_LINKED` — foydalanuvchi botga kirib kontakt yubormagan

### POST /auth/verify-otp

Body:

```json
{ "phone": "+998901234567", "code": "123456", "fcmToken": "..." }
```

Response:

```json
{ "token": "...", "user": { "id": "...", "phone": "...", "name": "..." } }
```

## Me

### GET /me

Header: `Authorization: Bearer <token>`

Response:

```json
{ "id": "...", "phone": "...", "name": "...", "gamesCount": 12 }
```

## Slots

### GET /slots?date=YYYY-MM-DD

Header: `Authorization: Bearer <token>`

Response:

```json
{
  "date": "2026-05-13",
  "slots": [
    { "startTime": "19:00", "endTime": "20:00", "status": "busy", "mine": false },
    { "startTime": "20:00", "endTime": "21:00", "status": "free" }
  ]
}
```

## Bookings

### GET /bookings/my

Header: `Authorization: Bearer <token>`

### POST /bookings/daily

Body:

```json
{ "date": "2026-05-13", "startTime": "19:00" }
```

Errors:

- `SLOT_BUSY`

### POST /bookings/weekly

6 hafta (startDate, startDate+7, ...).

Body:

```json
{ "startDate": "2026-05-13", "startTime": "19:00" }
```

Errors:

- `SLOT_BUSY` (conflicts bilan)

### DELETE /bookings/:id

Kunlik bronni bekor qiladi. Agar `date === today` bo‘lsa `penalties` ga 100000 yoziladi.

### DELETE /bookings/weekly-series/:id

Haftalik seriyani bekor qiladi (kelgusi bronlarni o‘chiradi). Agar bugungi bron ham tushsa, jarima yoziladi.

## Admin

### POST /admin/login

Body:

```json
{ "phone": "+998901234567", "password": "..." }
```

### GET /admin/penalties

Header: `Authorization: Bearer <admin token>`
