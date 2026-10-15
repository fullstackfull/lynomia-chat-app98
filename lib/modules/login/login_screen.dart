

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../layout/cubit/cubit.dart';
import '../../layout/cubit/states.dart';
import '../../shared/app_localizations.dart';
import '../../shared/components/components.dart';

import '../../shared/network/local/cache_helper.dart';
import '../inbox_selection/inbox_selection_screen.dart';
import '../splash/splash_screen.dart';
import '../../shared/styles/lyn_palette.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    final savedEmail = CacheHelper.getString(key: CacheHelper.keyUserEmail) ?? '';
    _emailController.text = savedEmail;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    context.read<AppCubit>().login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppCubit, AppStates>(
      listener: (context, state) {
        // ✅ فقط لما يكتمل كل شي — انتقل للـ Splash
        if (state is AppAuthCompleteState) {
          CustomToast.show(
            context: context,
            message: AppLocalizations.tr(context, 'Login successful!'),
            state: ToastStates.success,
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SplashScreen()),
          );
        }

        if (state is AppLoginErrorState) {
          CustomToast.show(
            context: context,
            message: state.error,
            state: ToastStates.error,
          );
        }

        if (state is AppSubscriptionErrorState) {
          CustomToast.show(
            context: context,
            message: '${AppLocalizations.tr(context, 'Subscription check failed: ')}${state.error}',
            state: ToastStates.error,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AppLoginLoadingState ||
            state is AppSubscriptionLoadingState;

        final isDark = AppCubit.get(context).isDark;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    // 🎨 الأيقونة
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: LynPalette.indigo.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chat_bubble_rounded,
                          size: 40,
                          color: LynPalette.indigo,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 📝 العنوان
                    Center(
                      child: Text(
                        AppLocalizations.tr(context, 'Welcome! 👋'),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: LynSurface.textPrimary(isDark),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Center(
                      child: Text(
                        AppLocalizations.tr(context, 'Enter your details to start chatting'),
                        style: TextStyle(
                          fontSize: 16,
                          color: LynSurface.textSecondary(isDark),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // 📧 حقل البريد
                    Text(AppLocalizations.tr(context, 'Email'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: LynSurface.textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 8),
                    defaultFormField(
                      controller: _emailController,
                      type: TextInputType.emailAddress,
                      validate: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.tr(context, 'Email is required');
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return AppLocalizations.tr(context, 'Invalid email');
                        }
                        return null;
                      },
                      prefix: Icons.email_outlined,
                      hint: 'example@email.com',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),

                    // 🔒 حقل كلمة المرور — مع أيقونة العين
                    Text(AppLocalizations.tr(context, 'Password'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: LynSurface.textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ✅ استخدام defaultFormField مع أيقونة العين
                    StatefulBuilder(
                      builder: (context, passwordSetState) {
                        return defaultFormField(
                          controller: _passwordController,
                          type: TextInputType.visiblePassword,
                          validate: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.tr(context, 'Password is required');
                            }
                            if (value.length < 6) {
                              return AppLocalizations.tr(context, 'Password is too short');
                            }
                            return null;
                          },
                          prefix: Icons.lock_outline,
                          hint: '••••••••',
                          isPassword: !_isPasswordVisible, // ✅ التحكم في الإخفاء
                          suffix: _isPasswordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          suffixPressed: () {
                            passwordSetState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                          isDark: isDark,
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // 🔘 زر الدخول
                    isLoading
                        ? Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            color: LynPalette.indigo,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            state is AppSubscriptionLoadingState
                                ? AppLocalizations.tr(context, 'Checking subscription...')
                                : AppLocalizations.tr(context, 'Logging in...'),
                            style: TextStyle(
                              color: LynSurface.textSecondary(isDark),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                        : defaultButton(
                      function: _submit,
                      text: AppLocalizations.tr(context, 'login'),
                      isUpperCase: false,
                      radius: 16,
                    ),

                    const SizedBox(height: 50),
                    // 🔘 زر Google Sign-In
                    isLoading
                        ? const SizedBox()
                        : InkWell(
                      onTap: () {
                        context.read<AppCubit>().loginWithGoogle();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: isDark ? HexColor('#FFFFFF') : HexColor('#F1F5F9'),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? HexColor('#E2E8F0') : HexColor('#CBD5E1'),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // ✅ شعار Google
                            Image.asset(
                              'assets/images/Google.png',
                              height: 30,
                              width: 30,
                              errorBuilder: (context, error, stackTrace) {
                                // ✅ fallback لو ما لقى الصورة
                                return Icon(
                                  Icons.g_mobiledata,
                                  color: HexColor('#4285F4'),
                                  size: 28,
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            Text(AppLocalizations.tr(context, 'google_sign_in'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: HexColor('#1E293B'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

// 🍎 زر Apple Sign-In
                    isLoading
                        ? const SizedBox()
                        : InkWell(
                      onTap: () {
                        context.read<AppCubit>().loginWithApple();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: isDark ? HexColor('#000000') : HexColor('#000000'),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? HexColor('#333333') : HexColor('#000000'),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.apple,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              AppLocalizations.tr(context, 'apple_sign_in'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

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
                              color: LynSurface.textTertiary(isDark),
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