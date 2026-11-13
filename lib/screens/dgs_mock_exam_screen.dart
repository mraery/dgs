import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_lessons.dart';
import '../models/lesson_models.dart';
import '../providers/game_provider.dart';
import '../services/sound_service.dart';

enum MockExamType {
  fullDgs, // 100 Soru - 135 Dakika (50 Sayısal + 50 Sözel)
  miniDgs, // 30 Soru - 40 Dakika (Hızlı Prova)
}

class DgsMockExamScreen extends ConsumerStatefulWidget {
  final MockExamType examType;

  const DgsMockExamScreen({
    super.key,
    this.examType = MockExamType.miniDgs,
  });

  @override
  ConsumerState<DgsMockExamScreen> createState() => _DgsMockExamScreenState();
}

class _DgsMockExamScreenState extends ConsumerState<DgsMockExamScreen> {
  late final List<Question> _questions;
  late final int _totalDurationSeconds;
  late int _remainingSeconds;
  Timer? _timer;

  int _currentIndex = 0;
  final Map<int, int?> _answers = {}; // Soru İndeksi -> Seçilen Şık İndeksi (null = Boş)
  final Set<int> _flaggedIndices = {}; // Şüpheli / Gözden Geçirilecek sorular

  @override
  void initState() {
    super.initState();
    _prepareExam();
    _startTimer();
  }

  void _prepareExam() {
    final allQuestions = mockUnits
        .expand((u) => u.lessons)
        .expand((l) => l.questions)
        .where((q) => q.type == QuestionType.multipleChoice && (q.options?.length ?? 0) >= 4)
        .toList()
      ..shuffle();

    if (widget.examType == MockExamType.fullDgs) {
      _totalDurationSeconds = 135 * 60; // 135 dakika resmi DGS süresi
      _questions = allQuestions.take(100).toList();
    } else {
      _totalDurationSeconds = 40 * 60; // 40 dakika mini deneme
      _questions = allQuestions.take(30).toList();
    }
    _remainingSeconds = _totalDurationSeconds;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _finishExam();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int totalSecs) {
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _finishExam() {
    _timer?.cancel();
    SoundService.playCorrect();

    // Net Hesapla (ÖSYM DGS 4Y = -1D Kuralı)
    int correct = 0;
    int wrong = 0;
    int empty = 0;

    for (int i = 0; i < _questions.length; i++) {
      final ans = _answers[i];
      if (ans == null) {
        empty++;
      } else if (ans == _questions[i].correctIndex) {
        correct++;
      } else {
        wrong++;
      }
    }

    final double rawNet = correct - (wrong * 0.25);
    final double net = rawNet < 0 ? 0.0 : rawNet;

    // XP ve Elmas ödülü
    final earnedXp = (net * 4).round() + 50;
    final earnedGems = (net * 1.5).round() + 15;
    ref.read(userProfileProvider.notifier).addXp(earnedXp);
    ref.read(userProfileProvider.notifier).addGems(earnedGems);
    ref.read(userProfileProvider.notifier).incrementQuestionsAnswered();

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _buildScoreSheet(
        context,
        correct: correct,
        wrong: wrong,
        empty: empty,
        net: net,
        earnedXp: earnedXp,
        earnedGems: earnedGems,
      ),
    );
  }

  Widget _buildScoreSheet(
    BuildContext context, {
    required int correct,
    required int wrong,
    required int empty,
    required double net,
    required int earnedXp,
    required int earnedGems,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeSpent = _totalDurationSeconds - _remainingSeconds;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          const Text('🎯', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 10),
          const Text(
            'DENEME SINAVI TAMAMLANDI!',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Text(
            'Resmi ÖSYM DGS Net Hesaplama Formülü Uygulandı',
            style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // Sonuç Kartları Grid
          Row(
            children: [
              _buildResultBox('DOĞRU', '$correct', const Color(0xFF10B981)),
              const SizedBox(width: 10),
              _buildResultBox('YANLIŞ', '$wrong', const Color(0xFFEF4444)),
              const SizedBox(width: 10),
              _buildResultBox('BOŞ', '$empty', const Color(0xFF6B7280)),
              const SizedBox(width: 10),
              _buildResultBox('TOPLAM NET', net.toStringAsFixed(2), const Color(0xFF6366F1)),
            ],
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_rounded, color: Color(0xFF6366F1), size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'Süre: ${_formatTime(timeSpent)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B), size: 20),
                    const SizedBox(width: 4),
                    Text('+$earnedXp XP', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                Row(
                  children: [
                    const Text('💎', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 4),
                    Text('+$earnedGems Elmas', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Sheet'i kapat
                Navigator.of(context).pop(); // Ekranı kapat
              },
              child: const Text('DENEMEYİ BİTİR VE DÖN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultBox(String title, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQ = _questions[_currentIndex];
    final selectedOption = _answers[_currentIndex];
    final isFlagged = _flaggedIndices.contains(_currentIndex);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.examType == MockExamType.fullDgs ? 'DGS Tam Deneme (100 Soru)' : 'DGS Hızlı Prova (30 Soru)',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, size: 14, color: Color(0xFFEF4444)),
                const SizedBox(width: 4),
                Text(
                  _formatTime(_remainingSeconds),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isFlagged ? 'İşareti Kaldır' : 'Soruyu İşaretle (Şüpheli)',
            icon: Icon(
              isFlagged ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: isFlagged ? const Color(0xFFF59E0B) : null,
            ),
            onPressed: () {
              setState(() {
                if (isFlagged) {
                  _flaggedIndices.remove(_currentIndex);
                } else {
                  _flaggedIndices.add(_currentIndex);
                }
              });
            },
          ),
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sınavı Bitirmek İstiyor musun?'),
                  content: Text(
                    'Şu ana kadar ${_answers.length}/${_questions.length} soru işaretledin. '
                    '${_questions.length - _answers.length} soru boş kalacak.',
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('DEVAM ET')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _finishExam();
                      },
                      child: const Text('SINAVI BİTİR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
            child: const Text('BİTİR', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w900)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Soru Numaraları Optik Gezinti Çubuğu
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _questions.length,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (ctx, idx) {
                final isCurrent = idx == _currentIndex;
                final isAnswered = _answers.containsKey(idx);
                final flagged = _flaggedIndices.contains(idx);

                Color bg = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
                Color text = isDark ? Colors.white : const Color(0xFF334155);

                if (isAnswered) {
                  bg = const Color(0xFF10B981);
                  text = Colors.white;
                }
                if (flagged) {
                  bg = const Color(0xFFF59E0B);
                  text = Colors.white;
                }
                if (isCurrent) {
                  bg = const Color(0xFF6366F1);
                  text = Colors.white;
                }

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentIndex = idx;
                    });
                  },
                  child: Container(
                    width: 36,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(10),
                      border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
                    ),
                    child: Center(
                      child: Text(
                        '${idx + 1}',
                        style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Soru İçeriği
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Soru ${_currentIndex + 1} / ${_questions.length}',
                          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF6366F1), fontSize: 12),
                        ),
                      ),
                      if (selectedOption != null)
                        TextButton.icon(
                          icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
                          label: const Text('Seçimi Temizle (Boş Bırak)', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                          onPressed: () {
                            setState(() {
                              _answers.remove(_currentIndex);
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Soru Metni
                  Text(
                    currentQ.prompt,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.5),
                  ),
                  const SizedBox(height: 20),

                  // Seçenekler (A, B, C, D, E)
                  ...List.generate(currentQ.options?.length ?? 0, (optIdx) {
                    final isSelected = selectedOption == optIdx;
                    final letter = String.fromCharCode(65 + optIdx); // A, B, C, D, E

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _answers[_currentIndex] = optIdx;
                        });
                        SoundService.playCorrect();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF6366F1).withOpacity(0.12)
                              : (isDark ? const Color(0xFF1E293B) : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF6366F1)
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            width: isSelected ? 2 : 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF6366F1) : Colors.grey.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  letter,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                currentQ.options![optIdx],
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Alt İleri / Geri Navigasyon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                  label: const Text('Önceki'),
                  onPressed: _currentIndex > 0
                      ? () => setState(() => _currentIndex--)
                      : null,
                ),
                Text(
                  '${_answers.length} Cevaplandı',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF10B981)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                  icon: const Text('Sonraki', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  label: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white),
                  onPressed: _currentIndex < _questions.length - 1
                      ? () => setState(() => _currentIndex++)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
