import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class JapaMalaScreen extends StatefulWidget {
  const JapaMalaScreen({super.key});

  @override
  State<JapaMalaScreen> createState() => _JapaMalaScreenState();
}

class _JapaMalaScreenState extends State<JapaMalaScreen> {
  int _count = 0;
  String _selectedChant = 'Om Namah Shivaya';
  final _customChantController = TextEditingController();

  final List<String> _chantOptions = [
    'Om Namah Shivaya',
    'Hare Krishna Hare Rama',
    'Gayatri Mantra',
    'Shri Ram Jayram Jayjay Ram',
    'Om Gam Ganapataye Namaha',
    'Om (Pranava)',
    'Custom Chant',
  ];

  @override
  void dispose() {
    _customChantController.dispose();
    super.dispose();
  }

  String get _actualChant {
    if (_selectedChant == 'Custom Chant') {
      return _customChantController.text.trim().isEmpty ? 'Sacred Japa' : _customChantController.text.trim();
    }
    return _selectedChant;
  }

  void _increment() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_count < 108) {
        _count++;
      }
      if (_count == 108) {
        HapticFeedback.heavyImpact();
        _showCompletedDialog();
      }
    });
  }

  void _reset() {
    setState(() => _count = 0);
  }

  Future<void> _logSession() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username ?? 'Devotee';
    final res = await ApiService.logChantingSession(
      username: username,
      chantName: _actualChant,
      count: _count,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Chanting session saved to audit history!'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  void _showCompletedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          '🙏 Japa Mala Completed!',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
        ),
        content: Text(
          'You have completed 108 sacred chants of "$_actualChant". May your sadhana bring peace and spiritual strength.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _reset();
            },
            child: const Text('Start New'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logSession();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primarySaffron),
            child: const Text('Save to History'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _count / 108.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Digital 108 Japa Mala',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textMuted),
            tooltip: 'Reset Counter',
            onPressed: _reset,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // Chant Selector Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select Chanting Mantra', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedChant,
                      items: _chantOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedChant = val;
                            _count = 0;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.record_voice_over_rounded, color: AppTheme.primarySaffron),
                        isDense: true,
                      ),
                    ),
                    if (_selectedChant == 'Custom Chant') ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _customChantController,
                        decoration: InputDecoration(
                          hintText: 'Enter custom chant text',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          isDense: true,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 36),

            // Large Circular Beads Counter
            Center(
              child: GestureDetector(
                onTap: _increment,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Circular Progress
                    SizedBox(
                      width: 250,
                      height: 250,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primarySaffron),
                      ),
                    ),
                    // Tap Button Bead
                    Container(
                      width: 210,
                      height: 210,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Color(0xFFFFF3E0), Color(0xFFFFCC80), AppTheme.sacredGold],
                          center: Alignment(-0.2, -0.2),
                          radius: 0.9,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primarySaffron.withValues(alpha: 0.35),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('📿', style: TextStyle(fontSize: 32)),
                          const SizedBox(height: 4),
                          Text(
                            '$_count / 108',
                            style: GoogleFonts.cinzel(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap to Chant',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 36),

            // Chant Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.sacredGold.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    _actualChant,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cinzel(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Touch the sacred bead for each recitation. Completing 108 chants purifies the mental sheath.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Actions Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Reset Count'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _count > 0 ? _logSession : null,
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text('Save Session'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primarySaffron,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
