import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../widgets/sacred_result_view.dart';

class MuhuratScreen extends StatefulWidget {
  const MuhuratScreen({super.key});

  @override
  State<MuhuratScreen> createState() => _MuhuratScreenState();
}

class _MuhuratScreenState extends State<MuhuratScreen> {
  String _selectedEvent = 'Griha Pravesh';
  final _customEventController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final _locationController = TextEditingController(text: 'India');

  bool _isLoading = false;
  String? _resultText;
  String? _lastSearchedEvent;
  String? _error;

  final List<String> _events = [
    'Griha Pravesh',
    'Vivaha (Marriage)',
    'Vahan Kharidi (Vehicle Purchase)',
    'Vidyarambha (Education)',
    'Namakaran (Naming Ceremony)',
    'Satyanarayan Katha',
    'Custom'
  ];

  @override
  void dispose() {
    _customEventController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primarySaffron,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _calculateMuhurat() async {
    final customName = _customEventController.text.trim();
    if (_selectedEvent == 'Custom' && customName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your custom event/ceremony name.')),
      );
      return;
    }

    final effectiveEvent = (_selectedEvent == 'Custom' && customName.isNotEmpty) ? customName : _selectedEvent;

    setState(() {
      _isLoading = true;
      _error = null;
      _resultText = null;
      _lastSearchedEvent = effectiveEvent;
    });

    final lang = Provider.of<AuthProvider>(context, listen: false).currentLanguage;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final res = await ApiService.getMuhurat(
      eventType: effectiveEvent,
      targetDate: dateStr,
      location: _locationController.text.trim().isEmpty ? 'India' : _locationController.text.trim(),
      language: lang,
    );

    setState(() {
      _isLoading = false;
      if (res['success']) {
        _resultText = res['muhurat_details'];
      } else {
        _error = res['error'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final dateStr = DateFormat('EEE, d MMMM yyyy').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          auth.tr('service_muhurat_title'),
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
            // Controls Card
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
                    'Muhurat Parameters',
                    style: GoogleFonts.cinzel(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Event Selector
                  DropdownButtonFormField<String>(
                    value: _selectedEvent,
                    decoration: const InputDecoration(
                      labelText: 'Auspicious Event',
                      prefixIcon: Icon(Icons.celebration_outlined, color: AppTheme.primarySaffron),
                    ),
                    items: _events.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setState(() => _selectedEvent = val ?? 'Griha Pravesh'),
                  ),
                  if (_selectedEvent == 'Custom') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _customEventController,
                      decoration: InputDecoration(
                        labelText: 'Specify Custom Event / Ceremony',
                        hintText: 'e.g. Mundan, Engagement (Sagai), Shop Opening, Yajnopavita',
                        prefixIcon: const Icon(Icons.edit_note_rounded, color: AppTheme.primarySaffron),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Date Picker Button
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.sacredGold.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined, color: AppTheme.primarySaffron),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Auspicious Date Target',
                                style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMuted),
                              ),
                              Text(
                                dateStr,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.edit_calendar, size: 18, color: AppTheme.primarySaffron),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Location
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'City / Location',
                      prefixIcon: Icon(Icons.location_city_outlined, color: AppTheme.primarySaffron),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _calculateMuhurat,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('✨ Find Auspicious Timings'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

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

            // Result
            if (_resultText != null) ...[
              SacredResultView(
                title: 'Auspicious Muhurat & Panchang Guidance',
                subtitle: '${_lastSearchedEvent ?? _selectedEvent} • Target: $dateStr • ${_locationController.text.trim().isEmpty ? "India" : _locationController.text.trim()}',
                content: _resultText!,
                iconEmoji: '🕰️',
              ),
              const SizedBox(height: 30),
            ],
          ],
        ),
      ),
    );
  }
}
