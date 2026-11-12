import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../widgets/sacred_result_view.dart';

class MasterPlannerScreen extends StatefulWidget {
  final String? initialPooja;
  const MasterPlannerScreen({super.key, this.initialPooja});

  @override
  State<MasterPlannerScreen> createState() => _MasterPlannerScreenState();
}

class _MasterPlannerScreenState extends State<MasterPlannerScreen> {
  int _currentStep = 1;

  // Step 1: Devotee & Location
  final _devoteeController = TextEditingController(text: 'Devotee');
  final _locationController = TextEditingController(text: 'New Delhi, India');

  // Step 2: Ritual & Dates
  String _selectedPooja = 'Satyanarayan Katha';
  final _customPoojaController = TextEditingController();
  DateTime _startDate = DateTime.now().add(const Duration(days: 2));
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  String _selectedRegion = 'General/Standard';

  // Step 3: Generation & Results
  bool _isLoading = false;
  String? _masterPlan;
  String? _errorMessage;

  final List<String> _poojaOptions = [
    'Satyanarayan Katha',
    'Griha Pravesh',
    'Navagraha Shanti',
    'Rudrabhishek',
    'Vivaha (Wedding)',
    'Ganesh Pujan & Havan',
    'Custom',
  ];

  final List<String> _regionOptions = [
    'North Indian',
    'South Indian',
    'Maharashtrian',
    'Gujarati',
    'Bengali',
    'General/Standard',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialPooja != null && widget.initialPooja!.isNotEmpty) {
      if (_poojaOptions.contains(widget.initialPooja)) {
        _selectedPooja = widget.initialPooja!;
      } else {
        _selectedPooja = 'Custom';
        _customPoojaController.text = widget.initialPooja!;
      }
    }
  }

  @override
  void dispose() {
    _devoteeController.dispose();
    _locationController.dispose();
    _customPoojaController.dispose();
    super.dispose();
  }

  String get _actualPoojaName {
    if (_selectedPooja == 'Custom') {
      return _customPoojaController.text.trim().isEmpty ? 'Sacred Pooja' : _customPoojaController.text.trim();
    }
    return _selectedPooja;
  }

  Future<void> _generatePlan() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username;
    final dateFormat = DateFormat('yyyy-MM-dd');

    final result = await ApiService.getMasterPlan(
      devoteeName: _devoteeController.text.trim(),
      location: _locationController.text.trim(),
      poojaName: _actualPoojaName,
      startDate: dateFormat.format(_startDate),
      endDate: dateFormat.format(_endDate),
      region: _selectedRegion,
      language: auth.currentLanguage,
      username: username,
    );

    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _masterPlan = result['master_plan'];
      } else {
        _errorMessage = result['error'] ?? 'Failed to generate Master Plan';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          auth.tr('service_planner_title'),
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => LocalizationService.showLanguageBottomSheet(context),
            icon: const Icon(Icons.language, size: 18, color: AppTheme.primarySaffron),
            label: Text(
              auth.currentLanguage,
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primarySaffron),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step Progress Indicator
            _buildStepIndicator(),
            const SizedBox(height: 24),

            if (_currentStep == 1) _buildStepOne(),
            if (_currentStep == 2) _buildStepTwo(),
            if (_currentStep == 3) _buildStepThree(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.sacredGold.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStepItem(1, '1. Devotee'),
          _buildDivider(1),
          _buildStepItem(2, '2. Ritual & Dates'),
          _buildDivider(2),
          _buildStepItem(3, '3. Review & Plan'),
        ],
      ),
    );
  }

  Widget _buildStepItem(int step, String title) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: isCurrent
                ? AppTheme.primarySaffron
                : (isActive ? AppTheme.sacredGold : Colors.grey.shade300),
            child: Text(
              '$step',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
              color: isCurrent ? AppTheme.primaryDark : AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(int priorStep) {
    final isDone = _currentStep > priorStep;
    return Container(
      width: 24,
      height: 2,
      color: isDone ? AppTheme.primarySaffron : Colors.grey.shade300,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  // --- Step 1: Devotee & Location ---
  Widget _buildStepOne() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('👤', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Text(
                  'Devotee & Location Information',
                  style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Devotee / Yajman Name',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _devoteeController,
              decoration: InputDecoration(
                hintText: 'e.g. Ramesh Sharma',
                prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.primarySaffron),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'City / Location for Muhurat',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'e.g. Pune, Maharashtra, India',
                prefixIcon: const Icon(Icons.location_on_outlined, color: AppTheme.primarySaffron),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_devoteeController.text.trim().isEmpty || _locationController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please provide both devotee name and location.')),
                    );
                    return;
                  }
                  setState(() => _currentStep = 2);
                },
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Next: Ritual Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 2: Ritual & Dates ---
  Widget _buildStepTwo() {
    final dateFormat = DateFormat('dd MMM yyyy');
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🕉️', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Text(
                  'Ritual & Tradition Selection',
                  style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Select Pooja / Havan Type', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedPooja,
              items: _poojaOptions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (val) => setState(() => _selectedPooja = val!),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.auto_awesome, color: AppTheme.sacredGold),
              ),
            ),
            if (_selectedPooja == 'Custom') ...[
              const SizedBox(height: 14),
              TextField(
                controller: _customPoojaController,
                decoration: InputDecoration(
                  hintText: 'Enter custom pooja or havan name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Text('Regional Tradition', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedRegion,
              items: _regionOptions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (val) => setState(() => _selectedRegion = val!),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.temple_hindu_rounded, color: AppTheme.primaryDark),
              ),
            ),
            const SizedBox(height: 18),
            Text('Target Date Range', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          _startDate = picked;
                          if (_endDate.isBefore(_startDate)) {
                            _endDate = _startDate.add(const Duration(days: 5));
                          }
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(dateFormat.format(_startDate), style: const TextStyle(fontSize: 12)),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('to', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: _startDate,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => _endDate = picked);
                      }
                    },
                    icon: const Icon(Icons.event_rounded, size: 16),
                    label: Text(dateFormat.format(_endDate), style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => _currentStep = 1),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back'),
                ),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _currentStep = 3),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Next: Review'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 3: Review & Generate ---
  Widget _buildStepThree() {
    final dateFormat = DateFormat('dd MMM yyyy');
    return Column(
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Text(
                      'Review Ceremony Summary',
                      style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildSummaryRow('Devotee:', _devoteeController.text.trim()),
                _buildSummaryRow('Location:', _locationController.text.trim()),
                _buildSummaryRow('Ritual:', _actualPoojaName),
                _buildSummaryRow('Tradition:', _selectedRegion),
                _buildSummaryRow('Window:', '${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}'),
                const SizedBox(height: 20),
                if (!_isLoading && _masterPlan == null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () => setState(() => _currentStep = 2),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Back'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _generatePlan,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('✨ Generate Master Plan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primarySaffron,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        if (_isLoading)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: Column(
              children: [
                const CircularProgressIndicator(color: AppTheme.primarySaffron),
                const SizedBox(height: 16),
                Text(
                  'Consulting the stars & sacred scriptures for $_actualPoojaName...',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(fontSize: 14, color: AppTheme.primaryDark),
                ),
              ],
            ),
          ),

        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
              ],
            ),
          ),

        if (_masterPlan != null) ...[
          SacredResultView(
            title: '3-in-1 Master Ceremony Blueprint',
            subtitle: 'Muhurat • Samagri Checklist • Step-by-Step Vidhi',
            content: _masterPlan!,
            iconEmoji: '📜',
          ),
          const SizedBox(height: 30),
        ],
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textMuted)),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
            ),
          ),
        ],
      ),
    );
  }
}
