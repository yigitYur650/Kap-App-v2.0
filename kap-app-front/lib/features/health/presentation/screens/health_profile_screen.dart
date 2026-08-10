import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../../shared/utils/fitness_calculator.dart';
import '../../data/health_profile_repository.dart';

class HealthProfileScreen extends ConsumerStatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  ConsumerState<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends ConsumerState<HealthProfileScreen> {
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _ageController;

  String _gender = 'male';
  String _activityLevel = 'moderate';
  String _goal = 'maintain';
  bool _isPublic = true;
  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController();
    _heightController = TextEditingController();
    _ageController = TextEditingController();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _populateData(HealthProfileData profile) {
    if (_isInitialized) return;
    _weightController.text = profile.weight.toStringAsFixed(1);
    _heightController.text = profile.height.toStringAsFixed(0);
    _ageController.text = profile.age.toString();
    _gender = profile.gender;
    _activityLevel = profile.activityLevel;
    _goal = profile.goal;
    _isPublic = profile.isPublic;
    _isInitialized = true;
  }

  Future<void> _saveProfile() async {
    final weight = double.tryParse(_weightController.text.trim()) ?? 70.0;
    final height = double.tryParse(_heightController.text.trim()) ?? 170.0;
    final age = int.tryParse(_ageController.text.trim()) ?? 25;

    setState(() => _isSaving = true);

    final updated = HealthProfileData(
      weight: weight,
      height: height,
      age: age,
      gender: _gender,
      activityLevel: _activityLevel,
      goal: _goal,
      isPublic: _isPublic,
    );

    try {
      await ref.read(healthProfileRepositoryProvider).saveHealthProfile(updated);
      ref.invalidate(healthProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kişisel sağlık profiliniz başarıyla güncellendi!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(healthProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Kişisel Beslenme & Fitness',
          style: AppTypography.headlineMd.copyWith(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text('Hata: $err', style: const TextStyle(color: Colors.white))),
        data: (profile) {
          _populateData(profile);

          final currentWeight = double.tryParse(_weightController.text.trim()) ?? profile.weight;
          final currentHeight = double.tryParse(_heightController.text.trim()) ?? profile.height;
          final currentAge = int.tryParse(_ageController.text.trim()) ?? profile.age;

          final calculatedProfile = HealthProfileData(
            weight: currentWeight,
            height: currentHeight,
            age: currentAge,
            gender: _gender,
            activityLevel: _activityLevel,
            goal: _goal,
            isPublic: _isPublic,
          );

          final macros = FitnessCalculator.calculateAll(calculatedProfile);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Macro Summary Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Günlük Kalori Hedefi',
                                style: AppTypography.labelSm.copyWith(color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${macros.targetCalories} kcal',
                                style: AppTypography.headlineLg.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _goal == 'lose'
                                  ? '🏃‍♂️ Kilo Verme'
                                  : _goal == 'gain'
                                      ? '🏋️‍♂️ Kilo Alma'
                                      : '🧘‍♀️ Form Koruma',
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMacroItem('BMR (Metabolizma)', '${macros.bmr}', 'kcal', Colors.orange),
                          _buildMacroItem('TDEE (Harcanan)', '${macros.tdee}', 'kcal', Colors.blue),
                          _buildMacroItem('Protein', '${macros.proteinGrams}', 'g', Colors.redAccent),
                          _buildMacroItem('Karbonhidrat', '${macros.carbGrams}', 'g', Colors.green),
                          _buildMacroItem('Yağ', '${macros.fatGrams}', 'g', Colors.amber),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Vücut Ölçülerim & Hedeflerim',
                  style: AppTypography.titleLg.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 16),

                // Form Fields
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(_weightController, 'Kilo (kg)', TextInputType.number),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(_heightController, 'Boy (cm)', TextInputType.number),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(_ageController, 'Yaş', TextInputType.number),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Gender Selection
                Text('Cinsiyet', style: AppTypography.labelLg.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Erkek 👨')),
                        selected: _gender == 'male',
                        onSelected: (_) => setState(() => _gender = 'male'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Kadın 👩')),
                        selected: _gender == 'female',
                        onSelected: (_) => setState(() => _gender = 'female'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Activity Level Dropdown
                Text('Günlük Hareket Seviyesi', style: AppTypography.labelLg.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _activityLevel,
                  dropdownColor: const Color(0xFF2C2C2E),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Color(0xFF1E1E1E),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'sedentary', child: Text('Hareketsiz (Masa başı iş)')),
                    DropdownMenuItem(value: 'light', child: Text('Hafif Aktif (Haftada 1-3 gün egzersiz)')),
                    DropdownMenuItem(value: 'moderate', child: Text('Orta Aktif (Haftada 3-5 gün egzersiz)')),
                    DropdownMenuItem(value: 'active', child: Text('Çok Aktif (Haftada 6-7 gün egzersiz)')),
                    DropdownMenuItem(value: 'very-active', child: Text('Fiziksel İş / Ağır Antrenman')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _activityLevel = val);
                  },
                ),
                const SizedBox(height: 16),

                // Goal Selection
                Text('Ana Hedef', style: AppTypography.labelLg.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Kilo Verme'),
                        selected: _goal == 'lose',
                        onSelected: (_) => setState(() => _goal = 'lose'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Form Koruma'),
                        selected: _goal == 'maintain',
                        onSelected: (_) => setState(() => _goal = 'maintain'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Kilo Alma'),
                        selected: _goal == 'gain',
                        onSelected: (_) => setState(() => _goal = 'gain'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Privacy Switch Tile
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: SwitchListTile(
                    activeColor: AppColors.primary,
                    title: Text(
                      'Grup Arkadaşlarıyla Paylaş',
                      style: AppTypography.bodyLg.copyWith(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Seçeneği açarsanız gruptaki üyeler beslenme ilerlemenizi görebilir.',
                      style: AppTypography.bodyMd.copyWith(color: AppColors.textMuted),
                    ),
                    value: _isPublic,
                    onChanged: (val) => setState(() => _isPublic = val),
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Kişisel Bilgileri Kaydet',
                            style: AppTypography.bodyLg.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMacroItem(String label, String val, String unit, Color color) {
    return Column(
      children: [
        Text(
          val,
          style: AppTypography.headlineMd.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
        Text(
          unit,
          style: AppTypography.labelSm.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, TextInputType keyboard) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
