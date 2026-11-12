import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../widgets/sacred_result_view.dart';

class PoojaGuidanceScreen extends StatefulWidget {
  final String? initialPooja;
  const PoojaGuidanceScreen({super.key, this.initialPooja});

  @override
  State<PoojaGuidanceScreen> createState() => _PoojaGuidanceScreenState();
}

class _PoojaGuidanceScreenState extends State<PoojaGuidanceScreen> {
  String _selectedPooja = 'Satyanarayan Katha';
  final _customPoojaController = TextEditingController();
  String _selectedRegion = 'General/Standard';

  bool _isLoading = false;
  String? _vidhi;
  String? _errorMessage;

  final List<String> _poojaOptions = [
    'Satyanarayan Katha',
    'Griha Pravesh',
    'Rudrabhishek',
    'Ganesh Pujan',
    'Lakshmi Pooja',
    'Navagraha Shanti',
    'Maha Mrityunjaya Havan',
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
    _customPoojaController.dispose();
    super.dispose();
  }

  String get _actualPoojaName {
    if (_selectedPooja == 'Custom') {
      return _customPoojaController.text.trim().isEmpty ? 'Sacred Pooja' : _customPoojaController.text.trim();
    }
    return _selectedPooja;
  }

  Future<void> _fetchGuidance() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username;
    final language = auth.currentLanguage;

    final result = await ApiService.getPoojaGuidance(
      poojaName: _actualPoojaName,
      region: _selectedRegion,
      language: language,
      username: username,
    );

    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _vidhi = result['vidhi'];
      } else {
        _errorMessage = result['error'] ?? 'Failed to generate Pooja Vidhi';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          auth.tr('service_guidance_title'),
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
            // Config Card
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
                        const Text('🪔', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Text(
                          'Step-by-Step Ritual Procedure',
                          style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Select Pooja Type', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedPooja,
                      items: _poojaOptions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                      onChanged: (val) => setState(() => _selectedPooja = val!),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.temple_hindu_rounded, color: AppTheme.primarySaffron),
                      ),
                    ),
                    if (_selectedPooja == 'Custom') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _customPoojaController,
                        decoration: InputDecoration(
                          hintText: 'Enter custom pooja name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text('Regional Tradition', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedRegion,
                      items: _regionOptions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (val) => setState(() => _selectedRegion = val!),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.public_rounded, color: AppTheme.sacredGold),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _fetchGuidance,
                        icon: const Icon(Icons.auto_stories_rounded),
                        label: Text(_isLoading ? 'Generating Vidhi...' : 'Generate Step-by-Step Vidhi'),
                      ),
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
                      'Synthesizing authentic Vidhi & Mantras for $_actualPoojaName...',
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

            if (_vidhi != null) ...[
              SacredResultView(
                title: 'Pooja Vidhi & Ritual Procedure',
                subtitle: '$_actualPoojaName • Vedic Steps, Mantras & Sankalpa',
                content: _vidhi!,
                iconEmoji: '🕉️',
              ),
              const SizedBox(height: 30),
            ],
          ],
        ),
      ),
    );
  }
}
