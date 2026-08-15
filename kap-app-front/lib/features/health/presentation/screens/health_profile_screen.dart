import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kap_app_front/l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../../shared/utils/fitness_calculator.dart';
import '../../../../shared/utils/food_database.dart';
import '../../data/health_profile_repository.dart';

class HealthProfileScreen extends ConsumerStatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  ConsumerState<HealthProfileScreen> createState() =>
      _HealthProfileScreenState();
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
  String _fitnessGoal = 'balanced';
  bool _hasKidneyDisease = false;
  List<String> _allergens = [];
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
    _weightController.text =
        profile.weight > 0 ? profile.weight.toStringAsFixed(1) : '70.0';
    _heightController.text =
        profile.height > 0 ? profile.height.toStringAsFixed(0) : '170';
    _ageController.text =
        profile.age > 0 ? profile.age.toString() : '25';
    _waterIntakeController.text = profile.dailyWaterIntakeLiters > 0
        ? profile.dailyWaterIntakeLiters.toStringAsFixed(1)
        : '2.5';
    _bodyFatController.text = profile.bodyFatPercentage > 0
        ? profile.bodyFatPercentage.toStringAsFixed(1)
        : '20.0';
    _gender = profile.gender;
    _activityLevel = profile.activityLevel;
    _goal = profile.goal;
    _fitnessGoal = profile.fitnessGoal;
    _hasKidneyDisease = profile.hasKidneyDisease;
    _allergens = List.from(profile.allergens);
    _isPublic = profile.isPublic;
    _isInitialized = true;
  }

  Future<void> _saveProfile() async {
    final localizations = AppLocalizations.of(context)!;
    final weight = double.tryParse(_weightController.text.trim()) ?? 70.0;
    final height = double.tryParse(_heightController.text.trim()) ?? 170.0;
    final age = int.tryParse(_ageController.text.trim()) ?? 25;
    final waterIntake =
        double.tryParse(_waterIntakeController.text.trim()) ?? 2.5;
    final bodyFat =
        double.tryParse(_bodyFatController.text.trim()) ?? 20.0;

    setState(() => _isSaving = true);

    final updated = HealthProfileData(
      weight: weight,
      height: height,
      age: age,
      gender: _gender,
      activityLevel: _activityLevel,
      goal: _goal,
      fitnessGoal: _fitnessGoal,
      hasKidneyDisease: _hasKidneyDisease,
      allergens: _allergens,
      isPublic: _isPublic,
      dailyWaterIntakeLiters: waterIntake,
      bodyFatPercentage: bodyFat,
    );

    try {
      await ref
          .read(healthProfileRepositoryProvider)
          .saveHealthProfile(updated);
      ref.invalidate(healthProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.health_save_success),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.health_save_error(e.toString())),
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
    final localizations = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(healthProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          localizations.health_title,
          style: AppTypography.headlineMd.copyWith(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: profileAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        data: (profile) {
          _populateData(profile);

          final currentWeight =
              double.tryParse(_weightController.text.trim()) ?? profile.weight;
          final currentHeight =
              double.tryParse(_heightController.text.trim()) ?? profile.height;
          final currentAge =
              int.tryParse(_ageController.text.trim()) ?? profile.age;
          final currentWater =
              double.tryParse(_waterIntakeController.text.trim()) ??
                  profile.dailyWaterIntakeLiters;
          final currentFat =
              double.tryParse(_bodyFatController.text.trim()) ??
                  profile.bodyFatPercentage;

          final calculatedProfile = HealthProfileData(
            weight: currentWeight,
            height: currentHeight,
            age: currentAge,
            gender: _gender,
            activityLevel: _activityLevel,
            goal: _goal,
            fitnessGoal: _fitnessGoal,
            hasKidneyDisease: _hasKidneyDisease,
            allergens: _allergens,
            isPublic: _isPublic,
            dailyWaterIntakeLiters: currentWater,
            bodyFatPercentage: currentFat,
          );

          final macros = FitnessCalculator.calculateAll(calculatedProfile);
          final foodRecommendations =
              FoodDatabase.getRecommendationsForGoal(
                  _fitnessGoal, _allergens);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Calorie Floor Warning Banner (Guardrail 1)
                if (macros.isCalorieFloorApplied) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.redAccent, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            localizations.health_calorie_floor_warning(
                              _gender == 'female' ? 1200 : 1500,
                            ),
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Macro Summary Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
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
                                localizations.health_daily_target_calories,
                                style: AppTypography.labelLg
                                    .copyWith(color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${macros.targetCalories} ${localizations.health_kcal_unit}',
                                style: AppTypography.headlineLg.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _goal == 'lose'
                                  ? localizations.health_goal_lose
                                  : _goal == 'gain'
                                      ? localizations.health_goal_gain
                                      : localizations.health_goal_maintain,
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
                            child: _buildEnergyCard(
                              localizations.health_bmr_label,
                              '${macros.bmr} ${localizations.health_kcal_unit}',
                              Icons.local_fire_department,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildEnergyCard(
                              localizations.health_tdee_label,
                              '${macros.tdee} ${localizations.health_kcal_unit}',
                              Icons.bolt,
                              Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Nutrients Row: Protein, Carbs, Fat
                      Row(
                        children: [
                          Expanded(
                            child: _buildNutrientCard(
                              localizations.health_protein_label,
                              '${macros.proteinGrams}g (${macros.proteinPct}%)',
                              Colors.redAccent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildNutrientCard(
                              localizations.health_carbs_label,
                              '${macros.carbGrams}g (${macros.carbPct}%)',
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildNutrientCard(
                              localizations.health_fat_label,
                              '${macros.fatGrams}g (${macros.fatPct}%)',
                              Colors.amber,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Sub-info Chips: Protein/kg & Model
                      Row(
                        children: [
                          Expanded(
                            child: _buildEnergyCard(
                              localizations.health_protein_per_kg_label,
                              localizations.health_protein_per_kg_value(
                                macros.proteinPerKg.toStringAsFixed(1),
                              ),
                              Icons.fitness_center_rounded,
                              Colors.purpleAccent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildEnergyCard(
                              localizations.health_macro_model_label,
                              macros.macroDistributionLabel,
                              Icons.pie_chart_rounded,
                              Colors.tealAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Hydration & Body Fat Analysis Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildEnergyCard(
                              localizations.health_water_target_label,
                              '${calculatedProfile.dailyWaterIntakeLiters}L / ${macros.recommendedWaterLiters}L',
                              Icons.water_drop_rounded,
                              Colors.cyanAccent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildEnergyCard(
                              localizations.health_body_fat_label,
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

                // Recommended Foods Section (Guardrail 3)
                Text(
                  localizations.health_recommended_foods_title,
                  style: AppTypography.headlineMd.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                ...foodRecommendations.entries.map((entry) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: entry.value.map((food) {
                            return Chip(
                              label: Text(
                                food.name,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11),
                              ),
                              backgroundColor: const Color(0xFF2C2C2E),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 0),
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),

                Text(
                  localizations.health_body_measurements_title,
                  style: AppTypography.headlineMd.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 16),

                // Form Fields (Kilo, Boy, Yaş)
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                          _weightController,
                          localizations.health_weight_label,
                          TextInputType.number),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                          _heightController,
                          localizations.health_height_label,
                          TextInputType.number),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                          _ageController,
                          localizations.health_age_label,
                          TextInputType.number),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Su Tüketimi (Litre) & Yağ Oranı (%)
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        _waterIntakeController,
                        localizations.health_daily_water_label,
                        const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: Icons.water_drop_rounded,
                        prefixColor: Colors.cyanAccent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        _bodyFatController,
                        localizations.health_body_fat_pct_label,
                        const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: Icons.pie_chart_rounded,
                        prefixColor: Colors.amberAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Gender Selection
                Text(localizations.health_gender_label,
                    style: AppTypography.labelLg
                        .copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Center(
                            child: Text(localizations.health_gender_male)),
                        selected: _gender == 'male',
                        selectedColor:
                            AppColors.primary.withValues(alpha: 0.25),
                        backgroundColor: const Color(0xFF1E1E1E),
                        labelStyle: TextStyle(
                          color: _gender == 'male'
                              ? AppColors.primary
                              : Colors.white70,
                          fontWeight: _gender == 'male'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        onSelected: (_) => setState(() => _gender = 'male'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: Center(
                            child: Text(localizations.health_gender_female)),
                        selected: _gender == 'female',
                        selectedColor:
                            AppColors.primary.withValues(alpha: 0.25),
                        backgroundColor: const Color(0xFF1E1E1E),
                        labelStyle: TextStyle(
                          color: _gender == 'female'
                              ? AppColors.primary
                              : Colors.white70,
                          fontWeight: _gender == 'female'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        onSelected: (_) => setState(() => _gender = 'female'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Activity Level Dropdown
                Text(localizations.health_activity_level_label,
                    style: AppTypography.labelLg
                        .copyWith(color: AppColors.textMuted)),
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
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  items: [
                    DropdownMenuItem(
                        value: 'sedentary',
                        child: Text(localizations.health_activity_sedentary,
                            overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(
                        value: 'light',
                        child: Text(localizations.health_activity_light,
                            overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(
                        value: 'moderate',
                        child: Text(localizations.health_activity_moderate,
                            overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(
                        value: 'active',
                        child: Text(localizations.health_activity_active,
                            overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(
                        value: 'very-active',
                        child: Text(localizations.health_activity_very_active,
                            overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _activityLevel = val);
                  },
                ),
                const SizedBox(height: 16),

                // Nutrition Model (Fitness Goal) Selection
                Text(localizations.health_fitness_goal_label,
                    style: AppTypography.labelLg
                        .copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Column(
                  children: [
                    _buildFitnessGoalTile(
                      'muscle_building',
                      localizations.health_fitness_muscle,
                    ),
                    const SizedBox(height: 8),
                    _buildFitnessGoalTile(
                      'fat_loss_keto',
                      localizations.health_fitness_keto,
                    ),
                    const SizedBox(height: 8),
                    _buildFitnessGoalTile(
                      'balanced',
                      localizations.health_fitness_balanced,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Main Goal Selection
                Text(localizations.health_main_goal_label,
                    style: AppTypography.labelLg
                        .copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildGoalChip('lose', localizations.health_goal_lose),
                    _buildGoalChip(
                        'maintain', localizations.health_goal_maintain),
                    _buildGoalChip('gain', localizations.health_goal_gain),
                  ],
                ),
                const SizedBox(height: 24),

                // Kidney Disease Switch Tile (Guardrail 2)
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _hasKidneyDisease
                          ? Colors.orange.withValues(alpha: 0.5)
                          : Colors.white12,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: SwitchListTile(
                      activeThumbColor: Colors.orangeAccent,
                      title: Text(
                        localizations.health_kidney_disease_title,
                        style: AppTypography.bodyLg
                            .copyWith(color: Colors.white),
                      ),
                      subtitle: Text(
                        localizations.health_kidney_disease_subtitle,
                        style: AppTypography.bodyMd
                            .copyWith(color: AppColors.textMuted),
                      ),
                      value: _hasKidneyDisease,
                      onChanged: (val) =>
                          setState(() => _hasKidneyDisease = val),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Allergen FilterChips (Guardrail 3)
                Text(localizations.health_allergen_title,
                    style: AppTypography.labelLg
                        .copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text(
                  localizations.health_allergen_subtitle,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: FoodDatabase.availableAllergens.map((allergen) {
                    final isSelected = _allergens.contains(allergen.key);
                    return FilterChip(
                      avatar: Text(allergen.emoji),
                      label: Text('${allergen.label} (${allergen.key})'),
                      selected: isSelected,
                      selectedColor: Colors.redAccent.withValues(alpha: 0.25),
                      backgroundColor: const Color(0xFF1E1E1E),
                      side: BorderSide(
                        color: isSelected ? Colors.redAccent : Colors.white12,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.redAccent : Colors.white70,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _allergens.add(allergen.key);
                          } else {
                            _allergens.remove(allergen.key);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Privacy Switch Tile
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: SwitchListTile(
                      activeThumbColor: AppColors.primary,
                      title: Text(
                        localizations.health_share_with_group_title,
                        style: AppTypography.bodyLg
                            .copyWith(color: Colors.white),
                      ),
                      subtitle: Text(
                        localizations.health_share_with_group_subtitle,
                        style: AppTypography.bodyMd
                            .copyWith(color: AppColors.textMuted),
                      ),
                      value: _isPublic,
                      onChanged: (val) => setState(() => _isPublic = val),
                    ),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(
                            color: Colors.white)
                        : Text(
                            localizations.health_save_button,
                            style: AppTypography.bodyLg.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
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

  Widget _buildFitnessGoalTile(String goalKey, String label) {
    final isSelected = _fitnessGoal == goalKey;
    return GestureDetector(
      onTap: () => setState(() => _fitnessGoal = goalKey),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white12,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : Colors.white,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
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

  Widget _buildEnergyCard(
      String title, String value, IconData icon, Color color) {
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
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
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
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
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
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon,
                color: prefixColor ?? AppColors.primary, size: 18)
            : null,
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
