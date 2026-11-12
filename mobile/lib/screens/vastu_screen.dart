import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/sacred_result_view.dart';

class VastuScreen extends StatefulWidget {
  const VastuScreen({super.key});

  @override
  State<VastuScreen> createState() => _VastuScreenState();
}

class _VastuScreenState extends State<VastuScreen> {
  String _mainDoor = 'North-East (Ishanya)';
  String _kitchen = 'South-East (Agneya)';
  String _bedroom = 'South-West (Nairruti)';
  String _poojaRoom = 'North-East (Ishanya)';
  final _otherDetailsController = TextEditingController();

  bool _isLoading = false;
  String? _analysisContent;
  String? _errorMessage;

  final List<String> _directions = [
    'North',
    'South',
    'East',
    'West',
    'North-East (Ishanya)',
    'North-West (Vayavya)',
    'South-East (Agneya)',
    'South-West (Nairruti)',
  ];

  @override
  void dispose() {
    _otherDetailsController.dispose();
    super.dispose();
  }

  Future<void> _analyzeVastu() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username;
    final lang = auth.currentUser?.preferredLanguage ?? 'English';

    final res = await ApiService.getVastuAnalysis(
      mainDoor: _mainDoor,
      kitchen: _kitchen,
      bedroom: _bedroom,
      poojaRoom: _poojaRoom,
      otherDetails: _otherDetailsController.text.trim(),
      language: lang,
      username: username,
    );

    setState(() {
      _isLoading = false;
      if (res['success'] == true) {
        _analysisContent = res['analysis'];
      } else {
        _errorMessage = res['error'] ?? 'Failed to analyze Vastu';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Vastu Shastra Consultant',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Direction Input Card
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
                        const Text('🏡', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Text('Home Layout Directions', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDirectionDropdown('Main Door Facing Direction', _mainDoor, (val) => setState(() => _mainDoor = val!)),
                    const SizedBox(height: 12),
                    _buildDirectionDropdown('Kitchen Placement', _kitchen, (val) => setState(() => _kitchen = val!)),
                    const SizedBox(height: 12),
                    _buildDirectionDropdown('Master Bedroom Location', _bedroom, (val) => setState(() => _bedroom = val!)),
                    const SizedBox(height: 12),
                    _buildDirectionDropdown('Pooja Room Location', _poojaRoom, (val) => setState(() => _poojaRoom = val!)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _otherDetailsController,
                      decoration: InputDecoration(
                        labelText: 'Additional Details (Optional)',
                        hintText: 'e.g., Balcony in North, slope towards East',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _analyzeVastu,
                        icon: const Icon(Icons.explore_rounded),
                        label: Text(_isLoading ? 'Analyzing Cosmic Energies...' : 'Analyze Vastu Compliance'),
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
                      'Evaluating cardinal directions & Pancha Bhoota balance...',
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

            if (_analysisContent != null) ...[
              SacredResultView(
                title: 'Vastu Cosmic Evaluation & Remedial Guidance',
                subtitle: 'Main Door: $_mainDoor • Kitchen: $_kitchen',
                content: _analysisContent!,
                iconEmoji: '🏡',
              ),
              const SizedBox(height: 30),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionDropdown(String label, String value, Function(String?) onChanged) {
    final effectiveValue = _directions.contains(value) ? value : _directions.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: effectiveValue,
          items: _directions.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}
