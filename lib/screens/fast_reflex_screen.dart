import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../services/sound_service.dart';
import '../widgets/duo_button.dart';

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
    prompt: 'Aralarında asal iki sayının EBOB ve EKOK çarpımı neye eşittir?',
    triggerWord: 'EBOB * EKOK',
    correctAnswer: 'Sayıların Kendi Çarpımına (a * b)',
    wrongOptions: [
      'Sayıların Toplamına (a + b)',
      'Daima 1\'e eşittir',
      'Sayıların Farkının Karesine'
    ],
    memoryCode: 'Kural: EBOB(a,b) = 1 olduğundan EKOK(a,b) = a * b olur!',
    subject: 'DGS Sayısal Matematik',
  ),
  const ReflexQuestion(
    prompt: 'Düzgün çokgenin bir dış açısı nasıl bulunur?',
    triggerWord: 'Dış Açı Formülü',
    correctAnswer: '360° / n (n = kenar sayısı)',
    wrongOptions: [
      '(n - 2) * 180°',
      '180° - (360° / n^2)',
      '360° * (n - 2)'
    ],
    memoryCode: 'Tüm dış açılar toplamı daima 360°\'dir. Bir dış açı = 360 / n.',
    subject: 'DGS Geometri',
  ),
  const ReflexQuestion(
    prompt: 'Hız - Zaman - Yol temel hareket formülü?',
    triggerWord: 'x = v * t',
    correctAnswer: 'Yol = Hız * Zaman',
    wrongOptions: [
      'Hız = Yol * Zaman',
      'Zaman = Hız / Yol',
      'Yol = Hız / (Zaman^2)'
    ],
    memoryCode: 'Birbirine doğru gelen araçlar: Hızlar toplanır! Aynı yöne giden araçlar: Hızlar çıkarılır!',
    subject: 'DGS Sayısal Problemler',
  ),
  const ReflexQuestion(
    prompt: 'Sözel Mantıkta kesin doğruya ulaşmanın ilk altın adımı?',
    triggerWord: 'Sabit Tablo Oluşturma',
    correctAnswer: 'Değişmeyen kriteri (Gün, Sıra, Kat) ana eksen olarak sabitlemek',
    wrongOptions: [
      'Şıklardan rastgele eleme yapmak',
      'Sadece olumsuz öncülleri çizmek',
      'Tüm olasılıkları tek tek ezberlemek'
    ],
    memoryCode: 'Taktik: Zaman/Gün/Sıra daima sabit sütundur, değişkenleri (isimleri) tabloya yerleştir!',
    subject: 'DGS Sözel Mantık',
  ),
  const ReflexQuestion(
    prompt: 'İşçi - Havuz problemlerinde birim zamanda yapılan iş?',
    triggerWord: '1 / t Formülü',
    correctAnswer: '1/A + 1/B = 1/T',
    wrongOptions: [
      'A + B = T',
      'A * B = 1/T',
      '(A - B) / 2 = T'
    ],
    memoryCode: 'Ahmet t1 günde, Burak t2 günde bitirirse birlikte 1 günde 1/t1 + 1/t2 iş yaparlar.',
    subject: 'DGS Sayısal',
  ),
  const ReflexQuestion(
    prompt: 'Paragrafta akışı bozan cümle nasıl tespit edilir?',
    triggerWord: 'Konu ve Bakış Açısı Değişimi',
    correctAnswer: 'Önceki ve sonraki cümlenin konu odağını kırıp farklı yöne sapan cümle',
    wrongOptions: [
      'Daima paragrafın ilk giriş cümlesidir',
      'En uzun ve noktalama işareti çok olan cümledir',
      'İçinde bağlaç olan her cümledir'
    ],
    memoryCode: 'Taktik: Cümleler arası köprü kelimelere (bu yüzden, nitekim, oysa) dikkat et!',
    subject: 'DGS Türkçe',
  ),
];


class FastReflexScreen extends ConsumerStatefulWidget {
  const FastReflexScreen({super.key});

  @override
  ConsumerState<FastReflexScreen> createState() => _FastReflexScreenState();
}

class _FastReflexScreenState extends ConsumerState<FastReflexScreen>
    with SingleTickerProviderStateMixin {
  late List<ReflexQuestion> _questions;
  int _currentIndex = 0;
  int _score = 0;
  int _combo = 0;
  int _maxCombo = 0;
  bool _isAnswered = false;
  String? _selectedOption;
  bool _isCorrect = false;

  Timer? _countdownTimer;
  double _timeLeft = 10.0;
  static const double _maxTime = 10.0;

  late List<String> _currentShuffledOptions;

  @override
  void initState() {
    super.initState();
    _questions = List.from(dgsReflexBank)..shuffle();
    _setupCurrentQuestion();
  }

  void _setupCurrentQuestion() {
    final q = _questions[_currentIndex];
    final allOpts = [q.correctAnswer, ...q.wrongOptions];
    allOpts.shuffle();
    _currentShuffledOptions = allOpts;
    _isAnswered = false;
    _selectedOption = null;
    _timeLeft = _maxTime;

    _startTimer();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        _timeLeft -= 0.1;
        if (_timeLeft <= 0.0) {
          _timeLeft = 0.0;
          _onTimeUp();
        }
      });
    });
  }

  void _onTimeUp() {
    _countdownTimer?.cancel();
    if (_isAnswered) return;

    SoundService.playIncorrect();
    HapticFeedback.heavyImpact();

    setState(() {
      _isAnswered = true;
      _isCorrect = false;
      _combo = 0;
    });
  }

  void _handleOptionSelect(String option) {
    if (_isAnswered) return;
    _countdownTimer?.cancel();

    final q = _questions[_currentIndex];
    final bool correct = (option == q.correctAnswer);

    setState(() {
      _isAnswered = true;
      _selectedOption = option;
      _isCorrect = correct;

      if (correct) {
        _combo++;
        if (_combo > _maxCombo) _maxCombo = _combo;
        final speedBonus = (_timeLeft * 10).toInt();
        _score += 100 + speedBonus + (_combo * 15);
        SoundService.playCorrect();
        HapticFeedback.mediumImpact();
      } else {
        _combo = 0;
        SoundService.playIncorrect();
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _setupCurrentQuestion();
    } else {
      _showResultDialog();
    }
  }

  void _showResultDialog() {
    ref.read(userProfileProvider.notifier).gainHeart();
    ref.read(userProfileProvider.notifier).addGems(15);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Tebrikler! ⚡', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, size: 64, color: Color(0xFFFF9600)),
            const SizedBox(height: 12),
            Text('Toplam Skor: $_score Puan', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('Maksimum Kombo: $_maxCombo x 🔥', style: const TextStyle(fontSize: 15, color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          DuoButton(
            text: 'KAPAT & ÖDÜLÜ AL',
            color: DuoButtonColor.green,
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bolt_rounded, color: Color(0xFFFF9600), size: 24),
            const SizedBox(width: 4),
            Text('$_score', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(width: 16),
            if (_combo > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(12)),
                child: Text('$_combo x COMBO 🔥', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
              ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('${_currentIndex + 1}/${_questions.length}', style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: _timeLeft / _maxTime,
                  backgroundColor: const Color(0xFF334155),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _timeLeft > 3.0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: Text(q.subject, style: const TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 12),
                    Text(q.prompt, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.3)),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: const Color(0xFFFF9600).withOpacity(0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFF9600).withOpacity(0.4))),
                      child: Row(
                        children: [
                          const Icon(Icons.key_rounded, color: Color(0xFFFF9600), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(q.triggerWord, style: const TextStyle(color: Color(0xFFFFB020), fontSize: 14, fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ..._currentShuffledOptions.map((opt) {
                Color btnBg = const Color(0xFF1E293B);
                Color borderC = const Color(0xFF334155);
                Color textC = Colors.white;

                if (_isAnswered) {
                  if (opt == q.correctAnswer) {
                    btnBg = const Color(0xFF065F46);
                    borderC = const Color(0xFF10B981);
                  } else if (opt == _selectedOption) {
                    btnBg = const Color(0xFF7F1D1D);
                    borderC = const Color(0xFFEF4444);
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _handleOptionSelect(opt),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: btnBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderC, width: 2),
                      ),
                      child: Text(opt, style: TextStyle(color: textC, fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                );
              }).toList(),
              const Spacer(),
              if (_isAnswered)
                DuoButton(
                  text: _currentIndex < _questions.length - 1 ? 'SONRAKİ REFLEKS ⚡' : 'SONUÇLARI GÖR 🏆',
                  color: _isCorrect ? DuoButtonColor.green : DuoButtonColor.gray,
                  onPressed: _nextQuestion,
                )
              else
                const SizedBox(height: 52),
            ],
          ),
        ),
      ),
    );
  }
}
