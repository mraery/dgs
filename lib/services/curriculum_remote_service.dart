import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/dgs_question_bank_builder.dart';
import '../data/dgs_units.dart';
import '../models/lesson_models.dart';

class CurriculumRemoteService {
  static const String _githubRawBase =
      'https://raw.githubusercontent.com/mraery';

  /// Sınav müfredat kataloğunu (iskelet üniteleri) yükler
  static Future<List<LearningUnit>> loadCurriculumCatalog({
    required String repoName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'catalog_${repoName}_v1';
      final cachedJson = prefs.getString(cacheKey);

      List<dynamic> jsonList;
      if (cachedJson != null && cachedJson.isNotEmpty) {
        jsonList = jsonDecode(cachedJson) as List<dynamic>;
      } else {
        // Yerel asset'ten yükle
        final assetString =
            await rootBundle.loadString('assets/curriculum/index.json');
        jsonList = jsonDecode(assetString) as List<dynamic>;
        // Ön belleğe kaydet
        await prefs.setString(cacheKey, assetString);
      }

      final units = jsonList.map((item) {
        final map = item as Map<String, dynamic>;
        final lessons = (map['lessons'] as List<dynamic>?)
                ?.map((l) => Lesson.fromJson(l as Map<String, dynamic>))
                .toList() ??
            [];
        return LearningUnit(
          id: map['id']?.toString() ?? '',
          unitNumber: map['unitNumber'] as int? ?? 1,
          title: map['title']?.toString() ?? '',
          subject: map['subject']?.toString() ?? '',
          colorHex: map['colorHex'] as int? ?? 0xFF4F46E5,
          lessons: lessons,
          isDownloaded: false,
        );
      }).toList();

      return units;
    } catch (e) {
      debugPrint('Katalog yükleme hatası ($repoName): $e');
      return [];
    }
  }

  /// Uzak ünite JSON'unun taşıması gereken en düşük "schema" değeri.
  /// GitHub'daki eski dışa aktarım (schema alanı yok, ünite başına 2 ders) yok sayılır;
  /// aksi halde indirilen ünite, uygulamadaki 7 derslik ünitenin yerine geçip dersleri siliyordu.
  static const int _minRemoteSchema = 2;

  /// Önbellekte "uzak içerik yok, uygulamadaki soru bankası kullanılıyor" işareti.
  static const String _localMarker = 'local';

  static String _cacheKey(String repoName, String unitId) =>
      'unit_v2_${repoName}_$unitId';

  static String _legacyCacheKey(String repoName, String unitId) =>
      'unit_json_${repoName}_$unitId';

  /// Ünitenin cihazda önbelleğe alınıp alınmadığını kontrol eder
  static Future<bool> isUnitDownloaded(
      String repoName, String unitId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_cacheKey(repoName, unitId));
    } catch (_) {
      return false;
    }
  }

  /// Uygulamayla birlikte gelen tam üniteyi (tüm dersler + yerel soru bankası) üretir.
  static LearningUnit? _buildLocalUnit(String unitId) {
    final rawIndex = dgsUnits.indexWhere((u) => u.id == unitId);
    if (rawIndex == -1) return null;
    final expanded = expandUnitsWithQuestionBank([dgsUnits[rawIndex]]);
    if (expanded.isEmpty || !expanded.first.isLoaded) return null;
    return expanded.first.copyWith(isDownloaded: true);
  }

  /// Uzak JSON'u doğrular; eski şema, yanlış ünite veya boş içerikse null döner.
  static LearningUnit? _parseRemoteUnit(String body, String expectedId) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;
      final schema = (decoded['schema'] as num?)?.toInt() ?? 1;
      if (schema < _minRemoteSchema) return null;
      if (decoded['id']?.toString() != expectedId) return null;
      final unit = LearningUnit.fromJson(decoded, isDownloaded: true);
      return unit.isLoaded ? unit : null;
    } catch (e) {
      debugPrint('Uzak ünite okunamadı ($expectedId): $e');
      return null;
    }
  }

  /// Uzak içeriği yerel ünitenin ÜZERİNE ekler: yerel dersler asla silinmez.
  /// - Aynı id'li derste uzak sorular öne alınır, yerel soru bankası arkasına eklenir.
  /// - Uygulamada olmayan yeni uzak dersler ünitenin sonuna eklenir.
  static LearningUnit _mergeRemoteIntoLocal(
      LearningUnit? local, LearningUnit remote) {
    if (local == null) return remote;
    final remoteById = <String, Lesson>{
      for (final l in remote.lessons) l.id: l,
    };
    final localIds = local.lessons.map((l) => l.id).toSet();
    final merged = <Lesson>[];

    for (final l in local.lessons) {
      final r = remoteById[l.id];
      if (r == null || r.questions.isEmpty) {
        merged.add(l);
        continue;
      }
      final seen = r.questions.map((q) => q.id).toSet();
      final combined = <Question>[
        ...r.questions,
        ...l.questions.where((q) => !seen.contains(q.id)),
      ];
      // Konu kartı her zaman dersin başında kalsın (ana ekran ilk soruya bakıyor).
      final ordered = <Question>[
        ...combined.where((q) => q.type == QuestionType.conceptCard),
        ...combined.where((q) => q.type != QuestionType.conceptCard),
      ];
      merged.add(Lesson(
        id: l.id,
        title: r.title.isNotEmpty ? r.title : l.title,
        description: r.description.isNotEmpty ? r.description : l.description,
        xpReward: l.xpReward,
        gemReward: l.gemReward,
        questions: ordered,
        isUnitExam: l.isUnitExam,
      ));
    }

    for (final r in remote.lessons) {
      if (!localIds.contains(r.id) && r.questions.isNotEmpty) {
        merged.add(r);
      }
    }

    return local.copyWith(lessons: merged, isDownloaded: true);
  }

  /// Ünite JSON'unu GitHub'dan çeker. Çevrimdışı/bulunamadı durumunda null döner.
  static Future<String?> _fetchRemoteBody(
      String repoName, String unitId) async {
    final remoteUrl = '$_githubRawBase/$repoName/main/curriculum/$unitId.json';
    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 6);
      final request = await client.getUrl(Uri.parse(remoteUrl));
      request.headers.set('User-Agent', 'QuestApp/$repoName');
      final response =
          await request.close().timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return await response
            .transform(utf8.decoder)
            .join()
            .timeout(const Duration(seconds: 15));
      }
      await response.drain<void>();
    } catch (e) {
      debugPrint('Remote indirme denemesi ($remoteUrl): $e');
    } finally {
      client?.close(force: true);
    }
    return null;
  }

  /// Belirli bir ünitenin içeriğini hazırlar.
  /// Sıra: önbellek -> internet (GitHub) -> uygulamadaki soru bankası -> asset.
  /// İnternetten gelen içerik yerel ünitenin üzerine eklenir, yerine geçmez.
  static Future<LearningUnit> loadUnitContent({
    required String repoName,
    required LearningUnit skeleton,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _cacheKey(repoName, skeleton.id);

    // Eski sürümün önbelleği (2 derslik bayat üniteler) artık kullanılmıyor; yer açmak için sil.
    final legacyKey = _legacyCacheKey(repoName, skeleton.id);
    if (prefs.containsKey(legacyKey)) {
      await prefs.remove(legacyKey);
    }

    final local = _buildLocalUnit(skeleton.id);

    // 1. Önbellek
    final cached = prefs.getString(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      if (cached != _localMarker) {
        final remote = _parseRemoteUnit(cached, skeleton.id);
        if (remote != null) return _mergeRemoteIntoLocal(local, remote);
      }
      if (local != null) return local;
    }

    // 2. İnternet (GitHub Raw)
    final body = await _fetchRemoteBody(repoName, skeleton.id);
    if (body != null) {
      final remote = _parseRemoteUnit(body, skeleton.id);
      if (remote != null) {
        await prefs.setString(cacheKey, body);
        return _mergeRemoteIntoLocal(local, remote);
      }
    }

    // 3. Uygulamadaki tam ünite (çevrimdışı güvence)
    if (local != null) {
      await prefs.setString(cacheKey, _localMarker);
      return local;
    }

    // 4. Uygulamada tanımlı olmayan ünite: eski uzak/asset içeriğini olduğu gibi kullan
    try {
      final assetString = body ??
          await rootBundle.loadString('assets/curriculum/${skeleton.id}.json');
      final decoded = jsonDecode(assetString) as Map<String, dynamic>;
      final unit = LearningUnit.fromJson(decoded, isDownloaded: true);
      if (unit.isLoaded) return unit;
    } catch (_) {}

    throw const HttpException('Ünite içeriği internetten ve yerel kaynaktan yüklenemedi.');
  }

  /// Daha önce açılmış ünitelerin GitHub'daki güncel halini arka planda kontrol eder
  /// (en fazla günde bir). Yeni içerik bir sonraki açılışta derslere eklenir.
  static Future<void> refreshCachedUnits({
    required String repoName,
    required List<String> unitIds,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stampKey = 'curriculum_refresh_at_$repoName';
      final now = DateTime.now().millisecondsSinceEpoch;
      final last = prefs.getInt(stampKey) ?? 0;
      if (now - last < const Duration(hours: 24).inMilliseconds) return;

      bool anySuccess = false;
      int consecutiveFailures = 0;
      for (final id in unitIds) {
        final key = _cacheKey(repoName, id);
        if (!prefs.containsKey(key)) continue;
        final body = await _fetchRemoteBody(repoName, id);
        if (body == null) {
          consecutiveFailures++;
          // Büyük olasılıkla çevrimdışı: boşuna denemeye devam etme
          if (!anySuccess && consecutiveFailures >= 2) return;
          continue;
        }
        anySuccess = true;
        consecutiveFailures = 0;
        if (_parseRemoteUnit(body, id) != null && prefs.getString(key) != body) {
          await prefs.setString(key, body);
        }
      }
      if (anySuccess) await prefs.setInt(stampKey, now);
    } catch (e) {
      debugPrint('Müfredat güncelleme kontrolü hatası: $e');
    }
  }

  /// Kullanıcının tüm üniteleri tek tıkla indirmesini sağlar
  static Future<int> downloadAllUnits({
    required String repoName,
    required List<LearningUnit> units,
    Function(int completed, int total)? onProgress,
  }) async {
    int count = 0;
    for (int i = 0; i < units.length; i++) {
      try {
        await loadUnitContent(repoName: repoName, skeleton: units[i]);
        count++;
        onProgress?.call(count, units.length);
      } catch (e) {
        debugPrint('Toplu indirmede ünite atlandı: ${units[i].id} - $e');
      }
    }
    return count;
  }
}
