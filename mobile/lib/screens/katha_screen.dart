import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/sacred_result_view.dart';

class KathaScreen extends StatefulWidget {
  const KathaScreen({super.key});

  @override
  State<KathaScreen> createState() => _KathaScreenState();
}

class _KathaScreenState extends State<KathaScreen> {
  final _topicController = TextEditingController(text: 'Samudra Manthan');
  String _selectedSource = 'Any';

  bool _isLoading = false;
  String? _kathaContent;
  String? _errorMessage;

  final List<String> _sourceOptions = [
    'Any',
    'Shiva Puran',
    'Vishnu Puran',
    'Bhagavata Purana',
    'Mahabharata',
    'Ramayana',
    'Bhagavad Gita',
  ];

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _fetchKatha() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username;
    final lang = auth.currentUser?.preferredLanguage ?? 'English';

    final res = await ApiService.getKatha(
      topic: topic,
      source: _selectedSource,
      language: lang,
      username: username,
    );

    setState(() {
      _isLoading = false;
      if (res['success'] == true) {
        _kathaContent = res['katha'];
      } else {
        _errorMessage = res['error'] ?? 'Failed to retrieve Katha';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pauranik Katha Explorer',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input Card
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
                        const Text('📖', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Text('What story do you wish to hear?', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _topicController,
                      decoration: InputDecoration(
                        hintText: "e.g., 'Samudra Manthan', 'Birth of Lord Ganesha'",
                        prefixIcon: const Icon(Icons.auto_stories_rounded, color: AppTheme.primarySaffron),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Preferred Source / Tradition', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedSource,
                      items: _sourceOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => setState(() => _selectedSource = val!),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.menu_book_rounded, color: AppTheme.sacredGold),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _fetchKatha,
                        icon: const Icon(Icons.record_voice_over_rounded),
                        label: Text(_isLoading ? 'Kathavachak narrating...' : 'Narrate Katha'),
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
                      'Retrieving ancient story from the cosmos...',
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

            if (_kathaContent != null) ...[
              SacredResultView(
                title: 'Pavitra Vrat & Pooja Katha',
                subtitle: '${_topicController.text.trim()} • Divine Narrative & Mahatmya',
                content: _kathaContent!,
                iconEmoji: '📜',
              ),
              const SizedBox(height: 30),
            ],
          ],
        ),
      ),
    );
  }
}
