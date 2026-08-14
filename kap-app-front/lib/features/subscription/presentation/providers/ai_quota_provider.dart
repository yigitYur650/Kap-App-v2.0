import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';

class AIQuotaState {
  final int remainingCredits;
  final bool isPro;
  final bool isLoading;
  final String? referralCode;
  final String? errorMessage;

  const AIQuotaState({
    this.remainingCredits = 2,
    this.isPro = false,
    this.isLoading = false,
    this.referralCode,
    this.errorMessage,
  });

  AIQuotaState copyWith({
    int? remainingCredits,
    bool? isPro,
    bool? isLoading,
    String? referralCode,
    String? errorMessage,
  }) {
    return AIQuotaState(
      remainingCredits: remainingCredits ?? this.remainingCredits,
      isPro: isPro ?? this.isPro,
      isLoading: isLoading ?? this.isLoading,
      referralCode: referralCode ?? this.referralCode,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final aiQuotaProvider =
    NotifierProvider<AIQuotaNotifier, AIQuotaState>(AIQuotaNotifier.new);

class AIQuotaNotifier extends Notifier<AIQuotaState> {
  @override
  AIQuotaState build() {
    // Schedule fetch after build phase
    Future.microtask(() => fetchQuota());
    return const AIQuotaState();
  }

  Future<void> fetchQuota() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    bool isPro = false;
    int remaining = 2;

    // 1. Direct Supabase Query (0ms delay & works even if backend is sleeping/offline)
    try {
      final client = Supabase.instance.client;

      // Check user_subscriptions for active subscription
      final subRes = await client
          .from('user_subscriptions')
          .select('expires_at')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .maybeSingle();

      if (subRes != null) {
        final expStr = subRes['expires_at'] as String?;
        if (expStr == null) {
          isPro = true;
        } else {
          final expDate = DateTime.tryParse(expStr);
          if (expDate == null || expDate.isAfter(DateTime.now())) {
            isPro = true;
          }
        }
      }

      // Check user_ai_usage
      final usageRes = await client
          .from('user_ai_usage')
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();

      if (usageRes != null) {
        final dbIsPro = usageRes['is_pro'] as bool? ?? false;
        if (dbIsPro) isPro = true;

        if (!isPro) {
          final freeLimit = (usageRes['free_daily_limit'] as num?)?.toInt() ?? 2;
          final bonus = (usageRes['bonus_credits'] as num?)?.toInt() ?? 0;
          final usedToday = (usageRes['used_count_today'] as num?)?.toInt() ?? 0;
          final remDaily = (freeLimit - usedToday).clamp(0, 999);
          remaining = remDaily + bonus;
        }
      }

      if (isPro) {
        remaining = 999999;
      }

      state = state.copyWith(
        isLoading: false,
        isPro: isPro,
        remainingCredits: remaining,
      );
    } catch (_) {
      // Ignore direct query errors
    }

    // 2. Secondary Backend status call
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final response = await http.get(
          Uri.parse('${AppConstants.backendBaseUrl}/api/v1/subscriptions/status'),
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final backendIsPro = data['is_pro'] as bool? ?? false;
          final backendRem = (data['remaining_credits'] as num?)?.toInt() ?? 2;
          final code = data['referral_code'] as String?;

          state = state.copyWith(
            isLoading: false,
            isPro: isPro || backendIsPro,
            remainingCredits: (isPro || backendIsPro) ? 999999 : backendRem,
            referralCode: code,
          );
        }
      }
    } catch (_) {
      // Backend offline or timeout fallback
    }
  }

  void addBonusCredit() {
    state = state.copyWith(
      remainingCredits: state.remainingCredits + 1,
    );
  }

  Future<bool> claimReferralCode(String code, {String? deviceHash}) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.backendBaseUrl}/api/v1/referral/claim'),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'referrer_code': code,
          'device_hash': deviceHash ?? 'device_hash_default',
        }),
      );

      if (response.statusCode == 200) {
        await fetchQuota();
        return true;
      } else {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        state = state.copyWith(
          errorMessage: body['reason'] as String? ?? 'Referral claim failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}
