# Stadion Bron Ilovasi — Loyihani To‘liq Tavsifi va Hozirgi Holat

Bu hujjat loyihadagi barcha mantiq (login, bron, jarima, admin), hozir qayergacha kelganimiz, nima ishlayapti/ishlamayapti va keyingi qadamlarni bir joyga yig‘adi.

## 1) Maqsad

Foydalanuvchi stadion vaqt slotlarini (19:00–00:00, 1 soatlik) ko‘radi, band/bo‘sh holatini biladi, bron qiladi va bekor qiladi. Login Telegram bot orqali keladigan OTP kod bilan bo‘ladi. Admin rejimida jarimalar ro‘yxati ko‘rinadi.

## 2) Texnologiya

- Mobile: Flutter (Android + iOS) — hali qo‘shilmagan (Flutter o‘rnatilgach boshlanadi).
- Backend: Node.js (ESM) + Express.
- DB: MongoDB Atlas (Railway’da deploy qilish rejalashtirilgan).
- OTP delivery: Telegram Bot (kontakt ulash orqali phone ↔ chatId bog‘lanadi).
- Push: FCM (Firebase Admin) — hozircha o‘chirilgan, keyin yoqiladi.

Repo tuzilmasi:
- `backend/` — backend API
- `mobile/` — Flutter ilova (keyingi bosqich)

## 3) Muhim tushunchalar (bizdagi qoidalar)

### 3.1 Slotlar
- Har kuni slotlar: 19:00–20:00, 20:00–21:00, 21:00–22:00, 22:00–23:00, 23:00–00:00.
- Slot 1 soat.

### 3.2 Bron turlari
- Kunlik bron: faqat bitta sana uchun.
- Haftalik bron: 6 hafta davom etadi (startDate, startDate+7, ..., 6 ta bron).
- Haftalik bron tugashiga 1 kun qolganda push xabari yuboriladi (FCM yoqilganda).

### 3.3 Bekor qilish va jarima
- Kunlik bronni bekor qilish:
  - Agar bron “bugun”ga bo‘lsa: 100 000 so‘m jarima yozuvi yaratiladi.
  - Aks holda: faqat bekor qilinadi.
- Haftalik bronni bekor qilish:
  - Seriya bekor qilinadi va bugundan keyingi bronlar o‘chirilib ketadi.
  - Agar bugungi bron ham shu seriyaga tegishli bo‘lsa: 100 000 so‘m jarima yoziladi.
- Jarima adminga xabar qilib yuborilmaydi, admin ilova ichidagi “Jarimalar” bo‘limida ko‘radi.

## 4) Login oqimi (Telegram OTP)

### 4.1 Telegram botga bog‘lash
Foydalanuvchi Telegram’da botni ochadi:
1) `/start`
2) “Kontakt yuborish” tugmasini bosadi
3) Backend `users` kolleksiyasida:
   - `phone`
   - `telegramChatId`
   - `telegramUserId`
   saqlanadi.

### 4.2 OTP so‘rash (ilovadan)
1) Ilova `POST /auth/request-otp` yuboradi (`name`, `phone` bilan).
2) Backend tekshiradi: shu `phone` uchun `telegramChatId` bormi?
   - Bo‘lmasa: `TELEGRAM_NOT_LINKED`
3) Bo‘lsa:
   - 6 xonali kod generatsiya qiladi
   - `otp_requests` ga hash ko‘rinishda 5 daqiqaga saqlaydi
   - Telegramga “Kirish kodi: 123456” yuboradi

### 4.3 OTP tasdiqlash (ilovadan)
1) Ilova `POST /auth/verify-otp` yuboradi (`phone`, `code`, ixtiyoriy `fcmToken`).
2) Backend:
   - OTP’ni tekshiradi
   - OTP’ni o‘chiradi (bir martalik)
   - `users` ni `phone` bo‘yicha upsert qiladi (agar user bo‘lmasa yaratadi)
   - JWT token qaytaradi

Eslatma:
- `CODE_EXPIRED` chiqsa — yangi OTP so‘rash kerak.
- Tokenni PowerShell/CLI’da ko‘rishda qisqarib ketmasligi uchun `Invoke-RestMethod` natijasini o‘zgaruvchiga olib `resp.token` dan olish kerak.

## 5) Slot ko‘rsatish mantiqi

`GET /slots?date=YYYY-MM-DD`
- O‘sha kunda `bookings` kolleksiyasidan `canceledAt` yo‘q bronlar olinadi.
- Har slot uchun:
  - Agar bron topilmasa: `free`
  - Bron bo‘lsa: `busy`
  - Agar bron foydalanuvchinikiga tegishli bo‘lsa: `mine=true`

## 6) Ma’lumotlar modeli (MongoDB kolleksiyalar)

### 6.1 users
- `phone` (unique)
- `name`
- `telegramChatId` (kontakt yuborilganda qo‘shiladi)
- `fcmTokens` (keyin push uchun)
- `createdAt`, `updatedAt`

### 6.2 otp_requests
- `phone`
- `hash`
- `expiresAt` (TTL index bilan avtomatik o‘chadi)
- `createdAt`

### 6.3 bookings
- `type`: `daily` yoki `weekly`
- `slotKey`: `${date}_${startTime}` (unique index) — slot band bo‘lishini DB darajasida kafolatlaydi
- `userId`
- `date` (YYYY-MM-DD)
- `startTime`, `endTime`
- `seriesId` (weekly bo‘lsa)
- `weekIndex` (weekly bo‘lsa)
- `canceledAt` (bekor qilingan bo‘lsa)
- `createdAt`

### 6.4 weekly_series
- `userId`
- `startDate`, `endDate`
- `weekday`
- `startTime`, `endTime`
- `weeks` = 6
- `canceledAt`
- `notifiedAt` (push yuborilgan bo‘lsa)
- `createdAt`

### 6.5 penalties
- `userId`
- `bookingId` yoki `seriesId`
- `amount` = 100000
- `date`, `startTime`
- `createdAt`

### 6.6 admins
- `phone` (unique)
- `name`
- `passwordHash`
- `createdAt`, `updatedAt`

## 7) API (qisqa)

To‘liq ro‘yxat: `backend/API.md`.

Muhim endpointlar:
- `POST /auth/request-otp`
- `POST /auth/verify-otp`
- `GET /me`
- `GET /slots?date=...`
- `POST /bookings/daily`
- `POST /bookings/weekly`
- `GET /bookings/my`
- `DELETE /bookings/:id`
- `DELETE /bookings/weekly-series/:id`
- `POST /admin/login`
- `GET /admin/penalties` (admin token bilan)

## 8) Muhit sozlamalari (.env)

Fayl: `backend/.env` (gitga kirmaydi).

Muhim:
- `JWT_SECRET` — token imzolash uchun.
- `TELEGRAM_BOT_TOKEN` — Telegram bot token.
- `MONGODB_URI` — Atlas connection string.
- `PUBLIC_BASE_URL`:
  - lokalda: `http://localhost:8080`
  - deployda: Railway public URL

FCM (keyin):
- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`

## 9) Ishga tushirish (lokal)

1) `cd backend`
2) `npm i`
3) `npm run dev`
4) Tekshiruv: `GET http://localhost:8080/health` → `{"ok":true}`

Telegram test:
- botda `/start` → kontakt yuborish
- `POST /auth/request-otp` → Telegramga kod keladi
- `POST /auth/verify-otp` → token qaytadi

## 10) Hozirgi holat (bugungi progress)

Ishlayapti:
- Backend `health` ishlayapti.
- Telegram orqali OTP so‘rash ishlayapti.
- `verify-otp` token qaytarayapti.
- Token bilan `GET /me` ishlayapti.
- Slotlar ro‘yxati chiqyapti.
- Kunlik bron yaratish ishlayapti.
- Bron bekor qilish ishlayapti va slot yana `free` bo‘ladi.
- Bugungi bron bekor qilinganda jarima yozuvi yaratiladi.

Hozirgi bosqich:
- Admin rejimini (jarimalar ko‘rish) tekshirib chiqish.
- Flutter o‘rnatilgach `mobile/` loyihasini yaratish.

### 10.1 Amaliy tekshiruv (PowerShell)

Token olish:

```powershell
$body = @{ name = "Test"; phone = "+998..." } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri "http://localhost:8080/auth/request-otp" -ContentType "application/json" -Body $body

$body = @{ phone = "+998..."; code = "XXXXXX" } | ConvertTo-Json
$resp = Invoke-RestMethod -Method Post -Uri "http://localhost:8080/auth/verify-otp" -ContentType "application/json" -Body $body
$token = $resp.token
```

Slotlar:

```powershell
$date = (Get-Date).ToString("yyyy-MM-dd")
Invoke-RestMethod -Method Get -Uri "http://localhost:8080/slots?date=$date" -Headers @{ Authorization = "Bearer $token" }
```

Kunlik bron:

```powershell
$body = @{ date = $date; startTime = "19:00" } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri "http://localhost:8080/bookings/daily" -ContentType "application/json" -Headers @{ Authorization = "Bearer $token" } -Body $body
```

Bronni bekor qilish:

```powershell
Invoke-RestMethod -Method Delete -Uri "http://localhost:8080/bookings/<bookingId>" -Headers @{ Authorization = "Bearer $token" }
```

## 11) Keyingi qadamlar (rejaga yaqin)

1) Token bilan endpointlarni tekshirish:
   - `/me`
   - `/slots`
   - `bookings/daily`, `bookings/my`
   - bekor qilish va jarima yozilishi
2) Flutter SDK o‘rnatilgach:
   - `mobile/` yaratish
   - Login ekranlari (bot link + phone + code)
   - Slotlar UI (slayd bilan kunlar)
   - Bron qilish modal (kunlik/haftalik)
   - Bekor qilish UI (faqat o‘z bronlari)
   - Profil (gamesCount)
   - Admin rejimi (admin login + jarimalar ro‘yxati)
3) Push (FCM)ni yoqish:
   - tokenlarni backendga yuborish
   - weekly expiring push

## 12) Telegram botga yangilik (yuklab olish oqimi)

Maqsad: botga `/start` yuborilganda foydalanuvchi telefon raqamini (kontakt) yuboradi, so‘ng platformani tanlaydi (Android / iPhone) va mos o‘rnatish yo‘riqnomasi + havola chiqadi.

Qilingan ishlar:
- Bot `/start` matni yangilandi: kontakt yuborishni aniq so‘raydi.
- Kontakt kelgach `users` ga `telegramChatId` bog‘lanadi va darhol platforma tanlash (inline) chiqadi.
- `/download` komandasi qo‘shildi: platforma tanlashni qayta chiqaradi.
- Platforma tanlanganda `users.preferredPlatform` (`android`/`ios`) saqlanadi.
- Android uchun APK o‘rnatishdagi “security alert” bo‘yicha qisqa yo‘riqnoma yuboriladi.
- iOS uchun TestFlight/App Store orqali o‘rnatish tushuntiriladi (iOS’da “APK kabi sideload” odatda bo‘lmaydi).

Kerakli env (backend):
- `ANDROID_APK_URL` — Android APK yuklab olish havolasi (https bo‘lishi tavsiya).
- `ANDROID_APK_SHA256` — ixtiyoriy, ishonch uchun checksum.
- `IOS_INSTALL_URL` — iOS TestFlight yoki App Store havolasi.

Railway (deploy) eslatma:
- Railway → Variables’da yuqoridagi env’larni qo‘shing/yangilang.
- O‘zgarishlar GitHub’ga push bo‘lgach Railway avtomatik redeploy bo‘lsa, yangi bot matnlari va havolalar darhol ishlaydi (aks holda manual redeploy).

Eslatma (xavfsizlik ogohlantirishi):
- Android’da Play Marketdan tashqaridan o‘rnatiladigan ilovalar doim ogohlantirishi mumkin; “to‘liq o‘chirib yuborish” yo‘li yo‘q.
- Eng ishonchli yechimlar: Google Play (Closed testing / Internal testing) yoki iOS’da TestFlight.
