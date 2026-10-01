import '../models/lesson_models.dart';
import '../models/exam_config.dart';
import 'dgs_units.dart';
import 'dgs_question_bank_builder.dart';

export 'dgs_units.dart';

/// DGS Quest Resmi ÖSYM DGS Müfredatı (30.000+ Soru)
final List<LearningUnit> mockUnits = expandUnitsWithQuestionBank(dgsUnits);

/// Aktif Quest sınavına göre müfredat ünitelerini döndürür
List<LearningUnit> getUnitsForExam(ExamFranchise franchise) {
  return mockUnits;
}
