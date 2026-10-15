import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../layout/cubit/cubit.dart';
import '../../layout/payment_history/payment_history_cubit.dart';
import '../../layout/payment_history/payment_history_states.dart';
import '../../models/payment_history_model.dart';
import '../../shared/app_localizations.dart';
import '../../shared/network/payment_api_service.dart';
import '../../shared/styles/lyn_palette.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = AppCubit.get(context).isDark;

    return BlocProvider(
      create: (context) =>
          PaymentHistoryCubit(PaymentApiService(Dio()))..fetchPaymentHistory(),
      child: Scaffold(
        backgroundColor: LynSurface.canvas(isDark),
        appBar: AppBar(
          backgroundColor: LynSurface.surface(isDark),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: LynSurface.textPrimary(isDark)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            AppLocalizations.tr(context, 'Payment History'),
            style: TextStyle(
              color: LynSurface.textPrimary(isDark),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<PaymentHistoryCubit, PaymentHistoryState>(
          builder: (context, state) {
            if (state is PaymentHistoryLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: isDark ? LynPalette.indigo : LynPalette.indigo,
                ),
              );
            } else if (state is PaymentHistoryLoaded) {
              if (state.history.isEmpty) {
                return _buildEmptyState(context, isDark);
              }
              return _buildHistoryList(context, state.history, isDark);
            } else if (state is PaymentHistoryError) {
              return _buildErrorState(context, state.error, isDark);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: LynSurface.borderStrong(isDark),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.tr(context, 'No payment history'),
            style: TextStyle(
              color: LynSurface.textSecondary(isDark),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
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
                SizedBox(
                  width: 2,
                ),
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
    );
  }

  Widget _buildErrorState(BuildContext context, String error, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LynPalette.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: isDark ? HexColor('#F87171') : LynPalette.danger,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.tr(context, 'Error loading payment history'),
              style: TextStyle(
                color: LynSurface.textPrimary(isDark),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                error,
                style: TextStyle(
                  color: LynSurface.textSecondary(isDark),
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<PaymentHistoryCubit>().fetchPaymentHistory(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(AppLocalizations.tr(context, 'Retry')),
              style: ElevatedButton.styleFrom(
                backgroundColor: LynPalette.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(
      BuildContext context, List<PaymentHistoryModel> history, bool isDark) {
    return RefreshIndicator(
      onRefresh: () =>
          context.read<PaymentHistoryCubit>().fetchPaymentHistory(),
      color: isDark ? LynPalette.indigo : LynPalette.indigo,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final payment = history[index];
          return _buildPaymentCard(context, payment, isDark, index);
        },
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, PaymentHistoryModel payment,
      bool isDark, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: LynSurface.surface(isDark),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? HexColor('#0F172A').withOpacity(0.3)
                : HexColor('#000000').withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: _getPaymentColor(payment.way).withOpacity(0.1),
                      ),
                      child: Icon(
                        _getPaymentIcon(payment.way),
                        color: _getPaymentColor(payment.way),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.planName,
                          style: TextStyle(
                            color: isDark
                                ? HexColor('#E2E8F0')
                                : HexColor('#1E293B'),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          payment.formattedDate,
                          style: TextStyle(
                            color: isDark
                                ? HexColor('#94A3B8')
                                : HexColor('#64748B'),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: _getPaymentColor(payment.way).withOpacity(0.1),
                  ),
                  child: Text(
                    payment.formattedPrice,
                    style: TextStyle(
                      color: _getPaymentColor(payment.way),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: LynSurface.border(isDark)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoItem(
                  context,
                  isDark,
                  Icons.payment_outlined,
                  AppLocalizations.tr(context, 'Payment Method'),
                  payment.way.toUpperCase(),
                ),
                const SizedBox(width: 24),
                _buildInfoItem(
                  context,
                  isDark,
                  Icons.receipt_long_outlined,
                  AppLocalizations.tr(context, 'Transaction ID'),
                  payment.intentId,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    bool isDark,
    IconData icon,
    String label,
    String value,
  ) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: LynSurface.textTertiary(isDark),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: LynSurface.textTertiary(isDark),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: LynSurface.textPrimary(isDark),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  // overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPaymentColor(String way) {
    switch (way.toLowerCase()) {
      case 'stripe':
        return LynPalette.indigo;
      case 'google_play':
        return LynPalette.success;
      default:
        return LynPalette.warning;
    }
  }

  IconData _getPaymentIcon(String way) {
    switch (way.toLowerCase()) {
      case 'stripe':
        return Icons.credit_card_outlined;
      case 'google_play':
        return Icons.play_circle_outline;
      default:
        return Icons.payment_outlined;
    }
  }
}
