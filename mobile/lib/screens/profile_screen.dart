import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/localization_service.dart';
import 'admin_dashboard_screen.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Password change controllers
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isChangingPassword = false;

  final List<String> _regions = [
    'General/Standard',
    'North Indian',
    'South Indian',
    'Maharashtrian',
    'Gujarati',
    'Bengali'
  ];

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleChangePassword() async {
    final oldPass = _oldPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all password fields.')),
      );
      return;
    }

    if (newPass.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password must be at least 4 characters long.')),
      );
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match.')),
      );
      return;
    }

    setState(() => _isChangingPassword = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final res = await auth.changePassword(oldPass, newPass);
    setState(() => _isChangingPassword = false);

    if (res['success'] == true && mounted) {
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Password updated successfully!'),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(res['error'] ?? 'Failed to update password.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final username = user?.username ?? 'Devotee';
    final region = user?.defaultRegion ?? 'General/Standard';
    final isPurohit = user?.isPurohit ?? false;
    final isAdmin = user?.username == 'BVarad0876';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          auth.tr('profile'),
          style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.sacredBoxDecoration(hasGlow: true),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: isPurohit ? Colors.deepOrange.shade100 : Colors.amber.shade100,
                    child: Text(
                      username.isNotEmpty ? username.substring(0, 1).toUpperCase() : '🕉️',
                      style: GoogleFonts.cinzel(
                        fontSize: 28,
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
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                            ),
                            if (isAdmin) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified, size: 18, color: Colors.amber),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: isPurohit ? Colors.deepOrange.shade50 : Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isPurohit ? Colors.deepOrange.shade300 : Colors.amber.shade400,
                                ),
                              ),
                              child: Text(
                                isPurohit ? auth.tr('purohit') : auth.tr('devotee'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isPurohit ? Colors.deepOrange.shade900 : Colors.brown.shade900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              region,
                              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Super Admin Shortcut (Only for BVarad0876)
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.admin_panel_settings, color: Colors.brown, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  auth.tr('admin_dashboard'),
                                  style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.brown.shade900),
                                ),
                                Text(
                                  'Platform metrics, usage stats & user directory',
                                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.brown.shade800),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.brown),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Section 1: Regional Spiritual Tradition
            Text(
              auth.tr('tradition'),
              style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.sacredBoxDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select your default regional tradition for customized Vedic vidhis, samagri and mantras:',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _regions.contains(region) ? region : 'General/Standard',
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.temple_hindu, color: AppTheme.primarySaffron),
                    ),
                    items: _regions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (newRegion) {
                      if (newRegion != null && newRegion != region) {
                        auth.updateProfile(newRegion, auth.currentLanguage);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Tradition set to $newRegion')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 2: Preferred Language
            Text(
              auth.tr('language'),
              style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.sacredBoxDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select language for app navigation and AI consultations:',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: auth.currentLanguage,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.language, color: AppTheme.primarySaffron),
                    ),
                    items: LocalizationService.supportedLanguages.map((l) {
                      return DropdownMenuItem(
                        value: l,
                        child: Text(LocalizationService.languageNamesNative[l] ?? l),
                      );
                    }).toList(),
                    onChanged: (newLang) {
                      if (newLang != null) {
                        auth.setPreferredLanguage(newLang);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Language set to $newLang')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 3: Change Password
            Text(
              auth.tr('change_password'),
              style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.sacredBoxDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _oldPasswordController,
                    obscureText: _obscureOld,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primarySaffron),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureOld ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                        onPressed: () => setState(() => _obscureOld = !_obscureOld),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_reset, color: AppTheme.primarySaffron),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                        onPressed: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.check_circle_outline, color: AppTheme.primarySaffron),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _isChangingPassword ? null : _handleChangePassword,
                      child: _isChangingPassword
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(auth.tr('change_password')),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  auth.logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: Text(
                  auth.tr('logout'),
                  style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}
