import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lesson_models.dart';
import '../providers/game_provider.dart';
import '../services/sound_service.dart';

class ReflexQuestion {
  final String prompt;
  final String triggerWord;
  final String correctAnswer;
  final List<String> wrongOptions;
  final String memoryCode;
  final String subject;

  const ReflexQuestion({
    required this.prompt,
    required this.triggerWord,
    required this.correctAnswer,
    required this.wrongOptions,
    required this.memoryCode,
    required this.subject,
  });
}

final List<ReflexQuestion> dgsReflexBank = [
  const ReflexQuestion(
    prompt: "Matematikte iki insan arasındaki yaş farkı zaman geçtikçe ne olur?",
    triggerWord: "Yaş Problemleri Sırrı",
    correctAnswer: "Asla Değişmez (Daima Sabittir)",
    wrongOptions: [
      "Yıl geçtikçe yaş farkı artar",
      "Yaş farkı ikiye katlanır",
      "Büyüğün lehine azalır"
    ],
    memoryCode: "İki kişi arasındaki yaş farkı DAİMA SABİTTİR!",
    subject: "DGS Problemler",
  ),
  const ReflexQuestion(
    prompt: "0 < a < 1 aralığındaki basit kesir sayılarda karesi ile kendisi kıyası?",
    triggerWord: "a² < a Kuralı",
    correctAnswer: "Karesi Kendisinden Küçüktür (a² < a)",
    wrongOptions: [
      "Karesi kendisinden büyüktür (a² > a)",
      "Karesi her zaman 1'e eşittir",
      "Karesi negatif olur"
    ],
    memoryCode: "Örnek: a = 1/2 ise a² = 1/4 olur; 1/4 < 1/2!",
    subject: "DGS Temel Matematik",
  ),
  const ReflexQuestion(
    prompt: "En küçük asal sayı ve tek çift asal sayı hangisidir?",
    triggerWord: "Tek Çift Asal",
    correctAnswer: "2 Sayısı",
    wrongOptions: [
      "1 Sayısı",
      "0 Sayısı",
      "3 Sayısı"
    ],
    memoryCode: "1 asal değildir; en küçük asal ve tek çift asal 2'dir!",
    subject: "DGS Temel Matematik",
  ),
  const ReflexQuestion(
    prompt: "İki kare farkı özdeşliği formülü nedir?",
    triggerWord: "a² - b²",
    correctAnswer: "(a - b)(a + b)",
    wrongOptions: [
      "(a - b)²",
      "a² - 2ab + b²",
      "(a + b)³"
    ],
    memoryCode: "a² - b² = (a - b)(a + b)!",
    subject: "DGS Temel Matematik",
  ),
  const ReflexQuestion(
    prompt: "Tam kare özdeşliği (a + b)² açılımı nedir?",
    triggerWord: "(a + b)²",
    correctAnswer: "a² + 2ab + b²",
    wrongOptions: [
      "a² + b²",
      "a² - 2ab + b²",
      "a² + ab + b²"
    ],
    memoryCode: "Birincinin karesi + İkisinin çarpımının 2 katı + İkincinin karesi!",
    subject: "DGS Temel Matematik",
  ),
  const ReflexQuestion(
    prompt: "Bir sayının 9 ile tam bölünebilmesi için ne gerekir?",
    triggerWord: "9 ile Bölünebilme",
    correctAnswer: "Rakamları Toplamı 9 veya Katı Olmalıdır",
    wrongOptions: [
      "Son basamağı 9 olmalıdır",
      "Son iki basamağı 09 olmalıdır",
      "Sayı tek sayı olmalıdır"
    ],
    memoryCode: "3 ve 9 kuralları doğrudan RAKAMLAR TOPLAMI ile ilgilidir!",
    subject: "DGS Temel Matematik",
  ),
  const ReflexQuestion(
    prompt: "Bir sayının 4 ile tam bölünebilmesi için hangi kural aranır?",
    triggerWord: "4 ile Bölünebilme",
    correctAnswer: "Son İki Basamağı 00 veya 4'ün Katı Olmalıdır",
    wrongOptions: [
      "Son basamağı çift olmalıdır",
      "Rakamları toplamı 4 olmalıdır",
      "İlk iki basamağı 4 olmalıdır"
    ],
    memoryCode: "4 ile bölünebilmede sadece SON İKİ BASAMAĞA bakılır!",
    subject: "DGS Temel Matematik",
  ),
  const ReflexQuestion(
    prompt: "Ardışık terimleri eşit artan bir dizide Terim Sayısı formülü?",
    triggerWord: "Terim Sayısı Formülü",
    correctAnswer: "[(Son Terim - İlk Terim) / Artış Miktarı] + 1",
    wrongOptions: [
      "(Son Terim + İlk Terim) / 2",
      "(Son Terim - İlk Terim) / 2",
      "Son Terim x İlk Terim"
    ],
    memoryCode: "TS = [(Son - İlk) / Artış] + 1!",
    subject: "DGS Temel Matematik",
  ),
  const ReflexQuestion(
    prompt: "1'den n'ye kadar ardışık doğal sayıların toplamı formülü?",
    triggerWord: "1 + 2 + ... + n",
    correctAnswer: "n x (n + 1) / 2",
    wrongOptions: [
      "n²",
      "n x (n - 1) / 2",
      "(n + 1)²"
    ],
    memoryCode: "Gauss Toplamı: n x (n + 1) / 2!",
    subject: "DGS Temel Matematik",
  ),
  const ReflexQuestion(
    prompt: "1'den (2n - 1)'e kadar ardışık tek sayıların toplamı nedir?",
    triggerWord: "1 + 3 + 5 + ... + (2n-1)",
    correctAnswer: "n²",
    wrongOptions: [
      "n x (n + 1)",
      "2n²",
      "n³"
    ],
    memoryCode: "Ardışık tek sayılar toplamı = Terim sayısının KARESİDİR (n²)!",
    subject: "DGS Temel Matematik",
  ),
  const ReflexQuestion(
    prompt: "Hız problemlerinde temel bağıntı nedir?",
    triggerWord: "Yol - Hız - Zaman",
    correctAnswer: "Yol = Hız x Zaman (X = V x t)",
    wrongOptions: [
      "Hız = Yol x Zaman",
      "Zaman = Yol x Hız",
      "Yol = Hız / Zaman"
    ],
    memoryCode: "X = V x t!",
    subject: "DGS Problemler",
  ),
  const ReflexQuestion(
    prompt: "Ortalama hız hesabı nasıl yapılır?",
    triggerWord: "V_ort Formülü",
    correctAnswer: "Toplam Alınan Yol / Toplam Geçen Zaman",
    wrongOptions: [
      "(V1 + V2) / 2 (Aritmetik Ortalama)",
      "V1 x V2 / 2",
      "Yol Farkı / Zaman"
    ],
    memoryCode: "Ortalama hız daima TOPLAM YOL / TOPLAM ZAMAN ile bulunur!",
    subject: "DGS Problemler",
  ),
  const ReflexQuestion(
    prompt: "İki işçinin birlikte bir işi bitirme süresi nasıl hesaplanır?",
    triggerWord: "Birlikte İşçi Mantığı",
    correctAnswer: "1/A + 1/B = 1/T",
    wrongOptions: [
      "A + B = T",
      "A x B = T",
      "A - B = T"
    ],
    memoryCode: "Birim zamanda yapılan işler toplanır: 1/A + 1/B = 1/T!",
    subject: "DGS Problemler",
  ),
  const ReflexQuestion(
    prompt: "Tuz-su karışımında tuz yüzdesi formülü nedir?",
    triggerWord: "Karışım Yüzdesi",
    correctAnswer: "[Tuz Miktarı / Toplam Karışım] x 100",
    wrongOptions: [
      "[Tuz Miktarı / Su Miktarı] x 100",
      "Su Miktarı x Tuz Miktarı",
      "Tuz + Su / 100"
    ],
    memoryCode: "Saf Madde / TOPLAM KARIŞIM!",
    subject: "DGS Problemler",
  ),
  const ReflexQuestion(
    prompt: "Kenarları tam sayı olan en meşhur dik üçgenler hangileridir?",
    triggerWord: "Özel Dik Üçgenler",
    correctAnswer: "3-4-5, 5-12-13, 8-15-17, 7-24-25",
    wrongOptions: [
      "2-3-4, 4-5-6, 6-7-8",
      "3-6-9, 4-8-12, 5-10-15",
      "1-2-3, 3-4-7, 5-6-11"
    ],
    memoryCode: "Pisagor üçlüleri: 3-4-5, 5-12-13, 8-15-17, 7-24-25 ve katları!",
    subject: "DGS Geometri",
  ),
  const ReflexQuestion(
    prompt: "30-60-90 dik üçgeninde hipotenüs 2a ise 30 ve 60 derecelerin karşısı?",
    triggerWord: "30 - 60 - 90 Üçgeni",
    correctAnswer: "30° karşısı a, 60° karşısı a√3",
    wrongOptions: [
      "30° karşısı a√2, 60° karşısı a",
      "30° karşısı a, 60° karşısı 2a",
      "30° karşısı a/2, 60° karşısı a"
    ],
    memoryCode: "30 derecenin karşısı hipotenüsün YARISIDIR (a); 60 derecenin karşısı a√3!",
    subject: "DGS Geometri",
  ),
  const ReflexQuestion(
    prompt: "Tüm dış bükey çokgenlerin dış açılarının toplamı kaç derecedir?",
    triggerWord: "Dış Açılar Toplamı",
    correctAnswer: "Daima 360 Derecedir (Kenar Sayısından Bağımsız)",
    wrongOptions: [
      "(n - 2) x 180 Derece",
      "180 Derece",
      "n x 360 Derece"
    ],
    memoryCode: "Kenar sayısı kaç olursa olsun DIŞ AÇILAR TOPLAMI DAİMA 360°!",
    subject: "DGS Geometri",
  ),
  const ReflexQuestion(
    prompt: "Yarıçapı r olan dairenin alanı ve çemberin çevresi nedir?",
    triggerWord: "Daire Alan & Çevre",
    correctAnswer: "Alan: πr² / Çevre: 2πr",
    wrongOptions: [
      "Alan: 2πr / Çevre: πr²",
      "Alan: 4/3πr³ / Çevre: 4πr²",
      "Alan: πr / Çevre: 2r"
    ],
    memoryCode: "Alan = πr² / Çevre = 2πr!",
    subject: "DGS Geometri",
  ),
  const ReflexQuestion(
    prompt: "DGS Sözel Mantık sorularında çözüme başlarken ilk yapılması gereken?",
    triggerWord: "Sözel Mantık Anahtarı",
    correctAnswer: "Değişkenleri Belirleyip Sabit Eksenli Tablo Çizmek",
    wrongOptions: [
      "Hemen şıklardan deneme yapmak",
      "Soruları metne bakmadan çözmek",
      "Sadece olumsuz ifadeleri okumak"
    ],
    memoryCode: "Sabit olanı (gün, sıra, kat) tablo ekseni yap, değişkenleri yerleştir!",
    subject: "DGS Sözel Mantık",
  ),
  const ReflexQuestion(
    prompt: "Paragrafta akışı bozan cümleyi bulurken hangi kurala bakılır?",
    triggerWord: "Akışı Bozan Cümle",
    correctAnswer: "Parçanın genel konusundan sapan veya farklı yönünü ele alan cümle",
    wrongOptions: [
      "En uzun cümle",
      "Son cümle",
      "İçinde noktalama işareti olmayan cümle"
    ],
    memoryCode: "Akışı bozan cümle farklı bir düşünceye geçer veya konuyu saptırır!",
    subject: "DGS Sözel Anlam",
  ),
];

class FastReflexScreen extends ConsumerStatefulWidget {
  const FastReflexScreen({super.key});

  @override
  ConsumerState<FastReflexScreen> createState() => _FastReflexScreenState();
}

class _FastReflexScreenState extends ConsumerState<FastReflexScreen> {
  int _score = 0;
  int _combo = 0;
  int _currentIndex = 0;
  int _timeLeft = 7;
  Timer? _timer;
  bool _isAnswered = false;
  int? _selectedOptionIndex;
  late List<ReflexQuestion> _questions;
  late List<String> _currentShuffledOptions;

  @override
  void initState() {
    super.initState();
    _questions = List.from(dgsReflexBank)..shuffle();
    _prepareQuestion();
  }

  void _prepareQuestion() {
    if (_currentIndex >= _questions.length) {
      _questions.shuffle();
      _currentIndex = 0;
    }
    final q = _questions[_currentIndex];
    final allOps = [q.correctAnswer, ...q.wrongOptions];
    allOps.shuffle();
    _currentShuffledOptions = allOps;
    _isAnswered = false;
    _selectedOptionIndex = null;
    _timeLeft = 7;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft > 1) {
          _timeLeft--;
        } else {
          _onTimeOut();
        }
      });
    });
  }

  void _onTimeOut() {
    _timer?.cancel();
    _isAnswered = true;
    _combo = 0;
    SoundService.playIncorrect();
    HapticFeedback.heavyImpact();

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        _currentIndex++;
        _prepareQuestion();
      });
    });
  }

  void _handleAnswer(int optionIndex) {
    if (_isAnswered) return;
    _timer?.cancel();
    _isAnswered = true;
    _selectedOptionIndex = optionIndex;

    final q = _questions[_currentIndex];
    final isCorrect = _currentShuffledOptions[optionIndex] == q.correctAnswer;

    if (isCorrect) {
      _combo++;
      final addedScore = 100 + (_combo * 20) + (_timeLeft * 10);
      _score += addedScore;
      SoundService.playCorrect();
      HapticFeedback.lightImpact();

      // Give XP reward to profile
      try {
        ref.read(userProfileProvider.notifier).completeLesson(
              Lesson(
                id: 'reflex_fast_dgs_${DateTime.now().millisecondsSinceEpoch}',
                title: 'Hızlı Refleks',
                description: 'Görünce Yapıştır Modu',
                questions: const [],
                xpReward: 15,
                gemReward: 3,
              ),
            );
      } catch (_) {}
    } else {
      _combo = 0;
      SoundService.playIncorrect();
      HapticFeedback.mediumImpact();
    }

    Future.delayed(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      setState(() {
        _currentIndex++;
        _prepareQuestion();
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
    if (_questions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final q = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B), size: 24),
            SizedBox(width: 6),
            Text(
              'GÖRÜNCE YAPIŞTIR! ⚡',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF59E0B), size: 18),
                const SizedBox(width: 4),
                Text(
                  'x$_combo',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Skor ve Zaman Çubuğu
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'Puan: $_score',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _timeLeft <= 2 ? const Color(0xFFEF4444) : const Color(0xFF8B5CF6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '$_timeLeft s',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Soru Alanı
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tetikleyici Başlık / Şifre Kartı
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            q.subject.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFFDDD6FE),
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            q.triggerWord,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Soru Metni
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Text(
                        q.prompt,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Şıklar
                    ...List.generate(_currentShuffledOptions.length, (idx) {
                      final option = _currentShuffledOptions[idx];
                      Color optBg = const Color(0xFF1E293B);
                      Color optBorder = Colors.white.withOpacity(0.12);

                      if (_isAnswered) {
                        if (option == q.correctAnswer) {
                          optBg = const Color(0xFF059669);
                          optBorder = const Color(0xFF10B981);
                        } else if (_selectedOptionIndex == idx) {
                          optBg = const Color(0xFFDC2626);
                          optBorder = const Color(0xFFEF4444);
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _handleAnswer(idx),
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: optBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: optBorder, width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      String.fromCharCode(65 + idx),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    if (_isAnswered) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lightbulb_rounded, color: Color(0xFFFBBF24), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                q.memoryCode,
                                style: const TextStyle(
                                  color: Color(0xFFDDD6FE),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
