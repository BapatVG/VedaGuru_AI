import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/localization_service.dart';
import 'japa_mala_screen.dart';
import 'annapurna_screen.dart';
import 'ayurveda_screen.dart';
import 'vastu_screen.dart';
import 'tirth_screen.dart';

class LifestyleScreen extends StatelessWidget {
  const LifestyleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          auth.tr('nav_lifestyle'),
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
                  colors: [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: const Text('🌿', style: TextStyle(fontSize: 32)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.tr('lifestyle_banner_title'),
                          style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          auth.tr('lifestyle_banner_sub'),
                          style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildTile(
              context: context,
              emoji: '🧘',
              title: auth.tr('service_japa_title'),
              subtitle: auth.tr('service_japa_desc'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JapaMalaScreen())),
            ),
            const SizedBox(height: 12),

            _buildTile(
              context: context,
              emoji: '🍲',
              title: auth.tr('service_annapurna_title'),
              subtitle: auth.tr('service_annapurna_desc'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnapurnaScreen())),
            ),
            const SizedBox(height: 12),

            _buildTile(
              context: context,
              emoji: '🌿',
              title: auth.tr('service_ayurveda_title'),
              subtitle: auth.tr('service_ayurveda_desc'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AyurvedaScreen())),
            ),
            const SizedBox(height: 12),

            _buildTile(
              context: context,
              emoji: '🏡',
              title: auth.tr('service_vastu_title'),
              subtitle: auth.tr('service_vastu_desc'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VastuScreen())),
            ),
            const SizedBox(height: 12),

            _buildTile(
              context: context,
              emoji: '🛕',
              title: auth.tr('service_tirth_title'),
              subtitle: auth.tr('service_tirth_desc'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TirthScreen())),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
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
