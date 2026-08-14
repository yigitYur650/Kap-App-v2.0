import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kap_app_front/features/subscription/presentation/providers/ai_quota_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class KapAppBrandLogo extends ConsumerWidget {
  final double fontSize;
  final bool showBadge;

  const KapAppBrandLogo({
    super.key,
    this.fontSize = 38.0,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotaState = ref.watch(aiQuotaProvider);
    final isPro = quotaState.isPro;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Glowing Icon Badge + Shader Text
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(fontSize > 28 ? 10 : 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPro
                      ? [const Color(0xFFFFB300), const Color(0xFFFF6F00)]
                      : [const Color(0xFFE50914), const Color(0xFFFF334B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(fontSize > 28 ? 14 : 10),
                boxShadow: [
                  BoxShadow(
                    color: isPro ? Colors.amber.withOpacity(0.5) : AppColors.primary.withOpacity(0.5),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                isPro ? Icons.workspace_premium_rounded : Icons.shopping_bag_outlined,
                color: Colors.white,
                size: fontSize > 28 ? 26 : 18,
              ),
            ),
            const SizedBox(width: 10),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: isPro
                    ? [const Color(0xFFFFFFFF), const Color(0xFFFFD54F), const Color(0xFFFFB300)]
                    : [const Color(0xFFFFFFFF), const Color(0xFFFF727A), const Color(0xFFE50914)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'KAP-APP',
                    style: AppTypography.display.copyWith(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.0,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: isPro ? Colors.amber.withOpacity(0.8) : AppColors.primary.withOpacity(0.8),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  if (isPro) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade800, Colors.amber.shade600],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'PRO 👑',
                        style: TextStyle(
                          fontSize: (fontSize * 0.45).clamp(10.0, 16.0),
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (showBadge) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isPro ? Colors.amber.withOpacity(0.15) : AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isPro ? Colors.amber.withOpacity(0.4) : AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              isPro ? 'PRO ÜYE — SINIRSIZ AI KULLANIMI 👑' : 'AKILLI EV & ALIŞVERİŞ ASİSTANI',
              style: AppTypography.labelSm.copyWith(
                color: isPro ? Colors.amber.shade300 : const Color(0xFFFF8A92),
                letterSpacing: 1.8,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
