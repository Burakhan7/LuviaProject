// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get greetingMorning => 'Günaydın';

  @override
  String get greetingDay => 'İyi günler';

  @override
  String get greetingEvening => 'İyi akşamlar';

  @override
  String get guestMode =>
      'Misafir modundasın. Kaydol veya Giriş yap, kıyafetlerini kalıcı olarak sakla.';

  @override
  String guestItemsWarn(int count) {
    return '$count kıyafetin var. Kaydolmazsan kaybolabilir — hesabını güvene al.';
  }

  @override
  String guestItemsCollected(int count) {
    return '$count kıyafet biriktirdin! Bunları kaybetmemek için hemen kaydol.';
  }

  @override
  String get signUpOrLogin => 'Kaydol veya Giriş Yap';

  @override
  String get whatToWear => 'Bugün ne giysek?';

  @override
  String get recentlyAdded => 'Son Eklenenler';

  @override
  String todayWithCity(String city) {
    return 'Bugün · $city';
  }

  @override
  String get today => 'Bugün';

  @override
  String get weatherBasedSuggestion => 'Hava durumuna göre öneri';

  @override
  String get grantPermission => 'İzin Ver';

  @override
  String get locationServiceOff =>
      'Konum servisin kapalı. Aç, günün havasına göre kombin önerelim.';

  @override
  String get locationPermissionAsk =>
      'Konum izni ver, günün gidişatına göre sana kombin önerelim.';

  @override
  String get todayOutfit => 'Bugünün Kombini';

  @override
  String get todayOutfitDesc =>
      'Bugün için gardırobuna özel bir kombin hazırladık';

  @override
  String get seeTodayOutfit => 'Bugünün Kombinini Gör';

  @override
  String get addMoreClothes => 'Kombin oluşturmak için daha fazla kıyafet ekle';

  @override
  String get tryAgain => 'Tekrar Dene';

  @override
  String get todayOutfitReady => 'Bugünün kombini hazır';

  @override
  String get boughtSomethingNew => 'Yeni bir şey mi aldın?';

  @override
  String get addToWardrobe => 'Dolabına ekle, kombinlerde çıksın';

  @override
  String get total => 'Toplam';

  @override
  String get upper => 'Üst';

  @override
  String get lower => 'Alt';

  @override
  String get shoes => 'Ayakkabı';

  @override
  String get noClothesYet => 'Henüz kıyafet eklemedin';

  @override
  String get kaydolVeyaGiris => 'Kaydol veya Giriş Yap';

  @override
  String get bugunNeGiysek => 'Bugün ne giysek?';

  @override
  String get sonEklenenler => 'Son Eklenenler';

  @override
  String get havaDurumunaGore => 'Hava durumuna göre öneri';

  @override
  String get izinVer => 'İzin Ver';

  @override
  String get bugununKombini => 'Bugünün Kombini';

  @override
  String get bugunIcinGardirobuna =>
      'Bugün için gardırobuna özel bir kombin hazırladık';

  @override
  String get bugununKombininiGor => 'Bugünün Kombinini Gör';

  @override
  String get kombinOlusturmakIcin =>
      'Kombin oluşturmak için daha fazla kıyafet ekle';

  @override
  String get bugununKombiniHazir => 'Bugünün kombini hazır';

  @override
  String get yeniBirSey => 'Yeni bir şey mi aldın?';

  @override
  String get dolabinaEkleKombinlerde => 'Dolabına ekle, kombinlerde çıksın';

  @override
  String get henuzKiyafetEklemedin => 'Henüz kıyafet eklemedin';

  @override
  String get birKiyafeteCift =>
      'Bir kıyafete çift dokunarak kombin önerilerine dahil/hariç edebilirsin ✨';

  @override
  String get silmekIcinKiyafete => 'Silmek için kıyafete uzun bas 🗑️';

  @override
  String get cokFazlaFotograf => 'Çok fazla fotoğraf';

  @override
  String get duzenle => 'Düzenle';

  @override
  String get stilKumasKalip =>
      'Stil, kumaş, kalıp, desen... senin için ayarlandı.';

  @override
  String get guncellendi => 'Güncellendi';

  @override
  String get gardirobum => 'Gardırobum';

  @override
  String get gardirobunBos => 'Gardırobun boş';

  @override
  String get ilkKiyafetiniEkle =>
      'İlk kıyafetini ekle, Luvia senin için kombin önermeye başlasın. Boydan ya da tek parça, fark etmez.';

  @override
  String get fotografEkle => 'Fotoğraf Ekle';

  @override
  String get musaitDegil => 'Müsait değil';

  @override
  String get buBaglamIcin => 'Bu bağlam için yeterince öneri gösterdik';

  @override
  String get konumIzni => 'Konum İzni';

  @override
  String get ayarlariAc => 'Ayarları Aç';

  @override
  String get kombinOner => 'Kombin Öner';

  @override
  String get kombininHazirOlsun => 'Kombinin hazır olsun';

  @override
  String get buBaglamaUygun => 'Bu bağlama uygun kombin bulunamadı.';

  @override
  String get degerlendirmeIcinEn =>
      'Değerlendirme için en az 2 parça seçili olmalı.';

  @override
  String get kombinStudyosu => 'Kombin Stüdyosu';

  @override
  String get degerlendir => 'Değerlendir';

  @override
  String get buKategorideParca => 'Bu kategoride parça yok';

  @override
  String get cikisYap => 'Çıkış yap';

  @override
  String get hesabindanCikmakIstedigine =>
      'Hesabından çıkmak istediğine emin misin?';

  @override
  String get vazgec => 'Vazgeç';

  @override
  String get hesabimiSil => 'Hesabımı Sil';

  @override
  String get hesabinVeTum =>
      'Hesabın ve tüm kıyafetlerin kalıcı olarak silinecek. ';

  @override
  String get guvenlikIcinCikis =>
      'Güvenlik için çıkış yapıp tekrar giriş yaptıktan sonra hesabını silebilirsin.';

  @override
  String get gardirobun => 'Gardırobun';

  @override
  String get renkPaletin => 'Renk Paletin';

  @override
  String get dilLanguage => 'Dil / Language';

  @override
  String get turkce => 'Türkçe';

  @override
  String get cikisYap2 => 'Çıkış Yap';

  @override
  String get luviaV => 'Luvia v1.0';

  @override
  String get todayShort => 'Bugün';

  @override
  String get addSingleTitle => 'Parça Ekle';

  @override
  String get addSingleSubtitle => 'Tek kıyafetin fotoğrafı';

  @override
  String get captureOutfitTitle => 'Kombin Yakala';

  @override
  String get captureOutfitSubtitle => 'Boydan fotoğraf';

  @override
  String get gallery => 'Galeri';

  @override
  String get cameraTutorial =>
      'Buradan kıyafet ekle 👕\nAynı anda birden fazla fotoğraf: boydan 3, tek parça 5 📸';

  @override
  String get capture => 'Çek';

  @override
  String get delete => 'Sil';

  @override
  String tooManyPhotosContent(int count) {
    return 'En fazla $count fotoğraf seçebilirsin. Lütfen tekrar seç.';
  }

  @override
  String get useWeather => 'Hava durumunu kullan';

  @override
  String get season => 'Mevsim';

  @override
  String get environment => 'Ortam';

  @override
  String get colorPreference => 'Renk tercihi';

  @override
  String get stylePreference => 'Stil tercihi';

  @override
  String get selectSeasonEnv =>
      'Mevsim ve ortamı seç,\ngardırobuna göre sana özel kombin oluşturalım.';

  @override
  String get hintColorHarmony => 'Renk uyumu';

  @override
  String get hintSeasonAppropriate => 'Mevsime uygun';

  @override
  String get hintPersonalized => 'Sana özel';

  @override
  String get seasonSummer => 'Yaz';

  @override
  String get seasonWinter => 'Kış';

  @override
  String get seasonMid => 'Ara Mevsim';

  @override
  String get seasonAll => 'Tüm Sezon';

  @override
  String get formalityHome => 'Ev';

  @override
  String get formalityCasual => 'Günlük';

  @override
  String get formalitySmart => 'Smart';

  @override
  String get formalityBusiness => 'İş';

  @override
  String get formalityFormal => 'Resmi';

  @override
  String get styleSporty => 'Sportif';

  @override
  String get styleStreet => 'Sokak';

  @override
  String get styleClassic => 'Klasik';

  @override
  String get styleMinimal => 'Minimal';

  @override
  String get styleBohemian => 'Bohem';

  @override
  String get styleSurprise => 'Sürpriz 🎲';

  @override
  String get colorBlack => 'Siyah';

  @override
  String get colorWhite => 'Beyaz';

  @override
  String get colorGray => 'Gri';

  @override
  String get colorRed => 'Kırmızı';

  @override
  String get colorBurgundy => 'Bordo';

  @override
  String get colorOrange => 'Turuncu';

  @override
  String get colorYellow => 'Sarı';

  @override
  String get colorGreen => 'Yeşil';

  @override
  String get colorBlue => 'Mavi';

  @override
  String get colorNavy => 'Lacivert';

  @override
  String get colorPurple => 'Mor';

  @override
  String get colorPink => 'Pembe';

  @override
  String get colorBrown => 'Kahve';

  @override
  String get colorBeige => 'Bej';

  @override
  String get colorCream => 'Krem';

  @override
  String get colorKhaki => 'Haki';

  @override
  String get colorTurquoise => 'Turkuaz';

  @override
  String get createOutfit => 'Kombin Oluştur';

  @override
  String get suggestAnother => 'Başka Öner';

  @override
  String get ok => 'Tamam';

  @override
  String noItemInCategory(String slot) {
    return '$slot kategorisinde parça yok.';
  }

  @override
  String get filterAccessory => 'Aksesuar';

  @override
  String get filterJewelry => 'Takı';

  @override
  String get adviceNoLower =>
      'Alt giyimin yok. Pantolon ya da etek ekleyince kombin çeşitliliğin artar.';

  @override
  String get adviceMoreUpper =>
      'Daha fazla üst giyim eklersen kombin seçeneklerin katlanır.';

  @override
  String get filterDress => 'Elbise';

  @override
  String get adviceNoShoes =>
      'Ayakkabın yok. Bir çift ekle, kombinlerin tamamlansın.';

  @override
  String get adviceNoUpper =>
      'Hiç üst giyimin yok. Birkaç tişört ya da gömlek ekle, kombinler oluşsun.';

  @override
  String get adviceBalanced =>
      'Gardırobun dengeli görünüyor! Farklı renkler ekleyerek çeşitliliği artırabilirsin.';

  @override
  String get adviceEmpty =>
      'Gardırobun boş. Birkaç kıyafet ekle, kombin önerileri başlasın!';

  @override
  String get navHome => 'Ana Sayfa';

  @override
  String get navWardrobe => 'Gardırop';

  @override
  String get navOutfits => 'Kombin';

  @override
  String get navStudio => 'Oluştur';

  @override
  String get navProfile => 'Profil';

  @override
  String get welcomeBack => 'Tekrar hoş geldin';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get forgotPassword => 'Şifremi unuttum';

  @override
  String get login => 'Giriş Yap';

  @override
  String get register => 'Kayıt Ol';

  @override
  String get noAccountRegister => 'Hesabın yok mu? Kayıt ol';

  @override
  String get haveAccountLogin => 'Zaten hesabın var mı? Giriş yap';

  @override
  String get secureAccountDesc =>
      'Hesabını güvene al, kıyafetlerin kaybolmasın';

  @override
  String get createAccount => 'Hesap oluştur';

  @override
  String get enterEmailFirst =>
      'Önce e-posta adresini gir, sonra \"Şifremi unuttum\"a bas.';

  @override
  String get emailPasswordRequired => 'E-posta ve şifre gerekli';

  @override
  String get addClothesFirst => 'Önce bir kıyafet ekleyelim mi? 👕';

  @override
  String memberItemCount(int count) {
    return '$count parça · Luvia üyesi';
  }

  @override
  String get filterAll => 'Tümü';

  @override
  String noItemInFilter(String filter) {
    return '\"$filter\" kategorisinde parça yok';
  }

  @override
  String get slotMorning => 'Sabah-öğle';

  @override
  String get slotAfternoon => 'Öğleden sonra';

  @override
  String get slotEvening => 'Akşam üstü';

  @override
  String get slotNight => 'Akşam';

  @override
  String get weatherClear => 'açık';

  @override
  String get weatherCloudy => 'bulutlu';

  @override
  String get weatherRainy => 'yağmurlu';

  @override
  String get weatherSnowy => 'karlı';

  @override
  String get weatherStorm => 'fırtınalı';

  @override
  String get tipUmbrellaJacket => 'Şemsiye ve ceket alabilirsin.';

  @override
  String get tipUmbrella => 'Şemsiye alabilirsin.';

  @override
  String get tipHeavy => 'Kalın giyin.';

  @override
  String get tipLightJacket => 'Hafif bir ceket iyi olur.';

  @override
  String get tipLight => 'Hafif giyin.';

  @override
  String get tipNice => 'Güzel bir hava.';
}
