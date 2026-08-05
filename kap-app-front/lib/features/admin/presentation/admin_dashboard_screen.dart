import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../auth/presentation/providers/auth_provider.dart';

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

  bool _isAdminChecked = false;
  bool _isAdminAuthorized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

      // 1. Record in Supabase database
      await client.from('push_notifications').insert({
        'title': title,
        'body': body,
        'status': 'sent',
        'sent_at': DateTime.now().toUtc().toIso8601String(),
        'created_by': currentUser?.id,
      });

      // 2. Instant 0-second Google FCM Push to ALL devices (open or closed!)
      const fcmKey = 'AIzaSyBFsCBCnESnkgw3LoYHqzZWBIZ1dE4-J-I';
      try {
        await http.post(
          Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'key=$fcmKey',
          },
          body: jsonEncode({
            'to': '/topics/all_users',
            'priority': 'high',
            'notification': {
              'title': title,
              'body': body,
              'sound': 'default',
            },
            'data': {
              'title': title,
              'body': body,
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            },
          }),
        );
      } catch (fcmError) {
        debugPrint('FCM direct push warning: $fcmError');
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Kap-App Web Admin Dashboard v2.0', style: AppTypography.headlineMd),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.secondary,
          tabs: const [
            Tab(icon: Icon(Icons.system_update), text: 'Sürüm Yayınla (OTA)'),
            Tab(icon: Icon(Icons.notifications_active), text: 'Bildirim Gönder'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Version Release
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🚀 Yeni APK Sürümü Yayınlama',
                  style: AppTypography.headlineLg.copyWith(color: AppColors.text, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Yüklediğiniz yeni APK sürümü tüm mobil kullanıcılarda uygulama içi diyalog olarak açılacaktır.',
                  style: AppTypography.bodyLg.copyWith(color: AppColors.secondary),
                ),
                const SizedBox(height: 24),
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
        ],
      ),
    );
  }
}
