import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username ?? 'Devotee';
    final logs = await ApiService.getUserHistory(username);
    if (mounted) {
      setState(() {
        _history = logs;
        _isLoading = false;
      });
    }
  }

  String _getModuleIcon(String mod) {
    if (mod.contains('master')) return '🌟';
    if (mod.contains('samagri')) return '📋';
    if (mod.contains('guidance')) return '🪔';
    if (mod.contains('muhurat')) return '⏳';
    if (mod.contains('kundali')) return '♈';
    if (mod.contains('matchmaking')) return '💞';
    if (mod.contains('rashichakra')) return '🌌';
    if (mod.contains('chanting')) return '🧘';
    if (mod.contains('annapurna')) return '🍲';
    if (mod.contains('library')) return '📚';
    if (mod.contains('aarti')) return '🪔';
    if (mod.contains('mantra')) return '📿';
    if (mod.contains('katha')) return '📖';
    if (mod.contains('vastu')) return '🏡';
    if (mod.contains('tirth')) return '🛕';
    return '📜';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Activity Log & Audit Trail',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primarySaffron))
          : _history.isEmpty
              ? const Center(child: Text('No past ritual history found.', style: TextStyle(color: AppTheme.textMuted)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final item = _history[idx];
                    final mod = item['module_name'] ?? 'Vedic Tool';
                    final icon = _getModuleIcon(mod);
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.surfaceElevated,
                          child: Text(icon, style: const TextStyle(fontSize: 20)),
                        ),
                        title: Text(item['query_details'] ?? mod, style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('${item['module_name']} | ${item['timestamp'] ?? ''}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Response Content:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    IconButton(
                                      icon: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.primarySaffron),
                                      tooltip: 'Copy',
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: item['response_text'] ?? ''));
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!')));
                                      },
                                    ),
                                  ],
                                ),
                                const Divider(),
                                SelectableText(
                                  item['response_text'] ?? '',
                                  style: GoogleFonts.poppins(fontSize: 12.5, height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
