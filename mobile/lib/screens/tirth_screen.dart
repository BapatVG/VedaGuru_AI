import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/sacred_result_view.dart';

class TirthScreen extends StatefulWidget {
  const TirthScreen({super.key});

  @override
  State<TirthScreen> createState() => _TirthScreenState();
}

class _TirthScreenState extends State<TirthScreen> {
  final _startCityController = TextEditingController(text: 'New Delhi');
  String _selectedDestination = 'Varanasi (Kashi)';
  final _customDestController = TextEditingController();
  int _days = 3;
  int _people = 2;

  bool _isLoading = false;
  String? _itineraryContent;
  String? _errorMessage;

  final List<String> _destinations = [
    'Varanasi (Kashi)',
    'Char Dham (Uttarakhand)',
    'Tirupati Balaji',
    'Rameshwaram & Madurai',
    'Dwarka & Somnath',
    'Ayodhya Dham',
    'Puri Jagannath',
    'Custom Destination',
  ];

  @override
  void dispose() {
    _startCityController.dispose();
    _customDestController.dispose();
    super.dispose();
  }

  String get _actualDestination => _selectedDestination == 'Custom Destination'
      ? (_customDestController.text.trim().isEmpty ? 'Sacred Tirth' : _customDestController.text.trim())
      : _selectedDestination;

  Future<void> _planYatra() async {
    final start = _startCityController.text.trim();
    if (start.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please specify a starting city.')));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username;
    final lang = auth.currentUser?.preferredLanguage ?? 'English';

    final res = await ApiService.getTirthItinerary(
      startCity: start,
      destination: _actualDestination,
      days: _days,
      peopleCount: _people,
      language: lang,
      username: username,
    );

    setState(() {
      _isLoading = false;
      if (res['success'] == true) {
        _itineraryContent = res['itinerary'];
      } else {
        _errorMessage = res['error'] ?? 'Failed to plan Tirth Yatra';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tirth Yatra Pilgrimage Planner',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
        ),
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
                        const Text('🛕', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Text('Plan Your Sacred Journey', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _startCityController,
                      decoration: InputDecoration(
                        labelText: 'Starting City',
                        hintText: 'e.g., Delhi, Mumbai, Bengaluru',
                        prefixIcon: const Icon(Icons.flight_takeoff_rounded, color: AppTheme.primarySaffron),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Pilgrimage Destination (Kshetra)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedDestination,
                      items: _destinations.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) => setState(() => _selectedDestination = val!),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.temple_hindu_rounded, color: AppTheme.sacredGold),
                        isDense: true,
                      ),
                    ),
                    if (_selectedDestination == 'Custom Destination') ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _customDestController,
                        decoration: InputDecoration(
                          hintText: 'Enter pilgrimage destination',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          isDense: true,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Duration: $_days Days', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                              Slider(
                                value: _days.toDouble(),
                                min: 1,
                                max: 14,
                                divisions: 13,
                                activeColor: AppTheme.primarySaffron,
                                onChanged: (v) => setState(() => _days = v.round()),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Travelers: $_people', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                              Slider(
                                value: _people.toDouble(),
                                min: 1,
                                max: 10,
                                divisions: 9,
                                activeColor: AppTheme.sacredGold,
                                onChanged: (v) => setState(() => _people = v.round()),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _planYatra,
                        icon: const Icon(Icons.map_rounded),
                        label: Text(_isLoading ? 'Plotting Sacred Route...' : 'Generate Tirth Itinerary'),
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
                      'Curating temple darshan timings, rituals & route for $_actualDestination...',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cinzel(fontSize: 14, color: AppTheme.primaryDark),
                    ),
                  ],
                ),
              ),

            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(14)),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),

            if (_itineraryContent != null) ...[
              SacredResultView(
                title: 'Tirth Yatra & Sacred Pilgrimage Itinerary',
                subtitle: '$_actualDestination • $_days Days Devotional Guide',
                content: _itineraryContent!,
                iconEmoji: '🛕',
              ),
              const SizedBox(height: 30),
            ],
          ],
        ),
      ),
    );
  }
}
