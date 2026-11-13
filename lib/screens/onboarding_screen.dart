import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/sound_service.dart';
import '../widgets/parrot_mascot_widget.dart';
import 'leaderboard_screen.dart' show LeagueTier;

/// İlk açılışta Zeki Paşa'nın uygulamayı tanıttığı animasyonlu sayfalar.
class ParrotOnboarding extends StatefulWidget {
  final VoidCallback onDone;
  const ParrotOnboarding({super.key, required this.onDone});

  @override
  State<ParrotOnboarding> createState() => _ParrotOnboardingState();
}

class _OnbPage {
  final String title;
  final String speech;
  final Color color;
  final ParrotMood mood;
  final Widget Function() illustration;
  const _OnbPage(this.title, this.speech, this.color, this.mood, this.illustration);
}

class _ParrotOnboardingState extends State<ParrotOnboarding> {
  final _controller = PageController();
  int _index = 0;

  late final List<_OnbPage> _pages = [
    _OnbPage(
      'Merhaba, ben Zeki Paşa! 🦜',
      'DGS yolculuğunda sana eşlik edeceğim. Hadi sana uygulamayı 1 dakikada tanıtayım!',
      const Color(0xFFF97316),
      ParrotMood.happy,
      () => const _WaveIllustration(),
    ),
    _OnbPage(
      'Her gün kısa dersler 🌱',
      'Sayısal ve Sözel patikasında ünite ünite ilerlersin. Her ders sadece birkaç dakika!',
      const Color(0xFF10B981),
      ParrotMood.idle,
      () => const _PathIllustration(),
    ),
    _OnbPage(
      'Doğru cevap = XP ⚡',
      'Her doğru cevap XP kazandırır. XP topladıkça seviye atlarsın: Çaylak Aday\'dan Efsane Şampiyon\'a!',
      const Color(0xFFF59E0B),
      ParrotMood.happy,
      () => const _XpIllustration(),
    ),
    _OnbPage(
      'Her hafta lig maçı 🏆',
      'Bronz\'dan Elmas\'a 10 lig var! Kendi ligindeki gerçek oyuncularla haftalık XP yarışı: ilk 5 bir üst lige çıkar, çalışmayan düşer.',
      const Color(0xFF6366F1),
      ParrotMood.thinking,
      () => const _LeagueIllustration(),
    ),
    _OnbPage(
      'Seriyi bozma! 🔥',
      'Her gün en az bir ders bitir, serin büyüsün. Yanlış cevaplar kalp götürür, dikkatli ol!',
      const Color(0xFFEF4444),
      ParrotMood.oops,
      () => const _StreakIllustration(),
    ),
    _OnbPage(
      'Arkadaşlarınla oyna 🤝',
      'Arkadaş kodunu paylaş, birlikte 500 XP\'lik ortak görevleri tamamlayın ve ligde kapışın!',
      const Color(0xFF0EA5E9),
      ParrotMood.happy,
      () => const _FriendsIllustration(),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_index < _pages.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
    } else {
      SoundService.playLessonPass();
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_index];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLast = _index == _pages.length - 1;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [page.color.withValues(alpha: 0.30), const Color(0xFF121216)]
                : [page.color.withValues(alpha: 0.22), const Color(0xFFFAF8F5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Üst bar: ilerleme + atla
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(end: (_index + 1) / _pages.length),
                          duration: const Duration(milliseconds: 400),
                          builder: (context, v, child) => LinearProgressIndicator(
                            value: v,
                            minHeight: 10,
                            color: page.color,
                            backgroundColor: page.color.withValues(alpha: 0.18),
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: isLast ? null : widget.onDone,
                      child: Text(
                        isLast ? '' : 'Atla',
                        style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white70 : const Color(0xFF78716C)),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => _OnbPageView(key: ValueKey(i), page: _pages[i], isDark: isDark),
                ),
              ),
              // Sayfa noktaları
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < _pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _index ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index ? page.color : page.color.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: page.color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: Text(
                      isLast ? 'HAYDİ BAŞLAYALIM! 🚀' : 'DEVAM',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnbPageView extends StatelessWidget {
  final _OnbPage page;
  final bool isDark;
  const _OnbPageView({super.key, required this.page, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Papağan + konuşma balonu
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Animate(
                onPlay: (c) => c.repeat(reverse: true),
                child: Animate(child: ParrotMascotWidget(size: 96, mood: page.mood))
                    .scale(begin: const Offset(0.3, 0.3), duration: 700.ms, curve: Curves.elasticOut)
                    .then()
                    .shake(hz: 2.5, rotation: 0.06, duration: 600.ms),
              ).moveY(begin: -4, end: 4, duration: 1300.ms, curve: Curves.easeInOut),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF26262F) : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4),
                    ),
                    border: Border.all(color: page.color.withValues(alpha: 0.35), width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: _TypewriterText(
                    text: page.speech,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF292524),
                    ),
                  ),
                ).animate().fadeIn(delay: 250.ms, duration: 300.ms).slideX(begin: -0.08, end: 0),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1C1917)),
          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.3, end: 0, curve: Curves.easeOutBack),
          const SizedBox(height: 22),
          page.illustration().animate().fadeIn(delay: 450.ms, duration: 400.ms).scale(
                begin: const Offset(0.9, 0.9),
                delay: 450.ms,
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Harf harf yazılan konuşma metni.
class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _TypewriterText({required this.text, required this.style});

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  int _shown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 22), (t) {
      if (!mounted) return;
      setState(() => _shown = (_shown + 1).clamp(0, widget.text.length));
      if (_shown >= widget.text.length) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Görünmeyen kısmı şeffaf yazarak balonun boyutu baştan sabit kalır.
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: widget.text.substring(0, _shown), style: widget.style),
        TextSpan(text: widget.text.substring(_shown), style: widget.style.copyWith(color: Colors.transparent)),
      ]),
    );
  }
}

// ----------------------- İllüstrasyonlar -----------------------

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E26) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: child,
    );
  }
}

class _WaveIllustration extends StatelessWidget {
  const _WaveIllustration();

  @override
  Widget build(BuildContext context) {
    const items = ['📚', '🧠', '🎯', '🏆', '⚡', '🌱'];
    return _Card(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 14,
        runSpacing: 14,
        children: [
          for (int i = 0; i < items.length; i++)
            Animate(
              onPlay: (c) => c.repeat(reverse: true),
              child: Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(items[i], style: const TextStyle(fontSize: 30)),
              )
                  .animate(delay: (600 + i * 120).ms)
                  .scale(begin: const Offset(0, 0), curve: Curves.elasticOut, duration: 700.ms),
            ).moveY(begin: 0, end: -5, duration: (900 + i * 90).ms, curve: Curves.easeInOut),
        ],
      ),
    );
  }
}

class _PathIllustration extends StatelessWidget {
  const _PathIllustration();

  Widget _node(String emoji, Color color, {bool active = false, bool locked = false}) {
    Widget n = Container(
      width: active ? 74 : 62,
      height: active ? 74 : 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: locked ? const Color(0xFFE5E7EB) : color,
        shape: BoxShape.circle,
        boxShadow: locked ? null : [BoxShadow(color: color.withValues(alpha: 0.45), offset: const Offset(0, 5))],
      ),
      child: Text(locked ? '🔒' : emoji, style: TextStyle(fontSize: active ? 32 : 26)),
    );
    if (active) {
      n = n
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 800.ms, curve: Curves.easeInOut);
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF10B981);
    return _Card(
      child: Column(
        children: [
          Align(alignment: const Alignment(-0.5, 0), child: _node('✅', green)),
          const SizedBox(height: 10),
          Align(alignment: const Alignment(0.3, 0), child: _node('✅', green)),
          const SizedBox(height: 10),
          Align(alignment: const Alignment(-0.1, 0), child: _node('⭐', const Color(0xFFF59E0B), active: true)),
          const SizedBox(height: 10),
          Align(alignment: const Alignment(0.5, 0), child: _node('', green, locked: true)),
        ],
      ),
    );
  }
}

class _XpIllustration extends StatefulWidget {
  const _XpIllustration();

  @override
  State<_XpIllustration> createState() => _XpIllustrationState();
}

class _XpIllustrationState extends State<_XpIllustration> {
  int _xp = 60;
  int _level = 1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!mounted) return;
      setState(() {
        _xp += 10;
        if (_xp >= 100) {
          _xp = 0;
          _level++;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFF59E0B);
    return _Card(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: amber, shape: BoxShape.circle),
                child: Text('Lv.$_level', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              ).animate(key: ValueKey(_level)).scale(begin: const Offset(1.4, 1.4), curve: Curves.elasticOut, duration: 600.ms),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_level == 1 ? 'Çaylak Aday 🐣' : 'DGS Kaşifi 🧭',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: _xp / 100),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, v, child) => LinearProgressIndicator(
                          value: v,
                          minHeight: 14,
                          color: amber,
                          backgroundColor: amber.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('$_xp / 100 XP', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('+10 XP ⚡', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: amber))
              .animate(key: ValueKey('xp$_xp$_level'))
              .fadeIn(duration: 150.ms)
              .moveY(begin: 10, end: -6, duration: 600.ms)
              .then()
              .fadeOut(duration: 250.ms),
        ],
      ),
    );
  }
}

class _LeagueIllustration extends StatelessWidget {
  const _LeagueIllustration();

  @override
  Widget build(BuildContext context) {
    const tiers = LeagueTier.values;
    return _Card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (int i = 0; i < tiers.length; i++)
                Column(
                  children: [
                    Text(tiers[i].icon, style: TextStyle(fontSize: 13.0 + i * 1.2)),
                    const SizedBox(height: 4),
                    Container(
                      width: 20,
                      height: 16.0 + i * 9,
                      decoration: BoxDecoration(
                        color: tiers[i].color,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ),
                  ],
                ).animate(delay: (400 + i * 110).ms).fadeIn().slideY(begin: 0.6, end: 0, curve: Curves.easeOutBack),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('⬆ İlk 5 yükselir', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
              SizedBox(width: 16),
              Text('⬇ Çalışmayan düşer', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFEF4444))),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakIllustration extends StatelessWidget {
  const _StreakIllustration();

  @override
  Widget build(BuildContext context) {
    const days = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'];
    return _Card(
      child: Column(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 56))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(0.92, 0.92), end: const Offset(1.08, 1.08), duration: 700.ms),
          const Text('7 günlük seri!', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFFEA580C))),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int i = 0; i < days.length; i++)
                Column(
                  children: [
                    Text(days[i], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 4),
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: Color(0xFFF97316), shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                    ).animate(delay: (500 + i * 120).ms).scale(begin: const Offset(0, 0), curve: Curves.elasticOut, duration: 600.ms),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < 5; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Text(i < 4 ? '❤️' : '💔', style: const TextStyle(fontSize: 22)),
                ),
            ],
          ).animate(delay: 1400.ms).shake(hz: 4, duration: 500.ms),
        ],
      ),
    );
  }
}

class _FriendsIllustration extends StatefulWidget {
  const _FriendsIllustration();

  @override
  State<_FriendsIllustration> createState() => _FriendsIllustrationState();
}

class _FriendsIllustrationState extends State<_FriendsIllustration> {
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _progress = 0.72);
    });
  }

  Widget _avatar(String emoji, String name, Color color) => Column(
        children: [
          CircleAvatar(radius: 28, backgroundColor: color.withValues(alpha: 0.18), child: Text(emoji, style: const TextStyle(fontSize: 28))),
          const SizedBox(height: 4),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF0EA5E9);
    return _Card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _avatar('😎', 'Sen', blue).animate().slideX(begin: -0.6, end: 0, delay: 400.ms, curve: Curves.easeOutBack),
              const Text('🤝', style: TextStyle(fontSize: 34))
                  .animate(delay: 800.ms)
                  .scale(begin: const Offset(0, 0), curve: Curves.elasticOut, duration: 800.ms),
              _avatar('🤓', 'Arkadaşın', const Color(0xFF8B5CF6))
                  .animate()
                  .slideX(begin: 0.6, end: 0, delay: 400.ms, curve: Curves.easeOutBack),
            ],
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Ortak Görev: 500 XP', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: _progress),
              duration: const Duration(milliseconds: 1400),
              curve: Curves.easeOutCubic,
              builder: (context, v, child) => LinearProgressIndicator(
                value: v,
                minHeight: 14,
                color: blue,
                backgroundColor: blue.withValues(alpha: 0.18),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: blue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: blue.withValues(alpha: 0.4)),
            ),
            child: const Text('Arkadaş kodun: DGS-7K2P', style: TextStyle(fontWeight: FontWeight.w900, color: blue)),
          ),
        ],
      ),
    );
  }
}
