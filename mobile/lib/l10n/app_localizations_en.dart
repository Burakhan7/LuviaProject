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
      'You\'re in guest mode. Sign up or log in to keep your clothes permanently.';

  @override
  String guestItemsWarn(int count) {
    return 'You have $count items. They may be lost if you don\'t sign up — secure your account.';
  }

  @override
  String guestItemsCollected(int count) {
    return 'You\'ve collected $count items! Sign up now so you don\'t lose them.';
  }

  @override
  String get signUpOrLogin => 'Sign Up or Log In';

  @override
  String get whatToWear => 'What should we wear today?';

  @override
  String get recentlyAdded => 'Recently Added';

  @override
  String todayWithCity(String city) {
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

  @override
  String get todayShort => 'Today';

  @override
  String get addSingleTitle => 'Add Item';

  @override
  String get addSingleSubtitle => 'Photo of a single item';

  @override
  String get captureOutfitTitle => 'Capture Outfit';

  @override
  String get captureOutfitSubtitle => 'Full-body photo';

  @override
  String get gallery => 'Gallery';

  @override
  String get cameraTutorial =>
      'Add clothes here 👕\nMultiple photos at once: 3 full-body, 5 single items 📸';

  @override
  String get capture => 'Capture';

  @override
  String get delete => 'Delete';

  @override
  String tooManyPhotosContent(int count) {
    return 'You can select up to $count photos. Please select again.';
  }

  @override
  String get useWeather => 'Use weather';

  @override
  String get season => 'Season';

  @override
  String get environment => 'Environment';

  @override
  String get colorPreference => 'Color preference';

  @override
  String get stylePreference => 'Style preference';

  @override
  String get selectSeasonEnv =>
      'Select season and environment,\nwe\'ll create a custom outfit from your wardrobe.';

  @override
  String get hintColorHarmony => 'Color harmony';

  @override
  String get hintSeasonAppropriate => 'Season-appropriate';

  @override
  String get hintPersonalized => 'Personalized';

  @override
  String get seasonSummer => 'Summer';

  @override
  String get seasonWinter => 'Winter';

  @override
  String get seasonMid => 'Mid-Season';

  @override
  String get seasonAll => 'All Seasons';

  @override
  String get formalityHome => 'Home';

  @override
  String get formalityCasual => 'Casual';

  @override
  String get formalitySmart => 'Smart';

  @override
  String get formalityBusiness => 'Business';

  @override
  String get formalityFormal => 'Formal';

  @override
  String get styleSporty => 'Sporty';

  @override
  String get styleStreet => 'Streetwear';

  @override
  String get styleClassic => 'Classic';

  @override
  String get styleMinimal => 'Minimal';

  @override
  String get styleBohemian => 'Bohemian';

  @override
  String get styleSurprise => 'Surprise 🎲';

  @override
  String get colorBlack => 'Black';

  @override
  String get colorWhite => 'White';

  @override
  String get colorGray => 'Gray';

  @override
  String get colorRed => 'Red';

  @override
  String get colorBurgundy => 'Burgundy';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorYellow => 'Yellow';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorNavy => 'Navy';

  @override
  String get colorPurple => 'Purple';

  @override
  String get colorPink => 'Pink';

  @override
  String get colorBrown => 'Brown';

  @override
  String get colorBeige => 'Beige';

  @override
  String get colorCream => 'Cream';

  @override
  String get colorKhaki => 'Khaki';

  @override
  String get colorTurquoise => 'Turquoise';

  @override
  String get createOutfit => 'Create Outfit';

  @override
  String get suggestAnother => 'Suggest Another';

  @override
  String get ok => 'OK';

  @override
  String noItemInCategory(String slot) {
    return 'No items in $slot category.';
  }

  @override
  String get filterAccessory => 'Accessory';

  @override
  String get filterJewelry => 'Jewelry';

  @override
  String get adviceNoLower =>
      'You have no bottoms. Adding pants or a skirt will increase your outfit variety.';

  @override
  String get adviceMoreUpper =>
      'Adding more tops will multiply your outfit options.';

  @override
  String get filterDress => 'Dress';

  @override
  String get adviceNoShoes =>
      'You have no shoes. Add a pair to complete your outfits.';

  @override
  String get adviceNoUpper =>
      'You have no tops. Add a few t-shirts or shirts to create outfits.';

  @override
  String get adviceBalanced =>
      'Your wardrobe looks balanced! Add different colors to increase variety.';

  @override
  String get adviceEmpty =>
      'Your wardrobe is empty. Add a few items to start getting outfit suggestions!';

  @override
  String get navHome => 'Home';

  @override
  String get navWardrobe => 'Wardrobe';

  @override
  String get navOutfits => 'Outfits';

  @override
  String get navStudio => 'Studio';

  @override
  String get navProfile => 'Profile';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password';

  @override
  String get login => 'Log In';

  @override
  String get register => 'Sign Up';

  @override
  String get noAccountRegister => 'Don\'t have an account? Sign up';

  @override
  String get haveAccountLogin => 'Already have an account? Log in';

  @override
  String get secureAccountDesc =>
      'Secure your account so you don\'t lose your clothes';

  @override
  String get createAccount => 'Create account';

  @override
  String get enterEmailFirst =>
      'Enter your email first, then tap \"Forgot password\".';

  @override
  String get emailPasswordRequired => 'Email and password are required';

  @override
  String get addClothesFirst => 'Shall we add an item first? 👕';

  @override
  String memberItemCount(int count) {
    return '$count items · Luvia member';
  }

  @override
  String get filterAll => 'All';

  @override
  String noItemInFilter(String filter) {
    return 'No items in \"$filter\" category';
  }

  @override
  String get slotMorning => 'Morning';

  @override
  String get slotAfternoon => 'Afternoon';

  @override
  String get slotEvening => 'Late afternoon';

  @override
  String get slotNight => 'Evening';

  @override
  String get weatherClear => 'clear';

  @override
  String get weatherCloudy => 'cloudy';

  @override
  String get weatherRainy => 'rainy';

  @override
  String get weatherSnowy => 'snowy';

  @override
  String get weatherStorm => 'stormy';

  @override
  String get tipUmbrellaJacket => 'You may want an umbrella and a jacket.';

  @override
  String get tipUmbrella => 'You may want an umbrella.';

  @override
  String get tipHeavy => 'Dress warmly.';

  @override
  String get tipLightJacket => 'A light jacket would be good.';

  @override
  String get tipLight => 'Dress light.';

  @override
  String get tipNice => 'Nice weather.';
}
