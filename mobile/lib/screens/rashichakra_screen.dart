import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/sacred_result_view.dart';

class RashichakraScreen extends StatefulWidget {
  const RashichakraScreen({super.key});

  @override
  State<RashichakraScreen> createState() => _RashichakraScreenState();
}

class _RashichakraScreenState extends State<RashichakraScreen> {
  String _selectedRashi = 'Aries (Mesh - मेष)';

  bool _isLoading = false;
  String? _rashiProfile;
  String? _errorMessage;

  final List<String> _rashiList = [
    'Aries (Mesh - मेष)',
    'Taurus (Vrishabh - वृषभ)',
    'Gemini (Mithun - मिथुन)',
    'Cancer (Kark - कर्क)',
    'Leo (Simha - सिंह)',
    'Virgo (Kanya - कन्या)',
    'Libra (Tula - तुला)',
    'Scorpio (Vrishchik - वृश्चिक)',
    'Sagittarius (Dhanu - धनु)',
    'Capricorn (Makar - मकर)',
    'Aquarius (Kumbh - कुंभ)',
    'Pisces (Meen - मीन)',
  ];

  Future<void> _exploreRashi() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username;
    final lang = auth.currentUser?.preferredLanguage ?? 'English';

    final res = await ApiService.getRashichakra(
      rashiName: _selectedRashi,
      language: lang,
      username: username,
    );

    setState(() {
      _isLoading = false;
      if (res['success'] == true) {
        _rashiProfile = res['profile'];
      } else {
        _errorMessage = res['error'] ?? 'Failed to explore Rashi details';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Rashichakra (Horoscope)',
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
                        const Text('🌌', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Text('Select Your Zodiac Sign (Rashi)', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedRashi,
                      items: _rashiList.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (val) => setState(() => _selectedRashi = val!),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.stars_rounded, color: AppTheme.sacredGold),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _exploreRashi,
                        icon: const Icon(Icons.auto_awesome),
                        label: Text(_isLoading ? 'Consulting the Stars...' : 'Explore Rashi & Spiritual Connections'),
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
                      'Unveiling Ishta Devata, Ratna & Aaradhya Vriksha for $_selectedRashi...',
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

            if (_rashiProfile != null) ...[
              SacredResultView(
                title: 'Rashichakra Astrological Profile & Predictions',
                subtitle: '$_selectedRashi Sign • Elements, Planetary Ruler & Predictions',
                content: _rashiProfile!,
                iconEmoji: '🌌',
              ),
              const SizedBox(height: 30),
            ],
          ],
        ),
      ),
    );
  }
}
