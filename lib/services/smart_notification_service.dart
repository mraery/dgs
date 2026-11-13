import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcı bildirim tercihlerini yöneten ve
/// kullanıcıyı asla rahatsız etmeyecek akıllı bildirim servisi.
///
/// Bildirim Kuralları:
/// 1. Rahatsız Etmeme Saatleri: 22:00 - 09:00 arası asla bildirim gönderilmez.
/// 2. Günde en fazla 1 adet motivasyon / seri koruma hatırlatması yapılır.
/// 3. Kullanıcı dilerse ayarlar menüsünden bildirimleri tamamen açıp kapatabilir.
class SmartNotificationService {
  SmartNotificationService._();
  static final SmartNotificationService instance = SmartNotificationService._();

  static const String _keyNotificationsEnabled = 'pref_notifications_enabled';
  static const String _keyDailyReminderHour = 'pref_daily_reminder_hour';
  static const String _keyLastNotificationDate = 'pref_last_notification_date';

  bool _isEnabled = true;
  int _reminderHour = 19; // Akşam 19:00 (en uygun çalışma saati)

  bool get isEnabled => _isEnabled;
  int get reminderHour => _reminderHour;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_keyNotificationsEnabled) ?? true;
    _reminderHour = prefs.getInt(_keyDailyReminderHour) ?? 19;
  }

  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  Future<void> setReminderHour(int hour) async {
    if (hour < 9 || hour > 21) return; // Gece saatlerine izin verme
    _reminderHour = hour;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDailyReminderHour, hour);
  }

  /// Uygun zaman dilimi kontrolü (Sadece 09:00 - 21:30 arası izinli)
  bool isComfortableNotificationTime(DateTime now) {
    if (!_isEnabled) return false;
    final hour = now.hour;
    // 22:00 ile 09:00 arası sessiz mod (uyku ve dinlenme saatleri)
    if (hour >= 22 || hour < 9) {
      return false;
    }
    return true;
  }

  /// Günde sadece 1 kez nazikçe hatırlat
  Future<bool> shouldSendDailyReminder() async {
    if (!_isEnabled) return false;
    final now = DateTime.now();
    if (!isComfortableNotificationTime(now)) return false;

    final prefs = await SharedPreferences.getInstance();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final lastSent = prefs.getString(_keyLastNotificationDate);

    if (lastSent == today) {
      return false; // Bugün zaten gönderildi, kullanıcıyı darlama
    }

    // Hedef saate ulaşıldı mı?
    if (now.hour >= _reminderHour) {
      await prefs.setString(_keyLastNotificationDate, today);
      return true;
    }
    return false;
  }

  /// Sevimli ve motive edici Papağan Fıstık mesajları (Spam değil)
  static final List<String> friendlyMascotReminders = [
    '🦜 Fıstık seni özledi! Günlük serini korumak için 3 dakikalık hızlı bir soru çözelim mi?',
    '🎯 DGS hedefine bir adım daha! Bugünün 5 soruluk pratiği seni bekliyor.',
    '🔥 Günlük çalışma serin yanmasın! Bugünün puanını kapmak için tıkla.',
    '💡 Kısa bir DGS hap bilgisi öğrenmek ister misin? Fıstık hazır!',
  ];
}
