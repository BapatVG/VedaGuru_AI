import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/localization_service.dart';
import 'master_planner_screen.dart';
import 'samagri_screen.dart';
import 'pooja_guidance_screen.dart';
import 'muhurat_screen.dart';

class RitualsScreen extends StatelessWidget {
  const RitualsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          auth.tr('nav_planner'),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Hero Banner
            Container(
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primarySaffron.withValues(alpha: 0.15),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Text('🕉️', style: TextStyle(fontSize: 32)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.tr('rituals_banner_title'),
                          style: GoogleFonts.cinzel(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          auth.tr('rituals_banner_sub'),
                          style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Featured Card: Master 3-in-1 Planner
            _buildFeaturedCard(
              context: context,
              tag: auth.tr('rituals_featured_tag'),
              title: auth.tr('rituals_featured_title'),
              description: auth.tr('rituals_featured_desc'),
              icon: Icons.auto_awesome,
              gradientColors: [const Color(0xFFE65100), const Color(0xFFAC1900)],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MasterPlannerScreen()),
                );
              },
            ),
            const SizedBox(height: 16),

            Text(
              auth.tr('rituals_modules_title'),
              style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 12),

            // Samagri Generator Card
            _buildModuleCard(
              context: context,
              emoji: '📋',
              title: auth.tr('service_samagri_title'),
              subtitle: auth.tr('service_samagri_desc'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SamagriScreen()),
                );
              },
            ),
            const SizedBox(height: 12),

            // Pooja Vidhi Guidance Card
            _buildModuleCard(
              context: context,
              emoji: '🪔',
              title: auth.tr('service_guidance_title'),
              subtitle: auth.tr('service_guidance_desc'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PoojaGuidanceScreen()),
                );
              },
            ),
            const SizedBox(height: 12),

            // Auspicious Muhurat Card
            _buildModuleCard(
              context: context,
              emoji: '⏳',
              title: auth.tr('service_muhurat_title'),
              subtitle: auth.tr('service_muhurat_desc'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MuhuratScreen()),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard({
    required BuildContext context,
    required String tag,
    required String title,
    required String description,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                tag,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.cinzel(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Launch Ceremony Wizard ➔',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard({
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
                    Text(
                      title,
                      style: GoogleFonts.cinzel(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted),
                    ),
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
