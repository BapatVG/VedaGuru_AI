import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/sacred_result_view.dart';

class MantraScreen extends StatefulWidget {
  const MantraScreen({super.key});

  @override
  State<MantraScreen> createState() => _MantraScreenState();
}

class _MantraScreenState extends State<MantraScreen> {
  String _selectedMantra = 'Gayatri Mantra';
  final _customMantraController = TextEditingController();

  bool _isLoading = false;
  String? _mantraContent;
  String? _errorMessage;

  final List<String> _mantraOptions = [
    'Gayatri Mantra',
    'Mahamrityunjaya Mantra',
    'Shanti Mantra',
    'Ganesh Vandana',
    'Shiva Tandava Stotram',
    'Maha Lakshmi Ashtakam',
    'Custom Mantra',
  ];

  @override
  void dispose() {
    _customMantraController.dispose();
    super.dispose();
  }

  String get _actualMantraName {
    if (_selectedMantra == 'Custom Mantra') {
      return _customMantraController.text.trim().isEmpty ? 'Sacred Mantra' : _customMantraController.text.trim();
    }
    return _selectedMantra;
  }

  Future<void> _fetchMantra() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username;
    final lang = auth.currentUser?.preferredLanguage ?? 'English';

    final res = await ApiService.getMantra(
      mantraName: _actualMantraName,
      language: lang,
      username: username,
    );

    setState(() {
      _isLoading = false;
      if (res['success'] == true) {
        _mantraContent = res['content'];
      } else {
        _errorMessage = res['error'] ?? 'Failed to load Mantra';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Vedic Mantras & Chants',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector Card
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
                        const Text('📿', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Text('Select Sacred Mantra', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedMantra,
                      items: _mantraOptions.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (val) => setState(() => _selectedMantra = val!),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.record_voice_over_rounded, color: AppTheme.primarySaffron),
                      ),
                    ),
                    if (_selectedMantra == 'Custom Mantra') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _customMantraController,
                        decoration: InputDecoration(
                          hintText: 'Enter custom mantra name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _fetchMantra,
                        icon: const Icon(Icons.auto_awesome),
                        label: Text(_isLoading ? 'Loading Pronunciation...' : 'Load Mantra & Phonetics'),
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
                      'Accessing Vedic phonetics & swaras for $_actualMantraName...',
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
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),

            if (_mantraContent != null) ...[
              SacredResultView(
                title: 'Vedic Mantra, Meaning & Japa Vidhi',
                subtitle: '$_actualMantraName • Authentic Sanskrit Shloka & Spiritual Benefits',
                content: _mantraContent!,
                iconEmoji: '📿',
              ),
              const SizedBox(height: 30),
            ],
          ],
        ),
      ),
    );
  }
}
