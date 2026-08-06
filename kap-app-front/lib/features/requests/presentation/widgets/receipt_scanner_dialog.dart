import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';

class ReceiptScannerDialog extends StatefulWidget {
  final List<String> currentItems;

  const ReceiptScannerDialog({
    super.key,
    required this.currentItems,
  });

  @override
  State<ReceiptScannerDialog> createState() => _ReceiptScannerDialogState();
}

class _ReceiptScannerDialogState extends State<ReceiptScannerDialog> {
  bool _isScanning = false;
  Map<String, dynamic>? _scanResult;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      await _processReceiptImage(base64Image);
    } catch (e) {
      setState(() {
        _errorMessage = 'Görsel seçme hatası: $e';
      });
    }
  }

  Future<void> _processReceiptImage(String base64Image) async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    try {
      const backendUrl = String.fromEnvironment(
        'GO_BACKEND_URL',
        defaultValue: String.fromEnvironment(
          'BACKEND_URL',
          defaultValue: 'http://localhost:8080',
        ),
      );

      final jwtToken = Supabase.instance.client.auth.currentSession?.accessToken;

      final response = await http.post(
        Uri.parse('$backendUrl/api/v1/ai/scan-receipt'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'base64_image': base64Image,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _scanResult = data;
        });
      } else {
        final errData = jsonDecode(response.body);
        setState(() {
          _errorMessage = errData['error'] ?? 'Fiş okunamadı';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Bağlantı hatası: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.receipt_long, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Fiş Tara (AI)', style: AppTypography.headlineLg),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isScanning) ...[
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Gemini AI fişinizi inceliyor...\nÜrünler ve fiyatlar ayıklanıyor.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd,
              ),
            ] else if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => setState(() => _errorMessage = null),
                child: const Text('Tekrar Dene'),
              ),
            ] else if (_scanResult != null) ...[
              Text(
                'Mağaza: ${_scanResult!['store_name'] ?? 'Bilinmeyen Market'}',
                style: AppTypography.labelLg.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Toplam Tutar: ${_scanResult!['total'] ?? 0} TL',
                style: AppTypography.headlineMd.copyWith(color: Colors.teal),
              ),
              const Divider(),
              const SizedBox(height: 8),
              ...?(_scanResult!['items'] as List<dynamic>?)?.map((item) {
                return ListTile(
                  dense: true,
                  title: Text(item['name'] ?? '', style: AppTypography.bodyMd),
                  trailing: Text(
                    '${item['price']} TL',
                    style: AppTypography.labelLg.copyWith(fontWeight: FontWeight.bold),
                  ),
                );
              }),
            ] else ...[
              Text(
                'Fiş fotoğrafını yükleyin. AI ürünleri ve fiyatları tespit edip veri havuzuna işleyecektir.\n\n🔒 Fiş görselleri sunucuda saklanmaz (RAM-only).',
                style: AppTypography.bodyMd.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Kamera'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galeri'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Kapat'),
        ),
      ],
    );
  }
}
