import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class AnnapurnaScreen extends StatefulWidget {
  const AnnapurnaScreen({super.key});

  @override
  State<AnnapurnaScreen> createState() => _AnnapurnaScreenState();
}

class _AnnapurnaScreenState extends State<AnnapurnaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Vrat Tab State
  String _selectedVrat = 'Ekadashi';
  final _customVratController = TextEditingController();
  bool _isLoadingVrat = false;
  String? _vratPlan;
  String? _vratError;

  // Prasad Tab State
  String _selectedDeity = 'Lord Ganesha';
  final _customDeityController = TextEditingController();
  String _selectedRegion = 'General/Standard';
  bool _isLoadingPrasad = false;
  String? _prasadRecipe;
  String? _prasadError;

  final List<String> _vratOptions = [
    'Ekadashi',
    'Navratri',
    'Pradosh Vrat',
    'Maha Shivratri',
    'Karwa Chauth',
    'Sawan Somvar',
    'Custom Vrat',
  ];

  final List<String> _deityOptions = [
    'Lord Ganesha',
    'Lord Shiva',
    'Lord Krishna',
    'Lord Rama',
    'Goddess Lakshmi',
    'Lord Hanuman',
    'Goddess Durga',
    'Custom Deity',
  ];

  final List<String> _regionOptions = [
    'North Indian',
    'South Indian',
    'Maharashtrian',
    'Gujarati',
    'Bengali',
    'General/Standard',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customVratController.dispose();
    _customDeityController.dispose();
    super.dispose();
  }

  String get _actualVratName => _selectedVrat == 'Custom Vrat'
      ? (_customVratController.text.trim().isEmpty ? 'Sacred Vrat' : _customVratController.text.trim())
      : _selectedVrat;

  String get _actualDeityName => _selectedDeity == 'Custom Deity'
      ? (_customDeityController.text.trim().isEmpty ? 'Sacred Deity' : _customDeityController.text.trim())
      : _selectedDeity;

  Future<void> _generateVratPlan() async {
    setState(() {
      _isLoadingVrat = true;
      _vratError = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username;
    final lang = auth.currentUser?.preferredLanguage ?? 'English';

    final res = await ApiService.getVratMeal(
      vratType: _actualVratName,
      language: lang,
      username: username,
    );

    setState(() {
      _isLoadingVrat = false;
      if (res['success'] == true) {
        _vratPlan = res['meal_plan'];
      } else {
        _vratError = res['error'] ?? 'Failed to generate Vrat meal plan';
      }
    });
  }

  Future<void> _generatePrasadRecipe() async {
    setState(() {
      _isLoadingPrasad = true;
      _prasadError = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username;
    final lang = auth.currentUser?.preferredLanguage ?? 'English';

    final res = await ApiService.getPrasadRecipe(
      deityName: _actualDeityName,
      region: _selectedRegion,
      language: lang,
      username: username,
    );

    setState(() {
      _isLoadingPrasad = false;
      if (res['success'] == true) {
        _prasadRecipe = res['recipe'];
      } else {
        _prasadError = res['error'] ?? 'Failed to generate Prasad recipe';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Annapurna Sattvic Kitchen',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primarySaffron,
          labelColor: AppTheme.primaryDark,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: '🌙 Vrat Meals', icon: Icon(Icons.nightlight_round, size: 18)),
            Tab(text: '🛕 Deity Prasad', icon: Icon(Icons.temple_hindu_rounded, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVratTab(),
          _buildPrasadTab(),
        ],
      ),
    );
  }

  Widget _buildVratTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Fasting Day / Vrat', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedVrat,
                    items: _vratOptions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: (val) => setState(() => _selectedVrat = val!),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.restaurant_rounded, color: AppTheme.primarySaffron),
                    ),
                  ),
                  if (_selectedVrat == 'Custom Vrat') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _customVratController,
                      decoration: InputDecoration(
                        hintText: 'Enter fasting day name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingVrat ? null : _generateVratPlan,
                      icon: const Icon(Icons.auto_stories_rounded),
                      label: Text(_isLoadingVrat ? 'Generating Sattvic Plan...' : 'Generate Vrat Meal Plan'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (_isLoadingVrat)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: AppTheme.primarySaffron))),

          if (_vratError != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
              child: Text(_vratError!, style: const TextStyle(color: Colors.red)),
            ),

          if (_vratPlan != null) ...[
            _buildResultCard('🌙 Vrat Plan: $_actualVratName', _vratPlan!),
            const SizedBox(height: 30),
          ],
        ],
      ),
    );
  }

  Widget _buildPrasadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Deity', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
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
                  const SizedBox(height: 14),
                  Text('Regional Tradition', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedRegion,
                    items: _regionOptions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) => setState(() => _selectedRegion = val!),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.public_rounded, color: AppTheme.sacredGold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingPrasad ? null : _generatePrasadRecipe,
                      icon: const Icon(Icons.soup_kitchen_rounded),
                      label: Text(_isLoadingPrasad ? 'Cooking in Temple Kitchen...' : 'Generate Sacred Prasad Recipe'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryDark),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (_isLoadingPrasad)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: AppTheme.primarySaffron))),

          if (_prasadError != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
              child: Text(_prasadError!, style: const TextStyle(color: Colors.red)),
            ),

          if (_prasadRecipe != null) ...[
            _buildResultCard('🛕 Prasad: $_actualDeityName ($_selectedRegion)', _prasadRecipe!),
            const SizedBox(height: 30),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCard(String title, String content) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryDark))),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: AppTheme.primarySaffron),
                  tooltip: 'Copy Recipe',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: content));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard!')));
                  },
                ),
              ],
            ),
            const Divider(),
            SelectableText(
              content,
              style: GoogleFonts.poppins(fontSize: 14, height: 1.6, color: AppTheme.textDark),
            ),
          ],
        ),
      ),
    );
  }
}
