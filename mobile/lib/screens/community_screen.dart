import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<dynamic> _posts = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  final Set<int> _expandedPostIds = {};

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedRegion = 'General/Standard';

  final List<String> _regions = [
    'General/Standard',
    'North Indian',
    'South Indian',
    'Maharashtrian',
    'Gujarati',
    'Bengali',
    'Kashmiri',
    'Konkani',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _fetchFeed();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  int? _getId(dynamic p) {
    final val = p['ID'] ?? p['id'];
    if (val is int) return val;
    if (val != null) return int.tryParse(val.toString());
    return null;
  }

  String _getAuthor(dynamic p) => (p['Author'] ?? p['author_username'] ?? 'Devotee').toString();
  String _getTitle(dynamic p) => (p['Title'] ?? p['title'] ?? 'Untitled Vidhi').toString();
  String _getRegion(dynamic p) => (p['Region'] ?? p['region'] ?? 'General').toString();
  String _getContent(dynamic p) => (p['Vidhi Text'] ?? p['vidhi_text'] ?? p['content'] ?? '').toString();
  String _getTimestamp(dynamic p) {
    final ts = (p['Timestamp'] ?? p['timestamp'] ?? '').toString();
    if (ts.length >= 10) return ts.substring(0, 10);
    return ts;
  }

  Future<void> _fetchFeed() async {
    final posts = await ApiService.getCommunityFeed();
    if (mounted) {
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    }
  }

  Future<void> _shareVidhi(StateSetter setDialogState) async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title for the ritual.')),
      );
      return;
    }
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the Vidhi steps and instructions.')),
      );
      return;
    }

    setDialogState(() => _isSubmitting = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username ?? 'Devotee';

    final res = await ApiService.addCommunityVidhi(
      username: username,
      title: title,
      region: _selectedRegion,
      content: content,
    );

    if (mounted) {
      setDialogState(() => _isSubmitting = false);
      if (res['success'] == true) {
        _titleController.clear();
        _contentController.clear();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your Vidhi has been published to the community!')),
        );
        _fetchFeed();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['error'] ?? res['message'] ?? 'Failed to publish Vidhi.')),
        );
      }
    }
  }

  Future<void> _confirmDeletePost(int vidhiId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Post', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this ritual from the community feed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ApiService.deleteCommunityVidhi(vidhiId);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ritual deleted successfully.')),
          );
          _fetchFeed();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete post.')),
          );
        }
      }
    }
  }

  void _showShareDialog() {
    _isSubmitting = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Share a Regional Custom',
              style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title of the Ritual / Tradition',
                      hintText: 'e.g. Maharashtrian Satyanarayan Pooja',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedRegion,
                    items: _regions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => _selectedRegion = val);
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Region / Tradition'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contentController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Vidhi Steps & Special Customs',
                      hintText: 'Type or paste the complete ritual steps, mantras, or guidance here...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isSubmitting ? null : () => _shareVidhi(setDialogState),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primarySaffron),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Publish to Community', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final currentUsername = auth.currentUser?.username ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Community Ritual Feed',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showShareDialog,
        backgroundColor: AppTheme.primarySaffron,
        icon: const Icon(Icons.share_rounded, color: Colors.white),
        label: const Text('Share Vidhi', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primarySaffron))
          : RefreshIndicator(
              color: AppTheme.primarySaffron,
              onRefresh: _fetchFeed,
              child: _posts.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text(
                              'No community traditions posted yet.\nBe the first to share your regional rituals!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.textMuted, height: 1.5),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: _posts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final p = _posts[idx];
                        final id = _getId(p);
                        final author = _getAuthor(p);
                        final title = _getTitle(p);
                        final region = _getRegion(p);
                        final content = _getContent(p);
                        final timestamp = _getTimestamp(p);
                        final isAuthor = currentUsername.isNotEmpty &&
                            author.toLowerCase() == currentUsername.toLowerCase();
                        final isExpanded = id != null && _expandedPostIds.contains(id);
                        final isLongText = content.length > 250;

                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: AppTheme.surfaceElevated,
                                          child: Text(
                                            author.isNotEmpty ? author[0].toUpperCase() : 'D',
                                            style: GoogleFonts.cinzel(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryDark,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              author,
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: AppTheme.textDark,
                                              ),
                                            ),
                                            if (timestamp.isNotEmpty)
                                              Text(
                                                '📅 $timestamp',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: AppTheme.textMuted,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        region,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.amber.shade900,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  title,
                                  style: GoogleFonts.cinzel(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryDark,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SelectableText(
                                  (!isLongText || isExpanded)
                                      ? content
                                      : '${content.substring(0, 250)}...',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                if (isLongText && id != null) ...[
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        if (isExpanded) {
                                          _expandedPostIds.remove(id);
                                        } else {
                                          _expandedPostIds.add(id);
                                        }
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            isExpanded ? 'Show Less' : 'Read Full Vidhi',
                                            style: const TextStyle(
                                              color: AppTheme.primarySaffron,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Icon(
                                            isExpanded
                                                ? Icons.keyboard_arrow_up
                                                : Icons.keyboard_arrow_down,
                                            size: 16,
                                            color: AppTheme.primarySaffron,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                if (isAuthor && id != null) ...[
                                  const Divider(height: 20),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () => _confirmDeletePost(id),
                                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                      label: const Text(
                                        'Delete Post',
                                        style: TextStyle(color: Colors.red, fontSize: 11),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
