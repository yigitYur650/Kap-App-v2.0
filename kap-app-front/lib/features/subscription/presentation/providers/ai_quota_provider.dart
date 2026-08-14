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
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.backendBaseUrl}/api/v1/subscriptions/status'),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        state = state.copyWith(
          isLoading: false,
          remainingCredits: (data['remaining_credits'] as num?)?.toInt() ?? 2,
          isPro: data['is_pro'] as bool? ?? false,
          referralCode: data['referral_code'] as String?,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Status request failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
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
