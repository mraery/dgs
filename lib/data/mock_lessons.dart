import '../models/lesson_models.dart';
import '../models/exam_config.dart';
import 'dgs_streaming_units.dart';

export 'dgs_streaming_units.dart';

/// DGS Quest Resmi Mufredati
final List<LearningUnit> mockUnits = dgsStreamingUnits;

List<LearningUnit> getUnitsForExam(ExamFranchise franchise) {
  return dgsStreamingUnits;
}
