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
  String guestItemsWarn(Object count) {
    return '$count kıyafetin var. Kaydolmazsan kaybolabilir — hesabını güvene al.';
  }

  @override
  String guestItemsCollected(Object count) {
    return '$count kıyafet biriktirdin! Bunları kaybetmemek için hemen kaydol.';
  }

  @override
  String get signUpOrLogin => 'Kaydol veya Giriş Yap';

  @override
  String get whatToWear => 'Bugün ne giysek?';

  @override
  String get recentlyAdded => 'Son Eklenenler';

  @override
  String todayWithCity(Object city) {
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
}
