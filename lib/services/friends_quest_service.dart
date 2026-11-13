import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FriendInfo {
  final String uid;
  final String friendCode;
  final String displayName;
  final int xp;
  final int level;
  final int streak;
  final int weeklyXp;
  final int league;
  final String? weekKey;
  final String? photoUrl;

  const FriendInfo({
    required this.uid,
    required this.friendCode,
    required this.displayName,
    required this.xp,
    required this.level,
    required this.streak,
    this.weeklyXp = 0,
    this.league = 0,
    this.weekKey,
    this.photoUrl,
  });

  /// Bu haftaya ait XP. Oyuncu bu hafta henüz uygulamayı açmadıysa kayıttaki
  /// weeklyXp geçen haftadan kalmıştır; o durumda 0 sayılır.
  int get currentWeeklyXp =>
      weekKey == FriendsQuestService.weekKeyFor(DateTime.now()) ? weeklyXp : 0;

  factory FriendInfo.fromMap(String uid, Map<String, dynamic> map) {
    return FriendInfo(
      uid: uid,
      friendCode: map['friendCode']?.toString() ?? 'DGS-0000',
      displayName: map['displayName']?.toString() ?? 'DGS Öğrencisi',
      xp: (map['xp'] as num?)?.toInt() ?? 0,
      level: (map['level'] as num?)?.toInt() ?? 1,
      streak: (map['streak'] as num?)?.toInt() ?? 0,
      weeklyXp: (map['weeklyXp'] as num?)?.toInt() ?? 0,
      league: (map['league'] as num?)?.toInt() ?? 0,
      weekKey: map['weekKey']?.toString(),
      photoUrl: map['photoUrl']?.toString(),
    );
  }
}

/// Hafta sonunda lig sonucunun özeti (kullanıcıya bir kez gösterilir).
class LeagueWeekResult {
  final int oldLeague;
  final int newLeague;
  final int? rank;
  final int groupSize;
  final int weeklyXp;

  const LeagueWeekResult({
    required this.oldLeague,
    required this.newLeague,
    required this.rank,
    required this.groupSize,
    required this.weeklyXp,
  });

  bool get promoted => newLeague > oldLeague;
  bool get demoted => newLeague < oldLeague;
}

class CoopFriendQuest {
  final String questId;
  final String partnerUid;
  final String partnerName;
  final String partnerCode;
  final int myXpContribution;
  final int partnerXpContribution;
  final int targetXp;
  final bool isRewardClaimedByMe;

  const CoopFriendQuest({
    required this.questId,
    required this.partnerUid,
    required this.partnerName,
    required this.partnerCode,
    required this.myXpContribution,
    required this.partnerXpContribution,
    this.targetXp = 500,
    this.isRewardClaimedByMe = false,
  });

  int get totalXp => myXpContribution + partnerXpContribution;
  double get progress => targetXp > 0 ? (totalXp / targetXp).clamp(0.0, 1.0) : 0.0;
  bool get isCompleted => totalXp >= targetXp;
}

class FriendsQuestService {
  FriendsQuestService._();
  static final FriendsQuestService instance = FriendsQuestService._();

  static const String _keyLocalFriendCode = 'local_friend_code_v1';
  static const String _keyDisplayName = 'local_display_name_v1';

  bool _isFirebaseReady = false;
  String? _uid;
  String _myFriendCode = 'DGS-0000';
  String _myDisplayName = 'DGS Şampiyonu';
  String? _userEmail;
  String? _photoUrl;

  bool get isFirebaseReady => _isFirebaseReady;
  bool get isGoogleSignedIn {
    if (!_isFirebaseReady) return false;
    final user = FirebaseAuth.instance.currentUser;
    return user != null && !user.isAnonymous;
  }

  String? get uid => _uid;
  String get myFriendCode => _myFriendCode;
  String get myDisplayName => _myDisplayName;
  String? get userEmail => _userEmail;
  String? get photoUrl => _photoUrl;

  Future<void>? _initFuture;
  Timer? _backupTimer;

  // ---------------- Haftalık Lig ----------------
  /// Lig sayısı (0: Bronz ... 9: Elmas). LeaderboardScreen'deki LeagueTier ile aynı sırada.
  static const int maxLeagueIndex = 9;
  static const int promoteCount = 5; // İlk 5 üst lige çıkar
  static const int demoteCount = 5; // Son 5 düşer (grup 10+ kişiyse)
  int _league = 0;
  String? _weekKey;
  LeagueWeekResult? _pendingLeagueResult;

  int get myLeague => _league;

  /// Hafta sonu lig sonucunu bir kez döner (ekranda kutlama/uyarı göstermek için).
  LeagueWeekResult? takePendingLeagueResult() {
    final r = _pendingLeagueResult;
    _pendingLeagueResult = null;
    return r;
  }

  /// ISO hafta anahtarı, ör. "2026-W46". Haftalar Pazartesi 00:00'da başlar (yerel saat).
  static String weekKeyFor(DateTime date) {
    // Herkes için aynı hafta: cihazın saat diliminden bağımsız, Türkiye saati (UTC+3)
    final tr = date.toUtc().add(const Duration(hours: 3));
    final d = DateTime.utc(tr.year, tr.month, tr.day);
    final thursday = d.add(Duration(days: 4 - d.weekday));
    final firstJan = DateTime.utc(thursday.year, 1, 1);
    final week = (thursday.difference(firstJan).inDays ~/ 7) + 1;
    return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
  }

  /// Bu haftanın bitişi (gelecek Pazartesi 00:00).
  static DateTime currentWeekEnd() {
    // Gelecek Pazartesi 00:00 (Türkiye saati) = Pazar 21:00 UTC
    final tr = DateTime.now().toUtc().add(const Duration(hours: 3));
    final todayTr = DateTime.utc(tr.year, tr.month, tr.day);
    final nextMondayTr = todayTr.add(Duration(days: 8 - todayTr.weekday));
    return nextMondayTr.subtract(const Duration(hours: 3)).toLocal();
  }

  /// Bağlı Google hesabının sağlayıcı bilgisi (anonimden bağlanan hesaplarda ad/foto burada durur).
  UserInfo? _googleProvider(User user) {
    for (final p in user.providerData) {
      if (p.providerId == 'google.com') return p;
    }
    return null;
  }

  String? _googleProfileName(User user) {
    final n = user.displayName ?? _googleProvider(user)?.displayName;
    return (n != null && n.trim().isNotEmpty) ? n.trim() : null;
  }

  /// Başlatmayı bir kez yapar; tekrar çağrılırsa aynı işlemi bekler.
  Future<void> ensureInitialized() => initialize();

  /// Firebase'i güvenli şekilde başlatır; test/offline ortamda uygulamayı kilitlemez.
  Future<void> initialize({int initialXp = 0, int initialLevel = 1, int initialStreak = 0}) async {
    _initFuture ??= _initializeInternal(initialXp, initialLevel, initialStreak);
    await _initFuture;
  }

  Future<void> _initializeInternal(int initialXp, int initialLevel, int initialStreak) async {
    final prefs = await SharedPreferences.getInstance();
    _myFriendCode = prefs.getString(_keyLocalFriendCode) ?? _generateFriendCode();
    await prefs.setString(_keyLocalFriendCode, _myFriendCode);
    _myDisplayName = prefs.getString(_keyDisplayName) ?? 'DGS Öğrencisi';

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      final auth = FirebaseAuth.instance;
      User? user = auth.currentUser;
      if (user == null) {
        // Çevrimdışıyken açılışın takılmaması için zaman aşımı
        final cred = await auth.signInAnonymously().timeout(const Duration(seconds: 8));
        user = cred.user;
      }
      if (user != null) {
        _uid = user.uid;
        _isFirebaseReady = true;
        if (!user.isAnonymous) {
          _myDisplayName = _googleProfileName(user) ?? _myDisplayName;
          _userEmail = user.email ?? _googleProvider(user)?.email;
          _photoUrl = user.photoURL ?? _googleProvider(user)?.photoURL;
        }
        await _ensureUserDocument(initialXp, initialLevel, initialStreak)
            .timeout(const Duration(seconds: 8));
      }
    } catch (e) {
      _isFirebaseReady = false;
      debugPrint('[FriendsQuestService] Offline/Test modu: $e');
    }
  }

  /// Google Hesabı ile giriş yapar veya mevcut misafir hesabını Google hesabına bağlar.
  Future<String> signInWithGoogle({
    required int currentXp,
    required int currentLevel,
    required int currentStreak,
  }) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      // Klasik Google hesap seçici (google_sign_in 6.x). 7.x'in Credential Manager paneli
      // MEmu gibi Android 9 emülatörlerinde sistemi çökertiyordu; tarayıcı tabanlı giriş ise
      // "quest-a182f.firebaseapp.com" adresini gösterip şüpheli görünüyordu.
      final googleUser = await GoogleSignIn(scopes: const ['email']).signIn();
      if (googleUser == null) {
        return 'Giriş iptal edildi.';
      }
      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        return 'Google kimlik doğrulama anahtarı alınamadı.';
      }
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;

      UserCredential userCred;
      if (currentUser != null && currentUser.isAnonymous) {
        try {
          userCred = await currentUser.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' ||
              e.code == 'email-already-in-use' ||
              e.code == 'provider-already-linked') {
            // Bu Google hesabı daha önce kullanılmış: o hesaba geç.
            // Geride kalan boş misafir kaydını sil ki ligde "hayalet" oyuncu olarak kalmasın.
            final orphanUid = currentUser.uid;
            try {
              await FirebaseFirestore.instance.collection('users').doc(orphanUid).delete();
            } catch (err) {
              debugPrint('[FriendsQuestService] Misafir kaydı silinemedi: $err');
            }
            try {
              await currentUser.delete();
            } catch (_) {}
            userCred = await auth.signInWithCredential(e.credential ?? credential);
          } else {
            rethrow;
          }
        }
      } else {
        userCred = await auth.signInWithCredential(credential);
      }

      final user = userCred.user;
      if (user == null) {
        return 'Kullanıcı oturumu oluşturulamadı.';
      }

      _uid = user.uid;
      _isFirebaseReady = true;
      // Anonim hesap Google'a bağlanınca Firebase kullanıcısının displayName'i boş kalır;
      // adı doğrudan Google hesabından al.
      _myDisplayName = (googleUser.displayName?.trim().isNotEmpty ?? false)
          ? googleUser.displayName!.trim()
          : (_googleProfileName(user) ?? 'DGS Öğrencisi');
      _userEmail = googleUser.email;
      _photoUrl = googleUser.photoUrl ?? user.photoURL;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyDisplayName, _myDisplayName);

      // Firestore'daki kullanıcı kaydını güncelle veya mevcut kaydı çek
      final docRef = FirebaseFirestore.instance.collection('users').doc(_uid);
      final snap = await docRef.get();
      if (!snap.exists) {
        await _ensureUniqueFriendCode();
        await docRef.set({
          'friendCode': _myFriendCode,
          'displayName': _myDisplayName,
          'photoUrl': _photoUrl,
          'xp': currentXp,
          'level': currentLevel,
          'streak': currentStreak,
          'friends': <String>[],
          'league': 0,
          'weeklyXp': 0,
          'weekKey': weekKeyFor(DateTime.now()),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _league = 0;
        _weekKey = weekKeyFor(DateTime.now());
      } else {
        final data = snap.data();
        if (data != null && data['friendCode'] != null) {
          _myFriendCode = data['friendCode'].toString();
          await prefs.setString(_keyLocalFriendCode, _myFriendCode);
        }
        // Başka cihazda kullanılan hesaba geçildiyse o hesabın lig bilgisini yükle
        try {
          await _processWeekRollover(data ?? const {});
        } catch (e) {
          debugPrint('[FriendsQuestService] Lig yükleme hatası: $e');
        }
        await docRef.set({
          'displayName': _myDisplayName,
          // E-posta herkese açık profile yazılmaz (diğer oyuncular okuyabiliyor).
          'email': FieldValue.delete(),
          'photoUrl': _photoUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return 'OK:$_myDisplayName';
    } catch (e) {
      debugPrint('[FriendsQuestService] Google giriş hatası: $e');
      if (e.toString().contains('canceled') || e.toString().contains('cancelled')) {
        return 'Giriş iptal edildi.';
      }
      return 'Google ile giriş yapılamadı: $e';
    }
  }

  /// Buluttaki tam ilerleme yedeğini getirir (yoksa null).
  Future<Map<String, dynamic>?> fetchRemoteProgress() async {
    if (!_isFirebaseReady || _uid == null) return null;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .get()
          .timeout(const Duration(seconds: 8));
      final progress = snap.data()?['progress'];
      if (progress is Map<String, dynamic>) return progress;
      return null;
    } catch (e) {
      debugPrint('[FriendsQuestService] İlerleme çekme hatası: $e');
      return null;
    }
  }

  /// İlerlemeyi 4 sn gecikmeyle (art arda yazmaları birleştirerek) buluta yedekler.
  /// Sadece Google hesabı bağlı kullanıcılar için çalışır.
  void scheduleProgressBackup(Map<String, dynamic> snapshot) {
    if (!isGoogleSignedIn || _uid == null) return;
    _backupTimer?.cancel();
    _backupTimer = Timer(const Duration(seconds: 4), () async {
      try {
        await FirebaseFirestore.instance.collection('users').doc(_uid).set({
          'progress': snapshot,
          'xp': snapshot['xp'],
          'streak': snapshot['streak'],
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('[FriendsQuestService] Yedekleme hatası: $e');
      }
    });
  }

  /// Tüm oyuncular arasında XP'ye göre ilk [limit] kişiyi getirir (gerçek lig tablosu).
  /// Çevrimdışıysa boş liste döner; ekran o zaman örnek tabloyu gösterir.
  Future<List<FriendInfo>> fetchGlobalLeaderboard({int limit = 30}) async {
    if (!_isFirebaseReady || _uid == null) return const [];
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('xp', descending: true)
          .limit(limit)
          .get()
          .timeout(const Duration(seconds: 8));
      return snap.docs.map((d) => FriendInfo.fromMap(d.id, d.data())).toList();
    } catch (e) {
      debugPrint('[FriendsQuestService] Lig tablosu hatası: $e');
      return const [];
    }
  }

  /// Google hesabından çıkış yapar ve misafir (anonim) oturuma döner.
  Future<void> signOutGoogle() async {
    try {
      _backupTimer?.cancel();
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
      await FirebaseAuth.instance.signOut();
      _userEmail = null;
      _photoUrl = null;
      _myDisplayName = 'DGS Öğrencisi';
      _league = 0;
      _weekKey = null;
      _pendingLeagueResult = null;
      // Misafir oturumu Google hesabının arkadaş kodunu taşımasın: aynı kod iki kayıtta
      // olursa arkadaş ekleme yanlış (misafir) kayda gidebiliyordu.
      _myFriendCode = _generateFriendCode();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLocalFriendCode, _myFriendCode);
      await prefs.setString(_keyDisplayName, _myDisplayName);

      final cred = await FirebaseAuth.instance.signInAnonymously();
      _uid = cred.user?.uid;
      if (_uid != null) {
        await _ensureUserDocument(0, 1, 0).timeout(const Duration(seconds: 8));
      }
    } catch (e) {
      debugPrint('[FriendsQuestService] Çıkış hatası: $e');
    }
  }

  String _generateFriendCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    // 6 karakter (~1 milyar olasılık). Eski 4 karakterli kodlar çalışmaya devam eder.
    final suffix = List.generate(6, (_) => chars[rnd.nextInt(chars.length)]).join();
    return 'DGS-$suffix';
  }

  /// Kod başka bir oyuncuda kullanılıyorsa yenisini üretir. Kayıt ilk kez oluşturulurken çağrılır.
  Future<void> _ensureUniqueFriendCode() async {
    try {
      final users = FirebaseFirestore.instance.collection('users');
      for (int attempt = 0; attempt < 5; attempt++) {
        final snap = await users
            .where('friendCode', isEqualTo: _myFriendCode)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 6));
        if (snap.docs.isEmpty || snap.docs.first.id == _uid) break;
        _myFriendCode = _generateFriendCode();
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLocalFriendCode, _myFriendCode);
    } catch (e) {
      debugPrint('[FriendsQuestService] Kod benzersizlik kontrolü hatası: $e');
    }
  }

  Future<void> _ensureUserDocument(int xp, int level, int streak) async {
    if (!_isFirebaseReady || _uid == null) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(_uid);
    final snap = await docRef.get();
    if (!snap.exists) {
      await _ensureUniqueFriendCode();
      await docRef.set({
        'friendCode': _myFriendCode,
        'displayName': _myDisplayName,
        'xp': xp,
        'level': level,
        'streak': streak,
        'friends': <String>[],
        'league': 0,
        'weeklyXp': 0,
        'weekKey': weekKeyFor(DateTime.now()),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _league = 0;
      _weekKey = weekKeyFor(DateTime.now());
    } else {
      final data = snap.data();
      if (data != null && data['friendCode'] != null) {
        _myFriendCode = data['friendCode'].toString();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyLocalFriendCode, _myFriendCode);
      }
      if (data != null && data['displayName'] != null) {
        _myDisplayName = data['displayName'].toString();
      }
      try {
        await _processWeekRollover(data ?? const {});
      } catch (e) {
        debugPrint('[FriendsQuestService] Lig haftası geçişi hatası: $e');
      }
    }
  }

  /// Yeni haftaya geçildiyse geçen haftanın sıralamasını hesaplar ve ligi günceller.
  /// Sunucu (Cloud Functions) olmadan çalışır: her kullanıcı yeni haftada uygulamayı
  /// ilk açtığında kendi sonucunu hesaplar. Geçen haftanın puanını prevWeeklyXp alanında
  /// sakladığımız için, önce geçiş yapanlar da sıralamadan düşmez.
  Future<void> _processWeekRollover(Map<String, dynamic> data) async {
    if (!_isFirebaseReady || _uid == null) return;
    final current = weekKeyFor(DateTime.now());
    final stored = data['weekKey']?.toString();
    final oldLeague = ((data['league'] as num?)?.toInt() ?? 0).clamp(0, maxLeagueIndex);
    _league = oldLeague;

    final docRef = FirebaseFirestore.instance.collection('users').doc(_uid);

    if (stored == null) {
      // Lig sistemi öncesinden kalan hesap: bu haftadan başlat
      await docRef.set({'league': oldLeague, 'weeklyXp': 0, 'weekKey': current}, SetOptions(merge: true));
      _weekKey = current;
      return;
    }
    if (stored == current) {
      _weekKey = current;
      return;
    }

    final myWeekly = (data['weeklyXp'] as num?)?.toInt() ?? 0;
    int newLeague = oldLeague;
    int? myRank;
    int groupSize = 0;

    if (myWeekly > 0) {
      final users = FirebaseFirestore.instance.collection('users');
      final results = await Future.wait([
        // Henüz yeni haftaya geçmemiş olanlar
        users.where('league', isEqualTo: oldLeague).where('weekKey', isEqualTo: stored).get(),
        // Yeni haftaya geçmiş olanlar (geçen haftanın puanı prev* alanlarında)
        users.where('prevLeague', isEqualTo: oldLeague).where('prevWeekKey', isEqualTo: stored).get(),
      ]).timeout(const Duration(seconds: 10));

      final scores = <String, int>{};
      for (final d in results[0].docs) {
        scores[d.id] = (d.data()['weeklyXp'] as num?)?.toInt() ?? 0;
      }
      for (final d in results[1].docs) {
        scores.putIfAbsent(d.id, () => (d.data()['prevWeeklyXp'] as num?)?.toInt() ?? 0);
      }
      scores[_uid!] = myWeekly;
      final ranked = scores.entries.where((e) => e.value > 0).toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      groupSize = ranked.length;
      myRank = ranked.indexWhere((e) => e.key == _uid) + 1;

      if (myRank <= promoteCount && oldLeague < maxLeagueIndex) {
        newLeague = oldLeague + 1;
      } else if (groupSize >= promoteCount + demoteCount &&
          myRank > groupSize - demoteCount &&
          oldLeague > 0) {
        newLeague = oldLeague - 1;
      }
    } else if (oldLeague > 0) {
      // Hiç XP kazanmadan geçen hafta: bir alt lige düşer
      newLeague = oldLeague - 1;
    }

    await docRef.set({
      'league': newLeague,
      'weekKey': current,
      'weeklyXp': 0,
      'prevLeague': oldLeague,
      'prevWeekKey': stored,
      'prevWeeklyXp': myWeekly,
      'prevRank': myRank,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _league = newLeague;
    _weekKey = current;
    _pendingLeagueResult = LeagueWeekResult(
      oldLeague: oldLeague,
      newLeague: newLeague,
      rank: myRank,
      groupSize: groupSize,
      weeklyXp: myWeekly,
    );
  }

  /// Hafta uygulama açıkken değiştiyse geçişi yapar.
  Future<void> _ensureCurrentWeek() async {
    if (!_isFirebaseReady || _uid == null) return;
    if (_weekKey == weekKeyFor(DateTime.now())) return;
    final snap = await FirebaseFirestore.instance.collection('users').doc(_uid).get();
    await _processWeekRollover(snap.data() ?? const {});
  }

  /// Kendi ligimdeki bu haftanın sıralamasını CANLI dinler: biri XP kazandığında
  /// Firestore anında yeni listeyi gönderir, ekran kendiliğinden güncellenir.
  Stream<List<FriendInfo>> watchLeagueBoard({int limit = 50}) async* {
    if (!_isFirebaseReady || _uid == null) {
      yield const [];
      return;
    }
    try {
      await _ensureCurrentWeek();
    } catch (e) {
      debugPrint('[FriendsQuestService] Hafta kontrolü hatası: $e');
    }
    yield* FirebaseFirestore.instance
        .collection('users')
        .where('league', isEqualTo: _league)
        .where('weekKey', isEqualTo: _weekKey ?? weekKeyFor(DateTime.now()))
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => FriendInfo.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => b.weeklyXp.compareTo(a.weeklyXp));
      return list.length > limit ? list.sublist(0, limit) : list;
    });
  }

  /// Kullanıcının kendi ligindeki bu haftanın sıralaması (haftalık XP'ye göre).
  Future<List<FriendInfo>> fetchLeagueBoard({int limit = 50}) async {
    if (!_isFirebaseReady || _uid == null) return const [];
    try {
      await _ensureCurrentWeek();
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('league', isEqualTo: _league)
          .where('weekKey', isEqualTo: _weekKey)
          .get()
          .timeout(const Duration(seconds: 10));
      final list = snap.docs.map((d) => FriendInfo.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => b.weeklyXp.compareTo(a.weeklyXp));
      return list.length > limit ? list.sublist(0, limit) : list;
    } catch (e) {
      debugPrint('[FriendsQuestService] Lig tablosu hatası: $e');
      return const [];
    }
  }

  Future<void> updateDisplayName(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    _myDisplayName = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDisplayName, trimmed);

    if (_isFirebaseReady && _uid != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(_uid).update({
          'displayName': trimmed,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('[FriendsQuestService] İsim güncelleme hatası: $e');
      }
    }
  }

  /// Ders veya deneme bittiğinde kazanılan XP'yi buluta ve aktif arkadaş görevlerine işler.
  /// Hile koruması: Tek işlemde en fazla 500 XP işlenir.
  Future<void> syncXpGain({
    required int addedXp,
    required int totalXp,
    required int level,
    required int streak,
  }) async {
    if (!_isFirebaseReady || _uid == null || addedXp <= 0) return;
    final safeAddedXp = addedXp.clamp(0, 500);

    try {
      final db = FirebaseFirestore.instance;
      try {
        await _ensureCurrentWeek();
      } catch (e) {
        debugPrint('[FriendsQuestService] Hafta kontrolü hatası: $e');
      }
      await db.collection('users').doc(_uid).set({
        'friendCode': _myFriendCode,
        'displayName': _myDisplayName,
        'xp': totalXp,
        'level': level,
        'streak': streak,
        // Haftalık lig puanı
        'weeklyXp': FieldValue.increment(safeAddedXp),
        'weekKey': _weekKey ?? weekKeyFor(DateTime.now()),
        'league': _league,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Kullanıcının aktif arkadaş görevlerine XP katkısı ekle
      final questsSnap = await db
          .collection('friend_quests')
          .where('participants', arrayContains: _uid)
          .get();

      for (final doc in questsSnap.docs) {
        await doc.reference.update({
          'xpByUser.$_uid': FieldValue.increment(safeAddedXp),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('[FriendsQuestService] XP senkronizasyon hatası: $e');
    }
  }

  /// Arkadaş kodu ile arkadaş ekler ve ikili arasında otomatik 500 XP Ortak Görevi başlatır.
  Future<String> addFriendByCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) return 'Lütfen geçerli bir arkadaş kodu girin.';
    if (code == _myFriendCode) return 'Kendi kodunu arkadaş olarak ekleyemezsin.';

    if (!_isFirebaseReady || _uid == null) {
      return 'İnternet bağlantısı veya Firebase oturumu hazır değil.';
    }

    try {
      final db = FirebaseFirestore.instance;
      final query = await db
          .collection('users')
          .where('friendCode', isEqualTo: code)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return '"$code" koduna sahip bir öğrenci bulunamadı.';
      }

      final partnerDoc = query.docs.first;
      final partnerUid = partnerDoc.id;
      if (partnerUid == _uid) return 'Kendi kodunu arkadaş olarak ekleyemezsin.';
      final partnerData = partnerDoc.data();
      final partnerName = partnerData['displayName']?.toString() ?? 'DGS Arkadaşı';

      // İki tarafın arkadaş listesine ekle
      await db.collection('users').doc(_uid).update({
        'friends': FieldValue.arrayUnion([partnerUid]),
      });
      await db.collection('users').doc(partnerUid).update({
        'friends': FieldValue.arrayUnion([_uid]),
      });

      // Deterministik görev ID'si oluştur (aynı ikili için tekrar oluşmasın)
      final pair = [_uid!, partnerUid]..sort();
      final questId = '${pair[0]}_${pair[1]}';
      final questRef = db.collection('friend_quests').doc(questId);
      final questSnap = await questRef.get();

      if (!questSnap.exists) {
        await questRef.set({
          'participants': pair,
          'targetXp': 500,
          'xpByUser': {
            _uid!: 0,
            partnerUid: 0,
          },
          'rewardClaimedBy': <String>[],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return 'OK:$partnerName';
    } catch (e) {
      debugPrint('[FriendsQuestService] Arkadaş ekleme hatası: $e');
      return 'Arkadaş eklenirken bir hata oluştu. İnternet bağlantını kontrol et.';
    }
  }

  /// Arkadaş listesini ve aktif ortak XP görevlerini tek seferlik (düşük maliyetli) çeker.
  /// `me`: arkadaş sıralamasında kullanıcının kendi satırı (haftalık XP dahil).
  Future<({List<FriendInfo> friends, List<CoopFriendQuest> quests, FriendInfo? me})> fetchDashboardData() async {
    if (!_isFirebaseReady || _uid == null) {
      return (friends: <FriendInfo>[], quests: <CoopFriendQuest>[], me: null);
    }

    try {
      final db = FirebaseFirestore.instance;
      final myDoc = await db.collection('users').doc(_uid).get();
      final friendUids = (myDoc.data()?['friends'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      final List<FriendInfo> friends = [];
      final Map<String, FriendInfo> friendMap = {};

      final myData = myDoc.data();
      final FriendInfo? me = myData != null ? FriendInfo.fromMap(_uid!, myData) : null;

      // Arkadaş kayıtlarını sırayla değil aynı anda çek (liste uzadıkça ekran yavaşlamasın)
      final friendDocs = await Future.wait(
        friendUids.where((id) => id != _uid).map((id) => db.collection('users').doc(id).get()),
      );
      for (final fDoc in friendDocs) {
        final fData = fDoc.data();
        if (fDoc.exists && fData != null) {
          final info = FriendInfo.fromMap(fDoc.id, fData);
          friends.add(info);
          friendMap[fDoc.id] = info;
        }
      }

      final questsSnap = await db
          .collection('friend_quests')
          .where('participants', arrayContains: _uid)
          .get();

      final List<CoopFriendQuest> quests = [];
      for (final qDoc in questsSnap.docs) {
        final data = qDoc.data();
        final participants = (data['participants'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final partnerUid = participants.firstWhere(
          (id) => id != _uid,
          orElse: () => '',
        );
        if (partnerUid.isEmpty) continue;

        final partnerInfo = friendMap[partnerUid];
        final xpMap = (data['xpByUser'] as Map<String, dynamic>?) ?? {};
        final claimedBy = (data['rewardClaimedBy'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

        quests.add(
          CoopFriendQuest(
            questId: qDoc.id,
            partnerUid: partnerUid,
            partnerName: partnerInfo?.displayName ?? 'DGS Arkadaşı',
            partnerCode: partnerInfo?.friendCode ?? 'DGS-????',
            myXpContribution: (xpMap[_uid] as num?)?.toInt() ?? 0,
            partnerXpContribution: (xpMap[partnerUid] as num?)?.toInt() ?? 0,
            targetXp: (data['targetXp'] as num?)?.toInt() ?? 500,
            isRewardClaimedByMe: claimedBy.contains(_uid),
          ),
        );
      }

      friends.sort((a, b) => b.xp.compareTo(a.xp));
      return (friends: friends, quests: quests, me: me);
    } catch (e) {
      debugPrint('[FriendsQuestService] Veri çekme hatası: $e');
      return (friends: <FriendInfo>[], quests: <CoopFriendQuest>[], me: null);
    }
  }

  /// Ortak görev tamamlandığında (+500 XP) kullanıcının ödülünü işler.
  Future<bool> claimQuestReward(String questId) async {
    if (!_isFirebaseReady || _uid == null) return false;
    try {
      final docRef = FirebaseFirestore.instance.collection('friend_quests').doc(questId);
      final snap = await docRef.get();
      if (!snap.exists || snap.data() == null) return false;

      final data = snap.data()!;
      final xpMap = (data['xpByUser'] as Map<String, dynamic>?) ?? {};
      final total = xpMap.values.fold<int>(0, (acc, v) => acc + ((v as num?)?.toInt() ?? 0));
      final target = (data['targetXp'] as num?)?.toInt() ?? 500;
      final claimedBy = (data['rewardClaimedBy'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      if (total >= target && !claimedBy.contains(_uid)) {
        await docRef.update({
          'rewardClaimedBy': FieldValue.arrayUnion([_uid]),
        });
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[FriendsQuestService] Ödül alma hatası: $e');
      return false;
    }
  }
}
