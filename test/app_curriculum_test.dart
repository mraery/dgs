import 'package:flutter_test/flutter_test.dart';
import 'package:dgs_quest/models/lesson_models.dart';
import 'package:dgs_quest/models/exam_config.dart';
import 'package:dgs_quest/data/mock_lessons.dart';

void main() {
  group('DGS Quest ÖSYM Sınav Sistemi ve Müfredat Testleri', () {
    test('ÖSYM Dikey Geçiş Sınavı (DGS) resmi net hesaplama kuralı (4Y = -1D)', () {
      final config = ExamConfig.fromFranchise(ExamFranchise.dgs);
      expect(config.officialBody, equals('ÖSYM'));
      expect(config.penaltyRatio, equals(4));
      expect(config.penaltyRuleText.contains('4 Yanlış 1 Doğru'), isTrue);

      // Net formülü doğrulaması
      expect(config.calculateNet(15, 4), equals(14.0));
      expect(config.calculateNet(10, 6), equals(8.5));
      expect(config.calculateNet(1, 4), equals(0.0));
    });

    test('DGS Quest 28 ünite, 56 ders ve 450+ sorudan oluşur', () {
      expect(mockUnits.length, equals(28));
      final totalLessons = mockUnits.expand((u) => u.lessons).length;
      final totalQuestions = mockUnits.expand((u) => u.lessons).expand((l) => l.questions).length;

      expect(totalLessons, equals(56));
      expect(totalQuestions, greaterThanOrEqualTo(450));
    });

    test('Her derste 8-12 soru bulunur, ilk soru kavram kartıdır ve son ders kupa sınavıdır', () {
      for (final unit in mockUnits) {
        expect(unit.lessons.length, equals(2));
        expect(unit.lessons.last.isUnitExam, isTrue, reason: '${unit.title} son dersi kupa sınavı olmalı');

        for (final lesson in unit.lessons) {
          expect(lesson.questions.length >= 8 && lesson.questions.length <= 12, isTrue,
              reason: '${lesson.title} dersinde ${lesson.questions.length} soru var');
          expect(lesson.questions.first.type, equals(QuestionType.conceptCard),
              reason: '${lesson.title} ilk adımı kavram kartı olmalı');
        }
      }
    });

    test('DGS branş dağılımı Sayısal ve Sözel müfredatı kapsar', () {
      final subjects = mockUnits.map((u) => u.subject).toSet();
      expect(subjects.contains('DGS Temel Matematik'), isTrue);
      expect(subjects.contains('DGS Problemler'), isTrue);
      expect(subjects.any((s) => s.contains('Sözel')), isTrue);
    });
  });
}
