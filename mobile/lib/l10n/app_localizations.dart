import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingDay.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingDay;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @guestMode.
  ///
  /// In en, this message translates to:
  /// **'You\'re in guest mode. Sign up or log in to save your clothes permanently.'**
  String get guestMode;

  /// No description provided for @guestItemsWarn.
  ///
  /// In en, this message translates to:
  /// **'You have {count} items. They may be lost if you don\'t sign up — secure your account.'**
  String guestItemsWarn(Object count);

  /// No description provided for @guestItemsCollected.
  ///
  /// In en, this message translates to:
  /// **'You\'ve collected {count} items! Sign up now so you don\'t lose them.'**
  String guestItemsCollected(Object count);

  /// No description provided for @signUpOrLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign Up or Log In'**
  String get signUpOrLogin;

  /// No description provided for @whatToWear.
  ///
  /// In en, this message translates to:
  /// **'What should we wear today?'**
  String get whatToWear;

  /// No description provided for @recentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently Added'**
  String get recentlyAdded;

  /// No description provided for @todayWithCity.
  ///
  /// In en, this message translates to:
  /// **'Today · {city}'**
  String todayWithCity(Object city);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @weatherBasedSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Weather-based suggestion'**
  String get weatherBasedSuggestion;

  /// No description provided for @grantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grantPermission;

  /// No description provided for @locationServiceOff.
  ///
  /// In en, this message translates to:
  /// **'Your location service is off. Turn it on for weather-based outfit suggestions.'**
  String get locationServiceOff;

  /// No description provided for @locationPermissionAsk.
  ///
  /// In en, this message translates to:
  /// **'Grant location permission for outfit suggestions based on your day.'**
  String get locationPermissionAsk;

  /// No description provided for @todayOutfit.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Outfit'**
  String get todayOutfit;

  /// No description provided for @todayOutfitDesc.
  ///
  /// In en, this message translates to:
  /// **'We\'ve prepared a special outfit from your wardrobe for today'**
  String get todayOutfitDesc;

  /// No description provided for @seeTodayOutfit.
  ///
  /// In en, this message translates to:
  /// **'See Today\'s Outfit'**
  String get seeTodayOutfit;

  /// No description provided for @addMoreClothes.
  ///
  /// In en, this message translates to:
  /// **'Add more clothes to create an outfit'**
  String get addMoreClothes;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @todayOutfitReady.
  ///
  /// In en, this message translates to:
  /// **'Today\'s outfit is ready'**
  String get todayOutfitReady;

  /// No description provided for @boughtSomethingNew.
  ///
  /// In en, this message translates to:
  /// **'Bought something new?'**
  String get boughtSomethingNew;

  /// No description provided for @addToWardrobe.
  ///
  /// In en, this message translates to:
  /// **'Add it to your wardrobe, see it in outfits'**
  String get addToWardrobe;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @upper.
  ///
  /// In en, this message translates to:
  /// **'Upper'**
  String get upper;

  /// No description provided for @lower.
  ///
  /// In en, this message translates to:
  /// **'Lower'**
  String get lower;

  /// No description provided for @shoes.
  ///
  /// In en, this message translates to:
  /// **'Shoes'**
  String get shoes;

  /// No description provided for @noClothesYet.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added any clothes yet'**
  String get noClothesYet;

  /// No description provided for @kaydolVeyaGiris.
  ///
  /// In en, this message translates to:
  /// **'Sign Up or Log In'**
  String get kaydolVeyaGiris;

  /// No description provided for @bugunNeGiysek.
  ///
  /// In en, this message translates to:
  /// **'What should we wear today?'**
  String get bugunNeGiysek;

  /// No description provided for @sonEklenenler.
  ///
  /// In en, this message translates to:
  /// **'Recently Added'**
  String get sonEklenenler;

  /// No description provided for @havaDurumunaGore.
  ///
  /// In en, this message translates to:
  /// **'Weather-based suggestion'**
  String get havaDurumunaGore;

  /// No description provided for @izinVer.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get izinVer;

  /// No description provided for @bugununKombini.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Outfit'**
  String get bugununKombini;

  /// No description provided for @bugunIcinGardirobuna.
  ///
  /// In en, this message translates to:
  /// **'We\'ve prepared a special outfit from your wardrobe for today'**
  String get bugunIcinGardirobuna;

  /// No description provided for @bugununKombininiGor.
  ///
  /// In en, this message translates to:
  /// **'See Today\'s Outfit'**
  String get bugununKombininiGor;

  /// No description provided for @kombinOlusturmakIcin.
  ///
  /// In en, this message translates to:
  /// **'Add more clothes to create an outfit'**
  String get kombinOlusturmakIcin;

  /// No description provided for @bugununKombiniHazir.
  ///
  /// In en, this message translates to:
  /// **'Today\'s outfit is ready'**
  String get bugununKombiniHazir;

  /// No description provided for @yeniBirSey.
  ///
  /// In en, this message translates to:
  /// **'Bought something new?'**
  String get yeniBirSey;

  /// No description provided for @dolabinaEkleKombinlerde.
  ///
  /// In en, this message translates to:
  /// **'Add it to your wardrobe, see it in outfits'**
  String get dolabinaEkleKombinlerde;

  /// No description provided for @henuzKiyafetEklemedin.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added any clothes yet'**
  String get henuzKiyafetEklemedin;

  /// No description provided for @birKiyafeteCift.
  ///
  /// In en, this message translates to:
  /// **'Double-tap an item to include/exclude it from outfit suggestions ✨'**
  String get birKiyafeteCift;

  /// No description provided for @silmekIcinKiyafete.
  ///
  /// In en, this message translates to:
  /// **'Long-press an item to delete it 🗑️'**
  String get silmekIcinKiyafete;

  /// No description provided for @cokFazlaFotograf.
  ///
  /// In en, this message translates to:
  /// **'Too many photos'**
  String get cokFazlaFotograf;

  /// No description provided for @duzenle.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get duzenle;

  /// No description provided for @stilKumasKalip.
  ///
  /// In en, this message translates to:
  /// **'Style, fabric, fit, pattern... set for you.'**
  String get stilKumasKalip;

  /// No description provided for @guncellendi.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get guncellendi;

  /// No description provided for @gardirobum.
  ///
  /// In en, this message translates to:
  /// **'My Wardrobe'**
  String get gardirobum;

  /// No description provided for @gardirobunBos.
  ///
  /// In en, this message translates to:
  /// **'Your wardrobe is empty'**
  String get gardirobunBos;

  /// No description provided for @ilkKiyafetiniEkle.
  ///
  /// In en, this message translates to:
  /// **'Add your first item and Luvia will start suggesting outfits for you. Full-body or single item, it doesn\'t matter.'**
  String get ilkKiyafetiniEkle;

  /// No description provided for @fotografEkle.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get fotografEkle;

  /// No description provided for @musaitDegil.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get musaitDegil;

  /// No description provided for @buBaglamIcin.
  ///
  /// In en, this message translates to:
  /// **'We\'ve shown enough suggestions for this context'**
  String get buBaglamIcin;

  /// No description provided for @konumIzni.
  ///
  /// In en, this message translates to:
  /// **'Location Permission'**
  String get konumIzni;

  /// No description provided for @ayarlariAc.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get ayarlariAc;

  /// No description provided for @kombinOner.
  ///
  /// In en, this message translates to:
  /// **'Suggest an Outfit'**
  String get kombinOner;

  /// No description provided for @kombininHazirOlsun.
  ///
  /// In en, this message translates to:
  /// **'Get your outfit ready'**
  String get kombininHazirOlsun;

  /// No description provided for @buBaglamaUygun.
  ///
  /// In en, this message translates to:
  /// **'No suitable outfit found for this context.'**
  String get buBaglamaUygun;

  /// No description provided for @degerlendirmeIcinEn.
  ///
  /// In en, this message translates to:
  /// **'At least 2 items must be selected for evaluation.'**
  String get degerlendirmeIcinEn;

  /// No description provided for @kombinStudyosu.
  ///
  /// In en, this message translates to:
  /// **'Outfit Studio'**
  String get kombinStudyosu;

  /// No description provided for @degerlendir.
  ///
  /// In en, this message translates to:
  /// **'Evaluate'**
  String get degerlendir;

  /// No description provided for @buKategorideParca.
  ///
  /// In en, this message translates to:
  /// **'No items in this category'**
  String get buKategorideParca;

  /// No description provided for @cikisYap.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get cikisYap;

  /// No description provided for @hesabindanCikmakIstedigine.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get hesabindanCikmakIstedigine;

  /// No description provided for @vazgec.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get vazgec;

  /// No description provided for @hesabimiSil.
  ///
  /// In en, this message translates to:
  /// **'Delete My Account'**
  String get hesabimiSil;

  /// No description provided for @hesabinVeTum.
  ///
  /// In en, this message translates to:
  /// **'Your account and all your clothes will be permanently deleted.'**
  String get hesabinVeTum;

  /// No description provided for @guvenlikIcinCikis.
  ///
  /// In en, this message translates to:
  /// **'For security reasons, you can delete your account after logging out and logging in again.'**
  String get guvenlikIcinCikis;

  /// No description provided for @gardirobun.
  ///
  /// In en, this message translates to:
  /// **'Your Wardrobe'**
  String get gardirobun;

  /// No description provided for @renkPaletin.
  ///
  /// In en, this message translates to:
  /// **'Your Color Palette'**
  String get renkPaletin;

  /// No description provided for @dilLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language / Dil'**
  String get dilLanguage;

  /// No description provided for @turkce.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get turkce;

  /// No description provided for @cikisYap2.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get cikisYap2;

  /// No description provided for @luviaV.
  ///
  /// In en, this message translates to:
  /// **'Luvia v1.0'**
  String get luviaV;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
