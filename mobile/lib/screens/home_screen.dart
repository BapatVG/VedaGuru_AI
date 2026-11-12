import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import 'chat_screen.dart';
import 'master_planner_screen.dart';
import 'samagri_screen.dart';
import 'pooja_guidance_screen.dart';
import 'muhurat_screen.dart';
import 'profile_screen.dart';
import 'admin_dashboard_screen.dart';
import '../utils/voice_helper.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;
  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _dailyWisdom = '';
  bool _isLoadingWisdom = true;

  // Live Real-Time Clock
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();

  // Active language tracker for dynamic re-fetching
  String? _activeLanguage;

  // Live Panchang State
  final _panchangCityController = TextEditingController(text: 'New Delhi, India');
  bool _isLoadingPanchang = false;
  Map<String, dynamic>? _panchangData;
  String? _panchangError;

  // Upcoming Festivals State
  final _festivalCityController = TextEditingController(text: 'New Delhi, India');
  bool _isLoadingFestivals = false;
  List<dynamic> _festivals = [];
  String? _festivalError;

  // Quick Consult State
  final _quickChatController = TextEditingController();
  bool _isQuickChatListening = false;
  String _preListeningQuickText = '';

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context);
    final currentLang = auth.currentLanguage;
    if (_activeLanguage != currentLang) {
      _activeLanguage = currentLang;
      _loadDailyWisdom(currentLang);
      _fetchLivePanchang(currentLang);
      _fetchUpcomingFestivals(currentLang);
    }
  }

  @override
  void dispose() {
    VoiceHelper.stopListening();
    _clockTimer?.cancel();
    _panchangCityController.dispose();
    _festivalCityController.dispose();
    _quickChatController.dispose();
    super.dispose();
  }

  Future<void> _loadDailyWisdom([String? lang]) async {
    final language = lang ?? _activeLanguage ?? 'English';
    setState(() => _isLoadingWisdom = true);
    final wisdom = await ApiService.getDailyWisdom(language: language);
    if (mounted) {
      setState(() {
        _dailyWisdom = wisdom;
        _isLoadingWisdom = false;
      });
    }
  }

  Future<void> _fetchLivePanchang([String? lang]) async {
    final city = _panchangCityController.text.trim();
    if (city.isEmpty) return;
    final language = lang ?? _activeLanguage ?? 'English';
    setState(() {
      _isLoadingPanchang = true;
      _panchangError = null;
    });

    final res = await ApiService.getLivePanchang(location: city, language: language);
    if (mounted) {
      setState(() {
        _isLoadingPanchang = false;
        if (res['success'] == true) {
          _panchangData = res['panchang'];
        } else {
          _panchangError = res['error'];
        }
      });
    }
  }

  Future<void> _fetchUpcomingFestivals([String? lang]) async {
    final city = _festivalCityController.text.trim();
    if (city.isEmpty) return;
    final language = lang ?? _activeLanguage ?? 'English';
    setState(() {
      _isLoadingFestivals = true;
      _festivalError = null;
    });

    final res = await ApiService.getUpcomingFestivals(location: city, language: language);
    if (mounted) {
      setState(() {
        _isLoadingFestivals = false;
        if (res['success'] == true) {
          _festivals = res['festivals'] ?? [];
        } else {
          _festivalError = res['error'];
        }
      });
    }
  }

  void _sendQuickChat() {
    if (_isQuickChatListening) {
      VoiceHelper.stopListening();
      setState(() => _isQuickChatListening = false);
    }
    final query = _quickChatController.text.trim();
    if (query.isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username ?? 'Devotee';
    final lang = auth.currentLanguage;

    chatProvider.sendMessage(username: username, text: query, language: lang);
    _quickChatController.clear();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  void _showLanguageSelector() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Select Language / भाषा चुनें',
                  style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: LocalizationService.supportedLanguages.map((lang) {
                    final isSelected = auth.currentLanguage == lang;
                    return ListTile(
                      title: Text(
                        LocalizationService.languageNamesNative[lang] ?? lang,
                        style: GoogleFonts.poppins(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppTheme.primarySaffron : AppTheme.textDark,
                        ),
                      ),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primarySaffron) : null,
                      onTap: () {
                        auth.setPreferredLanguage(lang);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final username = user?.username ?? 'Devotee';
    final isPurohit = user?.isPurohit ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          auth.tr('app_title'),
          style: GoogleFonts.cinzel(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryDark,
            fontSize: 22,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _showLanguageSelector,
            icon: const Icon(Icons.language, size: 18, color: AppTheme.primarySaffron),
            label: Text(
              auth.currentLanguage,
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primarySaffron),
            ),
          ),
          if (user?.username == 'BVarad0876')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.amber),
              tooltip: auth.tr('admin_dashboard'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: AppTheme.primaryDark),
            tooltip: auth.tr('profile'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadDailyWisdom();
          await _fetchLivePanchang();
          await _fetchUpcomingFestivals();
        },
        color: AppTheme.primarySaffron,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. User Greeting Card
              _buildGreetingCard(auth, username, user?.defaultRegion ?? 'General/Standard', isPurohit),
              const SizedBox(height: 14),

              // 2. Real-Time Live Clock
              _buildLiveClockCard(auth),
              const SizedBox(height: 16),

              // 3. Daily Vedic Wisdom Banner
              _buildDailyWisdomBanner(auth),
              const SizedBox(height: 18),

              // 4. Quick AI Consult Bar
              _buildQuickConsultBar(auth),
              const SizedBox(height: 22),

              // 5. Live Panchang & Astrological Clock
              _buildLivePanchangCard(auth),
              const SizedBox(height: 22),

              // 6. Upcoming Festivals & Vrats (Next 30 Days)
              _buildUpcomingFestivalsSection(auth),
              const SizedBox(height: 24),

              // 7. Sacred Services Hub Grid
              Text(
                auth.tr('sacred_services'),
                style: GoogleFonts.cinzel(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              _buildServicesGrid(auth),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget: User Greeting Card ---
  Widget _buildGreetingCard(AuthProvider auth, String username, String region, bool isPurohit) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.sacredGold.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primarySaffron.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text('🕉️', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${auth.tr("greeting_namaste")}, $username',
                    style: GoogleFonts.cinzel(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.temple_hindu_rounded, size: 13, color: AppTheme.primaryDark),
                      const SizedBox(width: 4),
                      Text(
                        '$region ${auth.tr("tradition_suffix")}',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isPurohit ? AppTheme.primaryDark : AppTheme.primarySaffron,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isPurohit ? auth.tr('purohit') : auth.tr('devotee'),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget: Real-time Live Date & Time Clock ---
  Widget _buildLiveClockCard(AuthProvider auth) {
    final timeStr = DateFormat('hh:mm:ss a').format(_currentTime);
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(_currentTime);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: AppTheme.midnightGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.sacredGold.withValues(alpha: 0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.sacredGold.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primarySaffron.withValues(alpha: 0.25),
                  border: Border.all(color: AppTheme.sacredGoldLight, width: 1.5),
                ),
                child: const Text('🪔', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.amberAccent,
                          boxShadow: [
                            BoxShadow(color: Colors.amberAccent.withValues(alpha: 0.8), blurRadius: 6),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: GoogleFonts.cinzel(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.sacredGoldLight,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.sacredGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.sacredGold.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Vikram 2083',
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.sacredGoldLight),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Shaka 1948',
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Widget: Daily Wisdom Banner ---
  Widget _buildDailyWisdomBanner(AuthProvider auth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.sacredGold.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✨', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.tr('wisdom_of_day'),
                  style: GoogleFonts.cinzel(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                ),
                const SizedBox(height: 4),
                if (_isLoadingWisdom)
                  const Text('Consulting the scriptures...', style: TextStyle(fontSize: 12, color: AppTheme.textMuted))
                else
                  Text(
                    _dailyWisdom,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textDark,
                      height: 1.4,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget: Quick AI Consult Bar ---
  Widget _buildQuickConsultBar(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isQuickChatListening ? Colors.red : AppTheme.sacredGold.withValues(alpha: 0.3),
              width: _isQuickChatListening ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isQuickChatListening
                    ? Colors.red.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppTheme.primarySaffron),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _quickChatController,
                  decoration: InputDecoration(
                    hintText: _isQuickChatListening
                        ? 'Listening in ${auth.currentLanguage}... speak now'
                        : auth.tr('ask_vedic_ai_hint'),
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: _isQuickChatListening ? Colors.red.shade700 : AppTheme.textMuted,
                      fontStyle: _isQuickChatListening ? FontStyle.italic : FontStyle.normal,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (_) => _sendQuickChat(),
                ),
              ),
              IconButton(
                icon: Icon(
                  _isQuickChatListening ? Icons.mic : Icons.mic_none_rounded,
                  color: _isQuickChatListening ? Colors.red : AppTheme.primarySaffron,
                  size: 20,
                ),
                tooltip: _isQuickChatListening
                    ? 'Listening... Tap to stop'
                    : 'Voice Input (Speech-to-Text)',
                onPressed: () {
                  if (_isQuickChatListening) {
                    VoiceHelper.stopListening();
                    setState(() => _isQuickChatListening = false);
                  } else {
                    _preListeningQuickText = _quickChatController.text.trim();
                    VoiceHelper.startListening(
                      language: auth.currentLanguage,
                      onResult: (text, isFinal) {
                        setState(() {
                          final combined = _preListeningQuickText.isEmpty ? text : '$_preListeningQuickText $text';
                          _quickChatController.text = combined;
                          _quickChatController.selection = TextSelection.fromPosition(
                            TextPosition(offset: combined.length),
                          );
                        });
                      },
                      onStatusChange: (listening) {
                        setState(() => _isQuickChatListening = listening);
                      },
                      onError: (err) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Voice: $err'),
                            backgroundColor: Colors.red.shade700,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_rounded, color: AppTheme.primarySaffron, size: 20),
                onPressed: _sendQuickChat,
              ),
            ],
          ),
        ),
        if (_isQuickChatListening)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.red),
                ),
                const SizedBox(width: 6),
                Text(
                  '🎙️ Listening in ${auth.currentLanguage}... Say your Vedic query',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // --- Widget: Live Panchang Card ---
  Widget _buildLivePanchangCard(AuthProvider auth) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('☀️', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(
                      auth.tr('live_panchang'),
                      style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                  ],
                ),
                if (_isLoadingPanchang)
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primarySaffron)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _panchangCityController,
                    decoration: InputDecoration(
                      hintText: auth.tr('location_placeholder'),
                      prefixIcon: const Icon(Icons.location_on_rounded, color: AppTheme.primarySaffron, size: 18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onSubmitted: (_) => _fetchLivePanchang(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _fetchLivePanchang,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(auth.tr('fetch_live_panchang'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (_panchangData != null) ...[
              Row(
                children: [
                  Expanded(child: _buildPanchangTile(auth.tr('tithi'), _panchangData!['tithi'] ?? '', const Color(0xFFFFF3E0))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildPanchangTile(auth.tr('nakshatra'), _panchangData!['nakshatra'] ?? '', const Color(0xFFEDE7F6))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildPanchangTile(auth.tr('rahu_kaal'), _panchangData!['rahu_kaal'] ?? '', const Color(0xFFFFEBEE))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildPanchangTile(auth.tr('yamaganda'), _panchangData!['yamaganda'] ?? '', const Color(0xFFE8F5E9))),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _panchangData!['status'] ?? '',
                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.brown.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_panchangError != null) ...[
              Text(_panchangError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Enter your city to view today\'s auspicious Muhurat & Tithi.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPanchangTile(String label, String value, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textDark),
          ),
        ],
      ),
    );
  }

  // --- Widget: Upcoming Festivals Section ---
  Widget _buildUpcomingFestivalsSection(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '🎉 ${auth.tr("upcoming_festivals")}',
              style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            if (_isLoadingFestivals)
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primarySaffron)),
          ],
        ),
        const SizedBox(height: 10),

        if (_festivals.isNotEmpty)
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _festivals.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, idx) {
                final fest = _festivals[idx];
                final isFest = fest['type'] == 'Festival';
                return Container(
                  width: 220,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.sacredGold.withValues(alpha: 0.25)),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primarySaffron.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isFest ? '🪔' : '🧘', style: const TextStyle(fontSize: 18)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isFest ? Colors.amber.shade100 : Colors.teal.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              fest['type'] ?? 'Festival',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isFest ? Colors.amber.shade900 : Colors.teal.shade900),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        fest['name'] ?? 'Festival',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cinzel(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      ),
                      Text(
                        fest['date'] ?? '',
                        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.primarySaffron),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 28,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MasterPlannerScreen(initialPooja: fest['name']),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            side: const BorderSide(color: AppTheme.primarySaffron, width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('${auth.tr("prepare")} ➔', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primarySaffron)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(
              child: Text('Upcoming festivals will appear here once loaded.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            ),
          ),
      ],
    );
  }

  // --- Widget: Sacred Services Grid ---
  Widget _buildServicesGrid(AuthProvider auth) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: [
        _buildGridTile(
          emoji: '🌟',
          title: auth.tr('service_planner_title'),
          subtitle: auth.tr('service_planner_desc'),
          color: const Color(0xFFFFF3E0),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MasterPlannerScreen()));
          },
        ),
        _buildGridTile(
          emoji: '📋',
          title: auth.tr('service_samagri_title'),
          subtitle: auth.tr('service_samagri_desc'),
          color: const Color(0xFFF1F8E9),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SamagriScreen()));
          },
        ),
        _buildGridTile(
          emoji: '🪔',
          title: auth.tr('service_guidance_title'),
          subtitle: auth.tr('service_guidance_desc'),
          color: const Color(0xFFEDE7F6),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PoojaGuidanceScreen()));
          },
        ),
        _buildGridTile(
          emoji: '⏳',
          title: auth.tr('service_muhurat_title'),
          subtitle: auth.tr('service_muhurat_desc'),
          color: const Color(0xFFE0F7FA),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MuhuratScreen()));
          },
        ),
      ],
    );
  }

  Widget _buildGridTile({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.sacredGold.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cinzel(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
