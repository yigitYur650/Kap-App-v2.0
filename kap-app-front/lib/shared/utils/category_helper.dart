class CategoryHelper {
  static const String sutKahvaltilik = 'Süt & Kahvaltılık';
  static const String meyveSebze = 'Meyve & Sebze';
  static const String etPilic = 'Et & Piliç';
  static const String temelGida = 'Temel Gıda';
  static const String atistirmalik = 'Atıştırmalık';
  static const String icecek = 'İçecek';
  static const String temizlik = 'Temizlik';
  static const String genel = 'Genel';

  static const List<String> categories = [
    'Tümü',
    sutKahvaltilik,
    meyveSebze,
    etPilic,
    temelGida,
    atistirmalik,
    icecek,
    temizlik,
    genel,
  ];

  static String detectCategory(String itemName) {
    if (itemName.trim().isEmpty) return genel;
    final lower = itemName.toLowerCase().trim();

    // Süt & Kahvaltılık
    if (_containsAny(lower, [
      'süt', 'sut', 'peynir', 'yumurta', 'yoğurt', 'yogurt', 'tereyağı', 'tereyag', 'kaşar', 'kasar',
      'zeytin', 'reçel', 'recel', 'bal', 'kaymak', 'lor', 'labne', 'sürüm', 'tost peyniri',
      'krem peynir', 'salam', 'sosis', 'pastırma', 'pastirma', 'helva', 'tahin', 'pekmez', 'lor peyniri'
    ])) {
      return sutKahvaltilik;
    }

    // Et & Piliç
    if (_containsAny(lower, [
      'tavuk', 'kıyma', 'kiyma', 'dana', 'kuzu', 'et', 'piliç', 'pilic', 'köfte', 'kofte',
      'balık', 'balik', 'antrikot', 'bonfile', 'kuşbaşı', 'kusbasi', 'pirzola', 'şinitzel',
      'sinitzel', 'kanat', 'baget', 'hindi', 'kavurma', 'kıymalı', 'kiymali', 'sucuk'
    ])) {
      return etPilic;
    }

    // Meyve & Sebze
    if (_containsAny(lower, [
      'elma', 'muz', 'domates', 'salatalık', 'salatalik', 'biber', 'soğan', 'sogan',
      'patates', 'ıspanak', 'ispanak', 'meyve', 'sebze', 'limon', 'portakal', 'mandalina',
      'çilek', 'cilek', 'karpuz', 'kavun', 'üzüm', 'uzum', 'şeftali', 'seftali', 'kayısı',
      'kayisi', 'kiraz', 'erik', 'armut', 'maydanoz', 'nane', 'dereotu', 'kıvırcık', 'marul',
      'roka', 'sarımsak', 'sarimsak', 'havuç', 'havuc', 'kabak', 'patlıcan', 'patlican',
      'fasulye', 'nohut', 'mercimek', 'bezelye', 'mantar', 'turp', 'enginar', 'karnabahar', 'brokoli'
    ])) {
      return meyveSebze;
    }

    // İçecek
    if (_containsAny(lower, [
      'kola', 'cola', 'fanta', 'sprite', 'meyve suyu', 'su', 'çay', 'cay', 'kahve',
      'soda', 'gazoz', 'içecek', 'icecek', 'ayran', 'şalgam', 'salgam', 'icetea', 'ice tea',
      'soğuk çay', 'soguk cay', 'enerji içeceği', 'nescafe', 'espresso', 'türk kahvesi',
      'turk kahvesi', 'maden suyu', 'şişe su', 'sise su', 'damacana'
    ])) {
      return icecek;
    }

    // Atıştırmalık
    if (_containsAny(lower, [
      'cips', 'chips', 'çikolata', 'cikolata', 'bisküvi', 'biskuvi', 'gofret', 'kraker',
      'kurabiye', 'fındık', 'findik', 'fıstık', 'fistik', 'ceviz', 'badem', 'çekirdek',
      'cekirdek', 'jelibon', 'şekerleme', 'sekerleme', 'dondurma', 'nuga', 'bar', 'doritos',
      'lays', 'ruffles', 'oreo', 'ülker', 'ulker', 'eti'
    ])) {
      return atistirmalik;
    }

    // Temizlik & Bakım
    if (_containsAny(lower, [
      'deterjan', 'sabun', 'şampuan', 'sampuan', 'peçete', 'pecete', 'tuvalet kağıdı',
      'tuvalet kagidi', 'diş macunu', 'dis macunu', 'sünger', 'sunger', 'yumuşatıcı',
      'yumusatici', 'çamaşır suyu', 'camasir suyu', 'temizlik', 'banyo', 'mutfak bezi',
      'fırça', 'firca', 'kireç çözücü', 'kirec cozucu', 'bulaşık kapsülü', 'bulasik kapsulu',
      'ıslak mendil', 'islak mendil', 'havlu peçete', 'ariel', 'domestos', 'fairy', 'finish'
    ])) {
      return temizlik;
    }

    // Temel Gıda
    if (_containsAny(lower, [
      'ekmek', 'somun', 'un', 'şeker', 'seker', 'tuz', 'makarna', 'pirinç', 'pirinc',
      'bulgur', 'yağ', 'yag', 'ayçiçek yağı', 'aycicek yagi', 'zeytinyağı', 'zeytinyagi',
      'salça', 'salca', 'sirke', 'baharat', 'karabiber', 'pul biber', 'maya', 'irmik',
      'nişasta', 'nisasta', 'bulyon', 'hazır çorba', 'hazir corba', 'konserve', 'filiz',
      'nuhun ankara', 'barilla'
    ])) {
      return temelGida;
    }

    return genel;
  }

  static bool _containsAny(String text, List<String> keywords) {
    for (final kw in keywords) {
      if (text.contains(kw)) return true;
    }
    return false;
  }
}
