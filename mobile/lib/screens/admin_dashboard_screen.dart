import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  // Platform Metrics
  int _totalUsers = 0;
  int _totalQueries = 0;
  int _totalYajmans = 0;

  // Visualizations
  Map<String, dynamic> _moduleUsage = {};
  Map<String, dynamic> _regionDistribution = {};
  Map<String, dynamic> _roleDistribution = {};

  // User Directory
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterUsers() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_users);
      } else {
        _filteredUsers = _users.where((u) {
          final uname = (u['Username'] ?? '').toString().toLowerCase();
          final role = (u['Role'] ?? '').toString().toLowerCase();
          final region = (u['Region'] ?? '').toString().toLowerCase();
          return uname.contains(query) || role.contains(query) || region.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _fetchAdminData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final statsRes = await ApiService.getAdminStats();
    final usersList = await ApiService.getAdminUsers();

    if (mounted) {
      if (statsRes['success'] == true) {
        final data = statsRes['data'];
        final summary = data['summary'] ?? {};
        setState(() {
          _totalUsers = summary['Total Users'] ?? 0;
          _totalQueries = summary['Total Queries'] ?? 0;
          _totalYajmans = summary['Total Yajmans'] ?? 0;
          _moduleUsage = Map<String, dynamic>.from(data['module_usage'] ?? {});
          _regionDistribution = Map<String, dynamic>.from(data['region_distribution'] ?? {});
          _roleDistribution = Map<String, dynamic>.from(data['role_distribution'] ?? {});
          _users = usersList;
          _filteredUsers = List.from(usersList);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = statsRes['error'] ?? 'Failed to load administrative analytics.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    // Strict Administrative Guard: Only BVarad0876
    if (user == null || user.username != 'BVarad0876') {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Sanctum')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gpp_bad, size: 72, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Access Denied',
                  style: GoogleFonts.cinzel(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Administrative dashboard is strictly restricted to administrator BVarad0876.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Return to Sanctum'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.admin_panel_settings, color: AppTheme.sacredGold),
            const SizedBox(width: 8),
            Text(
              auth.tr('admin_sanctum_title'),
              style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
            ),
          ],
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
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primarySaffron),
            onPressed: _fetchAdminData,
            tooltip: 'Refresh Metrics',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primarySaffron))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _fetchAdminData, child: const Text('Retry')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Admin Header Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppTheme.goldGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.sacredGold.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Text('👑', style: TextStyle(fontSize: 24)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome, Super Administrator',
                                    style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown.shade900),
                                  ),
                                  Text(
                                    'Logged in as BVarad0876 • Complete Platform Telemetry & Controls',
                                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.brown.shade800),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 1. Platform Metrics
                      Text(
                        auth.tr('platform_metrics'),
                        style: GoogleFonts.cinzel(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildMetricCard(auth.tr('total_registered_users'), '$_totalUsers', Icons.people_outline, Colors.blue)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildMetricCard(auth.tr('total_ai_queries'), '$_totalQueries', Icons.psychology_outlined, Colors.purple)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildMetricCard(auth.tr('total_yajman_managed'), '$_totalYajmans', Icons.volunteer_activism_outlined, Colors.orange)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 2. Usage Visualizations
                      Text(
                        'Usage Visualizations',
                        style: GoogleFonts.cinzel(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      ),
                      const SizedBox(height: 12),

                      // Module Popularity Card
                      _buildVisualizationCard(
                        title: 'Module Popularity [Usage Count]',
                        icon: Icons.bar_chart,
                        child: _moduleUsage.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No module telemetry recorded yet.'),
                              )
                            : Column(
                                children: _moduleUsage.entries.map((entry) {
                                  final maxVal = _moduleUsage.values.fold<int>(1, (max, v) => (v as int) > max ? v : max);
                                  final count = entry.value as int;
                                  final double progress = maxVal > 0 ? (count / maxVal).clamp(0.05, 1.0) : 0.1;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(entry.key, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
                                            Text('$count uses', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primarySaffron)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        LinearProgressIndicator(
                                          value: progress,
                                          backgroundColor: Colors.grey.shade200,
                                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primarySaffron),
                                          minHeight: 8,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Regional Traditions Breakdown & Role Distribution
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildVisualizationCard(
                              title: 'Regional Traditions',
                              icon: Icons.temple_hindu,
                              child: _regionDistribution.isEmpty
                                  ? const Text('No data')
                                  : Column(
                                      children: _regionDistribution.entries.map((e) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(child: Text(e.key, style: GoogleFonts.poppins(fontSize: 12), overflow: TextOverflow.ellipsis)),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
                                                child: Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildVisualizationCard(
                              title: 'User Roles',
                              icon: Icons.pie_chart_outline,
                              child: _roleDistribution.isEmpty
                                  ? const Text('No data')
                                  : Column(
                                      children: _roleDistribution.entries.map((e) {
                                        final isPurohit = e.key.toString().toLowerCase() == 'purohit';
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(e.key, style: GoogleFonts.poppins(fontSize: 12)),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isPurohit ? Colors.deepOrange.shade100 : Colors.blue.shade100,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '${e.value}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                    color: isPurohit ? Colors.deepOrange.shade900 : Colors.blue.shade900,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 3. User Directory
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${auth.tr("user_directory")} (${_filteredUsers.length})',
                            style: GoogleFonts.cinzel(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.sacredGold.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'Verified Accounts',
                              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryDark),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Search filter bar
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: auth.tr('search_users_hint'),
                          prefixIcon: const Icon(Icons.search, color: AppTheme.primarySaffron),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // User Directory List Cards
                      if (_filteredUsers.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          alignment: Alignment.center,
                          child: Text('No users found matching query.', style: GoogleFonts.poppins(color: AppTheme.textMuted)),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredUsers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final u = _filteredUsers[index];
                            final isPurohit = (u['Role'] ?? '').toString().toLowerCase() == 'purohit';
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: AppTheme.sacredBoxDecoration(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: isPurohit ? Colors.deepOrange.shade100 : Colors.amber.shade100,
                                            radius: 18,
                                            child: Text(
                                              (u['Username'] ?? 'U').toString().substring(0, 1).toUpperCase(),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: isPurohit ? Colors.deepOrange.shade900 : Colors.brown.shade900,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                u['Username'] ?? '',
                                                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                              ),
                                              Text(
                                                'ID: #${u['ID'] ?? index + 1}',
                                                style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMuted),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isPurohit ? Colors.deepOrange.shade50 : Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isPurohit ? Colors.deepOrange.shade300 : Colors.blue.shade300,
                                          ),
                                        ),
                                        child: Text(
                                          u['Role'] ?? 'User',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isPurohit ? Colors.deepOrange.shade800 : Colors.blue.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 18),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Region', style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textMuted)),
                                            Text(u['Region'] ?? 'General', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Language', style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textMuted)),
                                            Text(u['Language'] ?? 'English', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.key, size: 14, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Text('Encrypted Password: ', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade700)),
                                        Expanded(
                                          child: Text(
                                            u['Encrypted Password'] ?? '••••••••',
                                            style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.black87),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: AppTheme.sacredBoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizationCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.sacredBoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primarySaffron),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
