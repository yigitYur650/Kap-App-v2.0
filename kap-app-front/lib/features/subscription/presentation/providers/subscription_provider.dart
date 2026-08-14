import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionState {
  final bool isPro;
  final bool isLoading;
  final CustomerInfo? customerInfo;
  final Offerings? offerings;
  final String? errorMessage;

  const SubscriptionState({
    this.isPro = false,
    this.isLoading = false,
    this.customerInfo,
    this.offerings,
    this.errorMessage,
  });

  SubscriptionState copyWith({
    bool? isPro,
    bool? isLoading,
    CustomerInfo? customerInfo,
    Offerings? offerings,
    String? errorMessage,
  }) {
    return SubscriptionState(
      isPro: isPro ?? this.isPro,
      isLoading: isLoading ?? this.isLoading,
      customerInfo: customerInfo ?? this.customerInfo,
      offerings: offerings ?? this.offerings,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final subscriptionProvider =
    NotifierProvider<SubscriptionNotifier, SubscriptionState>(SubscriptionNotifier.new);

class SubscriptionNotifier extends Notifier<SubscriptionState> {
  @override
  SubscriptionState build() {
    Future.microtask(() => initRevenueCat());
    return const SubscriptionState();
  }

  Future<void> initRevenueCat() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final user = Supabase.instance.client.auth.currentUser;

    try {
      if (!kIsWeb) {
        await Purchases.setLogLevel(LogLevel.debug);
        // RevenueCat Public API Key configured for store deployment
        PurchasesConfiguration configuration = PurchasesConfiguration("goog_revcat_public_sdk_key");
        if (user != null) {
          configuration.appUserID = user.id;
        }
        await Purchases.configure(configuration);

        final customerInfo = await Purchases.getCustomerInfo();
        final offerings = await Purchases.getOfferings();

        final isPro = customerInfo.entitlements.active.containsKey('pro');

        state = state.copyWith(
          isLoading: false,
          isPro: isPro,
          customerInfo: customerInfo,
          offerings: offerings,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> purchasePackage(Package package) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final customerInfo = (await Purchases.purchasePackage(package)).customerInfo;
      final isPro = customerInfo.entitlements.active.containsKey('pro');
      state = state.copyWith(
        isLoading: false,
        isPro: isPro,
        customerInfo: customerInfo,
      );
      return isPro;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> restorePurchases() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final customerInfo = await Purchases.restorePurchases();
      final isPro = customerInfo.entitlements.active.containsKey('pro');
      state = state.copyWith(
        isLoading: false,
        isPro: isPro,
        customerInfo: customerInfo,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}
