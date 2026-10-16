

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../layout/cubit/cubit.dart';
import '../../layout/cubit/states.dart';
import '../../shared/app_localizations.dart';
import '../../shared/components/components.dart';

import '../../shared/network/local/cache_helper.dart';
import '../splash/splash_screen.dart';
import '../../shared/styles/lyn_palette.dart';
import '../../shared/styles/lyn_type.dart';

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
            message: AppLocalizations.tr(context, state.messageKey),
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
              padding: const EdgeInsets.fromLTRB(
                  LynSpace.xl, LynSpace.lg, LynSpace.xl, LynSpace.xxl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: LynSpace.xxl),

                    // The product's own mark, not a generic chat bubble in a circle. The fallback is
                    // the wordmark rather than another glyph, so a missing asset still says Lynomia.
                    Center(
                      child: Image.asset(
                        'assets/images/Logo.png',
                        height: 64,
                        errorBuilder: (context, error, stackTrace) => Text(
                          'Lynomia',
                          style: LynType.display.copyWith(color: LynPalette.indigo),
                        ),
                      ),
                    ),
                    const SizedBox(height: LynSpace.xxl),

                    Center(
                      child: Text(
                        AppLocalizations.tr(context, 'Welcome! 👋'),
                        style: LynType.title.copyWith(color: LynSurface.textPrimary(isDark)),
                      ),
                    ),
                    const SizedBox(height: LynSpace.sm),

                    Center(
                      child: Text(
                        AppLocalizations.tr(context, 'Enter your details to start chatting'),
                        textAlign: TextAlign.center,
                        style: LynType.callout.copyWith(color: LynSurface.textSecondary(isDark)),
                      ),
                    ),
                    const SizedBox(height: LynSpace.xxl),

                    Text(AppLocalizations.tr(context, 'Email'),
                      style: LynType.callout.copyWith(color: LynSurface.textPrimary(isDark)),
                    ),
                    const SizedBox(height: LynSpace.sm),
                    defaultFormField(
                      controller: _emailController,
                      type: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.username, AutofillHints.email],
                      textInputAction: TextInputAction.next,
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
                    const SizedBox(height: LynSpace.lg),

                    Text(AppLocalizations.tr(context, 'Password'),
                      style: LynType.callout.copyWith(color: LynSurface.textPrimary(isDark)),
                    ),
                    const SizedBox(height: LynSpace.sm),

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
                          autofillHints: const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          onSubmit: (_) => _submit(),
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
                    const SizedBox(height: LynSpace.xl),

                    isLoading
                        ? SizedBox(
                      height: 52,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: LynPalette.indigo, strokeWidth: 2),
                            ),
                            const SizedBox(width: LynSpace.md),
                            Text(
                              state is AppSubscriptionLoadingState
                                  ? AppLocalizations.tr(context, 'Checking subscription...')
                                  : AppLocalizations.tr(context, 'Logging in...'),
                              style: LynType.callout
                                  .copyWith(color: LynSurface.textSecondary(isDark)),
                            ),
                          ],
                        ),
                      ),
                    )
                        : defaultButton(
                      function: _submit,
                      text: AppLocalizations.tr(context, 'login'),
                      isUpperCase: false,
                    ),

                    // A bare 50px gap used to stand between the password button and the social ones,
                    // which left it unclear whether they were alternatives or extra steps.
                    const SizedBox(height: LynSpace.xl),
                    Row(
                      children: [
                        Expanded(child: Divider(color: LynSurface.border(isDark), height: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: LynSpace.md),
                          child: Text(
                            AppLocalizations.tr(context, 'or_continue_with'),
                            style: LynType.caption
                                .copyWith(color: LynSurface.textSecondary(isDark)),
                          ),
                        ),
                        Expanded(child: Divider(color: LynSurface.border(isDark), height: 1)),
                      ],
                    ),
                    const SizedBox(height: LynSpace.lg),

                    isLoading
                        ? const SizedBox()
                        : InkWell(
                      onTap: () {
                        context.read<AppCubit>().loginWithGoogle();
                      },
                      borderRadius: BorderRadius.circular(LynSpace.md),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          // Google's own guidance is one white button with a grey rule, in both
                          // themes. What was here inverted that -- white on the dark theme and a
                          // near-white slate on the light one -- with the border colours swapped too,
                          // so on paper the button was a pale rectangle on a pale page.
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(LynSpace.md),
                          border: Border.all(color: const Color(0xFF747775)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // ✅ شعار Google
                            Image.asset(
                              'assets/images/Google.png',
                              height: 20,
                              width: 20,
                              errorBuilder: (context, error, stackTrace) {
                                // ✅ fallback لو ما لقى الصورة
                                return Icon(
                                  Icons.g_mobiledata,
                                  color: const Color(0xFF4285F4),
                                  size: 28,
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            Text(AppLocalizations.tr(context, 'google_sign_in'),
                              style: LynType.subtitle.copyWith(color: const Color(0xFF1F1F1F)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: LynSpace.md),

// 🍎 زر Apple Sign-In
                    isLoading
                        ? const SizedBox()
                        : InkWell(
                      onTap: () {
                        context.read<AppCubit>().loginWithApple();
                      },
                      borderRadius: BorderRadius.circular(LynSpace.md),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          // Was `isDark ? '#000000' : '#000000'` -- a branch with the same answer on
                          // both sides. The rule it carries is the only part that needs a theme: on
                          // the ink canvas a pure black button needs an edge to be seen at all.
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(LynSpace.md),
                          border: Border.all(color: isDark ? LynPalette.inkSoft : Colors.black),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.apple, color: Colors.white, size: 22),
                            const SizedBox(width: LynSpace.md),
                            Text(
                              AppLocalizations.tr(context, 'apple_sign_in'),
                              style: LynType.subtitle.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: LynSpace.xl),

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
                            'Powered by',
                            style: LynType.caption
                                .copyWith(color: LynSurface.textSecondary(isDark)),
                          ),
                          // A trailing space inside a Text is trimmed at layout, which ran the two
                          // words together in Arabic; the gap has to be a widget.
                          const SizedBox(width: LynSpace.xs),
                          Text(
                            'Lynomia',
                            style: LynType.caption.copyWith(
                              color: isDark ? LynPalette.indigoOnDark : LynPalette.indigoDeep,
                              fontWeight: FontWeight.w700,
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