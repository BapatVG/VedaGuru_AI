import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../widgets/sacred_result_view.dart';

class SamagriScreen extends StatefulWidget {
  final String initialMode; // 'samagri' or 'guidance'
  const SamagriScreen({super.key, this.initialMode = 'samagri'});

  @override
  State<SamagriScreen> createState() => _SamagriScreenState();
}

class _SamagriScreenState extends State<SamagriScreen> {
  late String _mode;
  String _selectedPooja = 'Satyanarayan Katha';
  String _customPooja = '';
  String _selectedRegion = 'General/Standard';
  int _attendees = 5;

  bool _isLoading = false;
  String? _resultText;
  String? _error;

  final List<String> _poojaList = [
    'Satyanarayan Katha',
    'Griha Pravesh',
    'Navagraha Shanti',
    'Rudrabhishek',
    'Vivaha (Wedding)',
    'Custom'
  ];

  final List<String> _regions = [
    'General/Standard',
    'North Indian',
    'South Indian',
    'Maharashtrian',
    'Gujarati',
    'Bengali'
  ];

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null && _regions.contains(user.defaultRegion)) {
      _selectedRegion = user.defaultRegion;
    }
  }

  void _generate() async {
    final poojaToUse = _selectedPooja == 'Custom' ? _customPooja.trim() : _selectedPooja;
    if (poojaToUse.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter a Pooja name.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _resultText = null;
    });

    final lang = Provider.of<AuthProvider>(context, listen: false).currentLanguage;

    final res = await ApiService.getSamagriList(
      poojaName: poojaToUse,
      region: _selectedRegion,
      peopleCount: _attendees,
      language: lang,
    );

    setState(() {
      _isLoading = false;
      if (res['success']) {
        _resultText = res['samagri_list'];
      } else {
        _error = res['error'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _mode == 'guidance' ? auth.tr('service_guidance_title') : auth.tr('service_samagri_title'),
          style: GoogleFonts.cinzel(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryDark,
          ),
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
            // Config Box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.sacredGold.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ritual Configuration',
                    style: GoogleFonts.cinzel(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pooja Select
                  DropdownButtonFormField<String>(
                    value: _selectedPooja,
                    decoration: const InputDecoration(
                      labelText: 'Select Pooja / Havan',
                      prefixIcon: Icon(Icons.temple_hindu_outlined, color: AppTheme.primarySaffron),
                    ),
                    items: _poojaList.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (val) => setState(() => _selectedPooja = val ?? 'Satyanarayan Katha'),
                  ),

                  if (_selectedPooja == 'Custom') ...[
                    const SizedBox(height: 14),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Enter Custom Pooja Name',
                        prefixIcon: Icon(Icons.edit_note, color: AppTheme.primarySaffron),
                      ),
                      onChanged: (val) => _customPooja = val,
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Region Select
                  DropdownButtonFormField<String>(
                    value: _selectedRegion,
                    decoration: const InputDecoration(
                      labelText: 'Regional Tradition',
                      prefixIcon: Icon(Icons.map_outlined, color: AppTheme.primarySaffron),
                    ),
                    items: _regions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) => setState(() => _selectedRegion = val ?? 'General/Standard'),
                  ),

                  const SizedBox(height: 16),

                  // Attendees Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Estimated Attendees:',
                        style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textDark),
                      ),
                      Text(
                        '$_attendees people',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primarySaffron,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _attendees.toDouble(),
                    min: 1,
                    max: 50,
                    divisions: 49,
                    activeColor: AppTheme.primarySaffron,
                    inactiveColor: const Color(0xFFFFE0B2),
                    onChanged: (val) => setState(() => _attendees = val.round()),
                  ),

                  const SizedBox(height: 12),

                  // Generate Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _generate,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('✨ Generate Detailed Checklist'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Error display
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_error!, style: GoogleFonts.poppins(color: Colors.red.shade900)),
              ),

            // Result Card
            if (_resultText != null) ...[
              SacredResultView(
                title: _mode == 'samagri' ? 'Pooja Samagri & Preparation Checklist' : 'Vedic Ritual Step-by-Step Vidhi',
                subtitle: '${_selectedPooja == "Other / Custom" ? _customPooja : _selectedPooja} • Authentic Vedic Guidelines',
                content: _resultText!,
                iconEmoji: _mode == 'samagri' ? '🌺' : '🕉️',
              ),
              const SizedBox(height: 30),
            ],
          ],
        ),
      ),
    );
  }
}
