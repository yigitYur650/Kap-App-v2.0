import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/ai_quota_provider.dart';
import '../providers/subscription_provider.dart';

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  final TextEditingController _referralController = TextEditingController();
  bool _isClaiming = false;
  String? _referralFeedback;

  @override
  void dispose() {
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _handleClaimReferral(AppLocalizations l10n) async {
    final code = _referralController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isClaiming = true;
      _referralFeedback = null;
    });

    final success = await ref.read(aiQuotaProvider.notifier).claimReferralCode(code);

    setState(() => _isClaiming = false);

    if (success) {
      setState(() => _referralFeedback = l10n.paywall_claim_success);
      _referralController.clear();
    } else {
      final state = ref.read(aiQuotaProvider);
      setState(() => _referralFeedback = l10n.paywall_claim_failed(state.errorMessage ?? 'Hata'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final quotaState = ref.watch(aiQuotaProvider);
    final subState = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Text(
              'Kap-App Mağazası',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: quotaState.isPro
                      ? [Colors.amber.shade900, Colors.orange.shade800]
                      : [theme.colorScheme.primaryContainer, theme.colorScheme.surfaceContainerHighest],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: quotaState.isPro ? Colors.amber : theme.colorScheme.primary,
                    radius: 24,
                    child: Icon(
                      quotaState.isPro ? Icons.workspace_premium_rounded : Icons.star_outline_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quotaState.isPro ? 'Pro Plan Aktif 👑' : 'Ücretsiz Plan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: quotaState.isPro ? Colors.amber.shade100 : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          quotaState.isPro
                              ? l10n.quota_pro_unlimited
                              : l10n.quota_remaining_label(quotaState.remainingCredits),
                          style: TextStyle(
                            fontSize: 13,
                            color: quotaState.isPro ? Colors.white70 : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Hero Pro Plans Section
            Text(
              'Kap-App Pro Ayrıcalıkları',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            _buildFeatureTile(
              icon: Icons.bolt_rounded,
              color: Colors.amber,
              title: 'Sınırsız AI Tarif & Fiyat Tahmini',
              subtitle: 'Günlük limitlere takılmadan sınırsız AI analiz desteği.',
            ),
            _buildFeatureTile(
              icon: Icons.document_scanner_rounded,
              color: Colors.blue,
              title: 'Fiş Taramasından Otomatik Sepete Ekleme',
              subtitle: 'Market fişlerini saniyeler içinde sepetinize aktarın.',
            ),
            _buildFeatureTile(
              icon: Icons.fitness_center_rounded,
              color: Colors.green,
              title: 'Kişisel Beslenme & Alerjen Koruması',
              subtitle: 'BMR/TDEE hedeflerinize uygun kişiselleştirilmiş öneriler.',
            ),
            const SizedBox(height: 20),

            // Pricing Plans
            Text(
              'Abonelik Paketleri',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Yearly Plan (Best Value)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Yıllık Pro',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'EN POPÜLER (2 Ay Bedava)',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₺399.99 / yıl (₺33.33 / ay)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final offerings = subState.offerings;
                      if (offerings?.current != null && offerings!.current!.availablePackages.isNotEmpty) {
                        ref.read(subscriptionProvider.notifier).purchasePackage(offerings.current!.availablePackages.first);
                      }
                    },
                    child: Text(l10n.paywall_buy_button, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Monthly Plan
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aylık Pro',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₺49.99 / ay',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      final offerings = subState.offerings;
                      if (offerings?.current != null && offerings!.current!.availablePackages.length > 1) {
                        ref.read(subscriptionProvider.notifier).purchasePackage(offerings.current!.availablePackages[1]);
                      }
                    },
                    child: Text(l10n.paywall_buy_button),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Free Extra Credits & Referrals Section
            Text(
              'Ücretsiz Hak Kazanın',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Rewarded Ad Simulation Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    const Icon(Icons.ondemand_video_rounded, color: Colors.green, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.paywall_watch_ad_title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.paywall_watch_ad_subtitle,
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      onPressed: () {
                        ref.read(aiQuotaProvider.notifier).addBonusCredit();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.ad_reward_success)),
                        );
                      },
                      child: const Text('+1 Hak'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Referral Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.card_giftcard_rounded, color: Colors.purple, size: 26),
                        const SizedBox(width: 8),
                        Text(
                          l10n.paywall_referral_title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.paywall_referral_subtitle,
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 10),
                    if (quotaState.referralCode != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                      const SizedBox(height: 10),
                    ],
                    TextField(
                      controller: _referralController,
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isClaiming ? null : () => _handleClaimReferral(l10n),
                      child: Text(_isClaiming ? 'İşleniyor...' : l10n.paywall_claim_button),
                    ),
                    if (_referralFeedback != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _referralFeedback!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: _referralFeedback!.contains('Tebrikler') ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Restore Purchases Button
            TextButton.icon(
              onPressed: () => ref.read(subscriptionProvider.notifier).restorePurchases(),
              icon: const Icon(Icons.restore_rounded, size: 18),
              label: const Text('Satın Almaları Geri Yükle (Restore)'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            radius: 18,
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
