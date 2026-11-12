import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/sacred_result_view.dart';

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  // Boy Details
  final _boyNameController = TextEditingController(text: 'Rahul');
  DateTime _boyDob = DateTime(1994, 6, 20);
  TimeOfDay _boyTob = const TimeOfDay(hour: 10, minute: 15);
  final _boyCityController = TextEditingController(text: 'Pune, India');

  // Girl Details
  final _girlNameController = TextEditingController(text: 'Priya');
  DateTime _girlDob = DateTime(1996, 9, 12);
  TimeOfDay _girlTob = const TimeOfDay(hour: 18, minute: 45);
  final _girlCityController = TextEditingController(text: 'Mumbai, India');

  bool _isLoading = false;
  String? _compatibilityReport;
  String? _errorMessage;

  @override
  void dispose() {
    _boyNameController.dispose();
    _boyCityController.dispose();
    _girlNameController.dispose();
    _girlCityController.dispose();
    super.dispose();
  }

  Future<void> _calculateMatch() async {
    final bName = _boyNameController.text.trim();
    final bCity = _boyCityController.text.trim();
    final gName = _girlNameController.text.trim();
    final gCity = _girlCityController.text.trim();

    if (bName.isEmpty || bCity.isEmpty || gName.isEmpty || gCity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all details for both Boy and Girl.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username;
    final lang = auth.currentUser?.preferredLanguage ?? 'English';
    final dateFormat = DateFormat('yyyy-MM-dd');

    final bTimeStr = '${_boyTob.hour.toString().padLeft(2, '0')}:${_boyTob.minute.toString().padLeft(2, '0')}';
    final gTimeStr = '${_girlTob.hour.toString().padLeft(2, '0')}:${_girlTob.minute.toString().padLeft(2, '0')}';

    final res = await ApiService.getMatchmaking(
      boyName: bName,
      boyDob: dateFormat.format(_boyDob),
      boyTob: bTimeStr,
      boyCity: bCity,
      girlName: gName,
      girlDob: dateFormat.format(_girlDob),
      girlTob: gTimeStr,
      girlCity: gCity,
      language: lang,
      username: username,
    );

    setState(() {
      _isLoading = false;
      if (res['success'] == true) {
        _compatibilityReport = res['report'];
      } else {
        _errorMessage = res['error'] ?? 'Failed to calculate Ashtakoot Milan';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kundali Milan (Matchmaking)',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Disclaimer Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AI Ashtakoot guidance based on Vedic Jyotish. Consult a certified Jyotishi for final marriage decisions.',
                      style: TextStyle(fontSize: 11, color: Colors.brown.shade800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Boy Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('👦', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text("Boy's Details", style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _boyNameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _boyDob,
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) setState(() => _boyDob = picked);
                            },
                            child: Text(dateFormat.format(_boyDob), style: const TextStyle(fontSize: 11)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showTimePicker(context: context, initialTime: _boyTob);
                              if (picked != null) setState(() => _boyTob = picked);
                            },
                            child: Text(_boyTob.format(context), style: const TextStyle(fontSize: 11)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _boyCityController,
                      decoration: InputDecoration(
                        labelText: 'City of Birth',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Girl Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('👧', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text("Girl's Details", style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _girlNameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _girlDob,
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) setState(() => _girlDob = picked);
                            },
                            child: Text(dateFormat.format(_girlDob), style: const TextStyle(fontSize: 11)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showTimePicker(context: context, initialTime: _girlTob);
                              if (picked != null) setState(() => _girlTob = picked);
                            },
                            child: Text(_girlTob.format(context), style: const TextStyle(fontSize: 11)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _girlCityController,
                      decoration: InputDecoration(
                        labelText: 'City of Birth',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _calculateMatch,
                icon: const Icon(Icons.favorite_rounded),
                label: Text(_isLoading ? 'Calculating Ashtakoot Milan...' : 'Generate Compatibility Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
                      'Analyzing 36 Gunas (Varna, Vashya, Tara, Yoni, Graha Maitri, Gana, Bhakoot, Nadi)...',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cinzel(fontSize: 13, color: AppTheme.primaryDark),
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

            if (_compatibilityReport != null) ...[
              SacredResultView(
                title: 'Ashtakoot Guna Milan & Vivaha Compatibility',
                subtitle: '${_boyNameController.text.trim()} & ${_girlNameController.text.trim()}',
                content: _compatibilityReport!,
                iconEmoji: '💞',
              ),
              const SizedBox(height: 30),
            ],
          ],
        ),
      ),
    );
  }
}
