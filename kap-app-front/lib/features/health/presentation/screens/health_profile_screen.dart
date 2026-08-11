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
  late TextEditingController _waterIntakeController;
  late TextEditingController _bodyFatController;

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
    _waterIntakeController = TextEditingController();
    _bodyFatController = TextEditingController();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _waterIntakeController.dispose();
    _bodyFatController.dispose();
    super.dispose();
  }

  void _populateData(HealthProfileData profile) {
    if (_isInitialized) return;
    _weightController.text = profile.weight > 0 ? profile.weight.toStringAsFixed(1) : '70.0';
    _heightController.text = profile.height > 0 ? profile.height.toStringAsFixed(0) : '170';
    _ageController.text = profile.age > 0 ? profile.age.toString() : '25';
    _waterIntakeController.text = profile.dailyWaterIntakeLiters > 0 ? profile.dailyWaterIntakeLiters.toStringAsFixed(1) : '2.5';
    _bodyFatController.text = profile.bodyFatPercentage > 0 ? profile.bodyFatPercentage.toStringAsFixed(1) : '20.0';
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
    final waterIntake = double.tryParse(_waterIntakeController.text.trim()) ?? 2.5;
    final bodyFat = double.tryParse(_bodyFatController.text.trim()) ?? 20.0;

    setState(() => _isSaving = true);

    final updated = HealthProfileData(
      weight: weight,
      height: height,
      age: age,
      gender: _gender,
      activityLevel: _activityLevel,
      goal: _goal,
      isPublic: _isPublic,
      dailyWaterIntakeLiters: waterIntake,
      bodyFatPercentage: bodyFat,
    );

    try {
      await ref.read(healthProfileRepositoryProvider).saveHealthProfile(updated);
      ref.invalidate(healthProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kişisel sağlık profiliniz başarıyla güncellendi!'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
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
        error: (err, stack) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        data: (profile) {
          _populateData(profile);

          final currentWeight = double.tryParse(_weightController.text.trim()) ?? profile.weight;
          final currentHeight = double.tryParse(_heightController.text.trim()) ?? profile.height;
          final currentAge = int.tryParse(_ageController.text.trim()) ?? profile.age;
          final currentWater = double.tryParse(_waterIntakeController.text.trim()) ?? profile.dailyWaterIntakeLiters;
          final currentFat = double.tryParse(_bodyFatController.text.trim()) ?? profile.bodyFatPercentage;

          final calculatedProfile = HealthProfileData(
            weight: currentWeight,
            height: currentHeight,
            age: currentAge,
            gender: _gender,
            activityLevel: _activityLevel,
            goal: _goal,
            isPublic: _isPublic,
            dailyWaterIntakeLiters: currentWater,
            bodyFatPercentage: currentFat,
          );

          final macros = FitnessCalculator.calculateAll(calculatedProfile);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Macro Summary Card (Responsive Grid Layout)
                Container(
                  padding: const EdgeInsets.all(18),
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
                      // Target Calories Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Günlük Hedef Kalori',
                                style: AppTypography.labelLg.copyWith(color: AppColors.textMuted),
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
                              style: AppTypography.labelLg.copyWith(
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

                      // Energy Row: BMR & TDEE
                      Row(
                        children: [
                          Expanded(
                            child: _buildEnergyCard('BMR (Metabolizma)', '${macros.bmr} kcal', Icons.local_fire_department, Colors.orange),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildEnergyCard('TDEE (Harcanan)', '${macros.tdee} kcal', Icons.bolt, Colors.blue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Nutrients Row: Protein, Carbs, Fat
                      Row(
                        children: [
                          Expanded(
                            child: _buildNutrientCard('Protein', '${macros.proteinGrams}g', Colors.redAccent),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildNutrientCard('Karbonhidrat', '${macros.carbGrams}g', Colors.green),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildNutrientCard('Yağ', '${macros.fatGrams}g', Colors.amber),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Hydration & Body Fat Analysis Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildEnergyCard(
                              'Su Tüketimi (Hedef)',
                              '${calculatedProfile.dailyWaterIntakeLiters}L / ${macros.recommendedWaterLiters}L',
                              Icons.water_drop_rounded,
                              Colors.cyanAccent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildEnergyCard(
                              'Vücut Yağ Durumu',
                              '%${calculatedProfile.bodyFatPercentage} (${macros.bodyFatCategory})',
                              Icons.pie_chart_rounded,
                              Colors.amberAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Vücut Ölçülerim & Hedeflerim',
                  style: AppTypography.headlineMd.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 16),

                // Form Fields (Kilo, Boy, Yaş)
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(_weightController, 'Kilo (kg)', TextInputType.number),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(_heightController, 'Boy (cm)', TextInputType.number),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(_ageController, 'Yaş', TextInputType.number),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // New Form Fields: Ort. Su Tüketimi (Litre) & Yağ Oranı (%)
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        _waterIntakeController,
                        'Günlük Su (Litre)',
                        const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: Icons.water_drop_rounded,
                        prefixColor: Colors.cyanAccent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        _bodyFatController,
                        'Yağ Oranı (%)',
                        const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: Icons.pie_chart_rounded,
                        prefixColor: Colors.amberAccent,
                      ),
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
                        selectedColor: AppColors.primary.withValues(alpha: 0.25),
                        backgroundColor: const Color(0xFF1E1E1E),
                        labelStyle: TextStyle(
                          color: _gender == 'male' ? AppColors.primary : Colors.white70,
                          fontWeight: _gender == 'male' ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) => setState(() => _gender = 'male'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Kadın 👩')),
                        selected: _gender == 'female',
                        selectedColor: AppColors.primary.withValues(alpha: 0.25),
                        backgroundColor: const Color(0xFF1E1E1E),
                        labelStyle: TextStyle(
                          color: _gender == 'female' ? AppColors.primary : Colors.white70,
                          fontWeight: _gender == 'female' ? FontWeight.bold : FontWeight.normal,
                        ),
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
                  initialValue: _activityLevel,
                  dropdownColor: const Color(0xFF2C2C2E),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Color(0xFF1E1E1E),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'sedentary', child: Text('Hareketsiz (Masa başı iş)', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'light', child: Text('Hafif Aktif (Haftada 1-3 gün egzersiz)', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'moderate', child: Text('Orta Aktif (Haftada 3-5 gün egzersiz)', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'active', child: Text('Çok Aktif (Haftada 6-7 gün egzersiz)', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'very-active', child: Text('Fiziksel İş / Ağır Antrenman', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _activityLevel = val);
                  },
                ),
                const SizedBox(height: 16),

                // Goal Selection (Responsive Wrap)
                Text('Ana Hedef', style: AppTypography.labelLg.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildGoalChip('lose', '🏃‍♂️ Kilo Verme'),
                    _buildGoalChip('maintain', '🧘‍♀️ Form Koruma'),
                    _buildGoalChip('gain', '🏋️‍♂️ Kilo Alma'),
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
                    activeThumbColor: AppColors.primary,
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
                  height: 52,
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
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGoalChip(String goalKey, String label) {
    final isSelected = _goal == goalKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary.withValues(alpha: 0.25),
      backgroundColor: const Color(0xFF1E1E1E),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => setState(() => _goal = goalKey),
    );
  }

  Widget _buildEnergyCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(color: Colors.white60, fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    TextInputType keyboard, {
    IconData? prefixIcon,
    Color? prefixColor,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: prefixColor ?? AppColors.primary, size: 18) : null,
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
