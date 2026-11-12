import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/sacred_result_view.dart';

class KundaliScreen extends StatefulWidget {
  const KundaliScreen({super.key});

  @override
  State<KundaliScreen> createState() => _KundaliScreenState();
}

class _KundaliScreenState extends State<KundaliScreen> {
  final _nameController = TextEditingController(text: 'Rahul Sharma');
  DateTime _birthDate = DateTime(1995, 5, 15);
  TimeOfDay _birthTime = const TimeOfDay(hour: 14, minute: 30);
  final _cityController = TextEditingController(text: 'Pune, India');
  String _analysisType = 'Detailed Life Horoscope';

  bool _isLoading = false;
  String? _kundaliReading;
  String? _resolvedLocation;
  String? _errorMessage;

  final List<String> _analysisTypes = [
    'Detailed Life Horoscope',
    'Career & Wealth Focus',
    'Marriage & Relationship Prospects',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _generateKundali() async {
    final name = _nameController.text.trim();
    final city = _cityController.text.trim();
    if (name.isEmpty || city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide both name and birth city.')),
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

    final timeStr = '${_birthTime.hour.toString().padLeft(2, '0')}:${_birthTime.minute.toString().padLeft(2, '0')}';

    final res = await ApiService.getKundali(
      nativeName: name,
      birthDate: dateFormat.format(_birthDate),
      birthTime: timeStr,
      birthCity: city,
      analysisType: _analysisType,
      language: lang,
      username: username,
    );

    setState(() {
      _isLoading = false;
      if (res['success'] == true) {
        _kundaliReading = res['reading'];
        _resolvedLocation = res['resolved_location'];
      } else {
        _errorMessage = res['error'] ?? 'Failed to calculate Kundali';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Janam Kundali (Birth Chart)',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Details Card
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
                        const Text('♈', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Text('Native Birth Details', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name of the Native',
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.primarySaffron),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _birthDate,
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) setState(() => _birthDate = picked);
                            },
                            icon: const Icon(Icons.calendar_today_rounded, size: 16),
                            label: Text(dateFormat.format(_birthDate), style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showTimePicker(context: context, initialTime: _birthTime);
                              if (picked != null) setState(() => _birthTime = picked);
                            },
                            icon: const Icon(Icons.access_time_rounded, size: 16),
                            label: Text(_birthTime.format(context), style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: 'City and Country of Birth',
                        hintText: 'e.g. Pune, India',
                        prefixIcon: const Icon(Icons.location_on_outlined, color: AppTheme.primarySaffron),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Type of Reading', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _analysisType,
                      items: _analysisTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) => setState(() => _analysisType = val!),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.auto_graph_rounded, color: AppTheme.sacredGold),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _generateKundali,
                        icon: const Icon(Icons.auto_awesome),
                        label: Text(_isLoading ? 'Calculating Chart...' : 'Generate Kundali Reading'),
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
                      'Calculating planetary degrees, Lagna & 12 Houses...',
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

            if (_kundaliReading != null) ...[
              if (_resolvedLocation != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.teal, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Location resolved: $_resolvedLocation',
                          style: TextStyle(fontSize: 11, color: Colors.teal.shade900, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              SacredResultView(
                title: 'Janam Kundali & Astrological Chart Reading',
                subtitle: '${_nameController.text.trim()} • ${DateFormat("d MMM yyyy").format(_birthDate)} • ${_cityController.text.trim()}',
                content: _kundaliReading!,
                iconEmoji: '♈',
              ),
              const SizedBox(height: 30),
            ],
          ],
        ),
      ),
    );
  }
}
