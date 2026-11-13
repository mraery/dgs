import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../services/friends_quest_service.dart';
import '../services/sound_service.dart';
import '../widgets/league_board.dart';

/// Duolingo tarzı 10 lig (sıra = Firebase'deki 'league' alanı: 0 Bronz ... 9 Elmas).
/// Sırayı değiştirmeyin; mevcut oyuncuların lig numarası bu sıraya göre kayıtlı.
enum LeagueTier {
  bronze('Bronz Lig', '🥉', Color(0xFFCD7F32), 0),
  silver('Gümüş Lig', '🥈', Color(0xFF94A3B8), 0),
  gold('Altın Lig', '🥇', Color(0xFFF59E0B), 0),
  sapphire('Safir Lig', '🔷', Color(0xFF2563EB), 0),
  ruby('Yakut Lig', '🔴', Color(0xFFDC2626), 0),
  emerald('Zümrüt Lig', '💚', Color(0xFF10B981), 0),
  amethyst('Ametist Lig', '🔮', Color(0xFF8B5CF6), 0),
  pearl('İnci Lig', '⚪', Color(0xFFEC4899), 0),
  obsidian('Obsidyen Lig', '🖤', Color(0xFF374151), 0),
  diamond('Elmas Lig', '💎', Color(0xFF06B6D4), 0);

  final String title;
  final String icon;
  final Color color;
  final int minXp;

  const LeagueTier(this.title, this.icon, this.color, this.minXp);
}

class LeaderboardPlayer {
  final String name;
  final int xp;
  final String avatar;
  final bool isUser;

  const LeaderboardPlayer({
    required this.name,
    required this.xp,
    required this.avatar,
    this.isUser = false,
  });
}

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _friendCodeController = TextEditingController();
  bool _isLoadingFriends = false;
  bool _isAddingFriend = false;
  List<FriendInfo> _friends = [];
  FriendInfo? _me;
  List<CoopFriendQuest> _coopQuests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 2 && !_tabController.indexIsChanging) {
        _refreshFriendsData();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _friendCodeController.dispose();
    super.dispose();
  }

  Future<void> _refreshFriendsData() async {
    if (!mounted) return;
    setState(() => _isLoadingFriends = true);
    final data = await FriendsQuestService.instance.fetchDashboardData();
    if (!mounted) return;
    setState(() {
      _friends = data.friends;
      _me = data.me;
      _coopQuests = data.quests;
      _isLoadingFriends = false;
    });
  }

  Future<void> _handleAddFriend() async {
    final code = _friendCodeController.text.trim();
    if (code.isEmpty || _isAddingFriend) return;
    setState(() => _isAddingFriend = true);

    final result = await FriendsQuestService.instance.addFriendByCode(code);
    if (!mounted) return;
    setState(() => _isAddingFriend = false);

    if (result.startsWith('OK:')) {
      final partnerName = result.substring(3);
      _friendCodeController.clear();
      SoundService.playCorrect();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 $partnerName arkadaş eklendi ve 500 XP Ortak Görev başladı!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      await _refreshFriendsData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Lig, Görev & Arkadaşlar', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF10B981),
          unselectedLabelColor: isDark ? Colors.grey : const Color(0xFF64748B),
          indicatorColor: const Color(0xFF10B981),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          tabs: const [
            Tab(text: '🏆 LİG'),
            Tab(text: '🎯 GÖREVLER'),
            Tab(text: '🤝 ARKADAŞLAR'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Haftalık Lig (gerçek oyuncular, haftalık XP, yükselme/düşme)
          const LeagueBoard(),

          // TAB 2: Günlük ve Haftalık Görevler
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('GÜNLÜK GÖREVLER ⚡', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF64748B))),
              const SizedBox(height: 10),
              _buildQuestCard(
                title: '30 Soru Çöz',
                progress: (profile.questionsAnsweredCount % 30) / 30.0,
                progressText: '${profile.questionsAnsweredCount % 30} / 30 Soru',
                rewardXp: 30,
                rewardGems: 10,
                isCompleted: (profile.questionsAnsweredCount % 30) >= 30,
              ),
              const SizedBox(height: 10),
              _buildQuestCard(
                title: 'Günlük Serini Koru (1 Test Bitir)',
                progress: profile.streak > 0 ? 1.0 : 0.0,
                progressText: profile.streak > 0 ? 'Tamamlandı 🔥' : '0 / 1 Ders',
                rewardXp: 20,
                rewardGems: 5,
                isCompleted: profile.streak > 0,
              ),
              const SizedBox(height: 20),
              const Text('HAFTALIK BÜYÜK GÖREVLER 👑', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF64748B))),
              const SizedBox(height: 10),
              _buildQuestCard(
                title: '1 DGS Deneme Sınavı Tamamla',
                progress: 1.0,
                progressText: 'Hazır',
                rewardXp: 100,
                rewardGems: 30,
                isCompleted: false,
              ),
              const SizedBox(height: 10),
              _buildQuestCard(
                title: '5 Üniteyi %100 Başarıyla Tamamla',
                progress: (profile.completedLessonIds.length / 35.0).clamp(0.0, 1.0),
                progressText: '${profile.completedLessonIds.length} / 35 Ders',
                rewardXp: 150,
                rewardGems: 50,
                isCompleted: profile.completedLessonIds.length >= 35,
              ),
            ],
          ),

          // TAB 3: Online Arkadaşlar & Birlikte XP Görevi
          RefreshIndicator(
            onRefresh: _refreshFriendsData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Benim Arkadaş Kodum Kartı
                if (!FriendsQuestService.instance.isGoogleSignedIn) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_circle_rounded, color: Color(0xFF2563EB), size: 32),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Arkadaşlarına adınla görünmek ve hesabını korumak için Google ile bağlan.',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            final res = await FriendsQuestService.instance.signInWithGoogle(
                              currentXp: profile.xp,
                              currentLevel: profile.level,
                              currentStreak: profile.streak,
                            );
                            if (res.startsWith('OK:') && mounted) {
                              await ref.read(userProfileProvider.notifier).pullCloudProgress();
                            }
                            if (!context.mounted) return;
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  res.startsWith('OK:')
                                      ? '🎉 ${res.substring(3)} olarak giriş yapıldı!'
                                      : res,
                                ),
                                backgroundColor: res.startsWith('OK:') ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              ),
                            );
                          },
                          child: const Text('GİRİŞ YAP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5)),
                        ),
                      ],
                    ),
                  ),
                ],

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'SENİN ARKADAŞ KODUN 🤝',
                            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w900),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 9,
                                  color: FriendsQuestService.instance.isFirebaseReady
                                      ? const Color(0xFF4ADE80)
                                      : const Color(0xFFFBBF24),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  FriendsQuestService.instance.isFirebaseReady ? 'Çevrimiçi' : 'Çevrimdışı',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            FriendsQuestService.instance.myFriendCode,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF4F46E5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text('KOPYALA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: FriendsQuestService.instance.myFriendCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Arkadaş kodun kopyalandı! Arkadaşına gönder.')),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Bu kodu arkadaşına ver veya onun kodunu aşağıya girerek birlikte 500 XP görevi başlat!',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Arkadaş Ekleme Alanı
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _friendCodeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'Arkadaş Kodu (Örn: DGS-A4K9X2)',
                          prefixIcon: const Icon(Icons.person_add_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isAddingFriend ? null : _handleAddFriend,
                        child: _isAddingFriend
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('EKLE', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Birlikte XP Görevleri
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'BİRLİKTE XP GÖREVLERİ ⚡',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF64748B)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      onPressed: _refreshFriendsData,
                      tooltip: 'Yenile',
                    ),
                  ],
                ),

                if (_isLoadingFriends)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_coopQuests.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: const Text(
                      'Henüz aktif bir arkadaş görevin yok. Arkadaş kodunu paylaş veya bir arkadaşını ekle, birlikte 500 XP toplayıp +50 💎 kazanın!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                  )
                else
                  ..._coopQuests.map((q) => _buildCoopQuestCard(q)),

                ..._buildFriendRanking(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Ben + arkadaşlarım: bu haftanın XP'sine göre sıralama (eşitlikte toplam XP).
  List<Widget> _buildFriendRanking() {
    if (_friends.isEmpty) return const <Widget>[];
    final myUid = FriendsQuestService.instance.uid;
    final me = _me;
    final ranking = <FriendInfo>[..._friends, ?me]
      ..sort((a, b) {
        final byWeek = b.currentWeeklyXp.compareTo(a.currentWeeklyXp);
        return byWeek != 0 ? byWeek : b.xp.compareTo(a.xp);
      });
    return <Widget>[
      const SizedBox(height: 20),
      const Text(
        'ARKADAŞ SIRALAMASI • BU HAFTA 🏅',
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF64748B)),
      ),
      const SizedBox(height: 10),
      for (int i = 0; i < ranking.length; i++)
        _buildFriendRankRow(i + 1, ranking[i], ranking[i].uid == myUid),
    ];
  }

  Widget _buildFriendRankRow(int rank, FriendInfo f, bool isMe) {
    final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '$rank';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF10B981).withOpacity(0.10) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? const Color(0xFF10B981) : Colors.grey.withOpacity(0.2),
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              medal,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '${f.displayName} (Sen)' : f.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                ),
                Text(
                  'Lv.${f.level} • 🔥 ${f.streak} Gün • Toplam ${f.xp} XP',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            '${f.currentWeeklyXp} XP',
            style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFD97706)),
          ),
        ],
      ),
    );
  }

  Widget _buildCoopQuestCard(CoopFriendQuest q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: q.isCompleted ? const Color(0xFF10B981) : const Color(0xFF6366F1).withOpacity(0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${q.partnerName} ile Ortak Görev',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '+50 💎 • +100 XP',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF10B981)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: q.progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(q.isCompleted ? const Color(0xFF10B981) : const Color(0xFF6366F1)),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sen: ${q.myXpContribution} XP  •  ${q.partnerName}: ${q.partnerXpContribution} XP',
                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              Text(
                '${q.totalXp} / ${q.targetXp} XP',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF6366F1)),
              ),
            ],
          ),
          if (q.isCompleted && !q.isRewardClaimedByMe) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.card_giftcard_rounded, size: 18),
                label: const Text('ORTAK ÖDÜLÜ AL (+50 💎 +100 XP)', style: TextStyle(fontWeight: FontWeight.w900)),
                onPressed: () async {
                  final ok = await FriendsQuestService.instance.claimQuestReward(q.questId);
                  if (ok && mounted) {
                    ref.read(userProfileProvider.notifier).addGems(50);
                    ref.read(userProfileProvider.notifier).addXp(100);
                    SoundService.playCorrect();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎉 Ortak görev ödülü alındı: +50 💎 ve +100 XP!'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                    await _refreshFriendsData();
                  }
                },
              ),
            ),
          ] else if (q.isRewardClaimedByMe) ...[
            const SizedBox(height: 8),
            const Text('✅ Ödül alındı!', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestCard({
    required String title,
    required double progress,
    required String progressText,
    required int rewardXp,
    required int rewardGems,
    required bool isCompleted,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('+$rewardXp XP • +$rewardGems 💎',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF10B981))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? const Color(0xFF10B981) : const Color(0xFF6366F1)),
            minHeight: 8,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 6),
          Text(progressText, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
