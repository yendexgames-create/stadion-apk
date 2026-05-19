class ChangelogEntry {
  const ChangelogEntry({required this.version, required this.date, required this.items});

  final String version;
  final String date;
  final List<String> items;
}

/// Ilova ichidagi yangilanishlar jurnali.
/// Har safar o‘zgartirish kiritsak, shu ro‘yxatga yangi entry qo‘shib boramiz.
const appChangelog = <ChangelogEntry>[
  ChangelogEntry(
    version: '1.0.1',
    date: '2026-05-17',
    items: [
      'Android uchun INTERNET ruxsati qo‘shildi (serverga ulanmaslik xatosi tuzatildi).',
      'HTTP (cleartext) ishlashi uchun Android sozlama yoqildi.',
      'Sozlamalar ekrani qo‘shildi: baseUrl saqlash va /health test.',
      'Admin-only kirish oqimi va zamonaviy futbol temasi (keyingi commitda) tayyorlanmoqda.',
    ],
  ),
];

