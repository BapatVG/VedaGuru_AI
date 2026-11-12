import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import 'auth_screen.dart';
import 'yajman_crm_screen.dart';
import 'booking_screen.dart';
import 'yagya_board_screen.dart';
import 'community_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'admin_dashboard_screen.dart';

class WorkspaceScreen extends StatelessWidget {
  const WorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final isPurohit = user?.isPurohit ?? false;
    final username = user?.username ?? 'Devotee';
    final isAdmin = user?.username == 'BVarad0876';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          auth.tr('nav_workspace'),
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.amber),
              tooltip: 'Admin Sanctum',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
              },
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.primaryDark),
            tooltip: 'Profile Settings',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.textMuted),
            tooltip: 'Logout',
            onPressed: () {
              auth.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Card
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.sacredBoxDecoration(hasGlow: true),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: isPurohit ? Colors.deepOrange.shade100 : Colors.amber.shade100,
                      child: Text(
                        username.isNotEmpty ? username.substring(0, 1).toUpperCase() : '🕉️',
                        style: GoogleFonts.cinzel(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isPurohit ? Colors.deepOrange.shade900 : Colors.brown.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                username,
                                style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                              ),
                              if (isAdmin) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.verified, size: 16, color: Colors.amber),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${user?.defaultRegion ?? "General"} Tradition | ${user?.preferredLanguage ?? "English"}',
                            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPurohit ? AppTheme.primaryDark : AppTheme.primarySaffron,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isPurohit ? 'Purohit Account' : 'Devotee Account',
                              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Super Admin Dashboard Banner (Strictly for BVarad0876)
            if (isAdmin) ...[
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.sacredGold.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Text('👑', style: TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Admin Sanctum Dashboard',
                                  style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.brown.shade900),
                                ),
                                Text(
                                  'Metrics, module popularity, regional telemetry & user directory',
                                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.brown.shade800),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.brown),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            Text(
              isPurohit ? 'Purohit Operations & CRM' : 'My Ritual Bookings',
              style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 12),

            if (isPurohit) ...[
              _buildTile(
                emoji: '👥',
                title: 'Yajman CRM, Reviews & Reminders',
                subtitle: 'Manage client directory, ratings & reviews, and send 1-tap WhatsApp reminders',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const YajmanCrmScreen())),
              ),
            ] else ...[
              _buildTile(
                emoji: '🗺️',
                title: 'Purohit Reservations & Map Venue',
                subtitle: 'Pin venue on interactive map, browse registered Purohits & ratings',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingScreen())),
              ),
            ],
            const SizedBox(height: 18),

            Text(
              'Shared Ritual Tools & Community',
              style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 12),

            _buildTile(
              emoji: '📋',
              title: 'Yagya Event Collaboration Board',
              subtitle: 'Collaborative task planner for community festivals and family ceremonies',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const YagyaBoardScreen())),
            ),
            const SizedBox(height: 12),

            _buildTile(
              emoji: '📖',
              title: 'Community Ritual Feed',
              subtitle: 'Share family vidhis, regional customs & discover community traditions',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityScreen())),
            ),
            const SizedBox(height: 12),

            _buildTile(
              emoji: '📜',
              title: 'Activity Log & Past Readings',
              subtitle: 'Review all generated samagri lists, kundalis, aartis & muhurats',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
            ),
            const SizedBox(height: 12),

            _buildTile(
              emoji: '⚙️',
              title: 'Profile Settings & Language',
              subtitle: 'Change spiritual tradition, app language, update security and passwords',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
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
