

import 'package:chat/modules/login/login_screen.dart';
import 'package:chat/shared/app_localizations.dart';
import 'package:chat/shared/network/firebase_config/firebase_helper.dart';
import 'package:chat/shared/network/local/cache_helper.dart';
import 'package:chat/shared/network/remote/dio_helper.dart';
import 'package:chat/shared/styles/bloc_observer.dart';
import 'package:chat/shared/styles/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'layout/cubit/cubit.dart';
import 'layout/cubit/states.dart';
import 'modules/language/cubit/cubit.dart';
import 'modules/splash/splash_screen.dart';
import 'shared/styles/lyn_palette.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ تهيئة Firebase + Local Notifications (بدلاً من Firebase.initializeApp فقط)
  await FirebaseHelper.init();

  // ✅ إعداد Stripe
  Stripe.publishableKey = 'pk_test_51Tf99xQjbi1GWYvCGK9RA9cnIEdLraEMxPKF8aieVJTHX9Ub9nNhGR4R11t1NMoyaTg9HeP9q9gvtFGSqoXcX9bj00wjfgMUEj';
  await Stripe.instance.applySettings();

  await CacheHelper.init();
  DioHelper.init();

  Bloc.observer = MyBlocObserver();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F172A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  String? savedLocale = CacheHelper.getData(key: 'locale');
  final Locale deviceLocale = WidgetsBinding.instance.window.locale;
  final String deviceLanguageCode = deviceLocale.languageCode;

  Locale appLocale = savedLocale != null
      ? Locale(savedLocale)
      : (AppLocalizations.supportedLocales.any(
        (l) => l.languageCode == deviceLanguageCode,
  )
      ? Locale(deviceLanguageCode)
      : const Locale('en'));

  runApp( MyApp(locale: appLocale));
}

class MyApp extends StatelessWidget {
  final Locale locale;
  const MyApp({super.key,required this.locale});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            final cubit = AppCubit();
            cubit.init();
            return cubit;
          },
        ),
        BlocProvider(
          create: (context) => LocaleCubit()..loadSavedLocale(),
        ),
      ],
      child: BlocBuilder<AppCubit, AppStates>(
        builder: (context, state) {
          final isDark = AppCubit.get(context).isDark;
          
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
              systemNavigationBarColor: LynSurface.canvas(isDark),
              systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            ),
          );

          return BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) {
              return MaterialApp(
                title: 'Chatwoot Chat',
                debugShowCheckedModeBanner: false,
                theme: lightTheme,
                darkTheme: darkTheme,
                themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
                locale: locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                home: const SplashScreen(),
              );
            },
          );
        },
      ),
    );
  }
}

