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
  /// **'You\'re in guest mode. Sign up or log in to keep your clothes permanently.'**
  String get guestMode;

  /// No description provided for @guestItemsWarn.
  ///
  /// In en, this message translates to:
  /// **'You have {count} items. They may be lost if you don\'t sign up — secure your account.'**
  String guestItemsWarn(int count);

  /// No description provided for @guestItemsCollected.
  ///
  /// In en, this message translates to:
  /// **'You\'ve collected {count} items! Sign up now so you don\'t lose them.'**
  String guestItemsCollected(int count);

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
  String todayWithCity(String city);

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

  /// No description provided for @todayShort.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayShort;

  /// No description provided for @addSingleTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addSingleTitle;

  /// No description provided for @addSingleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Photo of a single item'**
  String get addSingleSubtitle;

  /// No description provided for @captureOutfitTitle.
  ///
  /// In en, this message translates to:
  /// **'Capture Outfit'**
  String get captureOutfitTitle;

  /// No description provided for @captureOutfitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Full-body photo'**
  String get captureOutfitSubtitle;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @cameraTutorial.
  ///
  /// In en, this message translates to:
  /// **'Add clothes here 👕\nMultiple photos at once: 3 full-body, 5 single items 📸'**
  String get cameraTutorial;

  /// No description provided for @capture.
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get capture;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @tooManyPhotosContent.
  ///
  /// In en, this message translates to:
  /// **'You can select up to {count} photos. Please select again.'**
  String tooManyPhotosContent(int count);

  /// No description provided for @useWeather.
  ///
  /// In en, this message translates to:
  /// **'Use weather'**
  String get useWeather;

  /// No description provided for @season.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get season;

  /// No description provided for @environment.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get environment;

  /// No description provided for @colorPreference.
  ///
  /// In en, this message translates to:
  /// **'Color preference'**
  String get colorPreference;

  /// No description provided for @stylePreference.
  ///
  /// In en, this message translates to:
  /// **'Style preference'**
  String get stylePreference;

  /// No description provided for @selectSeasonEnv.
  ///
  /// In en, this message translates to:
  /// **'Select season and environment,\nwe\'ll create a custom outfit from your wardrobe.'**
  String get selectSeasonEnv;

  /// No description provided for @hintColorHarmony.
  ///
  /// In en, this message translates to:
  /// **'Color harmony'**
  String get hintColorHarmony;

  /// No description provided for @hintSeasonAppropriate.
  ///
  /// In en, this message translates to:
  /// **'Season-appropriate'**
  String get hintSeasonAppropriate;

  /// No description provided for @hintPersonalized.
  ///
  /// In en, this message translates to:
  /// **'Personalized'**
  String get hintPersonalized;

  /// No description provided for @seasonSummer.
  ///
  /// In en, this message translates to:
  /// **'Summer'**
  String get seasonSummer;

  /// No description provided for @seasonWinter.
  ///
  /// In en, this message translates to:
  /// **'Winter'**
  String get seasonWinter;

  /// No description provided for @seasonMid.
  ///
  /// In en, this message translates to:
  /// **'Mid-Season'**
  String get seasonMid;

  /// No description provided for @seasonAll.
  ///
  /// In en, this message translates to:
  /// **'All Seasons'**
  String get seasonAll;

  /// No description provided for @formalityHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get formalityHome;

  /// No description provided for @formalityCasual.
  ///
  /// In en, this message translates to:
  /// **'Casual'**
  String get formalityCasual;

  /// No description provided for @formalitySmart.
  ///
  /// In en, this message translates to:
  /// **'Smart'**
  String get formalitySmart;

  /// No description provided for @formalityBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get formalityBusiness;

  /// No description provided for @formalityFormal.
  ///
  /// In en, this message translates to:
  /// **'Formal'**
  String get formalityFormal;

  /// No description provided for @styleSporty.
  ///
  /// In en, this message translates to:
  /// **'Sporty'**
  String get styleSporty;

  /// No description provided for @styleStreet.
  ///
  /// In en, this message translates to:
  /// **'Streetwear'**
  String get styleStreet;

  /// No description provided for @styleClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get styleClassic;

  /// No description provided for @styleMinimal.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get styleMinimal;

  /// No description provided for @styleBohemian.
  ///
  /// In en, this message translates to:
  /// **'Bohemian'**
  String get styleBohemian;

  /// No description provided for @styleSurprise.
  ///
  /// In en, this message translates to:
  /// **'Surprise 🎲'**
  String get styleSurprise;

  /// No description provided for @colorBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get colorBlack;

  /// No description provided for @colorWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get colorWhite;

  /// No description provided for @colorGray.
  ///
  /// In en, this message translates to:
  /// **'Gray'**
  String get colorGray;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// No description provided for @colorBurgundy.
  ///
  /// In en, this message translates to:
  /// **'Burgundy'**
  String get colorBurgundy;

  /// No description provided for @colorOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get colorOrange;

  /// No description provided for @colorYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get colorYellow;

  /// No description provided for @colorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// No description provided for @colorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// No description provided for @colorNavy.
  ///
  /// In en, this message translates to:
  /// **'Navy'**
  String get colorNavy;

  /// No description provided for @colorPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get colorPurple;

  /// No description provided for @colorPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get colorPink;

  /// No description provided for @colorBrown.
  ///
  /// In en, this message translates to:
  /// **'Brown'**
  String get colorBrown;

  /// No description provided for @colorBeige.
  ///
  /// In en, this message translates to:
  /// **'Beige'**
  String get colorBeige;

  /// No description provided for @colorCream.
  ///
  /// In en, this message translates to:
  /// **'Cream'**
  String get colorCream;

  /// No description provided for @colorKhaki.
  ///
  /// In en, this message translates to:
  /// **'Khaki'**
  String get colorKhaki;

  /// No description provided for @colorTurquoise.
  ///
  /// In en, this message translates to:
  /// **'Turquoise'**
  String get colorTurquoise;

  /// No description provided for @createOutfit.
  ///
  /// In en, this message translates to:
  /// **'Create Outfit'**
  String get createOutfit;

  /// No description provided for @suggestAnother.
  ///
  /// In en, this message translates to:
  /// **'Suggest Another'**
  String get suggestAnother;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @noItemInCategory.
  ///
  /// In en, this message translates to:
  /// **'No items in {slot} category.'**
  String noItemInCategory(String slot);

  /// No description provided for @filterAccessory.
  ///
  /// In en, this message translates to:
  /// **'Accessory'**
  String get filterAccessory;

  /// No description provided for @filterJewelry.
  ///
  /// In en, this message translates to:
  /// **'Jewelry'**
  String get filterJewelry;

  /// No description provided for @adviceNoLower.
  ///
  /// In en, this message translates to:
  /// **'You have no bottoms. Adding pants or a skirt will increase your outfit variety.'**
  String get adviceNoLower;

  /// No description provided for @adviceMoreUpper.
  ///
  /// In en, this message translates to:
  /// **'Adding more tops will multiply your outfit options.'**
  String get adviceMoreUpper;

  /// No description provided for @filterDress.
  ///
  /// In en, this message translates to:
  /// **'Dress'**
  String get filterDress;

  /// No description provided for @adviceNoShoes.
  ///
  /// In en, this message translates to:
  /// **'You have no shoes. Add a pair to complete your outfits.'**
  String get adviceNoShoes;

  /// No description provided for @adviceNoUpper.
  ///
  /// In en, this message translates to:
  /// **'You have no tops. Add a few t-shirts or shirts to create outfits.'**
  String get adviceNoUpper;

  /// No description provided for @adviceBalanced.
  ///
  /// In en, this message translates to:
  /// **'Your wardrobe looks balanced! Add different colors to increase variety.'**
  String get adviceBalanced;

  /// No description provided for @adviceEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your wardrobe is empty. Add a few items to start getting outfit suggestions!'**
  String get adviceEmpty;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navWardrobe.
  ///
  /// In en, this message translates to:
  /// **'Wardrobe'**
  String get navWardrobe;

  /// No description provided for @navOutfits.
  ///
  /// In en, this message translates to:
  /// **'Outfits'**
  String get navOutfits;

  /// No description provided for @navStudio.
  ///
  /// In en, this message translates to:
  /// **'Studio'**
  String get navStudio;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgotPassword;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get register;

  /// No description provided for @noAccountRegister.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get noAccountRegister;

  /// No description provided for @haveAccountLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get haveAccountLogin;

  /// No description provided for @secureAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'Secure your account so you don\'t lose your clothes'**
  String get secureAccountDesc;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @enterEmailFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter your email first, then tap \"Forgot password\".'**
  String get enterEmailFirst;

  /// No description provided for @emailPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Email and password are required'**
  String get emailPasswordRequired;

  /// No description provided for @addClothesFirst.
  ///
  /// In en, this message translates to:
  /// **'Shall we add an item first? 👕'**
  String get addClothesFirst;

  /// No description provided for @memberItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items · Luvia member'**
  String memberItemCount(int count);

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @noItemInFilter.
  ///
  /// In en, this message translates to:
  /// **'No items in \"{filter}\" category'**
  String noItemInFilter(String filter);
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
