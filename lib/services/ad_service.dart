import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Centralized Google AdMob management service for DGS Quest.
///
/// Pre-configured with official Google AdMob Test Ad Unit IDs
/// so you can develop and test safely without risk of policy violation or bans.
///
/// When ready for production:
/// 1. Create an AdMob account at https://admob.google.com
/// 2. Add your Android & iOS Apps
/// 3. Create Banner, Interstitial, and Rewarded ad units
/// 4. Replace the test IDs below (or set them via environment / remote config).
class AdService {
  AdService._privateConstructor();
  static final AdService instance = AdService._privateConstructor();

  bool _isInitialized = false;
  bool isInitialized() => _isInitialized;

  // --- Official Google AdMob Test Ad Unit IDs ---
  static const String _androidBannerTestId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _iosBannerTestId = 'ca-app-pub-3940256099942544/2934735716';

  static const String _androidInterstitialTestId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _iosInterstitialTestId = 'ca-app-pub-3940256099942544/4411468910';

  static const String _androidRewardedTestId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _iosRewardedTestId = 'ca-app-pub-3940256099942544/1712485313';

  static const String _androidRewardedInterstitialTestId = 'ca-app-pub-3940256099942544/5354046379';
  static const String _iosRewardedInterstitialTestId = 'ca-app-pub-3940256099942544/6978759866';

  // --- Live Ad Unit IDs (User can populate these when published) ---
  // Leave empty to use official Test IDs automatically!
  static const String liveAndroidBannerId = '';
  static const String liveIosBannerId = '';

  static const String liveAndroidInterstitialId = '';
  static const String liveIosInterstitialId = '';

  // "Video İzle & Can Kazan" düğmesi (AdMob: Ödüllü)
  static const String liveAndroidRewardedId = 'ca-app-pub-9171631346564651/2322943717';
  static const String liveIosRewardedId = '';

  // Ders arası "fıstık molası" (AdMob: Ödüllü geçiş)
  static const String liveAndroidRewardedInterstitialId = 'ca-app-pub-9171631346564651/9200002397';
  static const String liveIosRewardedInterstitialId = '';

  String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return liveAndroidBannerId.isNotEmpty ? liveAndroidBannerId : _androidBannerTestId;
    } else if (Platform.isIOS) {
      return liveIosBannerId.isNotEmpty ? liveIosBannerId : _iosBannerTestId;
    }
    return '';
  }

  String get interstitialAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return liveAndroidInterstitialId.isNotEmpty ? liveAndroidInterstitialId : _androidInterstitialTestId;
    } else if (Platform.isIOS) {
      return liveIosInterstitialId.isNotEmpty ? liveIosInterstitialId : _iosInterstitialTestId;
    }
    return '';
  }

  String get rewardedAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return liveAndroidRewardedId.isNotEmpty ? liveAndroidRewardedId : _androidRewardedTestId;
    } else if (Platform.isIOS) {
      return liveIosRewardedId.isNotEmpty ? liveIosRewardedId : _iosRewardedTestId;
    }
    return '';
  }

  String get rewardedInterstitialAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return liveAndroidRewardedInterstitialId.isNotEmpty
          ? liveAndroidRewardedInterstitialId
          : _androidRewardedInterstitialTestId;
    } else if (Platform.isIOS) {
      return liveIosRewardedInterstitialId.isNotEmpty
          ? liveIosRewardedInterstitialId
          : _iosRewardedInterstitialTestId;
    }
    return '';
  }

  // --- Ad instances cached for quick display ---
  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _isRewardedInterstitialLoading = false;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  RewardedAd? _rewardedAd;
  bool _isRewardedLoading = false;

  /// Initialize MobileAds SDK
  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('[AdService] Google Mobile Ads initialized successfully.');
      // Düz geçiş reklamı artık kullanılmıyor; ders arası molada ödüllü geçiş gösteriliyor.
      loadRewardedInterstitialAd();
      loadRewardedAd();
    } catch (e) {
      debugPrint('[AdService] MobileAds initialization failed: $e');
    }
  }

  // ==================== INTERSTITIAL ADS (Geçiş Reklamları) ====================

  /// Preload an Interstitial Ad into memory
  void loadInterstitialAd() {
    if (!_isInitialized || _isInterstitialLoading || _interstitialAd != null) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          debugPrint('[AdService] Interstitial Ad loaded.');
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isInterstitialLoading = false;
          debugPrint('[AdService] Interstitial Ad failed to load: $error');
        },
      ),
    );
  }

  /// Show Interstitial Ad if ready, then reload.
  /// If user is Premium or ad isn't ready, safely calls [onDismissed] immediately.
  void showInterstitialAd({bool isPremium = false, VoidCallback? onDismissed}) {
    if (isPremium) {
      onDismissed?.call();
      return;
    }

    if (_interstitialAd == null) {
      debugPrint('[AdService] Interstitial not ready yet, skipping.');
      loadInterstitialAd();
      onDismissed?.call();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdService] Failed to show Interstitial: $error');
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onDismissed?.call();
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null;
  }

  // ==================== REWARDED INTERSTITIAL (Ödüllü Geçiş) ====================

  /// Ödüllü geçiş reklamını önceden belleğe yükler.
  void loadRewardedInterstitialAd() {
    if (!_isInitialized || _isRewardedInterstitialLoading || _rewardedInterstitialAd != null) return;
    _isRewardedInterstitialLoading = true;

    RewardedInterstitialAd.load(
      adUnitId: rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd = ad;
          _isRewardedInterstitialLoading = false;
          debugPrint('[AdService] Rewarded Interstitial Ad loaded.');
        },
        onAdFailedToLoad: (error) {
          _rewardedInterstitialAd = null;
          _isRewardedInterstitialLoading = false;
          debugPrint('[AdService] Rewarded Interstitial Ad failed to load: $error');
        },
      ),
    );
  }

  /// Ödüllü geçiş reklamını gösterir. Reklam kapandığında (veya hazır değilse hemen)
  /// [onClosed] bir kez çağrılır; `earned` kullanıcı ödülü hak ettiyse true olur.
  void showRewardedInterstitialAd({required void Function(bool earned) onClosed}) {
    final ad = _rewardedInterstitialAd;
    if (ad == null) {
      debugPrint('[AdService] Rewarded Interstitial not ready yet, skipping.');
      loadRewardedInterstitialAd();
      onClosed(false);
      return;
    }
    _rewardedInterstitialAd = null;

    bool earnedReward = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewardedInterstitialAd();
        onClosed(earnedReward);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdService] Failed to show Rewarded Interstitial: $error');
        ad.dispose();
        loadRewardedInterstitialAd();
        onClosed(false);
      },
    );

    ad.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        earnedReward = true;
      },
    );
  }

  // ==================== REWARDED ADS (Ödüllü Reklamlar) ====================

  /// Preload a Rewarded Video Ad
  void loadRewardedAd() {
    if (!_isInitialized || _isRewardedLoading || _rewardedAd != null) return;
    _isRewardedLoading = true;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoading = false;
          debugPrint('[AdService] Rewarded Ad loaded.');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isRewardedLoading = false;
          debugPrint('[AdService] Rewarded Ad failed to load: $error');
        },
      ),
    );
  }

  /// Show Rewarded Video Ad to earn rewards (+1 Heart or +10 Diamonds).
  void showRewardedAd({
    required Function(int amount) onUserEarnedReward,
    VoidCallback? onFailed,
    VoidCallback? onDismissed,
  }) {
    if (_rewardedAd == null) {
      debugPrint('[AdService] Rewarded Ad not ready.');
      loadRewardedAd();
      onFailed?.call();
      return;
    }

    bool earnedReward = false;
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        if (!earnedReward) {
          onDismissed?.call();
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdService] Failed to show Rewarded: $error');
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        onFailed?.call();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        earnedReward = true;
        debugPrint('[AdService] User earned reward: ${reward.amount} ${reward.type}');
        onUserEarnedReward(reward.amount.toInt());
      },
    );
    _rewardedAd = null;
  }

  // ==================== BANNER ADS (Afiş Reklamlar) ====================

  /// Creates and loads a BannerAd widget controller
  BannerAd? createBannerAd({
    required AdSize size,
    required void Function(Ad) onAdLoaded,
    required void Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    if (!_isInitialized) return null;
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    );
  }
}
