// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingDay => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get guestMode =>
      'You\'re in guest mode. Sign up or log in to save your clothes permanently.';

  @override
  String guestItemsWarn(Object count) {
    return 'You have $count items. They may be lost if you don\'t sign up — secure your account.';
  }

  @override
  String guestItemsCollected(Object count) {
    return 'You\'ve collected $count items! Sign up now so you don\'t lose them.';
  }

  @override
  String get signUpOrLogin => 'Sign Up or Log In';

  @override
  String get whatToWear => 'What should we wear today?';

  @override
  String get recentlyAdded => 'Recently Added';

  @override
  String todayWithCity(Object city) {
    return 'Today · $city';
  }

  @override
  String get today => 'Today';

  @override
  String get weatherBasedSuggestion => 'Weather-based suggestion';

  @override
  String get grantPermission => 'Grant Permission';

  @override
  String get locationServiceOff =>
      'Your location service is off. Turn it on for weather-based outfit suggestions.';

  @override
  String get locationPermissionAsk =>
      'Grant location permission for outfit suggestions based on your day.';

  @override
  String get todayOutfit => 'Today\'s Outfit';

  @override
  String get todayOutfitDesc =>
      'We\'ve prepared a special outfit from your wardrobe for today';

  @override
  String get seeTodayOutfit => 'See Today\'s Outfit';

  @override
  String get addMoreClothes => 'Add more clothes to create an outfit';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get todayOutfitReady => 'Today\'s outfit is ready';

  @override
  String get boughtSomethingNew => 'Bought something new?';

  @override
  String get addToWardrobe => 'Add it to your wardrobe, see it in outfits';

  @override
  String get total => 'Total';

  @override
  String get upper => 'Upper';

  @override
  String get lower => 'Lower';

  @override
  String get shoes => 'Shoes';

  @override
  String get noClothesYet => 'You haven\'t added any clothes yet';

  @override
  String get kaydolVeyaGiris => 'Sign Up or Log In';

  @override
  String get bugunNeGiysek => 'What should we wear today?';

  @override
  String get sonEklenenler => 'Recently Added';

  @override
  String get havaDurumunaGore => 'Weather-based suggestion';

  @override
  String get izinVer => 'Grant Permission';

  @override
  String get bugununKombini => 'Today\'s Outfit';

  @override
  String get bugunIcinGardirobuna =>
      'We\'ve prepared a special outfit from your wardrobe for today';

  @override
  String get bugununKombininiGor => 'See Today\'s Outfit';

  @override
  String get kombinOlusturmakIcin => 'Add more clothes to create an outfit';

  @override
  String get bugununKombiniHazir => 'Today\'s outfit is ready';

  @override
  String get yeniBirSey => 'Bought something new?';

  @override
  String get dolabinaEkleKombinlerde =>
      'Add it to your wardrobe, see it in outfits';

  @override
  String get henuzKiyafetEklemedin => 'You haven\'t added any clothes yet';

  @override
  String get birKiyafeteCift =>
      'Double-tap an item to include/exclude it from outfit suggestions ✨';

  @override
  String get silmekIcinKiyafete => 'Long-press an item to delete it 🗑️';

  @override
  String get cokFazlaFotograf => 'Too many photos';

  @override
  String get duzenle => 'Edit';

  @override
  String get stilKumasKalip => 'Style, fabric, fit, pattern... set for you.';

  @override
  String get guncellendi => 'Updated';

  @override
  String get gardirobum => 'My Wardrobe';

  @override
  String get gardirobunBos => 'Your wardrobe is empty';

  @override
  String get ilkKiyafetiniEkle =>
      'Add your first item and Luvia will start suggesting outfits for you. Full-body or single item, it doesn\'t matter.';

  @override
  String get fotografEkle => 'Add Photo';

  @override
  String get musaitDegil => 'Unavailable';

  @override
  String get buBaglamIcin => 'We\'ve shown enough suggestions for this context';

  @override
  String get konumIzni => 'Location Permission';

  @override
  String get ayarlariAc => 'Open Settings';

  @override
  String get kombinOner => 'Suggest an Outfit';

  @override
  String get kombininHazirOlsun => 'Get your outfit ready';

  @override
  String get buBaglamaUygun => 'No suitable outfit found for this context.';

  @override
  String get degerlendirmeIcinEn =>
      'At least 2 items must be selected for evaluation.';

  @override
  String get kombinStudyosu => 'Outfit Studio';

  @override
  String get degerlendir => 'Evaluate';

  @override
  String get buKategorideParca => 'No items in this category';

  @override
  String get cikisYap => 'Log out';

  @override
  String get hesabindanCikmakIstedigine => 'Are you sure you want to log out?';

  @override
  String get vazgec => 'Cancel';

  @override
  String get hesabimiSil => 'Delete My Account';

  @override
  String get hesabinVeTum =>
      'Your account and all your clothes will be permanently deleted.';

  @override
  String get guvenlikIcinCikis =>
      'For security reasons, you can delete your account after logging out and logging in again.';

  @override
  String get gardirobun => 'Your Wardrobe';

  @override
  String get renkPaletin => 'Your Color Palette';

  @override
  String get dilLanguage => 'Language / Dil';

  @override
  String get turkce => 'Turkish';

  @override
  String get cikisYap2 => 'Log Out';

  @override
  String get luviaV => 'Luvia v1.0';
}
