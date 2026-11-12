import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../utils/url_helper.dart';
import '../widgets/interactive_map_widget.dart';

class YajmanCrmScreen extends StatefulWidget {
  const YajmanCrmScreen({super.key});

  @override
  State<YajmanCrmScreen> createState() => _YajmanCrmScreenState();
}

class _YajmanCrmScreenState extends State<YajmanCrmScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tab 1: Incoming Bookings
  List<dynamic> _pendingBookings = [];
  bool _isLoadingBookings = true;

  // Tab 2: Clients & Yajmans
  List<dynamic> _clients = [];
  bool _isLoadingClients = true;
  final _clientNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _poojaDateController = TextEditingController(text: '2026-11-20');
  final _poojaTypeController = TextEditingController(text: 'Satyanarayan Katha');
  final _addressController = TextEditingController(text: 'Home Mandir');

  // Tab 3: Completed Records & History Archive
  List<dynamic> _completedRecords = [];
  bool _isLoadingCompleted = true;
  String _completedSearchQuery = '';

  // Tab 4: My Reviews & Ratings
  List<dynamic> _myReviews = [];
  bool _isLoadingReviews = true;
  double _averageRating = 5.0;

  // Tab 5: Blocked Calendar Dates
  List<dynamic> _blockedDates = [];
  bool _isLoadingBlocked = true;
  final _blockDateController = TextEditingController(text: '2026-11-25');
  final _reasonController = TextEditingController(text: 'Personal / Traveling');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _clientNameController.dispose();
    _contactController.dispose();
    _poojaDateController.dispose();
    _poojaTypeController.dispose();
    _addressController.dispose();
    _blockDateController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _loadAll() {
    _fetchPendingBookings();
    _fetchClients();
    _fetchCompletedRecords();
    _fetchMyReviews();
    _fetchBlockedDates();
  }

  Future<void> _fetchPendingBookings() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username ?? 'Purohit';
    final bookings = await ApiService.getPendingBookings(purohitUsername: username);
    if (mounted) {
      setState(() {
        _pendingBookings = bookings;
        _isLoadingBookings = false;
      });
    }
  }

  Future<void> _fetchClients() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username ?? 'Purohit';
    final clients = await ApiService.getPurohitClients(username);
    if (mounted) {
      setState(() {
        _clients = clients;
        _isLoadingClients = false;
      });
    }
  }

  Future<void> _fetchCompletedRecords() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username ?? 'Purohit';
    final records = await ApiService.getPurohitBookings(username, status: 'Completed');
    if (mounted) {
      setState(() {
        _completedRecords = records;
        _isLoadingCompleted = false;
      });
    }
  }

  Future<void> _fetchMyReviews() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username ?? 'Purohit';
    final reviews = await ApiService.getPurohitReviews(username);
    if (mounted) {
      double avg = 5.0;
      if (reviews.isNotEmpty) {
        final total = reviews.fold<double>(0.0, (sum, r) => sum + (r['Rating'] ?? r['rating'] ?? 5));
        avg = double.parse((total / reviews.length).toStringAsFixed(1));
      }
      setState(() {
        _myReviews = reviews;
        _averageRating = avg;
        _isLoadingReviews = false;
      });
    }
  }

  Future<void> _acceptBooking(dynamic b) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username ?? 'Purohit';
    final bookingId = b['id'] ?? b['ID'] ?? 0;
    final devotee = b['User'] ?? b['user_username'] ?? 'Devotee';

    final success = await ApiService.acceptBooking(bookingId, username);
    if (success) {
      _fetchPendingBookings();
      _fetchClients();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Sacred ceremony for $devotee accepted! Added to your client directory.'),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to accept booking. Please try again.')),
        );
      }
    }
  }

  Future<void> _addClient() async {
    final name = _clientNameController.text.trim();
    final contact = _contactController.text.trim();
    if (name.isEmpty || contact.isEmpty) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username ?? 'Purohit';

    try {
      final uri = Uri.parse('${ApiService.baseUrl}/yajman/add');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'purohit_username': username,
          'client_name': name,
          'contact_number': contact,
          'pooja_date': _poojaDateController.text.trim(),
          'pooja_type': _poojaTypeController.text.trim(),
          'address': _addressController.text.trim().isEmpty ? 'Home Mandir' : _addressController.text.trim(),
        }),
      );
      if (res.statusCode == 200) {
        _clientNameController.clear();
        _contactController.clear();
        _fetchClients();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yajman added successfully!')));
        }
      }
    } catch (_) {}
  }

  Future<void> _deleteClient(int clientId) async {
    final success = await ApiService.deleteClient(clientId);
    if (success) {
      _fetchClients();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Client record deleted.')));
    }
  }

  Future<void> _fetchBlockedDates() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username ?? 'Purohit';
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/workspace/blocked-dates/$username');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _blockedDates = data['blocked_dates'] ?? [];
            _isLoadingBlocked = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBlocked = false);
    }
  }

  Future<void> _addBlockedDate() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username ?? 'Purohit';
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/workspace/blocked-dates');
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'purohit_username': username,
          'blocked_date': _blockDateController.text.trim(),
          'reason': _reasonController.text.trim(),
        }),
      );
      _fetchBlockedDates();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Date blocked on calendar!')));
      }
    } catch (_) {}
  }

  Future<void> _unblockDate(int blockedId) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/workspace/blocked-dates/$blockedId');
      await http.delete(uri);
      _fetchBlockedDates();
    } catch (_) {}
  }

  void _openWhatsAppReminderDialog({
    required String clientName,
    required String contactNumber,
    required String poojaType,
    required String poojaDate,
    required String address,
  }) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final purohitUsername = auth.currentUser?.username ?? 'Purohit';

    final defaultReminderText =
        '🙏 *सप्रेम नमस्कार / Auspicious Greetings!* 🙏\n\n'
        'Dear $clientName ji,\n'
        'This is a sacred reminder from Panditji $purohitUsername regarding your upcoming ceremony:\n'
        '🕉️ *Ceremony*: $poojaType\n'
        '📅 *Date*: $poojaDate\n'
        '📍 *Venue*: $address\n\n'
        '✨ *Sacred Samagri Preparation*:\n'
        'Please ensure the pooja space is washed, fresh flowers and fruits are arranged, and preliminary samagri is kept ready prior to the auspicious muhurta.\n\n'
        'May the divine deities shower eternal blessings and prosperity upon your family! 🌺\n'
        '— *Pandit $purohitUsername* via VedaGuru AI';

    final messageController = TextEditingController(text: defaultReminderText);
    final phoneController = TextEditingController(text: contactNumber);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(22),
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
                              color: Colors.green.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chat_bubble_rounded, color: Colors.green, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WhatsApp Sacred Reminder',
                                style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                              ),
                              Text(
                                'Auspicious notice for $clientName',
                                style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(height: 20),
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Devotee WhatsApp Phone',
                      prefixIcon: const Icon(Icons.phone, color: Colors.green, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: messageController,
                    maxLines: 7,
                    decoration: InputDecoration(
                      labelText: 'Personalized Vedic Message',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: messageController.text));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message copied to clipboard!')));
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy Text', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final rawPhone = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
                            final encodedMsg = Uri.encodeComponent(messageController.text);
                            final waUrl = rawPhone.isNotEmpty
                                ? 'https://wa.me/$rawPhone?text=$encodedMsg'
                                : 'https://wa.me/?text=$encodedMsg';
                            openWebUrl(waUrl);
                            Navigator.pop(ctx);
                          },
                          icon: const Icon(Icons.send_rounded, size: 16),
                          label: const Text('Open WhatsApp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddClientDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.person_add_rounded, color: AppTheme.primarySaffron),
            const SizedBox(width: 8),
            Text('Add Yajman Client', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _clientNameController,
                decoration: InputDecoration(
                  labelText: 'Devotee / Yajman Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contactController,
                decoration: InputDecoration(
                  labelText: 'WhatsApp Contact Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _poojaTypeController,
                decoration: InputDecoration(
                  labelText: 'Ceremony / Pooja Name',
                  prefixIcon: const Icon(Icons.temple_hindu_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _poojaDateController,
                decoration: InputDecoration(
                  labelText: 'Scheduled Date (YYYY-MM-DD)',
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Mandir / Home Venue Address',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: _addClient, child: const Text('Save Yajman')),
        ],
      ),
    );
  }

  void _showAddBlockedDateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.event_busy, color: Colors.red),
            const SizedBox(width: 8),
            Text('Block Calendar Date', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _blockDateController,
              decoration: InputDecoration(
                labelText: 'Date to Block (YYYY-MM-DD)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'Reason (Optional)',
                hintText: 'e.g. Out of town / Yagya Mahotsav',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: _addBlockedDate, child: const Text('Block Date')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Purohit Operations & CRM',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh all records',
            onPressed: _loadAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppTheme.primarySaffron,
          labelColor: AppTheme.primaryDark,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: [
            Tab(
              text: '🔔 Incoming (${_pendingBookings.length})',
            ),
            Tab(
              text: '👥 Yajmans (${_clients.length})',
            ),
            Tab(
              text: '📜 Completed (${_completedRecords.length})',
            ),
            Tab(
              text: '⭐ Reviews (${_myReviews.length})',
            ),
            Tab(
              text: '📅 Calendar (${_blockedDates.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingBookingsTab(),
          _buildClientsTab(),
          _buildCompletedRecordsTab(),
          _buildReviewsTab(),
          _buildBlockedDatesTab(),
        ],
      ),
    );
  }

  // ==================== Tab 1: Incoming Bookings with User Details & Location Map ====================
  Widget _buildPendingBookingsTab() {
    return _isLoadingBookings
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primarySaffron))
        : _pendingBookings.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_none_rounded, size: 54, color: AppTheme.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        'No pending ritual requests from devotees.',
                        style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Devotees who book you via the app will appear here with their ceremony and venue map.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _pendingBookings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, idx) {
                  final b = _pendingBookings[idx];
                  final userUname = b['User'] ?? b['user_username'] ?? b['client_name'] ?? 'Devotee';
                  final contact = b['Contact'] ?? b['contact_number'] ?? '';
                  final poojaType = b['Pooja Type'] ?? b['pooja_type'] ?? 'Sacred Ceremony';
                  final poojaDate = b['Pooja Date'] ?? b['pooja_date'] ?? '';
                  final address = b['Address'] ?? b['address'] ?? 'Devotee Mandir';
                  final lat = (b['latitude'] ?? b['lat'] ?? 18.5204).toDouble();
                  final lng = (b['longitude'] ?? b['lng'] ?? 73.8567).toDouble();

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.sacredBoxDecoration(hasGlow: true),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Pooja Name & Pending Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.temple_hindu, color: AppTheme.primarySaffron, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      poojaType,
                                      style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.orange.shade300),
                              ),
                              child: const Text('Pending Request', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ],
                        ),
                        const Divider(height: 18),

                        // Devotee Name & Contact
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.amber.shade100,
                              child: Text(
                                userUname.isNotEmpty ? userUname.substring(0, 1).toUpperCase() : 'D',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown.shade900),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Devotee: $userUname',
                                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                                  ),
                                  Text(
                                    contact.isNotEmpty ? '📞 $contact' : 'No contact phone provided',
                                    style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 12, color: AppTheme.sacredGold),
                                  const SizedBox(width: 4),
                                  Text(poojaDate, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Actual Location & Address
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                address,
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textDark),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // One-tap Direct Google Maps Navigation
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  final navUrl = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
                                  openWebUrl(navUrl);
                                },
                                icon: const Icon(Icons.navigation_rounded, color: Colors.green, size: 15),
                                label: const Text('Track on Google Maps', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.green.shade400),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Interactive Geographical Map Preview of Devotee's Location
                        InteractiveSacredMap(
                          isPicker: false,
                          initialLat: lat,
                          initialLng: lng,
                          height: 180,
                          devoteeName: userUname,
                          poojaType: poojaType,
                          venueAddress: address,
                        ),
                        const SizedBox(height: 16),

                        // Action Buttons: WhatsApp Reminder & Accept Booking
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _openWhatsAppReminderDialog(
                                  clientName: userUname,
                                  contactNumber: contact,
                                  poojaType: poojaType,
                                  poojaDate: poojaDate,
                                  address: address,
                                ),
                                icon: const Icon(Icons.chat_bubble_rounded, color: Colors.green, size: 16),
                                label: const Text('WhatsApp', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () => _acceptBooking(b),
                                icon: const Icon(Icons.check_circle_rounded, size: 16),
                                label: const Text('Accept Ceremony', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
  }

  // ==================== Tab 2: My Direct Yajmans ====================
  Widget _buildClientsTab() {
    return _isLoadingClients
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primarySaffron))
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Devotee Directory (${_clients.length})',
                      style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddClientDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Yajman', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _clients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_outline_rounded, size: 50, color: AppTheme.textMuted),
                            const SizedBox(height: 8),
                            Text('No direct clients added yet.', style: GoogleFonts.poppins(color: AppTheme.textMuted)),
                            const SizedBox(height: 8),
                            ElevatedButton(onPressed: _showAddClientDialog, child: const Text('Add Your First Yajman')),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _clients.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, idx) {
                          final c = _clients[idx];
                          final clientName = c['Client Name'] ?? c['client_name'] ?? c['User'] ?? 'Yajman';
                          final contact = c['Contact'] ?? c['contact_number'] ?? '';
                          final poojaType = c['Pooja Type'] ?? c['pooja_type'] ?? 'Pooja';
                          final poojaDate = c['Pooja Date'] ?? c['pooja_date'] ?? '';
                          final address = c['Address'] ?? c['address'] ?? 'Devotee Mandir';
                          final clientId = c['ID'] ?? c['id'] ?? 0;
                          final lat = (c['latitude'] ?? c['lat'] ?? 18.5204).toDouble();
                          final lng = (c['longitude'] ?? c['lng'] ?? 73.8567).toDouble();

                          return Container(
                            padding: const EdgeInsets.all(16),
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
                                          backgroundColor: Colors.amber.shade100,
                                          radius: 20,
                                          child: Text(
                                            clientName.isNotEmpty ? clientName.substring(0, 1).toUpperCase() : 'Y',
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown.shade900),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              clientName,
                                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                            ),
                                            Row(
                                              children: [
                                                const Icon(Icons.phone, size: 12, color: Colors.green),
                                                const SizedBox(width: 4),
                                                Text(contact, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      onPressed: () => _deleteClient(clientId),
                                      tooltip: 'Delete client',
                                    ),
                                  ],
                                ),
                                const Divider(height: 18),
                                Row(
                                  children: [
                                    const Icon(Icons.temple_hindu, size: 14, color: AppTheme.primarySaffron),
                                    const SizedBox(width: 6),
                                    Text(poojaType, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                                    const Spacer(),
                                    const Icon(Icons.calendar_today, size: 13, color: AppTheme.sacredGold),
                                    const SizedBox(width: 4),
                                    Text(poojaDate, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textMuted),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        address,
                                        style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMuted),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Action Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _openWhatsAppReminderDialog(
                                          clientName: clientName,
                                          contactNumber: contact,
                                          poojaType: poojaType,
                                          poojaDate: poojaDate,
                                          address: address,
                                        ),
                                        icon: const Icon(Icons.chat_bubble_rounded, size: 15, color: Colors.white),
                                        label: const Text('Send Reminder', style: TextStyle(fontSize: 11)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green.shade700,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        final navUrl = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
                                        openWebUrl(navUrl);
                                      },
                                      icon: const Icon(Icons.navigation_rounded, size: 14, color: Colors.green),
                                      label: const Text('Google Maps', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: Colors.green.shade400),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
  }

  // ==================== Tab 3: Completed Records & History Archive ====================
  Widget _buildCompletedRecordsTab() {
    if (_isLoadingCompleted) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primarySaffron));
    }

    final filtered = _completedRecords.where((r) {
      final q = _completedSearchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      final uname = (r['User'] ?? r['user_username'] ?? '').toString().toLowerCase();
      final pooja = (r['Pooja Type'] ?? r['pooja_type'] ?? '').toString().toLowerCase();
      return uname.contains(q) || pooja.contains(q);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.goldGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.sacredGold.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${_completedRecords.length}',
                      style: GoogleFonts.cinzel(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.brown.shade900),
                    ),
                    Text('Ceremonies Done', style: GoogleFonts.poppins(fontSize: 11, color: Colors.brown.shade800)),
                  ],
                ),
                Container(width: 1, height: 40, color: Colors.brown.shade300),
                Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '$_averageRating',
                          style: GoogleFonts.cinzel(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.brown.shade900),
                        ),
                      ],
                    ),
                    Text('Devotee Rating', style: GoogleFonts.poppins(fontSize: 11, color: Colors.brown.shade800)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search Box
          TextField(
            decoration: InputDecoration(
              hintText: 'Search completed records by devotee or ceremony...',
              hintStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.search, color: AppTheme.primarySaffron, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onChanged: (val) => setState(() => _completedSearchQuery = val),
          ),
          const SizedBox(height: 16),

          Text(
            'Completed Ritual Archive (${filtered.length})',
            style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),

          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(Icons.assignment_turned_in_outlined, size: 48, color: AppTheme.textMuted),
                    const SizedBox(height: 8),
                    Text(
                      'No completed ritual records found.',
                      style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final r = filtered[idx];
                final userUname = r['User'] ?? r['user_username'] ?? 'Devotee';
                final poojaType = r['Pooja Type'] ?? r['pooja_type'] ?? 'Pooja';
                final poojaDate = r['Pooja Date'] ?? r['pooja_date'] ?? '';
                final address = r['Address'] ?? r['address'] ?? 'Venue';
                final contact = r['Contact'] ?? r['contact_number'] ?? '';
                final stars = r['Rating'] ?? r['rating'] ?? 5;
                final feedback = r['Feedback'] ?? r['feedback'] ?? '';
                final lat = (r['latitude'] ?? r['lat'] ?? 18.5204).toDouble();
                final lng = (r['longitude'] ?? r['lng'] ?? 73.8567).toDouble();

                return Container(
                  padding: const EdgeInsets.all(16),
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
                                radius: 18,
                                backgroundColor: Colors.green.shade100,
                                child: Text(
                                  userUname.isNotEmpty ? userUname.substring(0, 1).toUpperCase() : 'D',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userUname,
                                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                  ),
                                  Text('Completed on $poojaDate', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMuted)),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: const Text('Completed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.temple_hindu, size: 14, color: AppTheme.primarySaffron),
                          const SizedBox(width: 6),
                          Text(poojaType, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                                size: 15,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              address,
                              style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMuted),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (feedback.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '"$feedback"',
                          style: GoogleFonts.poppins(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.brown.shade800),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Re-contact & Map Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final waUrl = contact.isNotEmpty
                                    ? 'https://wa.me/$contact?text=Namaste%20$userUname%20ji,%20greetings%20from%20Panditji.'
                                    : 'https://wa.me/?text=Namaste%20$userUname%20ji.';
                                openWebUrl(waUrl);
                              },
                              icon: const Icon(Icons.chat_bubble_rounded, size: 14, color: Colors.green),
                              label: const Text('Send Blessings', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              final navUrl = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
                              openWebUrl(navUrl);
                            },
                            icon: const Icon(Icons.navigation_rounded, size: 14, color: Colors.green),
                            label: const Text('Google Maps', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.green.shade400),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ==================== Tab 4: Devotee Reviews ====================
  Widget _buildReviewsTab() {
    return _isLoadingReviews
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primarySaffron))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Text('⭐', style: GoogleFonts.poppins(fontSize: 26)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_averageRating / 5.0 Rating',
                              style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown.shade900),
                            ),
                            Text(
                              'Based on ${_myReviews.length} devotee reviews',
                              style: GoogleFonts.poppins(fontSize: 11, color: Colors.brown.shade800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Devotee Reviews & Feedback (${_myReviews.length})',
                  style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                const SizedBox(height: 10),

                if (_myReviews.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(Icons.rate_review_outlined, size: 48, color: AppTheme.textMuted),
                          const SizedBox(height: 8),
                          Text('No reviews received yet.', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 13)),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _myReviews.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final r = _myReviews[idx];
                      final stars = r['Rating'] ?? r['rating'] ?? 5;
                      final user = r['User'] ?? r['user_username'] ?? 'Devotee';
                      final pooja = r['Pooja Type'] ?? r['pooja_type'] ?? 'Ceremony';
                      final date = r['Pooja Date'] ?? r['pooja_date'] ?? '';
                      final feedback = r['Feedback'] ?? r['feedback'] ?? 'Authentic ceremony conducted with devotion.';

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: AppTheme.sacredBoxDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(user, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => Icon(
                                      i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                                      size: 15,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('$pooja • $date', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMuted)),
                            const SizedBox(height: 6),
                            Text('"$feedback"', style: GoogleFonts.poppins(fontSize: 12, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
  }

  // ==================== Tab 5: Calendar Blocked Dates ====================
  Widget _buildBlockedDatesTab() {
    return _isLoadingBlocked
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primarySaffron))
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Blocked Dates (${_blockedDates.length})',
                      style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddBlockedDateDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Block Date', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _blockedDates.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.event_available_rounded, size: 50, color: AppTheme.textMuted),
                            const SizedBox(height: 8),
                            Text('No dates blocked on calendar.', style: GoogleFonts.poppins(color: AppTheme.textMuted)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _blockedDates.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, idx) {
                          final b = _blockedDates[idx];
                          final date = b['Date'] ?? b['blocked_date'] ?? '';
                          final reason = b['Reason'] ?? b['reason'] ?? 'Busy';
                          final id = b['ID'] ?? b['id'] ?? 0;

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: AppTheme.sacredBoxDecoration(),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.event_busy, color: Colors.red, size: 20),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(date, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                                        Text(reason, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMuted)),
                                      ],
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  onPressed: () => _unblockDate(id),
                                  tooltip: 'Unblock date',
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
  }
}
