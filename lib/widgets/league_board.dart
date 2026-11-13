import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/game_provider.dart';
import '../screens/leaderboard_screen.dart' show LeagueTier;
import '../services/friends_quest_service.dart';
import '../services/sound_service.dart';
import 'parrot_mascot_widget.dart';

/// Duolingo tarzı haftalık lig tablosu.
/// - Herkes kendi ligindeki oyuncularla bu haftanın XP'sine göre yarışır.
/// - Hafta sonunda ilk 5 bir üst lige çıkar, son 5 (grup 10+ kişiyse) düşer.
class LeagueBoard extends ConsumerStatefulWidget {
  const LeagueBoard({super.key});

  @override
  ConsumerState<LeagueBoard> createState() => _LeagueBoardState();
}

class _LeagueBoardState extends ConsumerState<LeagueBoard> {
  List<FriendInfo> _players = const [];
  bool _loading = true;
  bool _offline = false;
  bool _resultChecked = false;
  StreamSubscription<List<FriendInfo>>? _sub;
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => _updateRemaining());
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    if (!mounted) return;
    setState(() => _remaining = FriendsQuestService.currentWeekEnd().difference(DateTime.now()));
  }

  /// Canlı lig akışına (yeniden) abone olur. Aşağı çekip yenileme de bunu çağırır.
  Future<void> _refresh() async {
    setState(() => _loading = true);
    final service = FriendsQuestService.instance;
    await service.ensureInitialized();
    await _sub?.cancel();
    if (!mounted) return;
    if (!service.isFirebaseReady) {
      setState(() {
        _offline = true;
        _loading = false;
      });
      return;
    }
    _offline = false;
    _sub = service.watchLeagueBoard().listen(
      (list) {
        if (!mounted) return;
        setState(() {
          _players = list;
          _loading = false;
        });
        // Hafta sonu sonucu (yükseldin/düştün) ilk veriden sonra bir kez gösterilir
        if (!_resultChecked) {
          _resultChecked = true;
          final result = service.takePendingLeagueResult();
          if (result != null) _showWeekResult(result);
        }
      },
      onError: (Object e) {
        debugPrint('[LeagueBoard] Canlı lig hatası: $e');
        if (mounted) setState(() => _loading = false);
      },
    );
  }

  String get _remainingText {
    final d = _remaining.isNegative ? Duration.zero : _remaining;
    if (d.inDays >= 1) return '${d.inDays} gün ${d.inHours % 24} saat';
    if (d.inHours >= 1) return '${d.inHours} saat ${d.inMinutes % 60} dk';
    return '${d.inMinutes} dk';
  }

  void _showWeekResult(LeagueWeekResult r) {
    final oldTier = LeagueTier.values[r.oldLeague.clamp(0, LeagueTier.values.length - 1)];
    final newTier = LeagueTier.values[r.newLeague.clamp(0, LeagueTier.values.length - 1)];
    final String title;
    final String body;
    final ParrotMood mood;
    if (r.promoted) {
      title = '${newTier.icon} ${newTier.title}\'e yükseldin!';
      body = 'Geçen hafta ${r.rank}. oldun (${r.weeklyXp} XP). Zeki Paşa gurur duyuyor!';
      mood = ParrotMood.happy;
      SoundService.playLessonPass();
    } else if (r.demoted) {
      title = '${newTier.icon} ${newTier.title}\'e düştün';
      body = r.weeklyXp == 0
          ? 'Geçen hafta hiç XP kazanmadın. Bu hafta geri dönelim!'
          : 'Geçen hafta ${r.rank}. oldun. Bu hafta biraz daha çalışırsak tekrar çıkarız!';
      mood = ParrotMood.oops;
    } else {
      title = '${oldTier.icon} ${oldTier.title}\'de kaldın';
      body = r.rank != null
          ? 'Geçen hafta ${r.rank}. oldun (${r.weeklyXp} XP). İlk 5\'e girersen üst lige çıkarsın!'
          : 'Yeni hafta başladı. İlk 5\'e girersen üst lige çıkarsın!';
      mood = ParrotMood.thinking;
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Animate(child: ParrotMascotWidget(size: 110, mood: mood))
                .scale(begin: const Offset(0.4, 0.4), curve: Curves.elasticOut, duration: 800.ms),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Haydi!', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final service = FriendsQuestService.instance;
    final leagueIndex = service.myLeague.clamp(0, LeagueTier.values.length - 1);
    final tier = LeagueTier.values[leagueIndex];
    final myUid = service.uid;

    // Kendimizi listede garantiye al (henüz bu hafta XP kazanmadıysak 0 ile)
    final players = List<FriendInfo>.from(_players);
    if (myUid != null && !players.any((p) => p.uid == myUid)) {
      players.add(FriendInfo(
        uid: myUid,
        friendCode: service.myFriendCode,
        displayName: service.myDisplayName,
        xp: profile.xp,
        level: profile.level,
        streak: profile.streak,
        weeklyXp: 0,
        league: leagueIndex,
      ));
    }
    players.sort((a, b) => b.weeklyXp.compareTo(a.weeklyXp));
    final groupSize = players.length;
    final hasDemotionZone = groupSize >= FriendsQuestService.promoteCount + FriendsQuestService.demoteCount;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _LeagueHeader(tier: tier, leagueIndex: leagueIndex, remainingText: _remainingText),
          const SizedBox(height: 12),
          if (_loading && _players.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_offline)
            _InfoCard(
              isDark: isDark,
              emoji: '📡',
              text: 'Lig sıralaması için internet bağlantısı gerekiyor. Bağlanınca aşağı çekip yenile.',
            )
          else ...[
            if (groupSize <= 1)
              _InfoCard(
                isDark: isDark,
                emoji: '🦜',
                text: 'Bu hafta ligde henüz tek başınasın! Ders bitirdikçe XP kazanırsın; '
                    'arkadaşlarını davet et, aynı ligde yarışın.',
              ),
            for (int i = 0; i < players.length; i++) ...[
              if (i == FriendsQuestService.promoteCount && leagueIndex < FriendsQuestService.maxLeagueIndex && groupSize > FriendsQuestService.promoteCount)
                const _ZoneDivider(text: '⬆ YÜKSELME BÖLGESİ', color: Color(0xFF10B981)),
              if (hasDemotionZone && leagueIndex > 0 && i == groupSize - FriendsQuestService.demoteCount)
                const _ZoneDivider(text: '⬇ DÜŞME BÖLGESİ', color: Color(0xFFEF4444)),
              _PlayerRow(
                rank: i + 1,
                player: players[i],
                isMe: players[i].uid == myUid,
                isDark: isDark,
                inPromotion: i < FriendsQuestService.promoteCount && leagueIndex < FriendsQuestService.maxLeagueIndex,
                inDemotion: hasDemotionZone && leagueIndex > 0 && i >= groupSize - FriendsQuestService.demoteCount,
              ).animate().fadeIn(delay: (40 * i).ms, duration: 250.ms).slideX(begin: 0.05, end: 0),
            ],
          ],
        ],
      ),
    );
  }
}

class _LeagueHeader extends StatelessWidget {
  final LeagueTier tier;
  final int leagueIndex;
  final String remainingText;

  const _LeagueHeader({required this.tier, required this.leagueIndex, required this.remainingText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [tier.color.withValues(alpha: 0.8), tier.color]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: tier.color.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Lig merdiveni (10 lig: yatay kaydırılabilir, mevcut lig ortada açılır)
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              controller: ScrollController(
                initialScrollOffset: (leagueIndex * 36.0 - 110).clamp(0.0, double.infinity),
              ),
              itemCount: LeagueTier.values.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final t = LeagueTier.values[i];
                return Center(
                  child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: t.index == leagueIndex ? 48 : 30,
                  height: t.index == leagueIndex ? 48 : 30,
                  decoration: BoxDecoration(
                    color: t.index <= leagueIndex ? Colors.white : Colors.white.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                    border: t.index == leagueIndex ? Border.all(color: Colors.white, width: 3) : null,
                  ),
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: t.index <= leagueIndex ? 1 : 0.45,
                    child: Text(t.icon, style: TextStyle(fontSize: t.index == leagueIndex ? 24 : 15)),
                  ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            tier.title.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          Text(
            'Haftanın bitmesine $remainingText',
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            leagueIndex >= FriendsQuestService.maxLeagueIndex
                ? 'En üst ligdesin! Yerini korumak için XP kazanmaya devam et.'
                : 'İlk 5 üst lige çıkar • Hiç XP kazanmayan düşer',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final int rank;
  final FriendInfo player;
  final bool isMe;
  final bool isDark;
  final bool inPromotion;
  final bool inDemotion;

  const _PlayerRow({
    required this.rank,
    required this.player,
    required this.isMe,
    required this.isDark,
    required this.inPromotion,
    required this.inDemotion,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = rank == 1
        ? const Color(0xFFF59E0B)
        : rank == 2
            ? const Color(0xFF94A3B8)
            : rank == 3
                ? const Color(0xFFCD7F32)
                : const Color(0xFF94A3B8);
    final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe
            ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5))
            : (isDark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe
              ? const Color(0xFF10B981)
              : inPromotion
                  ? const Color(0xFF10B981).withValues(alpha: 0.35)
                  : inDemotion
                      ? const Color(0xFFEF4444).withValues(alpha: 0.35)
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isMe ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: medal != null
                ? Text(medal, style: const TextStyle(fontSize: 20))
                : Text('$rank', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: rankColor)),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            backgroundImage: player.photoUrl != null ? NetworkImage(player.photoUrl!) : null,
            child: player.photoUrl == null
                ? Text(
                    player.displayName.isNotEmpty ? player.displayName.characters.first.toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? 'Sen' : player.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isMe ? FontWeight.w900 : FontWeight.w800,
                    fontSize: 14.5,
                    color: isMe ? const Color(0xFF059669) : null,
                  ),
                ),
                Text(
                  'Lv.${player.level}${player.streak > 0 ? '  •  🔥 ${player.streak}' : ''}',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${player.weeklyXp} XP',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFFD97706)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneDivider extends StatelessWidget {
  final String text;
  final Color color;
  const _ZoneDivider({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: color, thickness: 1.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11.5)),
          ),
          Expanded(child: Divider(color: color, thickness: 1.5)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final bool isDark;
  final String emoji;
  final String text;
  const _InfoCard({required this.isDark, required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
        ],
      ),
    );
  }
}
