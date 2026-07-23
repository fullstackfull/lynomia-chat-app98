import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/app_localizations.dart';
import '../../../shared/network/local/cache_helper.dart';


class LocaleCubit extends Cubit<Locale> {
  LocaleCubit() : super(_getInitialLocale());

  static Locale _getInitialLocale() {
    final savedLocale = CacheHelper.getString(key: 'locale');
    if (savedLocale != null) {
      return Locale(savedLocale);
    }

    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final deviceLanguageCode = deviceLocale.languageCode;

    final isSupported = AppLocalizations.supportedLocales.any(
          (l) => l.languageCode == deviceLanguageCode,
    );

    return isSupported ? Locale(deviceLanguageCode) : const Locale('en');
  }

  // ✅ تغيير اللغة
  void changeLocale(String languageCode) async {
    if (!['en', 'ar'].contains(languageCode)) return;

    final newLocale = Locale(languageCode);
    await CacheHelper.saveData(key: 'locale', value: languageCode);
    emit(newLocale);
  }

  void loadSavedLocale() {
    final savedLocale = CacheHelper.getString(key: 'locale');
    if (savedLocale != null) {
      emit(Locale(savedLocale));
    }
  }

  bool get isArabic => state.languageCode == 'ar';
}