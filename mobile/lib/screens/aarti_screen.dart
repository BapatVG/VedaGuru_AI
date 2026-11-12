import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/sacred_result_view.dart';

class AartiScreen extends StatefulWidget {
  const AartiScreen({super.key});

  @override
  State<AartiScreen> createState() => _AartiScreenState();
}

class _AartiScreenState extends State<AartiScreen> {
  String _selectedDeity = 'Lord Ganesha';
  final _customDeityController = TextEditingController();

  bool _isLoading = false;
  String? _aartiContent;
  String? _errorMessage;

  final List<String> _deityOptions = [
    'Lord Ganesha',
    'Lord Shiva',
    'Lord Rama',
    'Lord Krishna',
    'Goddess Durga',
    'Lord Hanuman',
    'Goddess Lakshmi',
    'Goddess Saraswati',
    'Lord Vishnu',
    'Lord Surya',
    'Custom Deity',
  ];

  @override
  void dispose() {
    _customDeityController.dispose();
    super.dispose();
  }

  String get _actualDeityName {
    if (_selectedDeity == 'Custom Deity') {
      return _customDeityController.text.trim().isEmpty ? 'Sacred Deity' : _customDeityController.text.trim();
    }
    return _selectedDeity;
  }

  Future<void> _fetchAarti() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username;
    final lang = auth.currentUser?.preferredLanguage ?? 'English';

    final res = await ApiService.getAarti(
      deityName: _actualDeityName,
      language: lang,
      username: username,
    );

    setState(() {
      _isLoading = false;
      if (res['success'] == true) {
        _aartiContent = res['content'];
      } else {
        _errorMessage = res['error'] ?? 'Failed to fetch Aarti';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Aarti Sangrah',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Deity Selector Card
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
                        Text('Select Deity for Aarti', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedDeity,
                      items: _deityOptions.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (val) => setState(() => _selectedDeity = val!),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.temple_hindu_rounded, color: AppTheme.primarySaffron),
                      ),
                    ),
                    if (_selectedDeity == 'Custom Deity') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _customDeityController,
                        decoration: InputDecoration(
                          hintText: 'Enter deity name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _fetchAarti,
                        icon: const Icon(Icons.auto_stories_rounded),
                        label: Text(_isLoading ? 'Loading Aarti...' : 'Fetch Traditional Aarti'),
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
                      'Retrieving authentic Aarti for $_actualDeityName...',
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

            if (_aartiContent != null) ...[
              SacredResultView(
                title: 'Pavitra Aarti Sangrah & Stuti',
                subtitle: '$_actualDeityName • Devotional Verses & Meaning',
                content: _aartiContent!,
                iconEmoji: '🪔',
              ),
              const SizedBox(height: 30),
            ],
          ],
        ),
      ),
    );
  }
}
