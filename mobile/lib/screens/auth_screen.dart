import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import 'main_navigation_shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Controllers
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _securityAnswerController = TextEditingController();

  // Registration options
  String _selectedRegion = 'General/Standard';
  String _selectedRole = 'User';
  String _selectedSecurityQuestion = 'What is your Ishta Devata (favorite deity)?';

  final List<String> _regions = [
    'General/Standard',
    'North Indian',
    'South Indian',
    'Maharashtrian',
    'Gujarati',
    'Bengali'
  ];

  final List<String> _securityQuestions = [
    'What is your Ishta Devata (favorite deity)?',
    'What is your family Gotra or native village?',
    'What was the name of your first spiritual Guru or temple visited?',
    'What is your favorite Vedic festival?',
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _securityAnswerController.dispose();
    super.dispose();
  }

  void _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both username and password.')),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (_isLogin) {
      final success = await auth.login(username, password);
      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationShell()),
        );
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(auth.errorMessage ?? 'Login failed. Please check username & password.'),
          ),
        );
      }
    } else {
      final confirm = _confirmPasswordController.text.trim();
      if (password != confirm) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match.')),
        );
        return;
      }

      final success = await auth.register(
        username: username,
        password: password,
        defaultRegion: _selectedRegion,
        preferredLanguage: auth.currentLanguage,
        accountType: _selectedRole,
        securityQuestion: _selectedSecurityQuestion,
        securityAnswer: _securityAnswerController.text.trim(),
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Account created successfully! Please sign in with your credentials.'),
          ),
        );
        setState(() => _isLogin = true);
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(auth.errorMessage ?? 'Registration failed.'),
          ),
        );
      }
    }
  }

  void _openForgotPasswordDialog() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final recoveryUsernameController = TextEditingController(text: _usernameController.text.trim());
    final newPasswordController = TextEditingController();
    final confirmNewPasswordController = TextEditingController();
    final securityAnswerController = TextEditingController();
    
    bool isChecking = false;
    bool hasAccountFound = false;
    bool hasSecurityQuestion = false;
    String securityQuestionText = '';
    String fallbackRegion = 'General/Standard';
    String fallbackRole = 'User';
    bool obscureNew = true;
    bool obscureConfirmNew = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primarySaffron.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.lock_reset, color: AppTheme.primarySaffron),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                auth.tr('reset_password'),
                                style: GoogleFonts.cinzel(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Enter your username to recover your sanctum access:',
                        style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: recoveryUsernameController,
                        enabled: !hasAccountFound,
                        decoration: InputDecoration(
                          labelText: auth.tr('username'),
                          prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primarySaffron),
                          suffixIcon: !hasAccountFound
                              ? ElevatedButton(
                                  onPressed: isChecking
                                      ? null
                                      : () async {
                                          final u = recoveryUsernameController.text.trim();
                                          if (u.isEmpty) return;
                                          setModalState(() => isChecking = true);
                                          final res = await ApiService.getRecoveryInfo(u);
                                          setModalState(() {
                                            isChecking = false;
                                            if (res['success'] == true) {
                                              hasAccountFound = true;
                                              hasSecurityQuestion = res['has_security_question'] == true;
                                              securityQuestionText = res['security_question'] ?? '';
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(res['error'] ?? 'User not found')),
                                              );
                                            }
                                          });
                                        },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: isChecking
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Text('Verify', style: TextStyle(fontSize: 12)),
                                )
                              : const Icon(Icons.check_circle, color: Colors.green),
                        ),
                      ),

                      if (hasAccountFound) ...[
                        const SizedBox(height: 16),
                        if (hasSecurityQuestion && securityQuestionText.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.sacredGold.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Security Question:',
                                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryDark),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  securityQuestionText,
                                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textDark),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: securityAnswerController,
                            decoration: const InputDecoration(
                              labelText: 'Your Answer',
                              prefixIcon: Icon(Icons.question_answer_outlined, color: AppTheme.primarySaffron),
                            ),
                          ),
                        ] else ...[
                          // Fallback verification for accounts without security questions
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade300),
                            ),
                            child: Text(
                              'Verify your account by confirming your registered Tradition and Role:',
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.brown.shade800),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: fallbackRegion,
                            decoration: const InputDecoration(
                              labelText: 'Registered Tradition',
                              prefixIcon: Icon(Icons.map_outlined, color: AppTheme.primarySaffron),
                            ),
                            items: _regions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                            onChanged: (val) => setModalState(() => fallbackRegion = val ?? 'General/Standard'),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: fallbackRole,
                            decoration: const InputDecoration(
                              labelText: 'Registered Role',
                              prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.primarySaffron),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'User', child: Text('Devotee / User')),
                              DropdownMenuItem(value: 'Purohit', child: Text('Purohit / Brahmin')),
                            ],
                            onChanged: (val) => setModalState(() => fallbackRole = val ?? 'User'),
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextField(
                          controller: newPasswordController,
                          obscureText: obscureNew,
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primarySaffron),
                            suffixIcon: IconButton(
                              icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                              onPressed: () => setModalState(() => obscureNew = !obscureNew),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: confirmNewPasswordController,
                          obscureText: obscureConfirmNew,
                          decoration: InputDecoration(
                            labelText: 'Confirm New Password',
                            prefixIcon: const Icon(Icons.lock_reset, color: AppTheme.primarySaffron),
                            suffixIcon: IconButton(
                              icon: Icon(obscureConfirmNew ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                              onPressed: () => setModalState(() => obscureConfirmNew = !obscureConfirmNew),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () async {
                              final newPass = newPasswordController.text.trim();
                              final confirmPass = confirmNewPasswordController.text.trim();
                              if (newPass.length < 4) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Password must be at least 4 characters.')),
                                );
                                return;
                              }
                              if (newPass != confirmPass) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('New passwords do not match.')),
                                );
                                return;
                              }

                              final res = await ApiService.resetPassword(
                                username: recoveryUsernameController.text.trim(),
                                newPassword: newPass,
                                securityAnswer: securityAnswerController.text.trim(),
                                verifyRegion: hasSecurityQuestion ? null : fallbackRegion,
                                verifyRole: hasSecurityQuestion ? null : fallbackRole,
                              );

                              if (res['success'] == true && context.mounted) {
                                Navigator.pop(context);
                                _usernameController.text = recoveryUsernameController.text.trim();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: Colors.green,
                                    content: Text('Password reset successfully! Please sign in.'),
                                  ),
                                );
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.red.shade700,
                                    content: Text(res['error'] ?? 'Reset failed. Check details.'),
                                  ),
                                );
                              }
                            },
                            child: const Text('Reset & Update Password'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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

    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton.icon(
            onPressed: _showLanguageSelector,
            icon: const Icon(Icons.language, size: 18, color: AppTheme.primarySaffron),
            label: Text(
              auth.currentLanguage,
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primarySaffron),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header Sacred Symbol
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.goldGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.sacredGold.withValues(alpha: 0.45),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🕉️', style: TextStyle(fontSize: 36)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  auth.tr('app_title'),
                  style: GoogleFonts.cinzel(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDark,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  auth.tr('app_tagline'),
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 24),

                // Card with Toggle
                Container(
                  decoration: AppTheme.sacredBoxDecoration(hasGlow: true),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Toggle Tabs
                      Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.sacredGold.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isLogin = true),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: _isLogin ? AppTheme.saffronGradient : null,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    auth.tr('sign_in'),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: _isLogin ? Colors.white : AppTheme.textDark,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isLogin = false),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: !_isLogin ? AppTheme.saffronGradient : null,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    auth.tr('register'),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: !_isLogin ? Colors.white : AppTheme.textDark,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Username Input Field
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: auth.tr('username'),
                          prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primarySaffron),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password Input Field with Eye Toggle
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: auth.tr('password'),
                          prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primarySaffron),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),

                      // Forgot Password Link for Login
                      if (_isLogin) ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _openForgotPasswordDialog,
                            child: Text(
                              auth.tr('forgot_password'),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primarySaffron,
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Additional registration fields
                      if (!_isLogin) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: auth.tr('confirm_password'),
                            prefixIcon: const Icon(Icons.lock_reset, color: AppTheme.primarySaffron),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: InputDecoration(
                            labelText: auth.tr('role'),
                            prefixIcon: const Icon(Icons.verified_user_outlined, color: AppTheme.primarySaffron),
                          ),
                          items: [
                            DropdownMenuItem(value: 'User', child: Text(auth.tr('devotee'))),
                            DropdownMenuItem(value: 'Purohit', child: Text(auth.tr('purohit'))),
                          ],
                          onChanged: (val) => setState(() => _selectedRole = val ?? 'User'),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedRegion,
                          decoration: InputDecoration(
                            labelText: auth.tr('tradition'),
                            prefixIcon: const Icon(Icons.location_on_outlined, color: AppTheme.primarySaffron),
                          ),
                          items: _regions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                          onChanged: (val) => setState(() => _selectedRegion = val ?? 'General/Standard'),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedSecurityQuestion,
                          decoration: const InputDecoration(
                            labelText: 'Recovery Security Question',
                            prefixIcon: Icon(Icons.security, color: AppTheme.primarySaffron),
                          ),
                          items: _securityQuestions.map((q) => DropdownMenuItem(value: q, child: Text(q, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (val) => setState(() => _selectedSecurityQuestion = val ?? _securityQuestions.first),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _securityAnswerController,
                          decoration: const InputDecoration(
                            labelText: 'Security Answer',
                            prefixIcon: Icon(Icons.question_answer_outlined, color: AppTheme.primarySaffron),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 16),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: AppTheme.saffronGradient,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: auth.isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      _isLogin ? auth.tr('sign_in') : auth.tr('create_account'),
                                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
