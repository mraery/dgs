import '../models/lesson_models.dart';
import 'dgs_sozel_question_generator.dart';

/// ÖSYM DGS Sözel Müfredatını Kapsamlı Hale Getiren 10 Ek Sözel Ünitesi (70 Ders)
List<LearningUnit> buildExtraDgsSozelUnits() {
  const unitSpecs = [
    (29, 'dgs_cumle_u1', 'Cümlede Anlam: Neden, Amaç ve Koşul', 'DGS Sözel Anlam', 0xFF0EA5E9, [
      ('Neden-Sonuç İlişkisi', 'Gerçekleşmiş gerekçeli yargıları tespit etme'),
      ('Amaç-Sonuç İlişkisi', 'Henüz gerçekleşmemiş hedef bildiren cümleler'),
      ('Koşul-Sonuç Cümleleri', 'Şart ekleri ve koşul bağlaçlarıyla anlam analizi'),
      ('Karşılaştırma & Benzetme', 'İki kavram arası fark ve benzerlik kurma'),
      ('Öznel ve Nesnel Yargılar', 'Kanıtlanabilirlik ve kişisel görüş ayrımı'),
      ('Doğrudan ve Dolaylı Anlatım', 'Alıntı ve aktarım cümlelerini ayırt etme'),
      ('Ünite Sonu Cümle Anlamı Denemesi', 'DGS cümle ilişkileri tarama sınavı'),
    ]),
    (30, 'dgs_cumle_u2', 'Cümle Yorumlama & Yakın Anlam', 'DGS Sözel Anlam', 0xFF0284C7, [
      ('Anlamca En Yakın Cümle', 'Verilen cümlenin özünü koruyan eşdeğer cümleyi bulma'),
      ('Cümleden Kesin Çıkarılacak Yargı', 'Yalnızca metinde verilenlerden kesin yargıya ulaşma'),
      ('Cümle Tamamlama & Bağlama', 'Anlam bütünlüğüne göre boşluk doldurma'),
      ('Cümle Birleştirme Teknikleri', 'İki ayrı cümleyi anlam kaybı olmadan birleştirme'),
      ('Düşünceyi Destekleyen Örnekler', 'Soyut yargıyı somutlaştıran cümleleri seçme'),
      ('Sözün Cümleye Kattığı Anlam', 'Kavramların bağlam içi anlam derinliği'),
      ('Ünite Sonu Cümle Yorumu Denemesi', 'ÖSYM tarzı cümle yorumlama sınavı'),
    ]),
    (31, 'dgs_paragraf_u3', 'Paragrafta Ana & Yardımcı Düşünce', 'DGS Paragraf', 0xFF10B981, [
      ('Paragrafın Konusu ve Başlığı', 'Metnin üzerinde durduğu temel kavramı saptama'),
      ('Ana Düşünceyi Bulma Stratejisi', 'Yazarın asıl vurgulamak istediği mesajı yakalama'),
      ('Paragrafta Asıl Anlatılmak İstenen', 'Anahtar cümlelerden özet fikir çıkarma'),
      ('Yardımcı Düşünce (Değinilmemiştir)', 'Olumsuz soru köklerinde şık eleme tekniği'),
      ('Paragrafın Sorusu Hangisidir?', 'Yanıt niteliğindeki metnin sorusunu bulma'),
      ('Parçadan Çıkarılamayacak Yargılar', 'Metin sınırlarını aşan yorumları eleme'),
      ('Ünite Sonu Ana Düşünce Denemesi', 'ÖSYM DGS paragraf ana fikir taraması'),
    ]),
    (32, 'dgs_paragraf_u4', 'Paragraf Tamamlama & Akışı Bozan', 'DGS Paragraf', 0xFF059669, [
      ('Paragrafın Giriş Cümlesini Bulma', 'Bağlaçsız ve genel yargılı giriş tespiti'),
      ('Paragrafın Gelişme Bölümünü Tamamlama', 'Önceki ve sonraki cümleyle köprü kurma'),
      ('Paragrafın Sonuç Cümlesini Tamamlama', 'Metni mantıksal sonuca bağlama'),
      ('Düşüncenin Akışını Bozan Cümle', 'Konu veya bakış açısı sapmasını yakalama'),
      ('Anlatım Bütünlüğünü Sağlama', 'Zamir ve geçiş ifadeleriyle takip etme'),
      ('Paragrafta Boşluk Doldurma Kampı', 'Çoklu boşluklu DGS paragraf soruları'),
      ('Ünite Sonu Akış & Tamamlama Denemesi', 'Hızlı paragraf tamamlama sınavı'),
    ]),
    (33, 'dgs_paragraf_u5', 'Paragraf Yer Değiştirme & İkiye Bölme', 'DGS Paragraf', 0xFF14B8A6, [
      ('Anlamlı Paragraf Oluşturma (Sıralama)', 'Karışık cümleleri mantık sırasına dizme'),
      ('Cümlelerin Yerini Değiştirme', 'Akışı düzeltmek için iki cümleyi takas etme'),
      ('Paragrafı İkiye Bölme', 'Konunun yeni bir boyutunun başladığı cümleyi bulma'),
      ('Numaralanmış Cümlelerin Analizi', 'Cümleler arası neden-sonuç zinciri'),
      ('Zaman ve Bağlam Uyumu', 'Kronolojik ve düşünsel geçişleri yakalama'),
      ('DGS İleri Paragraf Yapı Soruları', 'Karma sıralama ve bölme pratikleri'),
      ('Ünite Sonu Paragraf Yapısı Denemesi', 'DGS paragraf yapı final sınavı'),
    ]),
    (34, 'dgs_paragraf_u6', 'Anlatım Teknikleri & Çoklu Paragraf', 'DGS Paragraf', 0xFF0D9488, [
      ('Açıklayıcı ve Tartışmacı Anlatım', 'Bilgi verme ile fikir çürütme ayrımı'),
      ('Öyküleyici ve Betimleyici Anlatım', 'Olay akışı ile görsel tasvir ayrımı'),
      ('Tanık Gösterme & Örneklendirme', 'Düşünceyi geliştirme yollarını ayırt etme'),
      ('Karşılaştırma & Sayısal Veriler', 'İstatistiksel ve kıyaslayıcı anlatım'),
      ('Aynı Parçaya Bağlı İkili Sorular', 'Bir metinden iki ayrı kazanım çözme'),
      ('Aynı Parçaya Bağlı Üçlü Sorular', 'Uzun DGS metinlerinde hız ve dikkat'),
      ('Ünite Sonu Çoklu Paragraf Denemesi', 'ÖSYM tarzı uzun paragraf sınavı'),
    ]),
    (35, 'dgs_mantik_u3', 'Sözel Mantık: Sıralama & Konum', 'DGS Sözel Mantık', 0xFF8B5CF6, [
      ('Tek Boyutlu Doğrusal Sıralama', '1\'den 5\'e veya 1\'den 7\'ye sıra kurma'),
      ('Öncelik - Sonralık İlişkileri', '"Hemen önce", "en az iki kişi sonra" ifadeleri'),
      ('Günler ve Saatler Çizelgesi', 'Pazartesi-Cuma arası program tabloları'),
      ('Kat ve Raf Yerleşim Bulmacaları', 'Dikey sıralamada alt-üst yerleşimi'),
      ('Dairesel ve Karşılıklı Oturma', 'Masa çevresi ve yön tabanlı yerleştirme'),
      ('Olasılık Dallanması (2 İhtimalli)', 'Kesin olmayan verilerde iki senaryo açma'),
      ('Ünite Sonu Sıralama Mantık Denemesi', 'DGS sıralama mantık final sınavı'),
    ]),
    (36, 'dgs_mantik_u4', 'Sözel Mantık: Eşleştirme & Dağıtım', 'DGS Sözel Mantık', 0xFF7C3AED, [
      ('İki Değişkenli Tablo Kurma', 'Kişi - Şehir / Meslek / Kitap eşleştirmeleri'),
      ('Üç Değişkenli Matris Tabloları', 'Sabit eksen seçip verileri çaprazlama'),
      ('Sayısal Kotalı Dağıtım Soruları', 'Her grupta en az/en çok kişi sayısı kuralları'),
      ('Aynı veya Farklı Grup Kuralları', '"A ve B aynı gruptadır / farklıdır" öncülleri'),
      ('Koşullu "Eğer... ise" Çıkarımları', 'Şarta bağlı senaryo üretme ve eleme'),
      ('Kesin Doğru vs Olabilir Soruları', 'Tüm ihtimallerde değişmeyen veriyi bulma'),
      ('Ünite Sonu Eşleştirme Mantık Denemesi', 'DGS tablo mantık final sınavı'),
    ]),
    (37, 'dgs_mantik_u5', 'Sözel Mantık: İleri Düzey & Çoklu Senaryo', 'DGS Sözel Mantık', 0xFF6366F1, [
      ('4\'lü DGS Sözel Mantık Setleri', 'Tek metne bağlı 4 soruluk tam DGS bloğu'),
      ('Kısmi Bilgiyle Eleme Teknikleri', 'Seçeneklerden geriye doğru kontrol'),
      ('Tekrarlı ve Dönüşümlü Görev Dağılımı', 'Aynı kişinin birden fazla gün görev alması'),
      ('Yön, Rota ve Durak Problemleri', 'Metro, otobüs ve uçuş aktarma mantığı'),
      ('İki Aşamalı Seçim ve Tercih Tabloları', 'Ön eleme ve final eşleşmeleri'),
      ('Zaman Baskısı Altında Hızlı Tablo', 'Sözel mantıkta 4 dakikada 4 net taktiği'),
      ('Ünite Sonu İleri Sözel Mantık Sınavı', 'ÖSYM zorluk seviyesinde mantık denemesi'),
    ]),
    (38, 'dgs_anlatim_u1', 'Anlatım Bozuklukları & Dil Mantığı', 'DGS Sözel Anlam', 0xFFF59E0B, [
      ('Gereksiz Sözcük ve Duruluk İlkesi', 'Eş anlamlı veya anlamca kapsayan sözcükler'),
      ('Anlamca Çelişen Sözcükler', 'Kesinlik ve olasılık ifadelerinin çatışması'),
      ('Sözcüğün Yanlış Anlamda Kullanımı', 'Birbirine karıştırılan yakın sözcükler'),
      ('Sözcüğün Yanlış Yerde Kullanımı', 'Sıfat ve zarfların cümle içi konumu'),
      ('Özne-Yüklem Uyumsuzluğu', 'Tekillik-çoğulluk ve kişi uyumu kuralları'),
      ('Mantık ve Sıralama Hataları', 'Derecelendirme ve anlam tutarlılığı'),
      ('Ünite Sonu Anlatım Bozukluğu Sınavı', 'Kapsamlı dil mantığı final denemesi'),
    ]),
  ];

  return unitSpecs.map((spec) {
    final unitNumber = spec.$1;
    final unitId = spec.$2;
    final unitTitle = spec.$3;
    final subject = spec.$4;
    final colorHex = spec.$5;
    final lessonSpecs = spec.$6;

    final lessons = List<Lesson>.generate(lessonSpecs.length, (idx) {
      final lSpec = lessonSpecs[idx];
      final lId = '${unitId}_l${idx + 1}';
      final isExam = idx == lessonSpecs.length - 1;
      final previewQuestions = DgsSozelQuestionGenerator.generate(lId, count: 6);

      return Lesson(
        id: lId,
        title: lSpec.$1,
        description: lSpec.$2,
        xpReward: isExam ? 100 : 50,
        gemReward: isExam ? 25 : 10,
        isUnitExam: isExam,
        questions: [
          Question(
            id: '${lId}_concept',
            type: QuestionType.conceptCard,
            prompt: '',
            explanation: '',
            conceptTitle: '${lSpec.$1} — ÖSYM Stratejisi',
            rule: '${lSpec.$2}.\nSözel bölümde her zaman soru kökündeki "değinilmemiştir / kesinlikle / asıl" ifadelerine dikkat edin.',
            examTip: 'DGS Sözel testinde 50 sorunun tamamı anlam, paragraf ve sözel mantık muhakemesi ölçer.',
            iconEmoji: isExam ? '🏆' : '📖',
          ),
          ...previewQuestions,
        ],
      );
    });

    return LearningUnit(
      id: unitId,
      unitNumber: unitNumber,
      title: unitTitle,
      subject: subject,
      colorHex: colorHex,
      lessons: lessons,
    );
  }).toList();
}
