import '../models/lesson_models.dart';

/// ÖSYM DGS Sözel Bölümü için gerçek Türkçe, Cümle, Paragraf,
/// Anlatım Bozukluğu ve Sözel Mantık soru üreticisi.
class DgsSozelQuestionGenerator {
  static bool isSozelLesson(String lessonId) {
    return lessonId.contains('soz') ||
        lessonId.contains('mantik') ||
        lessonId.contains('paragraf') ||
        lessonId.contains('cumle') ||
        lessonId.contains('anlatim');
  }

  static List<Question> generate(String lessonId, {int count = 380}) {
    final questions = <Question>[];
    final isMantik = lessonId.contains('mantik');
    final isParagraf = lessonId.contains('paragraf') || lessonId.contains('soz_u2');
    final isAnlatim = lessonId.contains('anlatim');
    final isCumle = lessonId.contains('cumle');

    for (int i = 0; i < count; i++) {
      final qId = '${lessonId}_sozel_gen_$i';
      if (isMantik) {
        questions.add(_buildSozelMantikQuestion(qId, i));
      } else if (isParagraf) {
        questions.add(_buildParagrafQuestion(qId, i));
      } else if (isAnlatim) {
        questions.add(_buildAnlatimBozukluguQuestion(qId, i));
      } else if (isCumle) {
        questions.add(_buildCumleAnlamQuestion(qId, i));
      } else {
        // Karma Sözcükte Anlam, Deyim, Cümle ve Paragraf
        final mod = i % 4;
        if (mod == 0) {
          questions.add(_buildSozcukAnlamQuestion(qId, i));
        } else if (mod == 1) {
          questions.add(_buildCumleAnlamQuestion(qId, i));
        } else if (mod == 2) {
          questions.add(_buildParagrafQuestion(qId, i));
        } else {
          questions.add(_buildAnlatimBozukluguQuestion(qId, i));
        }
      }
    }
    return questions;
  }

  // ==================== 1. SÖZCÜKTE ANLAM & DEYİM / ATASÖZÜ ====================
  static const _sozcukPool = [
    (
      'Onun sözlerinin altında başka bir niyet aramak yersizdir; ne düşünüyorsa açıkça söyler.',
      'Altında başka niyet aramak',
      'Sözün görünür anlamının dışında gizli bir amaç veya ima sezmek',
      ['Sözü olduğu gibi kabul etmek', 'Konuşulanları dikkatle dinlememek', 'Aynı konuyu sürekli tekrar etmek', 'Düşüncelerini gizlemeye çalışmak'],
      'Bir sözün altında niyet aramak, açık anlamın ötesinde gizli bir amaç bulunduğunu düşünmektir.'
    ),
    (
      'Bu projede ince eleyip sık dokumadan sonuca varmamız mümkün değil.',
      'İnce eleyip sık dokumak',
      'Bir işi en küçük ayrıntısına kadar titizlikle ve özenle incelemek',
      ['İşi aceleye getirip hızlıca bitirmek', 'Gereksiz detayları tamamen atlamak', 'Başkalarının fikirlerine göre hareket etmek', 'Zamanı plansız şekilde harcamak'],
      '"İnce eleyip sık dokumak" deyimi çok özenli, titiz ve ayrıntılı çalışmayı anlatır.'
    ),
    (
      'Yazarın yeni romanı, okuru ilk sayfasından itibaren avucunun içine alıyor.',
      'Avucunun içine almak',
      'Okurun bütün dikkatini ve ilgisini tamamen kendi üzerine çekmek, etkisiz bırakmak',
      ['Okuru kitabın dışına itmek', 'Anlatımda sıradanlığa düşmek', 'Olayları yüzeysel biçimde geçiştirmek', 'Okuyucuya eleştirel mesafe bırakmak'],
      'Metinde yazarın üslubunun okuru tamamen etkisi altına aldığı vurgulanmaktadır.'
    ),
    (
      'Eleştirmen, genç şairin dizelerindeki yapaylığı görmezden gelerek onu göklere çıkardı.',
      'Göklere çıkarmak',
      'Bir kimseyi veya eseri aşırı derecede övmek, yüceltmek',
      ['Acımasızca yerden yere vurmak', 'Nesnel ölçütlerle değerlendirmek', 'Eksiklerini tek tek sıralamak', 'Görmezden gelip yok saymak'],
      '"Göklere çıkarmak" deyimi aşırı övgü ve yüceltme anlamı taşır.'
    ),
    (
      'Zorluklar karşısında hemen yelkenleri suya indiren biri bu sınavı kazanamaz.',
      'Yelkenleri suya indirmek',
      'Direnmekten vazgeçip yenilgiyi veya karşı tarafın isteğini kabullenmek',
      ['Mücadeleye daha büyük bir azimle sarılmak', 'Yeni stratejiler geliştirerek ilerlemek', 'Çevresindeki insanlara umut aşılamak', 'Sorunları görmezden gelip eğlenmek'],
      '"Yelkenleri suya indirmek" pes etmek, mücadeleyi bırakmak demektir.'
    ),
    (
      'İki kardeş arasındaki soğukluk, bayram ziyaretiyle birlikte buzların erimesine dönüştü.',
      'Buzların erimesi',
      'Aralarındaki dargınlığın, mesafenin ve gerginliğin ortadan kalkması',
      ['Anlaşmazlığın daha da derinleşmesi', 'İletişimin tamamen kopma noktasına gelmesi', 'Sorunların halı altına süpürülmesi', 'Geçmişteki hataların tekrar gündeme gelmesi'],
      '"Buzların erimesi" küskünlük ve soğukluğun bitip yumuşamanın başlaması anlamına gelir.'
    ),
    (
      'Sınav yaklaştıkça öğrencinin etekleri tutuşmaya başladı.',
      'Etekleri tutuşmak',
      'Büyük bir telaşa, kaygıya ve paniğe kapılmak',
      ['Büyük bir soğukkanlılıkla beklemek', 'Kendinden emin adımlarla ilerlemek', 'Çalışmayı tamamen bırakıp dinlenmek', 'Başkalarının başarısına sevinmek'],
      '"Etekleri tutuşmak" çok telaşlanmak ve paniğe kapılmak anlamında kullanılır.'
    ),
    (
      'Kendi düşen ağlamaz atasözü aşağıdakilerden hangisini vurgular?',
      'Kendi düşen ağlamaz',
      'İnsan kendi hatalı kararlarının doğurduğu olumsuz sonuçlara katlanmalıdır',
      ['Başkalarının yardımı olmadan başarıya ulaşılamaz', 'Zor zamanlarda dostların desteği her şeyden önemlidir', 'Hata yapan kişiler mutlaka başkalarını suçlamalıdır', 'Tedbirli davranan insanlar asla zarar görmez'],
      'Atasözü, kişinin kendi seçiminin sorumluluğunu üstlenmesi gerektiğini anlatır.'
    ),
    (
      'Ağaç yaşken eğilir atasözünün vermek istediği temel mesaj nedir?',
      'Ağaç yaşken eğilir',
      'Eğitim ve alışkanlık kazandırma süreci küçük yaşlarda çok daha kolaydır',
      ['İnsan her yaşta aynı hızla yeni beceriler öğrenebilir', 'Yaş ilerledikçe öğrenme kapasitesi artar', 'Tecrübe sadece ileri yaşlarda kazanılır', 'Doğayı korumak gelecek nesiller için şarttır'],
      'İnsanlar küçük yaşta kolayca eğitilip şekillendirilebilir.'
    ),
    (
      'Aşağıdaki cümlelerin hangisinde "keskin" sözcüğü mecaz anlamda kullanılmıştır?',
      'Keskin',
      'Yazarın keskin zekâsı ve keskin eleştirileri her cümlede hissediliyor.',
      ['Mutfaktaki keskin bıçakla sebzeleri doğradı.', 'Keskin cam parçaları yere saçılmıştı.', 'Marangoz keskin testereyle tahtayı ikiye böldü.', 'Buz gibi keskin rüzgâr yüzümüzü yalıyordu.'],
      'Zekâ ve eleştiri için kullanılan "keskin" sözcüğü somut kesicilik değil, etkileyicilik (mecaz) anlamındadır.'
    ),
  ];

  static Question _buildSozcukAnlamQuestion(String id, int index) {
    final item = _sozcukPool[index % _sozcukPool.length];
    final variant = (index ~/ _sozcukPool.length) % 3;
    final correctIdx = (index * 7 + 2) % 5;
    final options = List<String>.from(item.$4);
    options.insert(correctIdx, item.$3);

    String prompt;
    if (variant == 0) {
      prompt = '(${index + 1}) "${item.$1}"\n\nBu cümledeki "${item.$2}" ifadesiyle anlatılmak istenen aşağıdakilerden hangisidir?';
    } else if (variant == 1) {
      prompt = '"${item.$1}"\nYukarıdaki parçada geçen "${item.$2}" sözünün kattığı anlam hangisidir?';
    } else {
      prompt = 'ÖSYM Sözel Anlam — "${item.$2}" kavramı veya cümlesi için en doğru anlam karşılığı hangisidir?\nÖrnek: "${item.$1}"';
    }

    return Question(
      id: id,
      type: QuestionType.multipleChoice,
      prompt: prompt,
      options: options,
      correctIndex: correctIdx,
      explanation: item.$5,
    );
  }

  // ==================== 2. CÜMLEDE ANLAM ====================
  static const _cumlePool = [
    (
      'Hava kararmadan eve yetişebilmek için adımlarını sıklaştırdı.',
      'Amaç-Sonuç cümlesi',
      ['Neden-Sonuç cümlesi', 'Koşul-Sonuç cümlesi', 'Karşılaştırma cümlesi', 'Tanım cümlesi'],
      '"-ebilmek için" yapısı henüz gerçekleşmemiş bir amacı bildirdiği için Amaç-Sonuç cümlesidir.'
    ),
    (
      'Gece boyunca şiddetli yağmur yağdığı için bütün yollar göle dönmüştü.',
      'Neden-Sonuç cümlesi',
      ['Amaç-Sonuç cümlesi', 'Koşul-Sonuç cümlesi', 'Öznel değerlendirme', 'Varsayım cümlesi'],
      'Yağmurun yağması gerçekleşmiş bir gerekçe (neden), yolların göle dönmesi sonuçtur.'
    ),
    (
      'Düzenli tekrar yaparsan öğrendiğin bilgileri sınav gününe kadar unutmazsın.',
      'Koşul-Sonuç cümlesi',
      ['Amaç-Sonuç cümlesi', 'Neden-Sonuç cümlesi', 'Kesinlik cümlesi', 'Pişmanlık cümlesi'],
      '"-se/-sa" şart ekiyle sonucun gerçekleşmesi düzenli tekrar şartına bağlanmıştır.'
    ),
    (
      'Dün okuduğum roman, yazarın önceki kitabına göre çok daha sürükleyici ve derinlikliydi.',
      'Karşılaştırma cümlesi',
      ['Tanım cümlesi', 'Nesnel yargı', 'Koşul cümlesi', 'Dolaylı anlatım'],
      '"önceki kitabına göre daha..." ifadesiyle iki eser arasında kıyaslama yapılmıştır.'
    ),
    (
      'Türkiye\'nin yüzölçümü bakımından en büyük gölü Van Gölü\'dür.',
      'Nesnel yargı',
      ['Öznel yargı', 'Tahmin cümlesi', 'Varsayım cümlesi', 'Kinayeli anlatım'],
      'Kişiden kişiye değişmeyen, ölçülebilir ve kanıtlanabilir bir bilgi olduğu için nesneldir.'
    ),
    (
      'Diyelim ki sınavda hiç beklemediğin bir konudan üç soru birden geldi.',
      'Varsayım cümlesi',
      ['Olasılık cümlesi', 'Öneri cümlesi', 'Pişmanlık cümlesi', 'Sitem cümlesi'],
      '"Diyelim ki" ifadesi gerçekleşmemiş bir durumu geçici olarak olmuş gibi kabul etmeyi (varsayım) bildirir.'
    ),
    (
      'Keşke üniversite yıllarımda yabancı dil öğrenmeye daha fazla vakit ayırsaydım.',
      'Pişmanlık ve hayıflanma',
      ['Öneri ve tavsiye', 'Beğeni ve takdir', 'Ön yargı', 'Kanıksama'],
      'Geçmişte yapılmayan bir işten duyulan üzüntüyü dile getirdiği için hayıflanma/pişmanlık bildirir.'
    ),
    (
      'Sanatçı, eserlerinde yalnızca gerçeği değil, o gerçeğin ardındaki insan ruhunu da yansıtmalıdır.',
      'Gereklilik ve sanat görüşü',
      ['Nesnel tanım', 'Yakınma cümlesi', 'Aşamalı durum', 'Eşitlik yargısı'],
      '"-malıdır" ekiyle sanatçının nasıl eser vermesi gerektiğine dair bir görüş/gereklilik sunulmuştur.'
    ),
  ];

  static Question _buildCumleAnlamQuestion(String id, int index) {
    final item = _cumlePool[index % _cumlePool.length];
    final correctIdx = (index * 5 + 1) % 5;
    final options = List<String>.from(item.$3);
    options.insert(correctIdx, item.$2);

    final variant = (index ~/ _cumlePool.length) % 2;
    final prompt = variant == 0
        ? '"${item.$1}"\n\nBu cümlenin anlam özelliği aşağıdakilerden hangisidir?'
        : 'Aşağıdaki özelliklerden hangisi "${item.$1}" cümlesi için doğrudur?';

    return Question(
      id: id,
      type: QuestionType.multipleChoice,
      prompt: prompt,
      options: options,
      correctIndex: correctIdx,
      explanation: item.$4,
    );
  }

  // ==================== 3. PARAGRAF SORULARI ====================
  static const _paragrafPool = [
    (
      'Teknoloji hızla ilerledikçe insanların bilgiye ulaşma süresi kısalıyor; ancak bilgiyi sindirme ve eleştirel süzgeçten geçirme becerisi aynı oranda gelişmiyor. Ekranlarda saniyeler içinde kaydırılan içerikler, derinlemesine düşünme alışkanlığını zayıflatıyor. Oysa kalıcı öğrenme, aceleyle tüketilen verilerden değil, üzerinde sabırla düşünülen fikirlerden doğar.',
      'Parçanın ana düşüncesi nedir?',
      'Hızlı bilgi tüketiminin derin düşünme ve kalıcı öğrenmeyi olumsuz etkilemesi',
      [
        'Teknolojinin eğitimde hiçbir fayda sağlamadığı',
        'İnsanların artık kitap okumayı tamamen bıraktığı',
        'Bilgiye ulaşmanın geçmişte çok daha kolay olduğu',
        'Ekran kullanımının sadece fiziksel sağlığa zarar verdiği',
      ],
      'Metin, hızlı tüketilen bilginin derin düşünmeyi zayıflattığını ve kalıcı öğrenmenin sabırlı düşünme gerektirdiğini vurgulamaktadır.'
    ),
    (
      'İyi bir romancı, karakterlerini yalnızca kusursuz kahramanlar olarak çizmez. Çünkü gerçek yaşamda her insanın korkuları, çelişkileri ve zaafları vardır. Okur, kendisinden bir parça bulamadığı, hiç hata yapmayan tek boyutlu karakterlere inanmaz; ancak zaaflarıyla yüzleşen bir kahramanın öyküsüne kalbinden bağlanır.',
      'Yazar bu parçada aşağıdakilerden hangisini vurgulamaktadır?',
      'İnandırıcı roman karakterlerinin insani zaaflara ve çelişkilere sahip olması gerektiğini',
      [
        'Okurların sadece mutlu sonla biten romanları sevdiğini',
        'Tarihsel romanların diğer türlerden daha gerçekçi olduğunu',
        'Kahramanların her zaman toplumun kurallarına uyması gerektiğini',
        'Romancının kendi hayatını olduğu gibi kitaba aktarması gerektiğini',
      ],
      'Parçada karakterlerin kusursuz değil, insani zaafları ve çelişkileriyle gerçekçi kılındığı anlatılmaktadır.'
    ),
    (
      '(I) Başarılı bir zaman yönetimi, her işi aynı anda yapmaya çalışmak değil, öncelikleri doğru sıralamaktır. (II) Önemli işlerle acil işleri birbirinden ayıramayan kişiler gün sonunda yorulur ama ilerleme kaydedemez. (III) Modern ofis binalarının mimarisi çalışanların motivasyonunu artırmalıdır. (IV) Bu yüzden güne başlamadan önce en yüksek etkiyi yaratacak üç temel hedef belirlemek verimliliği iki katına çıkarır.',
      'Bu parçada numaralanmış cümlelerden hangisi düşüncenin akışını bozmaktadır?',
      'III numaralı cümle',
      ['I numaralı cümle', 'II numaralı cümle', 'IV numaralı cümle', 'Parçada akışı bozan cümle yoktur'],
      'Parça zaman yönetimi ve öncelik sıralaması üzerinedir; III. cümle ofis mimarisinden söz ederek akışı bozar.'
    ),
    (
      'Bilim tarihinde pek çok büyük buluş, tesadüfen bulunmuş gibi görünse de aslında yıllar süren hazırlıklı bir zihnin ürünüdür. Alexander Fleming\'in penisilini keşfetmesi buna güzel bir örnektir. Başka bir gözlemci küflenen deney kabını çöpe atabilirdi; ancak Fleming yılların birikimiyle o küfün bakterileri yok ettiğini fark etti.',
      'Bu parçada kullanılan düşünceyi geliştirme yolu aşağıdakilerden hangisidir?',
      'Örneklendirme',
      ['Tanık gösterme', 'Sayısal verilerden yararlanma', 'Benzetme', 'Kişileştirme'],
      'Yazar düşüncesini somutlaştırmak için Alexander Fleming\'in penisilin keşfini örnek olarak vermiştir.'
    ),
    (
      'Kişisel gelişim kitapları bize çoğu zaman büyük sıçramalar yapmayı öğütler. ____ Oysa insan yaşamındaki kalıcı dönüşümler, her gün aksatılmadan atılan küçücük ama istikrarlı adımlarla gerçekleşir.',
      'Bu parçada boş bırakılan yere düşüncenin akışına göre aşağıdakilerden hangisi getirilmelidir?',
      'Ancak ani ve büyük değişimler çoğu zaman sürdürülebilir olmaz.',
      [
        'Bu yüzden herkes mutlaka günde bir kitap bitirmelidir.',
        'Sadece büyük adımlar atan insanlar tarihe geçebilir.',
        'İstikrarlı çalışmak her zaman zaman kaybına yol açar.',
        'Küçük hedefler koymak insanın hayallerini sınırlar.',
      ],
      '"Oysa..." diye devam eden sonraki cümleyle uyumlu olarak büyük adımların sürdürülebilir olmadığı belirtilmelidir.'
    ),
    (
      'Dil, bir milletin yüzyıllar boyunca biriktirdiği kültürün, düşüncenin ve duyguların canlı taşıyıcısıdır. Bir sözcüğü kaybettiğinizde yalnızca bir sesi değil, o sözcüğün arkasındaki yaşam biçimini ve hafızayı da yitirirsiniz. Ünlü düşünürün dediği gibi: "Sınırlarım dilimin sınırları kadardır."',
      'Bu parçanın anlatımında aşağıdakilerden hangisi vardır?',
      'Tanık gösterme (Alıntı yapma)',
      ['Öyküleme', 'Tartışmacı anlatım içinde karşılaştırma', 'Sayısal verilerle kanıtlama', 'Mizahi anlatım'],
      'Parçada düşünürün sözü tırnak içinde doğrudan alıntılanarak tanık gösterme yapılmıştır.'
    ),
  ];

  static Question _buildParagrafQuestion(String id, int index) {
    final item = _paragrafPool[index % _paragrafPool.length];
    final correctIdx = (index * 3 + 4) % 5;
    final options = List<String>.from(item.$4);
    options.insert(correctIdx, item.$3);

    return Question(
      id: id,
      type: QuestionType.multipleChoice,
      passage: item.$1,
      prompt: item.$2,
      options: options,
      correctIndex: correctIdx,
      explanation: item.$5,
    );
  }

  // ==================== 4. ANLATIM BOZUKLUKLARI ====================
  static const _anlatimPool = [
    (
      'Bu konuyu seninle karşılıklı tartıştık.',
      '"karşılıklı" sözcüğü gereksizdir; "tartışmak" zaten karşılıklı yapılır.',
      ['Özne-yüklem uyumsuzluğu vardır.', 'Tamlama yanlışı yapılmıştır.', 'Yanlış anlamda sözcük kullanılmıştır.', 'Sıralama ve mantık hatası vardır.'],
      'Gereksiz sözcük kullanımı duruluğu bozar; "tartışmak" eylemi zaten karşılıklı gerçekleşir.'
    ),
    (
      'Öğrencilerin çoğu derse zamanında geldi, ancak hiçbiri ödevini getirmemişler.',
      'Belgisiz zamir "hiçbiri" özne olduğunda yüklem tekil ("getirmemiş") olmalıdır.',
      ['Gereksiz yardımcı eylem kullanılmıştır.', 'Sözcük yanlış yerde kullanılmıştır.', 'Nesne eksikliği vardır.', 'Zarf tümleci gereksizdir.'],
      '"Hiçbiri, herkes, kimse" gibi belgisiz öznelerle yüklem tekil çekimlenir.'
    ),
    (
      'İlk kez yapılan bu yarışmaya katılım oldukça azdı ve kimse dereceye giremedi.',
      'Mantık hatası yoktur; ancak "Aşağıdaki cümlelerin hangisinde anlatım bozukluğu vardır?" kalıbında doğru yargı aranıyorsa dikkat edilmelidir.',
      ['Çelişen sözcükler bir arada kullanılmıştır.', 'Özne eksikliği anlatımı bozmuştur.', 'Dolaylı tümleç eksikliği vardır.', 'Edat yanlış kullanılmıştır.'],
      'Cümle dil bilgisi ve anlam bakımından tutarlıdır.'
    ),
    (
      'Eminim ki bu akşam mutlaka bize uğrayabilir.',
      '"Eminim/mutlaka" (kesinlik) ile "-ebilir" (olasılık) anlamca çelişmektedir.',
      ['Özne-yüklem uyumu bozulmuştur.', 'Tamlayan eki eksiktir.', 'Ek eylem yanlış kullanılmıştır.', 'Çatı uyuşmazlığı vardır.'],
      'Kesinlik bildiren zarflar ile olasılık bildiren kipler aynı cümlede çelişki yaratır.'
    ),
    (
      'Çok başım ağrıdığı için toplantıya katılamadım.',
      'Sözcüğün yanlış yerde kullanımı: "Başım çok ağrıdığı için..." olmalıdır.',
      ['Gereksiz ek kullanılmıştır.', 'Nesne eksikliği vardır.', 'Deyim yanlış anlamda kullanılmıştır.', 'Bağlaç yanlış yere konmuştur.'],
      '"Çok" zarfı "başım" ismini değil, "ağrıdığı" fiilimsisini nitelemelidir.'
    ),
    (
      'Bırakın doktor olmayı, iğne bile yapamaz o.',
      'Sıralama / mantık hatası: "Bırakın iğne yapmayı, doktor bile olamaz" şeklinde düzeltilmelidir.',
      ['Özne eksikliği vardır.', 'Yardımcı fiil gereksizdir.', 'Tamlama yanlışı vardır.', 'Eş anlamlı sözcükler bir arada kullanılmıştır.'],
      'Basit olandan zor olana doğru mantıksal sıralama yapılmalıdır.'
    ),
  ];

  static Question _buildAnlatimBozukluguQuestion(String id, int index) {
    final item = _anlatimPool[index % _anlatimPool.length];
    final correctIdx = (index * 2 + 1) % 5;
    final options = List<String>.from(item.$3);
    options.insert(correctIdx, item.$2);

    return Question(
      id: id,
      type: QuestionType.multipleChoice,
      prompt: '"${item.$1}"\n\nBu cümledeki anlatım durumuyla ilgili aşağıdakilerden hangisi doğrudur?',
      options: options,
      correctIndex: correctIdx,
      explanation: item.$4,
    );
  }

  // ==================== 5. SÖZEL MANTIK (DİNAMİK SIRALAMA & TABLO) ====================
  static Question _buildSozelMantikQuestion(String id, int index) {
    // 5 kişilik dinamik sıralama / kat / gün bulmacası üreticisi
    const namesSets = [
      ['Ahmet', 'Burcu', 'Can', 'Deniz', 'Elif'],
      ['Furkan', 'Gizem', 'Hakan', 'İrem', 'Kerem'],
      ['Lale', 'Mert', 'Nihal', 'Ozan', 'Pınar'],
      ['Selin', 'Tarık', 'Umut', 'Volkan', 'Zeynep'],
    ];
    const contexts = [
      ('beş katlı bir binanın 1\'den 5\'e numaralanmış katlarında oturmaktadır', 'katta oturmaktadır'),
      ('Pazartesi\'den Cuma\'ya kadar haftanın 5 günü birer sunum yapacaktır', 'günü sunum yapacaktır'),
      ('bir yarışmada 1\'den 5\'e kadar sıralanmıştır', 'sırada yer almıştır'),
      ('bir rafta soldan sağa 1\'den 5\'e kadar numaralanmış bölmelere kitap yerleştirmiştir', 'bölmeye kitap koymuştur'),
    ];

    final names = List<String>.from(namesSets[index % namesSets.length]);
    // Deterministik permütasyon kaydırması
    final shift = (index ~/ namesSets.length) % 5;
    final ordered = <String>[];
    for (int k = 0; k < 5; k++) {
      ordered.add(names[(k + shift) % 5]);
    }
    // ordered[0] = 1., ordered[1] = 2., ordered[2] = 3., ordered[3] = 4., ordered[4] = 5.

    final ctx = contexts[(index ~/ 3) % contexts.length];
    final isDays = ctx.$2.contains('günü');
    final labels = isDays
        ? ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma']
        : ['1.', '2.', '3.', '4.', '5.'];

    final passage =
        '${names.join(', ')} adlı beş kişi ${ctx.$1}.\n'
        '• ${ordered[0]} ilk sırada (${labels[0]}) ${ctx.$2}.\n'
        '• ${ordered[2]}, ${ordered[1]}\'in hemen ardından, ${ordered[3]}\'in hemen öncesinde ${ctx.$2}.\n'
        '• ${ordered[4]} son sırada (${labels[4]}) değildir diyen bilgi yanlıştır; tam aksine en sonda (${labels[4]}) ${ordered[4]} vardır.\n'
        '• ${ordered[1]}, ${ordered[0]}\'in hemen ardından ${ctx.$2}.';

    final qType = index % 3;
    late String prompt;
    late String correct;
    late List<String> distractors;
    late String explanation;

    if (qType == 0) {
      final askPos = (index % 3) + 1; // 1, 2 veya 3 (0-indexed: 2., 3., 4.)
      prompt = 'Buna göre, ${labels[askPos]} ${ctx.$2.replaceAll('oturmaktadır', 'oturan').replaceAll('yapacaktır', 'yapan').replaceAll('yer almıştır', 'yer alan').replaceAll('koymuştur', 'koyan')} kişi kimdir?';
      correct = ordered[askPos];
      distractors = ordered.where((e) => e != correct).toList();
      explanation = 'Verilen öncüller yerleştirildiğinde sıralama: 1:${ordered[0]}, 2:${ordered[1]}, 3:${ordered[2]}, 4:${ordered[3]}, 5:${ordered[4]} olur. Dolayısıyla cevap $correct.';
    } else if (qType == 1) {
      prompt = 'Aşağıdaki ifadelerden hangisi KESİNLİKLE doğrudur?';
      correct = '${ordered[2]}, ${labels[2]} ${ctx.$2}.';
      distractors = [
        '${ordered[1]}, ${labels[3]} ${ctx.$2}.',
        '${ordered[3]}, ${labels[1]} ${ctx.$2}.',
        '${ordered[4]}, ${labels[0]} ${ctx.$2}.',
        '${ordered[0]}, ${labels[4]} ${ctx.$2}.',
      ];
      explanation = 'Kesin sıralama: ${ordered[0]} - ${ordered[1]} - ${ordered[2]} - ${ordered[3]} - ${ordered[4]}.';
    } else {
      prompt = '${ordered[3]} ile ilgili aşağıdakilerden hangisi kesinlikle YANLIŞTIR?';
      correct = '${ordered[3]}, ${ordered[2]}\'den daha önce ${ctx.$2}.';
      distractors = [
        '${ordered[3]}, ${labels[3]} ${ctx.$2}.',
        '${ordered[3]}, ${ordered[4]}\'ten hemen önce ${ctx.$2}.',
        '${ordered[3]}, ${ordered[0]}\'ten sonra ${ctx.$2}.',
        '${ordered[3]}, ${ordered[2]}\'den hemen sonra ${ctx.$2}.',
      ];
      explanation = '${ordered[3]} 4. sıradadır; 3. sıradaki ${ordered[2]}\'den önce olması imkânsızdır.';
    }

    final correctIdx = (index * 4 + 1) % 5;
    final options = List<String>.from(distractors.take(4));
    options.insert(correctIdx, correct);

    return Question(
      id: id,
      type: QuestionType.multipleChoice,
      passage: passage,
      prompt: prompt,
      options: options,
      correctIndex: correctIdx,
      explanation: explanation,
    );
  }
}
