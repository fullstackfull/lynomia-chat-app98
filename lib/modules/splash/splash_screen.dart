

import 'package:chat/layout/layout_screen.dart';
import 'package:chat/modules/inbox_selection/inbox_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../layout/cubit/cubit.dart';
import '../../layout/cubit/states.dart';
import '../../shared/app_localizations.dart';
import '../../shared/network/local/cache_helper.dart';
import '../chat/chat_screen.dart';
import '../login/login_screen.dart';
import '../../shared/styles/lyn_palette.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      final authToken = CacheHelper.getString(key: CacheHelper.keyAuthToken);

      if (authToken != null && authToken.isNotEmpty) {
        // ✅ يوجد token - تحميل الجلسة
        context.read<AppCubit>().loadExistingSession();
      } else {
        // ❌ لا يوجد token - الذهاب لتسجيل الدخول
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppCubit, AppStates>(
      listener: (context, state) {
        if (state is AppLoadSessionSuccessState) {
          // ✅ فحص الاشتراك وتوجيه المستخدم
          final cubit = AppCubit.get(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LayoutScreen()),
          );
        } else if (state is AppNoSessionState || state is AppLoadSessionErrorState) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      },
      builder: (context,state){
        final isDark = AppCubit.get(context).isDark;
        return  Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 🎨 الأيقونة
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: LynPalette.indigo.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chat_bubble_rounded,
                        size: 60,
                        color: LynPalette.indigo,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 📝 العنوان
                    Text(
                      'Lynomia Chat',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: isDark ? HexColor('#F8FAFC') : HexColor('#0F172A'),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      AppLocalizations.tr(context, 'Instant support team communication'),
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? HexColor('#94A3B8') : HexColor('#475569'),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // ⏳ المؤشر
                    SpinKitWave(
                      color: LynPalette.indigo,
                      size: 30,
                    ),
                    const SizedBox(height: 48),

                    // 🏢 Powered by Lynomia
                    GestureDetector(
                      onTap: () async {
                        final Uri url = Uri.parse('https://lynomia.com');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Row(
                        textDirection: TextDirection.ltr,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Powered by ',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? HexColor('#64748B') : HexColor('#94A3B8'),
                            ),
                          ),
                          SizedBox(width: 2,),
                          Text(
                            'Lynomia',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: LynPalette.indigo,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}