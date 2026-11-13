import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_lessons.dart';
import '../models/lesson_models.dart';
import '../providers/game_provider.dart';
import '../services/ad_service.dart';
import '../services/smart_learning_engine.dart';
import '../services/sound_service.dart';
import '../widgets/duo_button.dart';
import 'dgs_mock_exam_screen.dart';
import 'fast_reflex_screen.dart';
import 'flashcards_screen.dart';
import 'quiz_screen.dart';

class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Pratik & Can Kazan',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Can Durum Kartı (Duolingo Stili)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3F1316) : const Color(0xFFFFDFE0),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFFB4B6),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFFF4B4B),
                    size: 54,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mevcut Can: ${profile.hearts} / 5',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFD32F2F),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.hearts < 5
                              ? 'Pratik testini tamamlayarak +1 Can kazanabilirsin!'
                              : 'Canların tamamen dolu! Bilgilerini taze tutmak için pratik yap.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF4B4B4B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Ebbinghaus Akıllı Öğrenme Tavsiye Kartı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(0.35),
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
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'EBBINGHAUS AKILLI ÖĞRENME 🧠',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    SmartLearningEngine.instance.getDailySmartAdvice(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4F46E5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.replay_rounded, size: 18),
                      label: Text(
                        SmartLearningEngine.instance.totalDueForReview > 0
                            ? 'VADESİ GELEN ${SmartLearningEngine.instance.totalDueForReview} SORUYU ÇÖZ'
                            : 'AKILLI TEKRAR SEPETİNİ ÇÖZ',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                      onPressed: () {
                        final due = SmartLearningEngine.instance.getDueQuestions(limit: 10);
                        final questionsToSolve = due.isNotEmpty
                            ? due
                            : mockUnits
                                .expand((u) => u.lessons)
                                .expand((l) => l.questions)
                                .where((q) => q.type != QuestionType.conceptCard)
                                .take(10)
                                .toList();

                        final reviewLesson = Lesson(
                          id: 'ebbinghaus_review_${DateTime.now().millisecondsSinceEpoch}',
                          title: 'Ebbinghaus Akıllı Tekrar',
                          description: 'Unutma eğrisine göre optimize edilmiş hafıza pekiştirme',
                          xpReward: 30,
                          gemReward: 12,
                          questions: questionsToSolve,
                        );

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => QuizScreen(lesson: reviewLesson),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // GÖRÜNCE YAPIŞTIR! ⚡ (Hızlı Refleks & Şifre Oyunu)
            _buildActionCard(
              context: context,
              title: 'Görünce Yapıştır! ⚡',
              subtitle: 'Kuralı gör, cevabı anında yapıştır! Kombo yap, rekor kır ve sınav formüllerini ezberle.',
              icon: Icons.bolt_rounded,
              iconColor: const Color(0xFFF59E0B),
              buttonText: 'REFLEKS OYNA ⚡',
              buttonColor: DuoButtonColor.green,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FastReflexScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Hızlı Pratik Modu Kartı
            _buildActionCard(
              context: context,
              title: 'Hızlı Soru Pratiği (10 Soru)',
              subtitle: 'DGS Sayısal ve Sözel Mantık karışık 10 soruluk set çöz, hem XP hem de +1 Can kazan.',
              icon: Icons.flash_on_rounded,
              iconColor: const Color(0xFFFF9600),
              buttonText: 'PRATİĞE BAŞLA',
              buttonColor: DuoButtonColor.green,
              onTap: () {
                final allQuizQuestions = mockUnits
                    .expand((u) => u.lessons)
                    .expand((l) => l.questions)
                    .where((q) => q.type != QuestionType.conceptCard)
                    .toList();
                allQuizQuestions.shuffle();
                final practiceQuestions = allQuizQuestions.take(10).toList();

                // Karışık pratik dersi oluştur
                final practiceLesson = Lesson(
                  id: 'practice_mixed_${DateTime.now().millisecondsSinceEpoch}',
                  title: 'Hızlı Pratik',
                  description: 'Can kazanma ve genel tekrar modu',
                  xpReward: 25,
                  gemReward: 10,
                  questions: practiceQuestions,
                );

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => QuizScreen(lesson: practiceLesson),
                  ),
                ).then((_) {
                  // Pratik sonrası can tazele
                  ref.read(userProfileProvider.notifier).gainHeart();
                });
              },
            ),

            const SizedBox(height: 16),

            // DGS RESMİ DENEME SINAVI MODÜLÜ (135 DK & OPTİK FORM)
            _buildActionCard(
              context: context,
              title: 'DGS Resmi Deneme Sınavı 📝',
              subtitle: '135 dakika, soru numarası gezgini ve optik form hissiyle gerçek DGS provası yap!',
              icon: Icons.assignment_turned_in_rounded,
              iconColor: const Color(0xFF6366F1),
              buttonText: 'DENEME MODUNA GİR',
              buttonColor: DuoButtonColor.purple,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (ctx) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('DGS DENEME TÜRÜNÜ SEÇ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF6366F1),
                            child: Icon(Icons.timer_rounded, color: Colors.white),
                          ),
                          title: const Text('Tam DGS Denemesi (100 Soru)', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('135 Dakika resmi ÖSYM süresi • 4 Yanlış 1 Doğruyu Götürür'),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const DgsMockExamScreen(examType: MockExamType.fullDgs),
                              ),
                            );
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF10B981),
                            child: Icon(Icons.flash_on_rounded, color: Colors.white),
                          ),
                          title: const Text('Hızlı Prova Denemesi (30 Soru)', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('40 Dakika hızlandırma seti • Hızlı net analizi'),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const DgsMockExamScreen(examType: MockExamType.miniDgs),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // DGS 50.000+ Soru Maratonu
            _buildActionCard(
              context: context,
              title: '100.000+ Soru Maratonu 🏆',
              subtitle: '100.000+ soruluk dev DGS Sayısal & Sözel havuzundan rastgele 25 karma soru ile kapsamlı sınav provası yap.',
              icon: Icons.military_tech_rounded,
              iconColor: const Color(0xFF10B981),
              buttonText: 'MARATONU BAŞLAT',
              buttonColor: DuoButtonColor.green,
              onTap: () {
                final allPool = mockUnits
                    .expand((u) => u.lessons)
                    .expand((l) => l.questions)
                    .where((q) => q.type != QuestionType.conceptCard)
                    .toList()
                  ..shuffle();
                final marathonQuestions = allPool.take(25).toList();

                final marathonLesson = Lesson(
                  id: 'marathon_${DateTime.now().millisecondsSinceEpoch}',
                  title: '50.000+ DGS Maratonu',
                  description: '25 Soruluk Genel DGS Karma Denemesi',
                  xpReward: 100,
                  gemReward: 30,
                  questions: marathonQuestions,
                  isUnitExam: true,
                );

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => QuizScreen(lesson: marathonLesson),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Kartlarla Pekiştir Modu (Flaş Kartlar)
            _buildActionCard(
              context: context,
              title: 'Kartlarla Pekiştir 🎴',
              subtitle: 'DGS Sayısal Mantık, Sözel Mantık ve Geometri kavram kartlarını çevir, formülleri pekiştir!',
              icon: Icons.style_rounded,
              iconColor: const Color(0xFF7C3AED),
              buttonText: 'KARTLARI ÇEVİR',
              buttonColor: DuoButtonColor.purple,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FlashcardsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Hata Defteri Modu
            _buildActionCard(
              context: context,
              title: 'Hata Defteri & Tekrar',
              subtitle: 'Önceki testlerde yanlış yaptığın veya boş bıraktığın sorular burada toplanır.',
              icon: Icons.auto_stories_rounded,
              iconColor: const Color(0xFF1CB0F6),
              buttonText: 'HATALARI TEKRAR ET',
              buttonColor: DuoButtonColor.blue,
              onTap: () {
                final allQuestions = mockUnits
                    .expand((u) => u.lessons)
                    .expand((l) => l.questions)
                    .where((q) => q.type != QuestionType.conceptCard)
                    .toList()
                  ..shuffle();
                final mistakeQuestions = allQuestions.take(5).toList();

                final mistakeLesson = Lesson(
                  id: 'practice_mistakes_${DateTime.now().millisecondsSinceEpoch}',
                  title: 'Hata Defteri',
                  description: 'Daha önce takıldığın kavramları pekiştir',
                  xpReward: 20,
                  gemReward: 8,
                  questions: mistakeQuestions,
                );
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => QuizScreen(lesson: mistakeLesson),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Video Reklam İzle & Can Kazan (Rewarded Video)
            if (!profile.isPremium)
              _buildActionCard(
                context: context,
                title: 'Video İzle & Can Kazan 🎥',
                subtitle: 'Kısa bir sponsorlu video izleyerek anında +1 Can ve +5 Elmas kazan!',
                icon: Icons.play_circle_fill_rounded,
                iconColor: const Color(0xFFF59E0B),
                buttonText: 'VİDEO İZLE (+1 ❤️ & +5 💎)',
                buttonColor: DuoButtonColor.purple,
                onTap: () {
                  AdService.instance.showRewardedAd(
                    onUserEarnedReward: (amount) {
                      ref.read(userProfileProvider.notifier).gainHeart();
                      ref.read(userProfileProvider.notifier).addGems(5);
                      SoundService.playCorrect();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.favorite_rounded, color: Colors.white),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tebrikler! +1 Can ve +5 💎 hesabına yüklendi.',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      );
                    },
                    onFailed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Reklam yüklenemedi veya henüz hazır değil. Lütfen biraz sonra tekrar dene.'),
                          backgroundColor: const Color(0xFFEF4444),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      );
                    },
                  );
                },
              ),

            const SizedBox(height: 24),

            // Günün DGS Hap Bilgisi
            const Text(
              'GÜNÜN DGS HAP BİLGİSİ 💡',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 0.8,
                color: Color(0xFF777777),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_rounded, color: Color(0xFFFFC800), size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Sayısal & Sözel Mantık Püf Noktası',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'DGS Sözel Mantık tablolarında daima sayısı az ve sabit olan değişkeni (günler, katlar veya sıralar) tablonun ana başlığı yap! Sayısal mantıkta ise ilk soruda bulduğun kuralı diğer öncüllere taşıyarak süreden %50 tasarruf edebilirsin.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF4B4B4B), height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String buttonText,
    required DuoButtonColor buttonColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E26) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2E3C) : const Color(0xFFE5E5E5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: isDark ? const Color(0xFFF4F4F5) : const Color(0xFF4B4B4B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF777777),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DuoButton(
            text: buttonText,
            color: buttonColor,
            height: 46,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}
