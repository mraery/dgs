import '../models/lesson_models.dart';
import '../models/exam_config.dart';
import 'dgs_units.dart';

export 'dgs_units.dart';

/// DGS Quest Resmi ÖSYM DGS Müfredatı
final List<LearningUnit> mockUnits = dgsUnits;

/// Aktif Quest sınavına göre müfredat ünitelerini döndürür
List<LearningUnit> getUnitsForExam(ExamFranchise franchise) {
  return dgsUnits;
}
