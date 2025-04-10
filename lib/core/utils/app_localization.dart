// Uygulama çeviri yönetimi için sınıf

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';
import '../constants/app_constants.dart';

class AppLocalization {
  // Dil çevirilerini içeren harita
  final Map<String, dynamic> _localizedValues;

  // Mevcut dil kodu
  final String locale;

  AppLocalization(this.locale, this._localizedValues);

  // Belirli bir key için çeviri değerini döndürür
  String translate(String key) {
    if (_localizedValues.containsKey(key)) {
      return _localizedValues[key].toString();
    }
    return key; // Eğer çeviri yoksa, key'in kendisini döndür
  }

  // JSON dosyalarından çevirileri yüklemek için factory constructor
  static Future<AppLocalization> load(Locale locale) async {
    // Desteklenen diller içinde kontrol et
    String currentLocale =
        AppConstants.supportedLanguages.contains(locale.languageCode)
            ? locale.languageCode
            : AppConstants.defaultLocale;

    // Çeviri dosyasını yükle
    String jsonString = await rootBundle.loadString(
      'assets/translations/$currentLocale.json',
    );
    Map<String, dynamic> jsonMap = json.decode(jsonString);

    return AppLocalization(currentLocale, jsonMap);
  }

  // Mevcut context'teki Localizations'dan AppLocalization örneğini al
  static AppLocalization of(BuildContext context) {
    return Localizations.of<AppLocalization>(context, AppLocalization)!;
  }
}

// AppLocalization için LocalizationsDelegate
class AppLocalizationDelegate extends LocalizationsDelegate<AppLocalization> {
  const AppLocalizationDelegate();

  // Delegate'in belirli bir Locale için desteklenip desteklenmediğini kontrol et
  @override
  bool isSupported(Locale locale) {
    return AppConstants.supportedLanguages.contains(locale.languageCode);
  }

  // Önceki instance'ın tekrar kullanılıp kullanılmayacağını belirt
  @override
  bool shouldReload(LocalizationsDelegate<AppLocalization> old) => false;

  // Belirli bir locale için AppLocalization yükle
  @override
  Future<AppLocalization> load(Locale locale) async {
    return await AppLocalization.load(locale);
  }
}

// Uygulama dil tercihi yönetimi
class LocaleProvider extends ChangeNotifier {
  // Varsayılan dil
  Locale _locale = const Locale(AppConstants.defaultLocale);

  // Mevcut locale
  Locale get locale => _locale;

  // Başlangıçta dil tercihini yükle
  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(AppConstants.languageKey);

    if (savedLocale != null &&
        AppConstants.supportedLanguages.contains(savedLocale)) {
      _locale = Locale(savedLocale);
      notifyListeners();
    } else {
      // Eğer kaydedilmiş dil yoksa, konuma göre dil belirle
      await setLocaleBasedOnLocation();
    }
  }

  // Konuma göre dil belirleme
  Future<void> setLocaleBasedOnLocation() async {
    try {
      // Önce cihazın dil ayarını almayı deneyelim
      final String deviceLanguage = await _getDeviceLanguageCode();

      // Cihaz dili desteklenen dillerden biri mi?
      if (AppConstants.supportedLanguages.contains(deviceLanguage)) {
        // Direkt olarak cihaz dilini kullan
        await setLocale(deviceLanguage);
        return;
      }

      // Eğer cihaz dili desteklenmiyorsa, ülke koduna göre belirle
      final String countryCode = await _getDeviceCountryCode();
      String languageCode;

      // Ülke koduna göre dil belirle
      switch (countryCode.toUpperCase()) {
        case 'TR':
          languageCode = 'tr';
          break;
        case 'RU':
          languageCode = 'ru';
          break;
        case 'UA':
          languageCode = 'uk';
          break;
        default:
          languageCode = 'en';
      }

      await setLocale(languageCode);
    } catch (e) {
      // Hata durumunda varsayılan dil
      await setLocale('en');
    }
  }

  // Cihazın dil kodunu al
  Future<String> _getDeviceLanguageCode() async {
    try {
      // Flutter'ın yerel olarak erişebildiği cihaz dil ayarını al
      final String languageCode =
          PlatformDispatcher.instance.locale.languageCode;

      // Dil kodu destekleniyor mu kontrol et
      if (AppConstants.supportedLanguages.contains(languageCode)) {
        return languageCode;
      }

      // Özel durumlar için kontroller
      // Diğer diller için İngilizce tercih et
      return 'en';
    } catch (e) {
      return 'en'; // Hata durumunda İngilizce
    }
  }

  // Cihazın ülke kodunu al
  Future<String> _getDeviceCountryCode() async {
    try {
      // Sistem locale'inden ülke kodunu al
      final String? countryCode =
          PlatformDispatcher.instance.locale.countryCode;

      // Eğer ülke kodu alınabildiyse döndür, aksi halde varsayılan değer
      return countryCode?.toUpperCase() ?? 'US';
    } catch (e) {
      return 'US'; // Hata durumunda varsayılan olarak US
    }
  }

  // Dili güncelle
  Future<void> setLocale(String languageCode) async {
    if (AppConstants.supportedLanguages.contains(languageCode)) {
      _locale = Locale(languageCode);

      // Dil tercihini kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.languageKey, languageCode);

      notifyListeners();
    }
  }
}

// Desteklenen yerelleştirme delegeleri
List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
  const AppLocalizationDelegate(),
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

// Desteklenen diller
List<Locale> supportedLocales =
    AppConstants.supportedLanguages
        .map((languageCode) => Locale(languageCode))
        .toList();
