import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'package:kap_app_front/features/admin/data/notification_admin_repository.dart';
import 'package:kap_app_front/features/admin/domain/models/scheduled_notification.dart';
import 'package:kap_app_front/core/services/notification_service.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Version Release Controllers
  final _versionCodeController = TextEditingController();
  final _versionNameController = TextEditingController();
  final _apkUrlController = TextEditingController();
  final _changelogController = TextEditingController();
  bool _isMandatory = false;
  bool _isReleasingVersion = false;

  // Push Notification Controllers
  final _notifTitleController = TextEditingController();
  final _notifBodyController = TextEditingController();
  bool _isSendingNotification = false;

  // Pro / Premium Management Controllers
  final _targetUserEmailController = TextEditingController();
  final _bonusCreditsController = TextEditingController(text: '0');
  bool _isGrantingPro = false;

  bool _isAdminChecked = false;
  bool _isAdminAuthorized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _verifyAdminAccess();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _versionCodeController.dispose();
    _versionNameController.dispose();
    _apkUrlController.dispose();
    _changelogController.dispose();
    _notifTitleController.dispose();
    _notifBodyController.dispose();
    _targetUserEmailController.dispose();
    _bonusCreditsController.dispose();
    super.dispose();
  }

  Future<void> _verifyAdminAccess() async {
    final client = Supabase.instance.client;
    final currentUser = client.auth.currentUser;

    if (currentUser == null) {
      setState(() {
        _isAdminChecked = true;
        _isAdminAuthorized = false;
      });
      return;
    }

    try {
      final res = await client
          .from('system_admins')
          .select('user_id')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      setState(() {
        _isAdminChecked = true;
        _isAdminAuthorized = res != null;
      });
    } catch (_) {
      setState(() {
        _isAdminChecked = true;
        _isAdminAuthorized = false;
      });
    }
  }

  Future<void> _releaseNewVersion() async {
    final code = int.tryParse(_versionCodeController.text.trim());
    final name = _versionNameController.text.trim();
    final url = _apkUrlController.text.trim();
    final changelog = _changelogController.text.trim();

    if (code == null || name.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen sürüm kodu, sürüm adı ve APK URL alanlarını eksiksiz doldurun.'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    setState(() => _isReleasingVersion = true);

    try {
      final client = Supabase.instance.client;
      final jwtToken = client.auth.currentSession?.accessToken;

      const backendUrl = String.fromEnvironment(
        'GO_BACKEND_URL',
        defaultValue: String.fromEnvironment(
          'BACKEND_URL',
          defaultValue: 'http://localhost:8080',
        ),
      );

      final resp = await http.post(
        Uri.parse('$backendUrl/api/v1/admin/app-version'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'version_code': code,
          'version_name': name,
          'apk_url': url,
          'changelog': changelog,
          'is_mandatory': _isMandatory,
        }),
      );

      if (!mounted) return;

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Yeni sürüm başarıyla yayınlandı!'),
            backgroundColor: Colors.teal,
          ),
        );
        _versionCodeController.clear();
        _versionNameController.clear();
        _apkUrlController.clear();
        _changelogController.clear();
        setState(() => _isMandatory = false);
      } else {
        final err = jsonDecode(resp.body)['error'] ?? 'Sunucu hatası';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $err'), backgroundColor: AppColors.primary),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: AppColors.primary),
      );
    } finally {
      if (mounted) setState(() => _isReleasingVersion = false);
    }
  }

  Future<void> _deleteVersion(String id) async {
    try {
      await Supabase.instance.client.from('app_versions').delete().eq('id', id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ Sürüm yayından kaldırıldı ve silindi.'),
          backgroundColor: Colors.teal,
        ),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: AppColors.primary),
      );
    }
  }

  Widget _buildVersionsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Supabase.instance.client
          .from('app_versions')
          .select('*')
          .order('version_code', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final list = snapshot.data!;
        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Henüz yayınlanmış bir sürüm yok.', style: TextStyle(color: Colors.white54)),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = list[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              item['version_name'] ?? 'v1.0.0',
                              style: AppTypography.headlineMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF242424),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('Code: ${item['version_code']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ),
                            if (item['is_mandatory'] == true) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('Zorunlu', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                        if (item['changelog'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              item['changelog'],
                              style: AppTypography.bodyLg.copyWith(color: AppColors.secondary),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                    tooltip: 'Yayından Kaldır / İptal Et',
                    onPressed: () => _deleteVersion(item['id']),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _sendNotification() async {
    final title = _notifTitleController.text.trim();
    final body = _notifBodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bildirim başlığı ve içeriğini doldurun.'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    setState(() => _isSendingNotification = true);

    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      final jwtToken = client.auth.currentSession?.accessToken;

      // 1. Record in Supabase database
      await client.from('push_notifications').insert({
        'title': title,
        'body': body,
        'status': 'sent',
        'sent_at': DateTime.now().toUtc().toIso8601String(),
        'created_by': currentUser?.id,
      });

      // 2. Dispatch via Go Backend (server-to-server, bypasses browser CORS)
      const backendUrl = String.fromEnvironment(
        'GO_BACKEND_URL',
        defaultValue: String.fromEnvironment(
          'BACKEND_URL',
          defaultValue: 'http://localhost:8080',
        ),
      );

      try {
        await http.post(
          Uri.parse('$backendUrl/api/v1/admin/push-notification'),
          headers: {
            'Authorization': 'Bearer $jwtToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'title': title,
            'body': body,
          }),
        );
      } catch (backendErr) {
        debugPrint('Go Backend push dispatch warning: $backendErr');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📢 Bildirim kapalı ve açık olan tüm kullanıcılara 0 saniyede gönderildi!'),
          backgroundColor: Colors.teal,
        ),
      );
      _notifTitleController.clear();
      _notifBodyController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: AppColors.primary),
      );
    } finally {
      if (mounted) setState(() => _isSendingNotification = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdminChecked) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (!_isAdminAuthorized) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Admin Paneli', style: AppTypography.headlineLg),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.gavel_rounded, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Erişim Engellendi (403 Forbidden)',
                style: AppTypography.headlineMd.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                'Bu alana sadece Yetkili Sistem Yöneticileri girebilir.',
                style: AppTypography.bodyLg.copyWith(color: AppColors.secondary),
              ),
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 480;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Kap-App Admin Dashboard v2.0', style: AppTypography.headlineMd),
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: isCompact,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.secondary,
          tabs: const [
            Tab(icon: Icon(Icons.system_update), text: 'Sürüm Yayınla (OTA)'),
            Tab(icon: Icon(Icons.notifications_active), text: 'Anlık Bildirim'),
            Tab(icon: Icon(Icons.alarm_on_rounded), text: 'Otomatik Hatırlatıcılar'),
            Tab(icon: Icon(Icons.workspace_premium_rounded), text: 'Pro / Premium Tanımla'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Version Release
          SingleChildScrollView(
            padding: EdgeInsets.all(isCompact ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🚀 Yeni APK Sürümü Yayınlama',
                  style: AppTypography.headlineLg.copyWith(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: isCompact ? 18 : 22),
                ),
                const SizedBox(height: 8),
                Text(
                  'Yüklediğiniz yeni APK sürümü tüm mobil kullanıcılarda uygulama içi diyalog olarak açılacaktır.',
                  style: AppTypography.bodyLg.copyWith(color: AppColors.secondary, fontSize: isCompact ? 12 : 14),
                ),
                const SizedBox(height: 24),
                if (isCompact) ...[
                  TextField(
                    controller: _versionCodeController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Sürüm Kodu (Örn: 102)',
                      labelStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Color(0xFF1F2022),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _versionNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Sürüm Adı (Örn: v2.1.0)',
                      labelStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Color(0xFF1F2022),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ] else
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _versionCodeController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Sürüm Kodu (Örn: 102)',
                            labelStyle: TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Color(0xFF1F2022),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _versionNameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Sürüm Adı (Örn: v2.1.0)',
                            labelStyle: TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Color(0xFF1F2022),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _apkUrlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'APK İndirme Bağlantısı (Supabase Storage veya CDN Linki)',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Color(0xFF1F2022),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _changelogController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Yenilikler / Değişiklik Notları (Changelog)',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Color(0xFF1F2022),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Zorunlu Güncelleme mi? (Mandatory Update)', style: TextStyle(color: Colors.white)),
                  value: _isMandatory,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _isMandatory = val ?? false),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isReleasingVersion ? null : _releaseNewVersion,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    icon: _isReleasingVersion
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.rocket_launch, color: Colors.white),
                    label: const Text('Yeni Sürümü Canlıya Al', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 36),
                const Divider(color: Color(0xFF242424)),
                const SizedBox(height: 16),
                Text(
                  '📋 Canlıdaki / Geçmiş Sürümler',
                  style: AppTypography.headlineLg.copyWith(color: AppColors.text, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'İptal etmek istediğiniz test sürümünün yanındaki çöp kutusu simgesine basarak yayından kaldırabilirsiniz.',
                  style: AppTypography.bodyLg.copyWith(color: AppColors.secondary),
                ),
                const SizedBox(height: 16),
                _buildVersionsList(),
              ],
            ),
          ),

          // Tab 2: Push Notifications
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📢 Toplu Bildirim Yayınlama',
                  style: AppTypography.headlineLg.copyWith(color: AppColors.text, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Uygulamayı kullanan tüm üyelere anlık bildirim gönderin.',
                  style: AppTypography.bodyLg.copyWith(color: AppColors.secondary),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _notifTitleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Bildirim Başlığı',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Color(0xFF1F2022),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notifBodyController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Bildirim Metni / İçeriği',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Color(0xFF1F2022),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSendingNotification ? null : _sendNotification,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    icon: _isSendingNotification
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: Colors.white),
                    label: const Text('Tüm Kullanıcılara Gönder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          // Tab 3: Scheduled Automated Notifications
          _buildScheduledNotificationsTab(),

          // Tab 4: Pro / Premium Management
          _buildProManagementTab(),
        ],
      ),
    );
  }

  Widget _buildScheduledNotificationsTab() {
    final scheduledAsync = ref.watch(scheduledNotificationsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⏰ Günlük Otomatik Hatırlatıcılar',
                      style: AppTypography.headlineLg.copyWith(color: AppColors.text, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Her gün belirli saatlerde kullanıcılara otomatik gönderilecek bildirimler.',
                      style: AppTypography.bodyLg.copyWith(color: AppColors.secondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _showAddScheduledNotificationDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.add_alarm_rounded, color: Colors.white),
                label: const Text('Yeni Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          scheduledAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (err, _) => Center(child: Text('Hata: $err', style: const TextStyle(color: Colors.red))),
            data: (list) {
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Henüz tanımlanmış otomatik hatırlatıcı yok.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = list[index];
                  final icon = item.notificationType == 'water'
                      ? Icons.water_drop_rounded
                      : item.notificationType == 'market'
                          ? Icons.shopping_cart_rounded
                          : item.notificationType == 'nutrition'
                              ? Icons.restaurant_rounded
                              : Icons.notifications_active_rounded;

                  final color = item.notificationType == 'water'
                      ? Colors.cyanAccent
                      : item.notificationType == 'market'
                          ? Colors.orangeAccent
                          : item.notificationType == 'nutrition'
                              ? Colors.lightGreenAccent
                              : AppColors.primary;

                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2022),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: item.isActive ? color.withValues(alpha: 0.4) : Colors.white12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.15),
                        child: Icon(icon, color: color),
                      ),
                      title: Row(
                        children: [
                          Text(
                            item.title,
                            style: AppTypography.bodyLg.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '🕒 ${item.scheduledTime.substring(0, 5)}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          item.body,
                          style: AppTypography.bodyMd.copyWith(color: AppColors.secondary),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: item.isActive,
                            activeThumbColor: color,
                            onChanged: (val) async {
                              await ref
                                  .read(notificationAdminRepositoryProvider)
                                  .toggleNotificationStatus(item.id, val);
                              ref.invalidate(scheduledNotificationsProvider);
                              ref.read(notificationServiceProvider).syncScheduledNotifications();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                            onPressed: () async {
                              await ref
                                  .read(notificationAdminRepositoryProvider)
                                  .deleteScheduledNotification(item.id);
                              ref.invalidate(scheduledNotificationsProvider);
                              ref.read(notificationServiceProvider).syncScheduledNotifications();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddScheduledNotificationDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final timeController = TextEditingController(text: '12:00');
    String selectedType = 'water';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text('⏰ Yeni Otomatik Hatırlatıcı Ekle', style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Bildirim Başlığı (Örn: 💧 Su İçme Zamanı!)',
                        labelStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Color(0xFF2C2C2E),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bodyController,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Mesaj İçeriği',
                        labelStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Color(0xFF2C2C2E),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: timeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Her Gün Çalma Saati (HH:mm formatı)',
                        hintText: '12:00 veya 17:30',
                        labelStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Color(0xFF2C2C2E),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      dropdownColor: const Color(0xFF2C2C2E),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Kategori / Tür',
                        labelStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Color(0xFF2C2C2E),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'water', child: Text('💧 Su Hatırlatıcısı')),
                        DropdownMenuItem(value: 'market', child: Text('🛒 Market Hatırlatıcısı')),
                        DropdownMenuItem(value: 'nutrition', child: Text('🥗 Beslenme Hatırlatıcısı')),
                        DropdownMenuItem(value: 'custom', child: Text('🔔 Genel Duyuru / Özel')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedType = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final body = bodyController.text.trim();
                    var timeStr = timeController.text.trim();
                    if (title.isEmpty || body.isEmpty || timeStr.isEmpty) return;

                    if (!timeStr.contains(':')) timeStr = '12:00';
                    if (timeStr.split(':').length == 2) timeStr = '$timeStr:00';

                    final notification = ScheduledNotification(
                      id: '',
                      title: title,
                      body: body,
                      scheduledTime: timeStr,
                      isActive: true,
                      notificationType: selectedType,
                    );

                    await ref
                        .read(notificationAdminRepositoryProvider)
                        .saveScheduledNotification(notification);

                    ref.invalidate(scheduledNotificationsProvider);
                    ref.read(notificationServiceProvider).syncScheduledNotifications();

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Kaydet ve Zamanla', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _grantProStatus(bool isPro) async {
    final email = _targetUserEmailController.text.trim();
    final bonus = int.tryParse(_bonusCreditsController.text.trim()) ?? 0;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen kullanıcının E-posta adresini veya UUID\'sini girin.'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    setState(() => _isGrantingPro = true);

    try {
      final client = Supabase.instance.client;
      final jwtToken = client.auth.currentSession?.accessToken;

      const backendUrl = String.fromEnvironment(
        'GO_BACKEND_URL',
        defaultValue: String.fromEnvironment(
          'BACKEND_URL',
          defaultValue: 'http://localhost:8080',
        ),
      );

      final resp = await http.post(
        Uri.parse('$backendUrl/api/v1/admin/user-pro'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_email': email,
          'is_pro': isPro,
          'bonus_credits': bonus,
        }),
      );

      if (!mounted) return;

      if (resp.statusCode == 200) {
        final msg = isPro
            ? '👑 Kullanıcıya Pro üyelik başarıyla tanımlandı!'
            : 'ℹ️ Kullanıcı Pro üyelikten çıkarıldı (Ücretsiz mod).';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: isPro ? Colors.amber.shade800 : Colors.teal,
          ),
        );
        _targetUserEmailController.clear();
      } else {
        final err = jsonDecode(resp.body)['error'] ?? 'İşlem başarısız';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $err'), backgroundColor: AppColors.primary),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: AppColors.primary),
      );
    } finally {
      if (mounted) setState(() => _isGrantingPro = false);
    }
  }

  Widget _buildProManagementTab() {
    final isCompact = MediaQuery.of(context).size.width < 480;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade900.withOpacity(0.8), Colors.amber.shade700.withOpacity(0.9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_rounded, size: 40, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Kap-App Pro / Premium Yönetimi 👑',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'İstediğiniz kullanıcıya anında sınırsız AI erişimi (Pro) tanımlayabilir veya ücretsiz moda alabilirsiniz.',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('Kullanıcı Bilgileri', style: AppTypography.headlineLg.copyWith(fontSize: 18)),
          const SizedBox(height: 12),

          TextField(
            controller: _targetUserEmailController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Kullanıcı E-Posta Adresi veya UUID',
              hintText: 'ornek@email.com veya UUID',
              labelStyle: TextStyle(color: Colors.white70),
              prefixIcon: Icon(Icons.email_outlined, color: Colors.white70),
              filled: true,
              fillColor: Color(0xFF1F2022),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _bonusCreditsController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Ekstra Bonus Hak Ekle (Opsiyonel)',
              hintText: '0',
              labelStyle: TextStyle(color: Colors.white70),
              prefixIcon: Icon(Icons.stars_rounded, color: Colors.amber),
              filled: true,
              fillColor: Color(0xFF1F2022),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          if (_isGrantingPro)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _grantProStatus(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.workspace_premium_rounded, color: Colors.white),
                label: const Text(
                  '👑 Pro Üyelik Tanımla (Aktif Et)',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _grantProStatus(false),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent),
                label: const Text(
                  '❌ Pro Üyeliği İptal Et (Ücretsiz Moda Al)',
                  style: TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
