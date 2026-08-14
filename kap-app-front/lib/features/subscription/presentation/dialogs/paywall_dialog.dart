import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/ai_quota_provider.dart';
import '../providers/subscription_provider.dart';

class PaywallDialog extends ConsumerStatefulWidget {
  const PaywallDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const PaywallDialog(),
    );
  }

  @override
  ConsumerState<PaywallDialog> createState() => _PaywallDialogState();
}

class _PaywallDialogState extends ConsumerState<PaywallDialog> {
  final TextEditingController _referralCodeController = TextEditingController();
  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;
  String? _referralMessage;
  bool _isClaimingReferral = false;

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
  }

  void _loadRewardedAd() {
    if (kIsWeb) return;
    setState(() => _isAdLoading = true);

    // Test Rewarded Ad Unit ID for Android
    const adUnitId = 'ca-app-pub-3940256099942544/5224354917';

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedAd = ad;
            _isAdLoading = false;
          });
        },
        onAdFailedToLoad: (error) {
          setState(() => _isAdLoading = false);
        },
      ),
    );
  }

  void _showRewardedAd(AppLocalizations l10n) {
    if (_rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (adWithoutView, reward) {
          ref.read(aiQuotaProvider.notifier).addBonusCredit();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.ad_reward_success)),
          );
          Navigator.of(context).pop();
        },
      );
    } else {
      // Fallback for Web/Test environment
      ref.read(aiQuotaProvider.notifier).addBonusCredit();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.ad_reward_success)),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _claimReferralCode(AppLocalizations l10n) async {
    final code = _referralCodeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isClaimingReferral = true;
      _referralMessage = null;
    });

    final success = await ref.read(aiQuotaProvider.notifier).claimReferralCode(code);

    setState(() => _isClaimingReferral = false);

    if (success) {
      setState(() {
        _referralMessage = l10n.paywall_claim_success;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).pop();
      });
    } else {
      final quotaState = ref.read(aiQuotaProvider);
      setState(() {
        _referralMessage = l10n.paywall_claim_failed(quotaState.errorMessage ?? 'Hata');
      });
    }
  }

  @override
  void dispose() {
    _referralCodeController.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final quotaState = ref.watch(aiQuotaProvider);
    final subState = ref.watch(subscriptionProvider);
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.colorScheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          quotaState.isPro
                              ? l10n.quota_pro_unlimited
                              : l10n.quota_remaining_label(quotaState.remainingCredits),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              const SizedBox(height: 12),

              // Title & Subtitle
              Text(
                l10n.quota_dialog_title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.quota_dialog_subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),

              // Option 1: Upgrade to Pro Card
              _buildOptionCard(
                context: context,
                icon: Icons.star_rounded,
                iconColor: Colors.amber,
                title: l10n.paywall_upgrade_pro_title,
                subtitle: l10n.paywall_upgrade_pro_subtitle,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size.fromHeight(44),
                      ),
                      onPressed: () {
                        final offerings = subState.offerings;
                        if (offerings?.current != null && offerings!.current!.availablePackages.isNotEmpty) {
                          ref.read(subscriptionProvider.notifier).purchasePackage(offerings.current!.availablePackages.first);
                        }
                      },
                      child: Text(
                        l10n.paywall_monthly_plan,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Option 2: Watch Rewarded Ad Card
              _buildOptionCard(
                context: context,
                icon: Icons.play_circle_fill_rounded,
                iconColor: Colors.green,
                title: l10n.paywall_watch_ad_title,
                subtitle: l10n.paywall_watch_ad_subtitle,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.ondemand_video_rounded),
                    label: Text(
                      _isAdLoading ? 'Yükleniyor...' : l10n.paywall_watch_ad_button,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isAdLoading ? null : () => _showRewardedAd(l10n),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Option 3: Invite Friend / Enter Referral Code Card
              _buildOptionCard(
                context: context,
                icon: Icons.card_giftcard_rounded,
                iconColor: Colors.purple,
                title: l10n.paywall_referral_title,
                subtitle: l10n.paywall_referral_subtitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    if (quotaState.referralCode != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${l10n.paywall_referral_code_label} ${quotaState.referralCode}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, color: Colors.purple),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: quotaState.referralCode!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.paywall_referral_copied)),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: _referralCodeController,
                      decoration: InputDecoration(
                        labelText: l10n.paywall_enter_code_title,
                        hintText: l10n.paywall_enter_code_hint,
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isClaimingReferral ? null : () => _claimReferralCode(l10n),
                      child: Text(
                        _isClaimingReferral ? 'İşleniyor...' : l10n.paywall_claim_button,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (_referralMessage != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _referralMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: _referralMessage!.contains('Tebrikler') ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
