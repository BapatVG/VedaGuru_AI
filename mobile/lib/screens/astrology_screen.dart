import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/localization_service.dart';
import 'kundali_screen.dart';
import 'matchmaking_screen.dart';
import 'rashichakra_screen.dart';

class AstrologyScreen extends StatelessWidget {
  const AstrologyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          auth.tr('nav_jyotish'),
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
                  colors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
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
                    child: const Text('🪐', style: TextStyle(fontSize: 32)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.tr('jyotish_banner_title'),
                          style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          auth.tr('jyotish_banner_sub'),
                          style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildAstroTile(
              context: context,
              emoji: '♈',
              title: auth.tr('service_kundali_title'),
              subtitle: auth.tr('service_kundali_desc'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KundaliScreen())),
            ),
            const SizedBox(height: 12),

            _buildAstroTile(
              context: context,
              emoji: '💞',
              title: auth.tr('service_matchmaking_title'),
              subtitle: auth.tr('service_matchmaking_desc'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchmakingScreen())),
            ),
            const SizedBox(height: 12),

            _buildAstroTile(
              context: context,
              emoji: '🌌',
              title: auth.tr('service_rashi_title'),
              subtitle: auth.tr('service_rashi_desc'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RashichakraScreen())),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAstroTile({
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
