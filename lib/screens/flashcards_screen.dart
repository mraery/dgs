import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lesson_models.dart';
import '../providers/game_provider.dart';
import '../services/sound_service.dart';
import '../widgets/duo_button.dart';
import '../widgets/parrot_mascot_widget.dart';

final List<Flashcard> defaultFlashcards = [
  const Flashcard(
    id: "fc_dgs_mat_1",
    subject: "DGS Temel Matematik",
    category: "Sayı Kümeleri",
    term: "Tek ve Çift Sayı Kuralları",
    meaning: "T ± T = Ç, Ç ± Ç = Ç, T ± Ç = T. T × T = T, T × Ç = Ç, Ç × Ç = Ç. Çarpım tek ise TÜM çarpanlar tektir. Çarpım çift ise EN AZ BİR çarpan çifttir.",
    example: "(a × b) + 1 = Çift ise a × b = Tek olmalı, dolayısıyla hem a hem b tek olmak zorundadır.",
    examTip: "ÖSYM taban-tavan üs sorularında pozitif tam sayı üsler tekliği-çiftliği DEĞİŞTİRMEZ (aⁿ ile a aynı tekliktedir)!",
  ),
  const Flashcard(
    id: "fc_dgs_mat_2",
    subject: "DGS Temel Matematik",
    category: "Asal Sayılar",
    term: "Asallık ve Aralarında Asallık",
    meaning: "Sadece 1'e ve kendisine bölünebilen 1'den büyük doğal sayılara asal sayı denir. 2, tek çift asal sayıdır. 1'den başka ortak pozitif böleni olmayan sayılar aralarında asaldır.",
    example: "8 ve 15 asal değildir ancak 1'den başka ortak bölenleri olmadığı için aralarında asaldır.",
    examTip: "Ardışık iki pozitif tam sayı daima aralarında asaldır ve EBOB'ları daima 1'dir!",
  ),
  const Flashcard(
    id: "fc_dgs_mat_3",
    subject: "DGS Temel Matematik",
    category: "Ardışık Sayılar",
    term: "Terim Sayısı ve Toplam Formülü",
    meaning: "Terim Sayısı = [(Son Terim - İlk Terim) / Artış Miktarı] + 1. Toplam = Terim Sayısı × [(Son Terim + İlk Terim) / 2] (Ortanca Terim).",
    example: "3 + 7 + 11 + ... + 39 için TS = [(39 - 3)/4] + 1 = 10 terim. Toplam = 10 × [(39 + 3)/2] = 210.",
    examTip: "DGS'de ardışık tek veya çift sayılar ikişer ikişer (n, n+2, n+4...) artar, artış miktarı 2 alınır!",
  ),
  const Flashcard(
    id: "fc_dgs_mat_4",
    subject: "DGS Temel Matematik",
    category: "Faktöriyel",
    term: "n! ve Sondan Sıfır Sayısı",
    meaning: "n! sayısının sondaki sıfır sayısını bulmak için n sayısı sürekli 5'e bölünür ve bölümler toplanır.",
    example: "60! sondan kaç basamağı sıfırdır? 60/5 = 12, 12/5 = 2. Toplam = 12 + 2 = 14 sıfır.",
    examTip: "Faktöriyel sadeleştirmelerinde büyük faktöriyel daima küçük olanın cinsinden açılır: (n+1)! = (n+1) × n!",
  ),
  const Flashcard(
    id: "fc_dgs_mat_5",
    subject: "DGS Temel Matematik",
    category: "Basamak Analizi",
    term: "Sayı Çözümleme ve Fark Kuralı",
    meaning: "AB = 10A + B, BA = 10B + A. AB - BA = 9(A - B). AB + BA = 11(A + B).",
    example: "AB - BA = 36 ise 9(A - B) = 36 -> A - B = 4 bulunur.",
    examTip: "ABC - CBA = 99(A - C) formülünde onlar basamağındaki B harfi fark işleminde birbirini yok eder!",
  ),
  const Flashcard(
    id: "fc_dgs_mat_6",
    subject: "DGS Temel Matematik",
    category: "Bölünebilme",
    term: "Bileşik Bölünebilme Kuralları",
    meaning: "Bir sayı aralarında asal iki sayıya tam bölünüyorsa çarpımlarına da tam bölünür. 6 için (2 ve 3), 12 için (3 ve 4), 15 için (3 ve 5), 36 için (4 ve 9), 45 için (5 ve 9).",
    example: "36'ya tam bölünen sayı hem 4'e (son iki basamak) hem 9'a (rakamlar toplamı) bölünmelidir.",
    examTip: "İncelemeye daima son basamağı belirleyen kuraldan (2, 5 veya 4) başlanır, ardından rakam toplamı (3, 9) incelenir!",
  ),
  const Flashcard(
    id: "fc_dgs_mat_7",
    subject: "DGS Temel Matematik",
    category: "Eşitsizlikler",
    term: "0 < a < 1 (a² < a) Kuralı",
    meaning: "Pozitif bir basit kesrin karesi daima kendisinden küçüktür (a² < a). Örnek: a = 1/2 ise a² = 1/4 ve 1/4 < 1/2.",
    example: "x² < x eşitsizliğini sağlayan x reel sayıları (0, 1) aralığındadır.",
    examTip: "ÖSYM bir soruda a² < a ifadesini veriyorsa a'nın (0, 1) aralığında olduğunu gizlemiştir!",
  ),
  const Flashcard(
    id: "fc_dgs_mat_8",
    subject: "DGS Temel Matematik",
    category: "Mutlak Değer",
    term: "Mutlak Değer Özellikleri",
    meaning: "|x| >= 0 daima. |x| = a (a >= 0) ise x = a veya x = -a. |x| < a ise -a < x < a. |x| > a ise x > a veya x < -a.",
    example: "|2x - 1| = 5 ise 2x - 1 = 5 (x=3) veya 2x - 1 = -5 (x=-2).",
    examTip: "Mutlak değerli denklemlerde mutlak değerin içi sıfıra eşitlenerek kritik noktalar bulunur!",
  ),
  const Flashcard(
    id: "fc_dgs_mat_9",
    subject: "DGS Temel Matematik",
    category: "Üslü & Köklü",
    term: "Köklü Sayılarda Eşlenik",
    meaning: "Paydadaki kökten kurtulmak için ifade paydanın eşleniği ile çarpılır. √(a) eşleniği √(a), (√a - √b) eşleniği (√a + √b)'dir. Çarpım (a - b) olur.",
    example: "1 / (√3 - √2) ifadesi (√3 + √2) ile çarpılırsa payda 3 - 2 = 1 olur, sonuç √3 + √2 çıkar.",
    examTip: "Çift dereceli köklerin içi asla negatif olamaz (içerisi >= 0 olmalıdır)!",
  ),
  const Flashcard(
    id: "fc_dgs_mat_10",
    subject: "DGS Temel Matematik",
    category: "Özdeşlikler",
    term: "İki Kare Farkı ve Tam Kare",
    meaning: "İki kare farkı: a² - b² = (a - b)(a + b). Tam kare: (a + b)² = a² + 2ab + b², (a - b)² = a² - 2ab + b².",
    example: "101² - 99² = (101 - 99)(101 + 99) = 2 × 200 = 400.",
    examTip: "DGS'de a² + b² sorulduğunda (a + b)² - 2ab açılımı en çok kullanılan pratik yoldur!",
  ),
  const Flashcard(
    id: "fc_dgs_prob_1",
    subject: "DGS Problemler",
    category: "Yaş Problemleri",
    term: "Yaş Farkı Asla Değişmez",
    meaning: "İki kişi arasındaki yaş farkı zaman geçtikçe daima sabit kalır. Geçen yıl sayısı herkesin yaşına eşit eklenir.",
    example: "Ali ile Veli arasındaki yaş farkı bugün 6 ise 15 yıl sonra da 6'dır.",
    examTip: "T kişi için n yıl sonra yaşları toplamı T × n kadar artar!",
  ),
  const Flashcard(
    id: "fc_dgs_prob_2",
    subject: "DGS Problemler",
    category: "Hız - Hareket",
    term: "Karşılaşma ve Yetişme Formülleri",
    meaning: "Zıt yönlü (Karşılaşma): Yol = (V1 + V2) × t. Aynı yönlü (Yetişme): Yol = (V1 - V2) × t (V1 > V2).",
    example: "Aralarında 300 km olan iki araç 60 ve 40 km/s hızlarla birbirine doğru gelirse t = 300 / (60+40) = 3 saatte karşılaşır.",
    examTip: "Tünel ve tren sorularında toplam yol = Tren Boyu + Tünel Boyu olarak alınır!",
  ),
  const Flashcard(
    id: "fc_dgs_prob_3",
    subject: "DGS Problemler",
    category: "İşçi Problemleri",
    term: "Birim Zamanda Yapılan İş Prensibi",
    meaning: "Bir işi A işçisi x saatte, B işçisi y saatte bitiriyorsa birlikte t saatte bitirme formülü: (1/x + 1/y) × t = 1.",
    example: "Biri 6 günde, diğeri 12 günde bitirirse: (1/6 + 1/12) × t = 1 -> (3/12) × t = 1 -> t = 4 gün.",
    examTip: "DGS işçi sorularında işçi kapasitesi (hızı) ile bitirme süresi ters orantılıdır!",
  ),
  const Flashcard(
    id: "fc_dgs_prob_4",
    subject: "DGS Problemler",
    category: "Yüzde & Kâr-Zarar",
    term: "Maliyet ve Satış Fiyatı Formülleri",
    meaning: "Maliyet = 100x seçilir. %20 karlı satış = 120x, %15 zararlı satış = 85x. İndirim daima o anki etiket fiyatı üzerinden hesaplanır.",
    example: "100 TL maliyetli ürüne %20 kar konursa 120 TL olur. 120 TL üzerinden %10 indirim yapılırsa 120 - 12 = 108 TL'ye satılır (Net %8 kar).",
    examTip: "Yüzde sorularında bilinmeyene x demek yerine 100x demek hesaplamayı 3 kat hızlandırır!",
  ),
  const Flashcard(
    id: "fc_dgs_prob_5",
    subject: "DGS Problemler",
    category: "Karışım Problemleri",
    term: "Karışım Yüzdesi Denklem Formülü",
    meaning: "(1. Miktar × 1. Yüzde) + (2. Miktar × 2. Yüzde) = Toplam Miktar × Son Yüzde.",
    example: "20 kg %30'luk tuzlu su ile 30 kg %40'lık karıştırılırsa: (20×30 + 30×40) / 50 = (600 + 1200) / 50 = %36.",
    examTip: "Karışıma saf su eklenirse tuz yüzdesi 0, saf tuz eklenirse tuz yüzdesi 100 alınır!",
  ),
  const Flashcard(
    id: "fc_dgs_say_1",
    subject: "DGS Sayısal Mantık",
    category: "Tablo & Grafik",
    term: "Daire Grafiği (360°) ve Oranlama",
    meaning: "Daire grafiğinin tamamı 360° açıdır ve %100'e denk gelir. 36° = %10, 18° = %5, 90° = 1/4 (%25).",
    example: "Merkez açısı 72° olan ürün üretimin 72/360 = 1/5'ini (%20'sini) oluşturur.",
    examTip: "DGS grafik sorularında büyük sayılarla uğraşmak yerine açıların EBOB'u ile sadeleştirip k katsayısı ver!",
  ),
  const Flashcard(
    id: "fc_dgs_say_2",
    subject: "DGS Sayısal Mantık",
    category: "Şifreli İşlemler",
    term: "Harfli Matematik ve Taban Mantığı",
    meaning: "Kelimeler veya harfler rakamlarla eşleştirildiğinde aynı harf aynı rakamı temsil eder. Toplama-çarpma eldelerine dikkat edilir.",
    example: "A + A = B ve B tek sayı olamaz çünkü iki aynı sayının toplamı çift olmalıdır.",
    examTip: "Çarpma işleminde son basamak kuralı (örneğin 5 ile çarpımda son basamak 0 veya 5 olur) en kritik ipucudur!",
  ),
  const Flashcard(
    id: "fc_dgs_say_3",
    subject: "DGS Sayısal Mantık",
    category: "Şekil Yeteneği",
    term: "Küp Açılımları ve Karşılıklı Yüzler",
    meaning: "Bir küp açınımında aralarında tam 1 kare bulunan yüzler küp kapatıldığında birbirine PARALEL (karşı karşıya) gelir.",
    example: "Yan yana duran yüzler asla karşı karşıya gelemez, komşu yüz olurlar.",
    examTip: "DGS küp sorularında karşı karşıya gelen yüz çiftlerini hemen eşleştirip şıkları buna göre ele!",
  ),
  const Flashcard(
    id: "fc_dgs_say_4",
    subject: "DGS Sayısal Mantık",
    category: "Sayı Dizileri",
    term: "Örüntü ve Periyodik Tekrarlar",
    meaning: "Dizi belirli bir adımda bir kendini tekrar ediyorsa periyot bulunur ve istenen adım sayısı periyoda bölünür.",
    example: "Pazartesiden itibaren 100 gün sonrası: 100 mod 7 = 2 gün sonrası -> Çarşamba.",
    examTip: "DGS periyodik problemlerde modüler aritmetik kalanı aranılan gün ve durumu verir!",
  ),
  const Flashcard(
    id: "fc_dgs_geo_1",
    subject: "DGS Geometri",
    category: "Özel Dik Üçgenler",
    term: "Pisagor ve Özel Kenar Üçgenleri",
    meaning: "a² + b² = c² (Hipotenüs en uzun kenardır). Özel kenarlar: 3-4-5, 5-12-13, 8-15-17, 7-24-25 ve katları.",
    example: "Dik kenarları 6 ve 8 olan üçgenin hipotenüsü 3-4-5'in 2 katından 10'dur.",
    examTip: "30-60-90 üçgeninde 30° karşısı a ise 90° karşısı 2a, 60° karşısı a√3 olur!",
  ),
  const Flashcard(
    id: "fc_dgs_geo_2",
    subject: "DGS Geometri",
    category: "Üçgende Alan",
    term: "Muhteşem Üçlü Kuralı",
    meaning: "Bir dik üçgende 90°'lik açıdan hipotenüse çizilen kenarortay, ayırdığı parçalara eşittir (|AD| = |BD| = |DC|).",
    example: "Hipotenüs uzunluğu 20 cm ise kenarortay uzunluğu 10 cm olur.",
    examTip: "Soruda dik üçgen ve hipotenüse inen kenarortay varsa tereddütsüz eşitlik işaretini koy!",
  ),
  const Flashcard(
    id: "fc_dgs_geo_3",
    subject: "DGS Geometri",
    category: "Benzerlik",
    term: "Benzerlik Oranı ve Alan İlişkisi (k²)",
    meaning: "İki üçgen arasındaki benzerlik oranı k ise, çevreleri oranı k, ALANLARI ORANI k² olur.",
    example: "Benzerlik oranı 1/2 olan iki üçgenin alanları oranı (1/2)² = 1/4'tür.",
    examTip: "Orta taban çizildiğinde tepe üçgenin alanı S ise alttaki yamuğun alanı 3S olur!",
  ),
  const Flashcard(
    id: "fc_dgs_geo_4",
    subject: "DGS Geometri",
    category: "Daire ve Çember",
    term: "Dairenin Alanı ve Çevresi",
    meaning: "Çevre = 2πr. Alan = πr². α derecelik daire dilimi alanı = πr² × (α / 360).",
    example: "Yarıçapı 6 cm olan 60°'lik daire diliminin alanı: π × 36 × (60/360) = 6π cm².",
    examTip: "Çapı gören çevre açı daima 90°'dir!",
  ),
  const Flashcard(
    id: "fc_dgs_tr_1",
    subject: "DGS Türkçe",
    category: "Paragrafta Anlam",
    term: "Ana Düşünce Belirleme",
    meaning: "Yazarın okuyucuya vermek istediği asıl mesaj, öğüt veya temel iletidir. Genellikle kısacası, özetle, oysa, asıl önemli olan gibi bağlayıcı sözcüklerden sonra vurgulanır.",
    example: "Paragrafın bütünü tek bir yargı cümlesiyle özetlenebiliyorsa o cümle ana fikirdir.",
    examTip: "Ana düşünce sorularında parçada geçse bile yan ayrıntılara takılma, yazarın savunduğu temel teze odaklan!",
  ),
  const Flashcard(
    id: "fc_dgs_tr_2",
    subject: "DGS Türkçe",
    category: "Paragraf Yapısı",
    term: "Düşüncenin Akışını Bozan Cümle",
    meaning: "Paragrafta ele alınan konunun dışına çıkan veya konunun bambaşka bir yönüne aniden geçiş yapan cümle akışı bozar.",
    example: "Bir yazarın üslubundan bahsederken araya giren yazarın çocukluk yılları çok zor geçmiştir cümlesi akışı bozar.",
    examTip: "Akışı bozan cümleyi paragraftan çıkardığında önceki ve sonraki cümle birbirine anlamca kusursuz bağlanmalıdır!",
  ),
  const Flashcard(
    id: "fc_dgs_tr_3",
    subject: "DGS Türkçe",
    category: "Sözcükte Anlam",
    term: "Dolaylama ve Güzel Adlandırma",
    meaning: "Dolaylama: Tek sözcükle anlatılabilecek kavramı birden çok sözcükle anlatmaktır (Kara elmas: Kömür, Yavru vatan: Kıbrıs). Güzel Adlandırma: Korkulan veya nahoş durumları yumuşatarak söylemektir (İnce hastalık: Verem).",
    example: "File bekçisi (Kaleci), Bacasız sanayi (Turizm).",
    examTip: "DGS sözcükte anlamda mecaz-ı mürsel (ad aktarması) ve dolaylama sıkça karıştırılır, dolaylamada kalıplaşmış tamlama aranır!",
  ),
  const Flashcard(
    id: "fc_dgs_tr_4",
    subject: "DGS Türkçe",
    category: "Anlatım Bozuklukları",
    term: "Gereksiz Sözcük Kullanımı",
    meaning: "Aynı anlama gelen sözcüklerin veya eş anlamlı kelimelerin bir arada kullanılması anlatım bozukluğuna yol açar.",
    example: "Bari hiç olmazsa sen gel cümlesinde bari ve hiç olmazsa aynı anlamdadır, biri gereksizdir.",
    examTip: "Bir sözcük cümleden çıkarıldığında anlamda daralma veya bozulma olmuyorsa o sözcük gereksizdir!",
  ),
  const Flashcard(
    id: "fc_dgs_soz_1",
    subject: "DGS Sözel Mantık",
    category: "Tablo Kurma",
    term: "Sabit Değişken Eksen Kuralı",
    meaning: "Sözel mantıkta kişi sayısı fazla, günler/katlar/sıralar az ve sabitse; tabloya daima az ve sabit olan eksen yazılır.",
    example: "Ali, Berk, Can, Deniz, Ece haftanın 5 gününde nöbet tutuyorsa tablonun üst satırı Pazartesi-Cuma günleri olmalıdır.",
    examTip: "Tabloyu kurduktan sonra kesin verilen öncülleri yerleştir, ihtimalleri (Veya) tablonun altına iki olasılık dalı olarak yaz!",
  ),
  const Flashcard(
    id: "fc_dgs_soz_2",
    subject: "DGS Sözel Mantık",
    category: "Sıralama Soruları",
    term: "Hemen Öncesi / Sonrası İfadesi",
    meaning: "A, B'den hemen öncedir denirse AB bloğu bozulamaz. A, B'den öncedir denirse araya başka elemanlar girebilir.",
    example: "Hemen öncesi: [A][B] bitişik bloktur. Sadece öncesi: A ... B (arada eleman olabilir).",
    examTip: "DGS sözel mantıkta hemen kelimesi blok yapmayı zorunlu kılar; gözden kaçarsa tüm sorular hatalı çözülür!",
  ),
  const Flashcard(
    id: "fc_dgs_soz_3",
    subject: "DGS Sözel Mantık",
    category: "Çıkarım Analizi",
    term: "Kesin Doğru vs Kesin Yanlış",
    meaning: "Her iki ihtimalde de değişmeyen bilgiler KESİN DOĞRU'dur. İki ihtimalde de gerçekleşmesi imkansız durumlar KESİN YANLIŞ'tır.",
    example: "1. İhtimalde Ali 3. sırada, 2. İhtimalde de Ali 3. sırada ise Ali 3. sıradadır kesin doğrudur.",
    examTip: "ÖSYM DGS'de genellikle 4 soruluk bir sözel mantık grubunun son iki sorusunu Hangisi kesinlikle doğrudur/yanlıştır şeklinde sorar!",
  ),
];

class FlashcardsScreen extends ConsumerStatefulWidget {
  final List<Flashcard>? customDeck;

  const FlashcardsScreen({super.key, this.customDeck});

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen>
    with SingleTickerProviderStateMixin {
  late List<Flashcard> _deck;
  int _currentIndex = 0;
  bool _isFlipped = false;
  final Set<String> _learnedCardIds = {};
  final Set<String> _reviewCardIds = {};

  // Branş Filtresi
  String _selectedFilterSubject = 'Tümü';
  final List<String> _filterSubjects = const [
    'Tümü',
    'DGS Temel Matematik',
    'DGS Problemler',
    'DGS Sayısal Mantık',
    'DGS Geometri',
    'DGS Türkçe',
    'DGS Sözel Mantık',
  ];

  // 3D Flip Animasyonu
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  // Drag & Swipe Durumu
  double _dragOffset = 0.0;
  bool _isFinished = false;

  void _onSelectFilterSubject(String subj) {
    setState(() {
      _selectedFilterSubject = subj;
      final base = (widget.customDeck ?? defaultFlashcards);
      if (subj == 'Tümü') {
        _deck = List.from(base)..shuffle();
      } else {
        _deck = base.where((c) => c.subject == subj).toList()..shuffle();
        if (_deck.isEmpty) {
          _deck = List.from(base)..shuffle();
        }
      }
      _currentIndex = 0;
      _isFlipped = false;
      _isFinished = false;
      _dragOffset = 0.0;
      _learnedCardIds.clear();
      _reviewCardIds.clear();
      _flipController.reset();
    });
  }

  @override
  void initState() {
    super.initState();
    _deck = List.from(widget.customDeck ?? defaultFlashcards)..shuffle();

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    HapticFeedback.lightImpact();
    SoundService.playFlip();
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    _isFlipped = !_isFlipped;
  }

  void _onSwipe(bool isLearned) {
    if (_currentIndex >= _deck.length) return;

    final currentCard = _deck[_currentIndex];
    HapticFeedback.mediumImpact();

    if (isLearned) {
      SoundService.playCorrect();
    } else {
      SoundService.playIncorrect();
    }

    setState(() {
      if (isLearned) {
        _learnedCardIds.add(currentCard.id);
        _reviewCardIds.remove(currentCard.id);
      } else {
        _reviewCardIds.add(currentCard.id);
        _learnedCardIds.remove(currentCard.id);
      }

      // Animasyonu sıfırla
      if (_isFlipped) {
        _flipController.reset();
        _isFlipped = false;
      }
      _dragOffset = 0.0;

      if (_currentIndex + 1 >= _deck.length) {
        _isFinished = true;
        SoundService.playComplete();
        // Tamamlandı, ödül ver
        ref.read(userProfileProvider.notifier).recordLessonAttempt(
              Lesson(
                id: 'flashcards_complete_${DateTime.now().millisecondsSinceEpoch}',
                title: 'Kartlarla Pekiştir',
                description: 'Flaş kart tamamlama',
                xpReward: 35,
                gemReward: 12,
                questions: const [],
              ),
              100.0,
            );
      } else {
        _currentIndex++;
      }
    });
  }

  void _restartDeck({bool onlyReview = false}) {
    setState(() {
      final base = (widget.customDeck ?? defaultFlashcards);
      final filteredBase = _selectedFilterSubject == 'Tümü'
          ? base
          : base.where((c) => c.subject == _selectedFilterSubject).toList();
      if (onlyReview && _reviewCardIds.isNotEmpty) {
        _deck = filteredBase
            .where((fc) => _reviewCardIds.contains(fc.id))
            .toList()
          ..shuffle();
      } else {
        _deck = List.from(filteredBase.isEmpty ? base : filteredBase)..shuffle();
      }
      _currentIndex = 0;
      _isFlipped = false;
      _isFinished = false;
      _dragOffset = 0.0;
      _learnedCardIds.clear();
      _reviewCardIds.clear();
      _flipController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) {
      return _buildFinishedScreen();
    }

    final currentCard = _deck[_currentIndex];
    final progress = (_currentIndex + 1) / _deck.length;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121216) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF18181F) : Colors.white,
        elevation: 0,
        title: const Text(
          'Kartlarla Pekiştir 🎴',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19),
        ),
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : const Color(0xFF4B4B4B), size: 26),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Öğrenilen / Tekrar sayaçları
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${_learnedCardIds.length}',
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.replay_rounded, color: Color(0xFFC62828), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${_reviewCardIds.length}',
                        style: const TextStyle(
                          color: Color(0xFFC62828),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Branş Filtreleme Çubuğu
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFF1ECE4), width: 1)),
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filterSubjects.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final subj = _filterSubjects[index];
                  final isSelected = _selectedFilterSubject == subj;
                  return InkWell(
                    onTap: () => _onSelectFilterSubject(subj),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF6D28D9) : const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          subj,
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF4B5563),
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // İlerleme Barı
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_currentIndex + 1} / ${_deck.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Kart Alanı (Swipeable & 3D Flip)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        _dragOffset += details.primaryDelta!;
                      });
                    },
                    onHorizontalDragEnd: (details) {
                      if (_dragOffset > 90) {
                        // Sağa atıldı ➔ Öğrendim
                        _onSwipe(true);
                      } else if (_dragOffset < -90) {
                        // Sola atıldı ➔ Tekrar Çalış
                        _onSwipe(false);
                      } else {
                        // Merkeze geri dön
                        setState(() {
                          _dragOffset = 0.0;
                        });
                      }
                    },
                    onTap: _toggleFlip,
                    child: Transform.translate(
                      offset: Offset(_dragOffset, 0),
                      child: Transform.rotate(
                        angle: (_dragOffset / 300) * 0.15,
                        child: _buildFlipCard(currentCard),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Alt Butonlar (Sola At & Sağa At)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1.5)),
              ),
              child: Row(
                children: [
                  // Sola At Butonu (Tekrar Çalış)
                  Expanded(
                    child: DuoButton(
                      text: '👈 TEKRAR ÇALIŞ',
                      color: DuoButtonColor.red,
                      height: 52,
                      onPressed: () => _onSwipe(false),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Sağa At Butonu (Öğrendim)
                  Expanded(
                    child: DuoButton(
                      text: 'ÖĞRENDİM 👉',
                      color: DuoButtonColor.green,
                      height: 52,
                      onPressed: () => _onSwipe(true),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlipCard(Flashcard card) {
    final angle = _flipAnimation.value * pi;
    final isBack = angle >= pi / 2;

    return Stack(
      children: [
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: isBack
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(pi),
                  child: _buildCardBack(card),
                )
              : _buildCardFront(card),
        ),

        // Sola kaydırırken çıkan kırmızı "TEKRAR ET" rozeti
        if (_dragOffset < -20)
          Positioned(
            top: 24,
            right: 24,
            child: Opacity(
              opacity: min(1.0, (-_dragOffset / 120)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.replay_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'TEKRAR ÇALIŞ',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Sağa kaydırırken çıkan yeşil "ÖĞRENDİM" rozeti
        if (_dragOffset > 20)
          Positioned(
            top: 24,
            left: 24,
            child: Opacity(
              opacity: min(1.0, (_dragOffset / 120)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'ÖĞRENDİM',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Kart Ön Yüzü (Kelime / Kavram)
  Widget _buildCardFront(Flashcard card) {
    Color subjectColor;
    if (card.subject.contains('Biyoloji')) {
      subjectColor = const Color(0xFF10B981);
    } else if (card.subject.contains('Matematik')) {
      subjectColor = const Color(0xFF1CB0F6);
    } else if (card.subject.contains('Fizik')) {
      subjectColor = const Color(0xFF7C3AED);
    } else if (card.subject.contains('Kimya')) {
      subjectColor = const Color(0xFFEC4899);
    } else if (card.subject.contains('Türkçe')) {
      subjectColor = const Color(0xFFEA580C);
    } else if (card.subject.contains('Edebiyat')) {
      subjectColor = const Color(0xFFB91C1C);
    } else if (card.subject.contains('Tarih')) {
      subjectColor = const Color(0xFFFF9600);
    } else if (card.subject.contains('Coğrafya')) {
      subjectColor = const Color(0xFF14B8A6);
    } else if (card.subject.contains('Felsefe')) {
      subjectColor = const Color(0xFF6366F1);
    } else if (card.subject.contains('Din')) {
      subjectColor = const Color(0xFF047857);
    } else {
      subjectColor = const Color(0xFF58CC02);
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      constraints: const BoxConstraints(maxHeight: 460),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ders ve Kategori Rozeti
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: subjectColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${card.subject} • ${card.category ?? "DGS Temel"}',
              style: TextStyle(
                color: subjectColor,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),

          const Spacer(),

          // Kart İkonu
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: subjectColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.style_rounded,
              size: 42,
              color: subjectColor,
            ),
          ),

          const SizedBox(height: 20),

          // Kelime / Kavram
          Text(
            card.term,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1F2937),
              letterSpacing: -0.5,
            ),
          ),

          const Spacer(),

          // İpucu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app_rounded, size: 18, color: Color(0xFF6B7280)),
                SizedBox(width: 6),
                Text(
                  'Kartı çevirmek için dokun',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Kart Arka Yüzü (Anlam & Taktik)
  Widget _buildCardBack(Flashcard card) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      constraints: const BoxConstraints(maxHeight: 460),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5FF), // Hafif Mor arka plan
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFD8B4FE), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Başlık & Çevir Simgesi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  card.term,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF6B21A8),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.flip_camera_android_rounded,
                    size: 18,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: Color(0xFFE9D5FF), height: 1),
            const SizedBox(height: 12),

            // Anlam & Tanım
            const Text(
              'AÇIKLAMA / TANIM:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF9333EA),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              card.meaning,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
                height: 1.45,
              ),
            ),

            if (card.example != null) ...[
              const SizedBox(height: 14),
              const Text(
                'ÖRNEK:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2563EB),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  card.example!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1E40AF),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],

            if (card.examTip != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡 ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        card.examTip!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF92400E),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Deste Bittiğinde Kutlama Ekranı
  Widget _buildFinishedScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Papağan Kutlama
              const ParrotMascotWidget(
                size: 130,
                mood: ParrotMood.happy,
                speechText: 'Harika iş çıkardın! Kartları pekiştirdin! 🎉',
              ),

              const SizedBox(height: 24),

              const Text(
                'Deste Tamamlandı!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF10B981),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Toplam ${_deck.length} kart üzerinden ${_learnedCardIds.length} tanesini öğrendin.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 28),

              // Durum Kartları
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 28),
                          const SizedBox(height: 6),
                          Text(
                            '${_learnedCardIds.length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF059669),
                            ),
                          ),
                          const Text(
                            'ÖĞRENİLDİ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.replay_rounded, color: Color(0xFFDC2626), size: 28),
                          const SizedBox(height: 6),
                          Text(
                            '${_reviewCardIds.length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                          const Text(
                            'TEKRAR EDİLECEK',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Tekrar Çalış ve Çıkış Butonları
              if (_reviewCardIds.isNotEmpty) ...[
                DuoButton(
                  text: 'TEKRAR EDİLECEKLERİ ÇÖZ (${_reviewCardIds.length})',
                  color: DuoButtonColor.blue,
                  height: 52,
                  onPressed: () => _restartDeck(onlyReview: true),
                ),
                const SizedBox(height: 10),
              ],

              DuoButton(
                text: 'TÜMÜNÜ YENİDEN BAŞLAT',
                color: DuoButtonColor.green,
                height: 52,
                onPressed: () => _restartDeck(onlyReview: false),
              ),

              const SizedBox(height: 10),

              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Pratiğe Dön',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6B7280),
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
