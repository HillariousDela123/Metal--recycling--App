import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/helpers.dart';
import '../../models/service_model.dart';
import '../../viewmodels/auth_provider.dart';
import '../../viewmodels/plan_provider.dart';
import '../../viewmodels/service_provider.dart';
import '../history/activity_history_screen.dart';

class PlanCreationScreen extends StatefulWidget {
  final ServiceModel? preselectedService;

  const PlanCreationScreen({super.key, this.preselectedService});

  @override
  State<PlanCreationScreen> createState() => _PlanCreationScreenState();
}

class _PlanCreationScreenState extends State<PlanCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController(text: '15.0');
  final _notesController = TextEditingController();

  ServiceModel? _selectedService;
  String _selectedMetal = 'Copper';
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _scheduledTime = const TimeOfDay(hour: 10, minute: 0);
  bool _reminderEnabled = true;

  @override
  void initState() {
    super.initState();
    _selectedService = widget.preselectedService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedService == null) {
        final services = context.read<ServiceProvider>().allServices;
        if (services.isNotEmpty) {
          setState(() => _selectedService = services.first);
        }
      }
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _calculateEstimatedPayout() {
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    final pricePerKg = _selectedService?.pricePerKg[_selectedMetal] ??
        AppConstants.metalCategories.firstWhere(
          (m) => m.name.toLowerCase() == _selectedMetal.toLowerCase(),
          orElse: () => AppConstants.metalCategories.first,
        ).estimatedPricePerKg;
    return weight * pricePerKg;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
    );
    if (picked != null) {
      setState(() => _scheduledTime = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedService == null) {
      AppHelpers.showSnackBar(context, 'Please select a recycling facility', isError: true);
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final planProvider = context.read<PlanProvider>();

    final user = authProvider.currentUser;
    final userId = user?.userId ?? 'usr_guest';

    final appointmentDateTime = DateTime(
      _scheduledDate.year,
      _scheduledDate.month,
      _scheduledDate.day,
      _scheduledTime.hour,
      _scheduledTime.minute,
    );

    final success = await planProvider.createPlan(
      userId: userId,
      serviceId: _selectedService!.serviceId,
      serviceName: _selectedService!.name,
      metalType: _selectedMetal,
      weightKg: double.parse(_weightController.text.trim()),
      scheduledDate: appointmentDateTime,
      notes: _notesController.text.trim(),
      reminderEnabled: _reminderEnabled,
    );

    if (success && mounted) {
      AppHelpers.showSnackBar(context, 'Recycling plan successfully created! ♻️');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ActivityHistoryScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceProvider = context.watch<ServiceProvider>();
    final planProvider = context.watch<PlanProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final services = serviceProvider.allServices;
    final estimatedPayout = _calculateEstimatedPayout();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.createPlanTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Facility Selector
                const Text('Select Recycling Facility', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                DropdownButtonFormField<ServiceModel>(
                  value: _selectedService ?? (services.isNotEmpty ? services.first : null),
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.storefront_rounded)),
                  items: services.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(s.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedService = val);
                  },
                ),
                const SizedBox(height: 18),

                // Metal Category Selector
                const Text('Metal Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedMetal,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.category_rounded)),
                  items: AppConstants.metalCategories.map((m) {
                    return DropdownMenuItem(
                      value: m.name,
                      child: Text('${m.name} (${m.symbol})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedMetal = val);
                  },
                ),
                const SizedBox(height: 18),

                // Weight Input
                const Text('Estimated Weight (kg)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: AppValidators.validateWeight,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.scale_rounded),
                    suffixText: 'kg',
                  ),
                ),
                const SizedBox(height: 18),

                // Date & Time Selectors Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Drop-Off Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDarkElevated : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month_rounded, size: 20, color: AppColors.primaryGreen),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      DateFormatter.formatShortDate(_scheduledDate),
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Drop-Off Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _pickTime,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDarkElevated : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 20, color: AppColors.copper),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _scheduledTime.format(context),
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Notes Input
                const Text('Special Instructions / Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Sorted copper tubes, ready on pallets',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 18),

                // Notification Reminder Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primaryGreen,
                  title: const Text(
                    AppStrings.reminderToggle,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Get push & local notification before scheduled appointment',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _reminderEnabled,
                  onChanged: (val) => setState(() => _reminderEnabled = val),
                ),
                const SizedBox(height: 18),

                // Payout & Carbon Summary Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                          : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: BorderSide(color: AppColors.primaryGreen.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Estimated Scrap Value', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            '\$${estimatedPayout.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryGreenDark,
                            ),
                          ),
                        ],
                      ),
                      Container(height: 36, width: 1, color: Colors.grey.withOpacity(0.3)),
                      Column(
                        children: [
                          const Text('CO₂ Offset Impact', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            '~${AppHelpers.calculateCo2Saved(_selectedMetal, double.tryParse(_weightController.text) ?? 0.0).toStringAsFixed(1)} kg',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.copper,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Submit Button
                ElevatedButton(
                  onPressed: planProvider.isLoading ? null : _handleSubmit,
                  child: planProvider.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(AppStrings.confirmPlan),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
