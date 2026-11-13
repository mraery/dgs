import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lesson_models.dart';

/// Her bir sorunun öğrenme durumunu temsil eden model.
/// Ebbinghaus Unutma Eğrisi aralıklarına göre sonraki tekrar zamanını belirler.
class QuestionLearningRecord {
  final String questionId;
  final String subject; // 'DGS Temel Matematik', 'DGS Problemler', vs.
  final String topic;   // 'Temel Kavramlar', 'Hız Problemleri', vs.
  final int correctStreak; // Art arda doğru sayısı
  final int totalAttempts;
  final int wrongCount;
  final DateTime lastAttemptDate;
  final DateTime nextReviewDate; // Tekrar edilmesi gereken tarih
  final double averageTimeSeconds; // Ortalama çözüm süresi
  final Map<String, dynamic>? questionSnapshot; // Offline tekrar için soru verisi

  const QuestionLearningRecord({
    required this.questionId,
    required this.subject,
    required this.topic,
    this.correctStreak = 0,
    this.totalAttempts = 0,
    this.wrongCount = 0,
    required this.lastAttemptDate,
    required this.nextReviewDate,
    this.averageTimeSeconds = 0.0,
    this.questionSnapshot,
  });

  bool get isDueForReview {
    return DateTime.now().isAfter(nextReviewDate);
  }

  /// Ebbinghaus Aralıklı Tekrar (Spaced Repetition) hesaplayıcısı:
  /// - Yanlış yapıldıysa: 1 saat sonra veya aynı gün tekrar
  /// - 1. Doğru: 1 gün sonra (24 saat)
  /// - 2. Doğru: 3 gün sonra (72 saat)
  /// - 3. Doğru: 7 gün sonra (1 hafta)
  /// - 4. Doğru: 16 gün sonra
  /// - 5+ Doğru: 30 gün sonra (Kalıcı hafızaya geçti)
  QuestionLearningRecord recordAttempt({
    required bool isCorrect,
    double timeSeconds = 0.0,
    Map<String, dynamic>? snapshot,
  }) {
    final now = DateTime.now();
    int newStreak = isCorrect ? (correctStreak + 1) : 0;
    int newWrong = isCorrect ? wrongCount : (wrongCount + 1);
    int newAttempts = totalAttempts + 1;

    Duration reviewInterval;
    if (!isCorrect) {
      reviewInterval = const Duration(hours: 4); // Aynı gün içinde acil telafi
    } else {
      switch (newStreak) {
        case 1:
          reviewInterval = const Duration(days: 1);
          break;
        case 2:
          reviewInterval = const Duration(days: 3);
          break;
        case 3:
          reviewInterval = const Duration(days: 7);
          break;
        case 4:
          reviewInterval = const Duration(days: 16);
          break;
        default:
          reviewInterval = const Duration(days: 30);
          break;
      }
    }

    final double newAvgTime = totalAttempts == 0
        ? timeSeconds
        : ((averageTimeSeconds * totalAttempts) + timeSeconds) / newAttempts;

    return QuestionLearningRecord(
      questionId: questionId,
      subject: subject,
      topic: topic,
      correctStreak: newStreak,
      totalAttempts: newAttempts,
      wrongCount: newWrong,
      lastAttemptDate: now,
      nextReviewDate: now.add(reviewInterval),
      averageTimeSeconds: newAvgTime,
      questionSnapshot: snapshot ?? questionSnapshot,
    );
  }

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'subject': subject,
    'topic': topic,
    'correctStreak': correctStreak,
    'totalAttempts': totalAttempts,
    'wrongCount': wrongCount,
    'lastAttemptDate': lastAttemptDate.toIso8601String(),
    'nextReviewDate': nextReviewDate.toIso8601String(),
    'averageTimeSeconds': averageTimeSeconds,
    'questionSnapshot': questionSnapshot,
  };

  factory QuestionLearningRecord.fromJson(Map<String, dynamic> json) {
    return QuestionLearningRecord(
      questionId: json['questionId'] as String? ?? '',
      subject: json['subject'] as String? ?? 'Genel',
      topic: json['topic'] as String? ?? 'Genel',
      correctStreak: json['correctStreak'] as int? ?? 0,
      totalAttempts: json['totalAttempts'] as int? ?? 0,
      wrongCount: json['wrongCount'] as int? ?? 0,
      lastAttemptDate: DateTime.tryParse(json['lastAttemptDate'] as String? ?? '') ?? DateTime.now(),
      nextReviewDate: DateTime.tryParse(json['nextReviewDate'] as String? ?? '') ?? DateTime.now(),
      averageTimeSeconds: (json['averageTimeSeconds'] as num?)?.toDouble() ?? 0.0,
      questionSnapshot: json['questionSnapshot'] as Map<String, dynamic>?,
    );
  }
}

/// Akıllı Öğrenme & Ebbinghaus Aralıklı Tekrar Servisi
class SmartLearningEngine {
  SmartLearningEngine._();
  static final SmartLearningEngine instance = SmartLearningEngine._();

  static const String _keyRecords = 'ebbinghaus_learning_records_v1';
  final Map<String, QuestionLearningRecord> _records = {};
  bool _isLoaded = false;

  Future<void> initialize() async {
    if (_isLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyRecords);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _records.clear();
        decoded.forEach((key, val) {
          _records[key] = QuestionLearningRecord.fromJson(val as Map<String, dynamic>);
        });
      }
      _isLoaded = true;
      debugPrint('[SmartLearningEngine] ${_records.length} soru öğrenme kaydı yüklendi.');
    } catch (e) {
      debugPrint('[SmartLearningEngine] Yükleme hatası: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _records.map((k, v) => MapEntry(k, v.toJson()));
      await prefs.setString(_keyRecords, jsonEncode(map));
    } catch (e) {
      debugPrint('[SmartLearningEngine] Kayıt hatası: $e');
    }
  }

  /// Bir sorunun çözüm sonucunu kaydeder ve sonraki tekrar vaktini günceller
  Future<void> recordQuestionAnswer({
    required Question question,
    required String subject,
    required String topic,
    required bool isCorrect,
    double timeSeconds = 0.0,
  }) async {
    await initialize();

    final existing = _records[question.id] ?? QuestionLearningRecord(
      questionId: question.id,
      subject: subject,
      topic: topic,
      lastAttemptDate: DateTime.now(),
      nextReviewDate: DateTime.now(),
      questionSnapshot: question.toJson(),
    );

    final updated = existing.recordAttempt(
      isCorrect: isCorrect,
      timeSeconds: timeSeconds,
      snapshot: question.toJson(),
    );

    _records[question.id] = updated;
    await _save();
  }

  /// Şu an vadesi gelmiş (unutulma riski yüksek) tekrar soruları
  List<Question> getDueQuestions({int limit = 10}) {
    final now = DateTime.now();
    final dueRecords = _records.values
        .where((r) => r.nextReviewDate.isBefore(now) && r.questionSnapshot != null)
        .toList()
      ..sort((a, b) {
        // En çok yanlış yapılan ve tarihi en çok geçmiş olanlar önce gelsin
        if (a.wrongCount != b.wrongCount) {
          return b.wrongCount.compareTo(a.wrongCount);
        }
        return a.nextReviewDate.compareTo(b.nextReviewDate);
      });

    final questions = <Question>[];
    for (final rec in dueRecords.take(limit)) {
      try {
        questions.add(Question.fromJson(rec.questionSnapshot!));
      } catch (_) {}
    }
    return questions;
  }

  /// Kullanıcının en çok zorlandığı (en zayıf) 3 konuyu tespit eder
  Map<String, double> getWeakestTopics() {
    final Map<String, int> topicWrongs = {};
    final Map<String, int> topicTotals = {};

    for (final rec in _records.values) {
      topicWrongs[rec.topic] = (topicWrongs[rec.topic] ?? 0) + rec.wrongCount;
      topicTotals[rec.topic] = (topicTotals[rec.topic] ?? 0) + rec.totalAttempts;
    }

    final Map<String, double> failureRates = {};
    topicWrongs.forEach((topic, wrongs) {
      final total = topicTotals[topic] ?? 1;
      if (total >= 3 && wrongs > 0) { // En az 3 deneme yapılmış konular
        failureRates[topic] = (wrongs / total) * 100.0;
      }
    });

    final sortedEntries = failureRates.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries.take(3));
  }

  /// Kişiselleştirilmiş Günlük Çalışma Önerisi Metni
  String getDailySmartAdvice() {
    final dueCount = _records.values.where((r) => r.nextReviewDate.isBefore(DateTime.now())).length;
    final weakTopics = getWeakestTopics();

    if (dueCount > 0) {
      return '🧠 Ebbinghaus algoritması hafızanda unutulmak üzere olan $dueCount kritik soru tespit etti. Hemen Akıllı Tekrar yap!';
    } else if (weakTopics.isNotEmpty) {
      final worst = weakTopics.keys.first;
      final rate = weakTopics.values.first.toStringAsFixed(0);
      return '🎯 Performans analizin "$worst" konusunda %$rate hata oranı gösteriyor. Bugün bu konuya odaklanmalısın!';
    } else {
      return '🌟 Harika ilerliyorsun! Günlük soru hedefini tamamlamak ve serini korumak için yeni bir üniteye başla.';
    }
  }

  int get totalTrackedQuestions => _records.length;
  int get totalDueForReview => _records.values.where((r) => r.nextReviewDate.isBefore(DateTime.now())).length;
}
