import '../models/lesson_models.dart';
import '../models/exam_config.dart';
import 'dgs_units.dart';
import 'dgs_question_bank_builder.dart';

export 'dgs_streaming_units.dart';

/// DGS Quest Resmi ÖSYM DGS Müfredatı (50.000+ Soru)
final List<LearningUnit> mockUnits = expandUnitsWithQuestionBank(dgsUnits);

/// Uygulama açılışında sadece ünite iskeletlerini yükler;
/// ders soruları internetten (CurriculumRemoteService) talep üzerine çekilir.
List<LearningUnit> getUnitsForExam(ExamFranchise franchise) {
  return dgsUnits.map((u) => u.toSkeleton()).toList();
}
