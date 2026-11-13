import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lesson_models.dart';
import '../providers/game_provider.dart';
import '../providers/exam_provider.dart';
import '../providers/theme_provider.dart';
import '../services/friends_quest_service.dart';
import '../services/smart_notification_service.dart';
import '../widgets/parrot_mascot_widget.dart';
import '../widgets/premium_purchase_sheet.dart';
import '../widgets/promo_code_dialog.dart';
import 'leaderboard_screen.dart' show LeagueTier;

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  AchievementCategory? _selectedCategory;

  Widget _buildCategoryChip(String label, AchievementCategory? category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedCategory = category;
          });
        },
        selectedColor: const Color(0xFF10B981).withOpacity(0.15),
        checkmarkColor: const Color(0xFF059669),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
          color: isSelected ? const Color(0xFF059669) : const Color(0xFF475569),
        ),
        backgroundColor: const Color(0xFFF1F5F9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOptionChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF8B5CF6)
                : (isDark ? const Color(0xFF262633) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF8B5CF6)
                  : (isDark ? const Color(0xFF383848) : const Color(0xFFE2E8F0)),
              width: 1.2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFFD4D4D8) : const Color(0xFF475569)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final activeExam = ref.watch(examConfigProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final achievements = ref.watch(achievementsProvider);
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    final filteredAchievements = _selectedCategory == null
        ? achievements
        : achievements.where((a) => a.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121216) : Colors.white,
      appBar: AppBar(
        title: const Text(
          'Profilim',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF6366F1),
            ),
            tooltip: isDark ? 'Açık Temaya Geç' : 'Karanlık Temaya Geç',
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.card_giftcard_rounded, color: Color(0xFF1CB0F6)),
            tooltip: 'Promosyon Kodu',
            onPressed: () => PromoCodeDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Color(0xFF777777)),
            onPressed: () => _showResetDialog(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Kullanıcı Başlık Kartı
            Row(
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF064E3B).withOpacity(0.4) : const Color(0xFFF0FDF4),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF10B981) : const Color(0xFF10B981),
                      width: 3.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: ParrotMascotWidget(
                      size: 78,
                      mood: ParrotMood.happy,
                      hasCrown: profile.isPremium,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${activeExam.shortTitle} Şampiyonu',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: isDark ? const Color(0xFFF4F4F5) : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activeExam.targetExamDateText,
                        style: TextStyle(
                          fontSize: 14.5,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF777777),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                        ),
                        child: Text(
                          'Lv.${profile.level} • ${profile.levelTitle}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Google Üyelik & Hesap Bağlama Kartı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E26) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: FriendsQuestService.instance.isGoogleSignedIn
                      ? const Color(0xFF10B981).withOpacity(0.5)
                      : (isDark ? const Color(0xFF2E2E3C) : const Color(0xFFE2E8F0)),
                  width: 1.5,
                ),
              ),
              child: FriendsQuestService.instance.isGoogleSignedIn
                  ? Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF10B981).withOpacity(0.15),
                          backgroundImage: FriendsQuestService.instance.photoUrl != null
                              ? NetworkImage(FriendsQuestService.instance.photoUrl!)
                              : null,
                          child: FriendsQuestService.instance.photoUrl == null
                              ? const Icon(Icons.person_rounded, color: Color(0xFF10B981), size: 28)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                FriendsQuestService.instance.myDisplayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                '${FriendsQuestService.instance.userEmail ?? ''} • Bulut Senkronize ☁️',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await FriendsQuestService.instance.signOutGoogle();
                            if (mounted) setState(() {});
                          },
                          child: const Text('Çıkış', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4285F4).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.account_circle_rounded, color: Color(0xFF4285F4), size: 26),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hesabını Google ile Bağla',
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const Text(
                                    'İlerlemen, XP ve arkadaş kodun kaybolmasın!',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4285F4),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.login_rounded, size: 18),
                            label: const Text('GOOGLE İLE GİRİŞ YAP', style: TextStyle(fontWeight: FontWeight.w900)),
                            onPressed: () async {
                              final res = await FriendsQuestService.instance.signInWithGoogle(
                                currentXp: profile.xp,
                                currentLevel: profile.level,
                                currentStreak: profile.streak,
                              );
                              if (res.startsWith('OK:') && mounted) {
                                // Başka cihazda kazanılan XP/ders ilerlemesini geri getir
                                await ref.read(userProfileProvider.notifier).pullCloudProgress();
                              }
                              if (!context.mounted) return;
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    res.startsWith('OK:')
                                        ? '🎉 Hoş geldin ${res.substring(3)}! Google hesabın bağlandı.'
                                        : res,
                                  ),
                                  backgroundColor: res.startsWith('OK:') ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 14),

            // RPG Seviye & XP İlerleme Kartı
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Seviye ${profile.level} İlerlemesi',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF92400E),
                        ),
                      ),
                      Text(
                        '${profile.xpIntoCurrentLevel} / ${profile.xpRequiredForNextLevel} XP',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: profile.levelProgress,
                      minHeight: 10,
                      backgroundColor: Colors.grey.withOpacity(0.25),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sonraki seviye (Lv.${profile.level + 1}) için ${profile.xpRequiredForNextLevel - profile.xpIntoCurrentLevel} XP kaldı • Ödül: +15 💎',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 🌙 GÖRÜNÜM & TEMA SEÇİMİ (Karanlık / Açık Mod)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E26) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF2E2E3C) : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF6366F1),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDark ? 'Karanlık Tema 🌙' : 'Açık Tema ☀️',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isDark
                                  ? 'Gece çalışmaları için göz dostu koyu tema aktif.'
                                  : 'Gündüz çalışmaları için aydınlık tema aktif.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: isDark,
                        activeColor: const Color(0xFF8B5CF6),
                        activeTrackColor: const Color(0xFF4C1D95),
                        onChanged: (val) {
                          ref.read(themeModeProvider.notifier).setThemeMode(
                            val ? ThemeMode.dark : ThemeMode.light,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0x1F888888)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildThemeOptionChip(
                        label: '☀️ Açık Mod',
                        isSelected: themeMode == ThemeMode.light,
                        isDark: isDark,
                        onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
                      ),
                      const SizedBox(width: 8),
                      _buildThemeOptionChip(
                        label: '🌙 Koyu Mod',
                        isSelected: themeMode == ThemeMode.dark,
                        isDark: isDark,
                        onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
                      ),
                      const SizedBox(width: 8),
                      _buildThemeOptionChip(
                        label: '⚙️ Sistem',
                        isSelected: themeMode == ThemeMode.system,
                        isDark: isDark,
                        onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // İstatistikler Başlığı
            const Text(
              'İSTATİSTİKLER',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 0.8,
                color: Color(0xFF777777),
              ),
            ),
            const SizedBox(height: 12),

            // 2x2 İstatistik Grid
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: const Color(0xFFFF9600),
                    value: '${profile.streak} Gün',
                    label: 'Günlük Seri',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.bolt_rounded,
                    iconColor: const Color(0xFFFFC800),
                    value: '${profile.xp}',
                    label: 'Toplam XP',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.diamond_rounded,
                    iconColor: const Color(0xFF1CB0F6),
                    value: '${profile.gems}',
                    label: 'Elmas',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Builder(builder: (context) {
                    // Haftalık lig sisteminden gelen gerçek lig
                    final league = LeagueTier.values[FriendsQuestService.instance.myLeague
                        .clamp(0, LeagueTier.values.length - 1)];
                    return _StatCard(
                      icon: Icons.shield_rounded,
                      iconColor: league.color,
                      value: league.title.replaceAll(' Lig', ''),
                      label: 'Mevcut Lig',
                    );
                  }),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // 👑 Super Premium Kartı
            _buildPremiumCard(context, ref, profile),

            const SizedBox(height: 16),

            // 🎁 Promosyon Kodu & İndirim Kartı
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1CB0F6), Color(0xFF0288D1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x331CB0F6),
                    offset: Offset(0, 4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.card_giftcard_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Promosyon Kodu',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'İndirim veya hediye kodunu gir!',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () => PromoCodeDialog.show(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_offer_rounded, color: Color(0xFF1CB0F6), size: 18),
                            SizedBox(width: 8),
                            Text(
                              'KODU GİR & KULLAN',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1CB0F6),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Akıllı & Rahatsız Etmeyen Bildirim Ayarları Kartı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF10B981), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Akıllı Hatırlatıcı 🔔',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            const Text(
                              'Günde sadece 1 kez, rahatsız etmeyen saatte seri uyarısı',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: SmartNotificationService.instance.isEnabled,
                        activeColor: const Color(0xFF10B981),
                        onChanged: (val) async {
                          await SmartNotificationService.instance.setEnabled(val);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  if (SmartNotificationService.instance.isEnabled) ...[
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.bedtime_rounded, size: 16, color: Color(0xFF94A3B8)),
                            SizedBox(width: 6),
                            Text(
                              '22:00 - 09:00 arası otomatik sessiz mod',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                        Text(
                          '${SmartNotificationService.instance.reminderHour}:00',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Başarılar & Rozetler Başlık ve İlerleme
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'BAŞARILAR & ROZETLER',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 0.8,
                    color: Color(0xFF777777),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Text(
                    '🏆 $unlockedCount / ${achievements.length} Açıldı',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Kategori Filtreleri
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('Hepsi', null),
                  _buildCategoryChip('Seri 🔥', AchievementCategory.streak),
                  _buildCategoryChip('Konular 📚', AchievementCategory.lessons),
                  _buildCategoryChip('Kupalar 🏆', AchievementCategory.trophies),
                  _buildCategoryChip('Ustalık 💯', AchievementCategory.mastery),
                  _buildCategoryChip('Hazine 💎', AchievementCategory.gems),
                  _buildCategoryChip('Özel ✨', AchievementCategory.special),
                ],
              ),
            ),
            const SizedBox(height: 14),

            ...filteredAchievements.map((ach) => _AchievementTile(
              achievement: ach,
              onClaim: () {
                final success = ref.read(userProfileProvider.notifier).claimAchievement(
                  ach.id,
                  ach.gemReward,
                  ach.xpReward,
                );
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Text(ach.iconEmoji, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tebrikler! "${ach.title}" ödülü alındı: +${ach.gemReward} 💎 +${ach.xpReward} XP',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
            )),

            const SizedBox(height: 24),

            // Quest Sınav Değiştirici & Versiyon Kartı
            Center(
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          title: Row(
                            children: [
                              Icon(Icons.verified_rounded, color: activeExam.primaryColor),
                              const SizedBox(width: 8),
                              const Text('DGS Quest v1.0.0', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                          content: const Text(
                            '🎯 Resmi ÖSYM DGS Müfredatı\n'
                            '📚 38 Kapsamlı Ünite & 266 Ders\n'
                            '⚡ 100.000+ Güncel Sayısal & Sözel Soru\n'
                            '🧠 Sayısal, Sözel & Mantık Modülleri\n'
                            '👑 Super VIP & Sınırsız Can Desteği',
                            style: TextStyle(fontSize: 14, height: 1.6),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('HARİKA', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: activeExam.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: activeExam.primaryColor.withOpacity(0.35), width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: activeExam.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${activeExam.title} • v1.0.0 Resmi Sürüm',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: activeExam.primaryColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.verified_rounded, size: 16, color: activeExam.primaryColor),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${activeExam.title} • ${activeExam.description} 🎓',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context, WidgetRef ref, UserProfile profile) {
    final isPremium = profile.isPremium;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isPremium
            ? const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20),
        border: isPremium ? Border.all(color: const Color(0xFFFBBF24), width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPremium ? const Color(0xFFFBBF24) : Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: isPremium ? const Color(0xFF4C1D95) : Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPremium ? 'DGS Quest Super VIP 👑' : 'Super VIP\'e Geç 👑',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPremium
                          ? 'Sınırsız can aktif! Canın asla bitmeyecek.'
                          : 'Sınırsız can ile canın bitmeden kesintisiz DGS çalış!',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isPremium) ...[
            const SizedBox(height: 14),
            InkWell(
              onTap: () => PremiumPurchaseSheet.show(context, ref),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium_rounded, color: Color(0xFF7C3AED), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'PREMIUM\'U AKTİF ET (SINIRSIZ CAN)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF7C3AED),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            InkWell(
              onTap: () {
                ref.read(userProfileProvider.notifier).deactivatePremium();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.favorite_rounded, color: Colors.white),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '❤️ Premium kapatıldı, normal 5 canlı moda dönüldü.',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFFE11D48),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white70, width: 1.2),
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'PREMİUM\'U KAPAT (CANLI MODA DÖN)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('İlerlemeyi Sıfırla'),
        content: const Text(
          'Tüm can, streak, XP ve tamamlanan ders verilerini temizlemek istiyor musunuz? (Test için kullanılabilir)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İPTAL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4B4B)),
            onPressed: () {
              ref.read(userProfileProvider.notifier).resetAllProgress();
              Navigator.pop(ctx);
            },
            child: const Text('SIFIRLA', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E26) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2E3C) : const Color(0xFFE5E5E5),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 30),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: isDark ? const Color(0xFFF4F4F5) : const Color(0xFF4B4B4B),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF777777),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback onClaim;

  const _AchievementTile({
    required this.achievement,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final ach = achievement;
    final isDone = ach.isUnlocked;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseCardColor = isDark
        ? (isDone
            ? (ach.isClaimed ? const Color(0xFF1E1E26) : const Color(0xFF064E3B).withOpacity(0.4))
            : const Color(0xFF18181F))
        : (isDone
            ? (ach.isClaimed ? const Color(0xFFF8FAFC) : const Color(0xFFF0FDF4))
            : const Color(0xFFFAFAFA));

    final baseBorderColor = isDark
        ? (isDone
            ? (ach.isClaimed ? const Color(0xFF333342) : const Color(0xFF059669))
            : const Color(0xFF262632))
        : (isDone
            ? (ach.isClaimed ? const Color(0xFFCBD5E1) : const Color(0xFF10B981))
            : const Color(0xFFE2E8F0));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: baseCardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: baseBorderColor,
          width: isDone && !ach.isClaimed ? 2.2 : 1.5,
        ),
        boxShadow: isDone && !ach.isClaimed
            ? [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDone
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(ach.iconEmoji, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            ach.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: isDone
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDone
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '★ Aşama ${ach.tier}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isDone
                                  ? const Color(0xFFB45309)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ach.desc,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isDone && !ach.isClaimed)
                ElevatedButton(
                  onPressed: onClaim,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'ÖDÜLÜ AL',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                  ),
                )
              else if (ach.isClaimed)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded,
                          size: 14, color: Color(0xFF475569)),
                      SizedBox(width: 3),
                      Text(
                        'Alındı',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                )
              else
                const Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFF94A3B8),
                  size: 22,
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ach.progressRatio,
              minHeight: 7,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                isDone ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'İlerleme: ${ach.currentProgress} / ${ach.maxProgress}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.diamond_rounded,
                      size: 13, color: Color(0xFF0284C7)),
                  const SizedBox(width: 2),
                  Text(
                    '+${ach.gemReward}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.bolt_rounded,
                      size: 13, color: Color(0xFFEAB308)),
                  const SizedBox(width: 2),
                  Text(
                    '+${ach.xpReward} XP',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

