import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/localization_service.dart';
import 'chat_screen.dart';
import 'library_screen.dart';
import 'aarti_screen.dart';
import 'mantra_screen.dart';
import 'katha_screen.dart';

class WisdomScreen extends StatelessWidget {
  const WisdomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          auth.tr('nav_wisdom'),
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.sacredGold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: const Text('📜', style: TextStyle(fontSize: 32)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.tr('wisdom_banner_title'),
                          style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          auth.tr('wisdom_banner_sub'),
                          style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // AI Chatbot Card
            _buildWisdomTile(
              context: context,
              emoji: '🤖',
              title: auth.tr('service_chat_title'),
              subtitle: auth.tr('service_chat_desc'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen())),
            ),
            const SizedBox(height: 12),

            // Vedic Library Card
            _buildWisdomTile(
              context: context,
              emoji: '📚',
              title: auth.tr('service_library_title'),
              subtitle: auth.tr('service_library_desc'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LibraryScreen())),
            ),
            const SizedBox(height: 12),

            // Aarti Sangrah Card
            _buildWisdomTile(
              context: context,
              emoji: '🪔',
              title: auth.tr('service_aarti_title'),
              subtitle: auth.tr('service_aarti_desc'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AartiScreen())),
            ),
            const SizedBox(height: 12),

            // Vedic Mantras Card
            _buildWisdomTile(
              context: context,
              emoji: '📿',
              title: auth.tr('service_mantra_title'),
              subtitle: auth.tr('service_mantra_desc'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MantraScreen())),
            ),
            const SizedBox(height: 12),

            // Pauranik Katha Card
            _buildWisdomTile(
              context: context,
              emoji: '📖',
              title: auth.tr('service_katha_title'),
              subtitle: auth.tr('service_katha_desc'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KathaScreen())),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWisdomTile({
    required BuildContext context,
    required String emoji,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.sacredGold.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.sacredGold.withValues(alpha: 0.2)),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.primarySaffron),
            ],
          ),
        ),
      ),
    );
  }
}
