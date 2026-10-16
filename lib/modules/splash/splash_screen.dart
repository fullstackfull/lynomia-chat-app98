import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:chat/layout/layout_screen.dart';

import '../../layout/cubit/cubit.dart';
import '../../layout/cubit/states.dart';
import '../../shared/app_localizations.dart';
import '../../shared/network/local/cache_helper.dart';
import '../../shared/styles/lyn_controls.dart';
import '../../shared/styles/lyn_palette.dart';
import '../../shared/styles/lyn_type.dart';
import '../login/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  /// How long the mark takes to arrive, and — because they are the same interval — how long the
  /// screen waits before it starts deciding where to send you. It used to wait 2,500ms against an
  /// animation that finished at 1,500: a full second of a still picture, on every single launch.
  static const Duration _intro = Duration(milliseconds: 1500);

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: _intro);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.88, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();

    Future.delayed(_intro, _route);
  }

  /// Where to go next.
  ///
  /// `mounted` is checked because this runs after a delay: leaving the app inside that window
  /// disposes this State, and using its `context` afterwards throws. Nothing guarded it before.
  void _route() {
    if (!mounted) return;

    final authToken = CacheHelper.getString(key: CacheHelper.keyAuthToken);
    if (authToken != null && authToken.isNotEmpty) {
      context.read<AppCubit>().loadExistingSession();
      return;
    }
    _replaceWith(const LoginScreen());
  }

  void _replaceWith(Widget screen) {
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppCubit, AppStates>(
      listener: (context, state) {
        if (state is AppLoadSessionSuccessState) {
          _replaceWith(const LayoutScreen());
        } else if (state is AppNoSessionState || state is AppLoadSessionErrorState) {
          _replaceWith(const LoginScreen());
        }
      },
      child: Builder(
        builder: (context) {
          final isDark = AppCubit.get(context).isDark;

          return Scaffold(
            backgroundColor: LynSurface.canvas(isDark),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: FadeTransition(
                        opacity: _fade,
                        child: ScaleTransition(
                          scale: _scale,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  color: LynPalette.indigo.withOpacity(isDark ? 0.22 : 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.chat_bubble_rounded,
                                    size: 44, color: LynPalette.indigo),
                              ),
                              const SizedBox(height: LynSpace.xl),
                              Text(
                                'Lynomia Chat',
                                style: LynType.display.copyWith(
                                  color: LynSurface.textPrimary(isDark),
                                  // The scale tightens display ranks; a wordmark wants the opposite,
                                  // but 1.5 was enough to open gaps inside the name itself.
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: LynSpace.sm),
                              Text(
                                AppLocalizations.tr(
                                    context, 'Instant support team communication'),
                                textAlign: TextAlign.center,
                                style: LynType.body
                                    .copyWith(color: LynSurface.textSecondary(isDark)),
                              ),
                              const SizedBox(height: LynSpace.xxl),
                              SpinKitWave(color: LynPalette.indigo, size: 26),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: LynSpace.xl),
                    child: LynPoweredBy(
                      isDark: isDark,
                      onTap: () async {
                        final url = Uri.parse('https://lynomia.com');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
