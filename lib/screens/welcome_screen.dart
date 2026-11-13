import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/exam_provider.dart';
import '../providers/game_provider.dart';
import '../services/friends_quest_service.dart';
import '../services/sound_service.dart';
import '../widgets/parrot_mascot_widget.dart';
import 'main_navigation_screen.dart';
import 'onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama açılışında Zeki Paşa'nın "Hoş geldin" animasyonu.
/// Google hesabı bağlı değilse "Google ile Bağlan" seçeneği sunar.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  static const _greetings = [
    'Hoş geldin Paşam! 🦜',
    'Bugün netleri uçuruyoruz! 🚀',
    'Hazırsan patikaya çıkalım! 🌱',
  ];

  bool _authChecked = false;
  bool _isLinked = false;
  bool _isSigningIn = false;
  bool _navigated = false;
  String? _errorText;
  Timer? _autoContinue;
  late final String _subGreeting = _greetings[Random().nextInt(_greetings.length)];

  static const _keyOnboardingSeen = 'onboarding_seen_v1';

  /// null: henüz okunmadı, true: ilk açılış tanıtımı gösteriliyor
  bool? _showOnboarding;

  @override
  void initState() {
    super.initState();
    _loadOnboardingFlag();
    _checkAuth();
  }

  Future<void> _loadOnboardingFlag() async {
    bool seen = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      seen = prefs.getBool(_keyOnboardingSeen) ?? false;
    } catch (_) {}
    if (!mounted) return;
    setState(() => _showOnboarding = !seen);
    if (seen) {
      SoundService.playCorrect();
      // Google girişi kontrolü bu bayraktan önce bittiyse otomatik geçişi burada başlat
      if (_isLinked && _autoContinue == null) {
        _autoContinue = Timer(const Duration(milliseconds: 2600), _goHome);
      }
    }
  }

  Future<void> _finishOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyOnboardingSeen, true);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _showOnboarding = false);
    if (_isLinked && _autoContinue == null) {
      _autoContinue = Timer(const Duration(milliseconds: 2600), _goHome);
    }
  }

  Future<void> _checkAuth() async {
    // Firebase en fazla ~8 sn bekletir; çevrimdışıysa yine de devam edilir.
    await FriendsQuestService.instance.ensureInitialized();
    if (!mounted) return;
    final linked = FriendsQuestService.instance.isGoogleSignedIn;
    setState(() {
      _authChecked = true;
      _isLinked = linked;
    });
    if (linked && _showOnboarding == false) {
      // Bağlı kullanıcıyı kısa bir selamdan sonra otomatik içeri al.
      // (Tanıtım gösteriliyorsa, bitince _finishOnboarding başlatır.)
      _autoContinue = Timer(const Duration(milliseconds: 2600), _goHome);
    }
  }

  @override
  void dispose() {
    _autoContinue?.cancel();
    super.dispose();
  }

  void _goHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _autoContinue?.cancel();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, secondaryAnimation) => const MainNavigationScreen(),
        transitionsBuilder: (context, anim, secondaryAnimation, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    if (_isSigningIn) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _isSigningIn = true;
      _errorText = null;
    });

    final profile = ref.read(userProfileProvider);
    final res = await FriendsQuestService.instance.signInWithGoogle(
      currentXp: profile.xp,
      currentLevel: profile.level,
      currentStreak: profile.streak,
    );
    if (!mounted) return;

    final success = res.startsWith('OK:');
    if (success) {
      // Başka cihazda kazanılan XP/ders ilerlemesini geri getir
      await ref.read(userProfileProvider.notifier).pullCloudProgress();
      if (!mounted) return;
      SoundService.playCorrect();
      setState(() {
        _isSigningIn = false;
        _isLinked = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Hoş geldin ${res.substring(3)}! Google hesabın bağlandı.'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _autoContinue = Timer(const Duration(milliseconds: 1400), _goHome);
    } else {
      setState(() {
        _isSigningIn = false;
        _errorText = res == 'Giriş iptal edildi.' ? null : res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    if (_showOnboarding == true) {
      return ParrotOnboarding(onDone: _finishOnboarding);
    }
    final activeExam = ref.watch(examConfigProvider);
    final profile = ref.watch(userProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = FriendsQuestService.instance.myDisplayName;
    final firstName = name.split(' ').first;
    final hasCustomName = name != 'DGS Öğrencisi' && name != 'DGS Şampiyonu';

    final title = _isLinked && hasCustomName ? 'Tekrar hoş geldin, $firstName!' : 'Hoş geldin!';

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _isLinked ? _goHome : null,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [const Color(0xFF1E1B2E), const Color(0xFF121216)]
                  : [activeExam.primaryColor.withValues(alpha: 0.16), const Color(0xFFFAF8F5)],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Uçuşan tüyler & yıldızlar
                ..._buildFloatingDecor(activeExam.primaryColor, activeExam.secondaryColor),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const Spacer(flex: 3),

                      // Konuşma balonu
                      _SpeechBubble(text: _subGreeting, isDark: isDark)
                          .animate()
                          .fadeIn(delay: 900.ms, duration: 400.ms)
                          .slideY(begin: 0.4, end: 0, delay: 900.ms, duration: 400.ms, curve: Curves.easeOutBack),

                      const SizedBox(height: 14),

                      // Zeki Paşa: içeri zıplayarak gelir, el sallar gibi sallanır, sonra süzülür
                      // Not: ParrotMascotWidget'ın kendi "animate" alanı olduğu için
                      // .animate() yerine Animate(...) ile açıkça sarmalanıyor.
                      Animate(
                        onPlay: (c) => c.repeat(reverse: true),
                        child: Animate(
                          child: ParrotMascotWidget(size: 170, mood: ParrotMood.happy, hasCrown: profile.isPremium),
                        )
                            .scale(
                              begin: const Offset(0.2, 0.2),
                              end: const Offset(1, 1),
                              duration: 900.ms,
                              curve: Curves.elasticOut,
                            )
                            .fadeIn(duration: 300.ms)
                            .then(delay: 150.ms)
                            .shake(hz: 3, rotation: 0.08, duration: 700.ms),
                      ).moveY(begin: -6, end: 6, duration: 1400.ms, curve: Curves.easeInOut),

                      const SizedBox(height: 26),

                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF292524),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 500.ms, duration: 450.ms)
                          .slideY(begin: 0.3, end: 0, delay: 500.ms, duration: 450.ms),

                      const SizedBox(height: 8),

                      Text(
                        '${activeExam.title} • ${activeExam.targetExamDateText}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF78716C),
                        ),
                      ).animate().fadeIn(delay: 700.ms, duration: 450.ms),

                      if (profile.streak > 0) ...[
                        const SizedBox(height: 14),
                        _StreakChip(streak: profile.streak)
                            .animate()
                            .fadeIn(delay: 1100.ms)
                            .scale(begin: const Offset(0.7, 0.7), delay: 1100.ms, curve: Curves.easeOutBack),
                      ],

                      const Spacer(flex: 3),

                      _buildActions(isDark, activeExam.primaryColor),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(bool isDark, Color primary) {
    if (!_authChecked) {
      return const SizedBox(
        height: 110,
        child: Center(child: SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 3))),
      );
    }

    if (_isLinked) {
      return SizedBox(
        height: 110,
        child: Center(
          child: Text(
            'Devam etmek için dokun 👆',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF78716C),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 900.ms),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Arkadaşlarınla yarışmak, ligde puan toplamak ve ilerlemeni kaybetmemek için hesabını bağla.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.35,
            color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF78716C),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isSigningIn ? null : _signInWithGoogle,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1F1F1F),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFDADCE0), width: 1.2),
              ),
            ),
            child: _isSigningIn
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _GoogleGLogo(),
                      SizedBox(width: 12),
                      Text('Google ile Bağlan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ],
                  ),
          ),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 10),
          Text(
            _errorText!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFFEF4444)),
          ),
        ],
        const SizedBox(height: 6),
        TextButton(
          onPressed: _isSigningIn ? null : _goHome,
          child: Text(
            'Şimdilik geç',
            style: TextStyle(fontWeight: FontWeight.w800, color: primary),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 1200.ms, duration: 400.ms).slideY(begin: 0.25, end: 0, delay: 1200.ms);
  }

  List<Widget> _buildFloatingDecor(Color a, Color b) {
    const items = ['✨', '🍃', '⭐', '🌱', '✨', '🍃'];
    const positions = [
      Alignment(-0.85, -0.75),
      Alignment(0.8, -0.6),
      Alignment(-0.7, 0.05),
      Alignment(0.85, 0.15),
      Alignment(-0.3, -0.92),
      Alignment(0.4, -0.88),
    ];
    return List.generate(items.length, (i) {
      return Align(
        alignment: positions[i],
        child: Animate(
          onPlay: (c) => c.repeat(reverse: true),
          child: Animate(
            delay: (200 * i).ms,
            child: Text(items[i], style: TextStyle(fontSize: 18 + (i % 3) * 4.0)),
          ).fadeIn(duration: 600.ms),
        )
            .moveY(begin: -8, end: 8, duration: (1600 + i * 250).ms, curve: Curves.easeInOut)
            .rotate(begin: -0.05, end: 0.05, duration: (1600 + i * 250).ms),
      );
    });
  }
}

class _SpeechBubble extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SpeechBubble({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A36) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF3A3A48) : const Color(0xFFE7E1D8), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : const Color(0xFF1E293B),
        ),
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  final int streak;
  const _StreakChip({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDD5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDBA74)),
      ),
      child: Text(
        '🔥 $streak günlük seri — bozma!',
        style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFEA580C)),
      ),
    );
  }
}

/// Paket gerektirmeyen basit Google "G" logosu.
class _GoogleGLogo extends StatelessWidget {
  const _GoogleGLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: ShaderMask(
        shaderCallback: (rect) => const SweepGradient(
          colors: [Color(0xFF4285F4), Color(0xFF34A853), Color(0xFFFBBC05), Color(0xFFEA4335), Color(0xFF4285F4)],
        ).createShader(rect),
        child: const Text(
          'G',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, height: 1),
        ),
      ),
    );
  }
}
