// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:dgs_quest/data/mock_lessons.dart';
import 'package:dgs_quest/models/lesson_models.dart';
import 'package:dgs_quest/screens/flashcards_screen.dart';
import 'package:dgs_quest/screens/fast_reflex_screen.dart';

void main() {
  test('DGS Quest Müfredat ve Soru Bankası Detaylı Denetimi', () {
    int totalQuestions = 0;
    final Map<String, int> subjectQuestionCounts = {};
    final Map<QuestionType, int> typeCounts = {};
    int emptyPromptCount = 0;
    int invalidOptionCount = 0;

    for (final unit in mockUnits) {
      subjectQuestionCounts[unit.subject] = (subjectQuestionCounts[unit.subject] ?? 0);
      for (final lesson in unit.lessons) {
        for (final q in lesson.questions) {
          totalQuestions++;
          subjectQuestionCounts[unit.subject] = subjectQuestionCounts[unit.subject]! + 1;
          typeCounts[q.type] = (typeCounts[q.type] ?? 0) + 1;

          if (q.type == QuestionType.conceptCard) {
            if ((q.conceptTitle == null || q.conceptTitle!.isEmpty) && q.prompt.isEmpty) {
              emptyPromptCount++;
            }
          } else if (q.type == QuestionType.multipleChoice) {
            if (q.options == null || q.options!.length < 2) {
              invalidOptionCount++;
            }
            if (q.correctIndex == null || q.correctIndex! < 0 || q.correctIndex! >= (q.options?.length ?? 0)) {
              invalidOptionCount++;
            }
          } else if (q.type == QuestionType.trueFalse) {
            if (q.isTrue == null) {
              invalidOptionCount++;
            }
          } else if (q.type == QuestionType.fillInTheBlank) {
            if (q.blankOptions == null || q.correctBlankAnswer == null) {
              invalidOptionCount++;
            }
          } else if (q.type == QuestionType.matching) {
            if (q.matchingPairs == null || q.matchingPairs!.isEmpty) {
              invalidOptionCount++;
            }
          }
        }
      }
    }

    print('=== DGS QUEST SORU RAPORU ===');
    print('Toplam Ünite Sayısı: ${mockUnits.length}');
    print('Toplam Ders Sayısı: ${mockUnits.expand((u) => u.lessons).length}');
    print('Toplam Soru Sayısı: $totalQuestions');
    print('--- Branş Dağılımı ---');
    subjectQuestionCounts.forEach((subj, count) {
      print('  $subj: $count soru');
    });
    print('--- Soru Tipi Dağılımı ---');
    typeCounts.forEach((type, count) {
      print('  ${type.name}: $count soru');
    });
    print('--- Ekstra Modlar ---');
    print('  Flaş Kart Sayısı: ${defaultFlashcards.length}');
    print('  Hızlı Refleks Soru Sayısı: ${dgsReflexBank.length}');
    print('==============================');

    expect(totalQuestions, greaterThanOrEqualTo(50000));
    expect(emptyPromptCount, equals(0));
    expect(invalidOptionCount, equals(0));
  });
}
