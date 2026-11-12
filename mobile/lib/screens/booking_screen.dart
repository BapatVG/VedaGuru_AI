import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../utils/url_helper.dart';
import '../widgets/interactive_map_widget.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // New Booking Form State
  String _poojaKey = 'pooja_satyanarayan';
  final _dateController = TextEditingController(text: '2026-11-20');
  final _contactController = TextEditingController();
  final _addressDetailsController = TextEditingController();
  final _areaLandmarkController = TextEditingController();
  bool _isSubmitting = false;

  // Selected Purohit
  String _selectedPurohit = '';
  List<dynamic> _purohitsList = [];
  bool _isLoadingPurohits = true;

  // Interactive Geographical Map State
  double _mapLat = 18.5204; // Default: Pune, Maharashtra
  double _mapLng = 73.8567;
  String _selectedCityName = 'Pune';

  // My Bookings State
  List<dynamic> _myBookings = [];
  bool _isLoadingBookings = true;

  final List<String> _poojaKeys = [
    'pooja_satyanarayan',
    'pooja_griha_pravesh',
    'pooja_rudrabhishek',
    'pooja_navagraha',
    'pooja_vivaha',
    'pooja_mahamrityunjaya',
    'pooja_ganesh',
    'pooja_vastu',
    'pooja_kalsarp',
    'pooja_shraddha',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchRegisteredPurohits();
    _fetchMyBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dateController.dispose();
    _contactController.dispose();
    _addressDetailsController.dispose();
    _areaLandmarkController.dispose();
    super.dispose();
  }

  Future<void> _fetchRegisteredPurohits() async {
    final list = await ApiService.getPurohitsDirectory();
    if (mounted) {
      setState(() {
        _purohitsList = list;
        _isLoadingPurohits = false;
      });
    }
  }

  Future<void> _fetchMyBookings() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username ?? 'Devotee';
    final bookings = await ApiService.getUserBookings(username);
    if (mounted) {
      setState(() {
        _myBookings = bookings;
        _isLoadingBookings = false;
      });
    }
  }

  void _onLocationChanged(double lat, double lng, String resolvedAddress, String city) {
    setState(() {
      _mapLat = lat;
      _mapLng = lng;
      if (city.isNotEmpty) _selectedCityName = city;

      // Update area/landmark with map's detected address
      if (resolvedAddress.isNotEmpty) {
        _areaLandmarkController.text = resolvedAddress;
      }
    });
  }

  void _showPurohitReviews(Map<String, dynamic> purohit) {
    final reviews = purohit['reviews'] as List<dynamic>? ?? [];
    final uname = purohit['username'] ?? 'Purohit';
    final rating = purohit['rating'] ?? 5.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        'Pandit $uname',
                        style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                      ),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text('$rating / 5.0', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${reviews.length} Devotee Reviews', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: reviews.isEmpty
                    ? Center(
                        child: Text(
                          'No public reviews yet for Pandit $uname.',
                          style: GoogleFonts.poppins(color: AppTheme.textMuted),
                        ),
                      )
                    : ListView.separated(
                        itemCount: reviews.length,
                        separatorBuilder: (_, __) => const Divider(height: 16),
                        itemBuilder: (c, idx) {
                          final r = reviews[idx];
                          final stars = r['rating'] ?? 5;
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      r['user_username'] ?? r['devotee'] ?? 'Devotee',
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Row(
                                      children: List.generate(
                                        5,
                                        (i) => Icon(
                                          i < stars ? Icons.star : Icons.star_border,
                                          size: 14,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${r['pooja_type'] ?? 'Pooja'} • ${r['pooja_date'] ?? ''}',
                                  style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMuted),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '"${r['feedback'] ?? 'Authentic chanting and patient guidance.'}"',
                                  style: GoogleFonts.poppins(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.textDark),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitBooking() async {
    final contact = _contactController.text.trim();
    if (contact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your contact number.')));
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final poojaDisplayName = auth.tr(_poojaKey);
    final flatHouse = _addressDetailsController.text.trim();
    final streetArea = _areaLandmarkController.text.trim();
    final List<String> addressParts = [];
    if (flatHouse.isNotEmpty) addressParts.add(flatHouse);
    if (streetArea.isNotEmpty) addressParts.add(streetArea);
    if (_selectedCityName.isNotEmpty && !streetArea.toLowerCase().contains(_selectedCityName.toLowerCase())) {
      addressParts.add(_selectedCityName);
    }
    addressParts.add('(Map: ${_mapLat.toStringAsFixed(4)}°N, ${_mapLng.toStringAsFixed(4)}°E)');
    final fullAddress = addressParts.join(', ');

    setState(() => _isSubmitting = true);
    final username = auth.currentUser?.username ?? 'Devotee';

    try {
      final uri = Uri.parse('${ApiService.baseUrl}/yajman/bookings');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_username': username,
          'pooja_type': poojaDisplayName,
          'pooja_date': _dateController.text.trim(),
          'purohit_username': _selectedPurohit,
          'contact_number': contact,
          'address': fullAddress,
          'latitude': _mapLat,
          'longitude': _mapLng,
        }),
      );
      if (res.statusCode == 200) {
        _contactController.clear();
        _fetchMyBookings();
        setState(() {
          _isSubmitting = false;
          _tabController.index = 1;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green,
              content: Text('Pooja reservation placed with map location ($_selectedCityName)!'),
            ),
          );
        }
      } else {
        setState(() => _isSubmitting = false);
      }
    } catch (_) {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _cancelBooking(int bookingId) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/yajman/bookings/$bookingId/cancel');
      await http.put(uri);
      _fetchMyBookings();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking cancelled.')));
    } catch (_) {}
  }

  void _showCompleteAndRateDialog(dynamic booking) {
    int selectedRating = 5;
    final feedbackController = TextEditingController();
    final bookingId = booking['id'] ?? booking['ID'] ?? 0;
    final pooja = booking['pooja_type'] ?? booking['Pooja Type'] ?? 'Ceremony';
    final purohit = booking['purohit_username'] ?? booking['Purohit'] ?? 'Purohit';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rate Sacred Experience',
                      style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$pooja with Pandit $purohit',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                    ),
                    const SizedBox(height: 12),
                    Text('How was the authenticity of mantras and vidhi?', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted)),
                    const SizedBox(height: 10),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final star = index + 1;
                          return IconButton(
                            icon: Icon(
                              star <= selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                              color: Colors.amber,
                              size: 36,
                            ),
                            onPressed: () {
                              setDialogState(() => selectedRating = star);
                            },
                          );
                        }),
                      ),
                    ),
                    Center(
                      child: Text(
                        '$selectedRating of 5 Stars',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: feedbackController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Review & Blessings (Optional)',
                        hintText: 'Share your spiritual feedback...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Later'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogCtx);
                    final success = await ApiService.completeBooking(
                      bookingId,
                      rating: selectedRating,
                      feedback: feedbackController.text.trim(),
                    );
                    if (success) {
                      _fetchMyBookings();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ceremony marked as Completed! Thank you for the sacred review.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Submit Review'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBookingMapModal(dynamic booking) {
    final pooja = booking['pooja_type'] ?? booking['Pooja Type'] ?? 'Pooja';
    final addr = booking['address'] ?? booking['Address'] ?? 'Venue';
    final lat = (booking['latitude'] ?? booking['lat'] ?? 18.5204).toDouble();
    final lng = (booking['longitude'] ?? booking['lng'] ?? 73.8567).toDouble();

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pooja Venue Map',
                      style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 8),
                InteractiveSacredMap(
                  isPicker: false,
                  initialLat: lat,
                  initialLng: lng,
                  height: 320,
                  devoteeName: 'Your Location',
                  poojaType: pooja,
                  venueAddress: addr,
                ),
              ],
            ),
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
        title: Text(
          auth.tr('purohit_reservation'),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primarySaffron,
          labelColor: AppTheme.primaryDark,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: auth.tr('request_booking_tab'), icon: const Icon(Icons.add_circle_outline, size: 18)),
            Tab(text: auth.tr('my_bookings_tab'), icon: const Icon(Icons.list_alt_rounded, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestTab(auth),
          _buildMyBookingsTab(auth),
        ],
      ),
    );
  }

  Widget _buildRequestTab(AuthProvider auth) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step 1: Pooja / Ritual
              Text(
                auth.tr('select_pooja'),
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _poojaKey,
                items: _poojaKeys.map((k) => DropdownMenuItem(value: k, child: Text(auth.tr(k)))).toList(),
                onChanged: (val) => setState(() => _poojaKey = val!),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.temple_hindu_rounded, color: AppTheme.primarySaffron),
                ),
              ),
              const SizedBox(height: 16),

              // Preferred Date
              TextField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: auth.tr('preferred_date'),
                  prefixIcon: const Icon(Icons.calendar_today_rounded, color: AppTheme.sacredGold),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // Step 2: Choose Registered Purohit with Ratings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    auth.tr('choose_purohit'),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
                  ),
                  if (_isLoadingPurohits)
                    const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primarySaffron)),
                ],
              ),
              const SizedBox(height: 8),

              // Any Available Purohit Choice
              GestureDetector(
                onTap: () => setState(() => _selectedPurohit = ''),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _selectedPurohit.isEmpty ? AppTheme.surfaceElevated : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _selectedPurohit.isEmpty ? AppTheme.primarySaffron : Colors.grey.shade300,
                      width: _selectedPurohit.isEmpty ? 1.8 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedPurohit.isEmpty ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: _selectedPurohit.isEmpty ? AppTheme.primarySaffron : Colors.grey,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.tr('any_purohit'),
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryDark),
                            ),
                            Text(
                              auth.tr('any_purohit_sub'),
                              style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Registered Purohits Directory Cards
              if (_purohitsList.isNotEmpty)
                Column(
                  children: _purohitsList.map((p) {
                    final uname = p['username'] ?? '';
                    final rating = p['rating'] ?? 5.0;
                    final revCount = p['reviews_count'] ?? 0;
                    final region = p['region'] ?? 'Vedic';
                    final isSel = _selectedPurohit == uname;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSel ? AppTheme.surfaceElevated : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSel ? AppTheme.primarySaffron : Colors.grey.shade200,
                          width: isSel ? 1.8 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _selectedPurohit = uname),
                            child: Icon(
                              isSel ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: isSel ? AppTheme.primarySaffron : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 10),
                          CircleAvatar(
                            backgroundColor: Colors.deepOrange.shade100,
                            radius: 18,
                            child: Text(
                              uname.isNotEmpty ? uname.substring(0, 1).toUpperCase() : 'P',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange.shade900),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedPurohit = uname),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pandit $uname', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6)),
                                        child: Text(region, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.star, color: Colors.amber, size: 14),
                                      const SizedBox(width: 2),
                                      Text('$rating', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                      Text(' ($revCount)', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showPurohitReviews(p),
                            icon: const Icon(Icons.rate_review_outlined, size: 14),
                            label: Text(auth.tr('reviews'), style: const TextStyle(fontSize: 11)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),

              // Step 3: Interactive Ceremony Venue Map & Manual Address
              Text(
                '📍 Ceremony Venue & Address',
                style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryDark),
              ),
              const SizedBox(height: 3),
              Text(
                'Pin your location on the map, and type or verify your manual house/flat address below.',
                style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),

              InteractiveSacredMap(
                isPicker: true,
                initialLat: _mapLat,
                initialLng: _mapLng,
                height: 280,
                onLocationChanged: _onLocationChanged,
              ),
              const SizedBox(height: 14),

              // Manual Address Entry Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.sacredGold.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.edit_location_alt_rounded, size: 18, color: AppTheme.primarySaffron),
                        const SizedBox(width: 8),
                        Text(
                          'Manual Address Details',
                          style: GoogleFonts.cinzel(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Flat / House / Mandir
                    TextField(
                      controller: _addressDetailsController,
                      decoration: InputDecoration(
                        labelText: 'Flat / House No., Society / Mandir Name',
                        hintText: 'e.g. Flat 402, Shivshankar Heights, near Maruti Mandir',
                        prefixIcon: const Icon(Icons.home_outlined, color: AppTheme.primaryDark),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Street / Landmark / Area
                    TextField(
                      controller: _areaLandmarkController,
                      decoration: InputDecoration(
                        labelText: 'Street / Landmark / Area (Auto-filled from map or type custom)',
                        hintText: 'e.g. Shivaji Road, Kasba Peth, Sangli',
                        prefixIcon: const Icon(Icons.place_outlined, color: AppTheme.primarySaffron),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Contact Number (WhatsApp)
              TextField(
                controller: _contactController,
                decoration: InputDecoration(
                  labelText: auth.tr('contact_number'),
                  hintText: '+91 98765 43210',
                  prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.primarySaffron),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitBooking,
                  icon: const Icon(Icons.send_rounded),
                  label: Text(_isSubmitting ? 'Reserving Purohit...' : auth.tr('confirm_booking')),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyBookingsTab(AuthProvider auth) {
    return _isLoadingBookings
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primarySaffron))
        : _myBookings.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.event_busy_outlined, size: 48, color: AppTheme.textMuted),
                      const SizedBox(height: 12),
                      Text('${auth.tr("my_bookings")} empty.', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 14)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => setState(() => _tabController.index = 0),
                        child: const Text('Book a Ceremony'),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _myBookings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  final b = _myBookings[idx];
                  final status = b['status'] ?? b['Status'] ?? 'Pending';
                  final poojaType = b['pooja_type'] ?? b['Pooja Type'] ?? 'Sacred Ceremony';
                  final poojaDate = b['pooja_date'] ?? b['Pooja Date'] ?? '';
                  final address = b['address'] ?? b['Address'] ?? 'Venue';
                  final purohitName = b['purohit_username'] ?? b['Purohit'] ?? '';
                  final bookingId = b['id'] ?? b['ID'] ?? 0;
                  final rating = b['rating'] ?? b['Rating'] ?? 0;
                  final feedback = b['feedback'] ?? b['Feedback'] ?? '';

                  Color statusColor = Colors.amber.shade700;
                  Color statusBg = Colors.amber.shade50;
                  if (status == 'Confirmed' || status == 'Accepted') {
                    statusColor = Colors.green.shade800;
                    statusBg = Colors.green.shade50;
                  } else if (status == 'Completed') {
                    statusColor = Colors.blue.shade800;
                    statusBg = Colors.blue.shade50;
                  } else if (status == 'Cancelled') {
                    statusColor = Colors.red.shade800;
                    statusBg = Colors.red.shade50;
                  }

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.sacredBoxDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                poojaType,
                                style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.sacredGold),
                            const SizedBox(width: 6),
                            Text('Date: $poojaDate', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
                            if (purohitName.isNotEmpty && purohitName != 'Not Assigned') ...[
                              const Spacer(),
                              const Icon(Icons.person, size: 14, color: AppTheme.primarySaffron),
                              const SizedBox(width: 4),
                              Text('Pandit $purohitName', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                            ],
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _showBookingMapModal(b),
                              icon: const Icon(Icons.map, size: 13),
                              label: const Text('Map', style: TextStyle(fontSize: 11)),
                              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2)),
                            ),
                          ],
                        ),

                        // Completed Status Review Badge
                        if (status == 'Completed') ...[
                          const Divider(height: 16),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => Icon(
                                      i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                                      size: 16,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    feedback.isNotEmpty ? '"$feedback"' : 'Completed with Vedic authenticity',
                                    style: GoogleFonts.poppins(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.blue.shade900),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Action Buttons: Complete/Rate for Confirmed, Cancel for Pending
                        if (status == 'Confirmed') ...[
                          const Divider(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _showCompleteAndRateDialog(b),
                                  icon: const Icon(Icons.star_rate_rounded, color: Colors.amber, size: 16),
                                  label: const Text('Mark Completed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.amber),
                                  ),
                                ),
                              ),
                              if (purohitName.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.chat_bubble_rounded, color: Colors.green),
                                  tooltip: 'WhatsApp Panditji',
                                  onPressed: () {
                                    final waUrl = 'https://wa.me/?text=Namaste%20Pandit%20$purohitName,%20regarding%20our%20scheduled%20$poojaType%20on%20$poojaDate.';
                                    openWebUrl(waUrl);
                                  },
                                ),
                              ],
                            ],
                          ),
                        ] else if (status == 'Pending') ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _cancelBooking(bookingId),
                              icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 16),
                              label: Text(auth.tr('cancel_booking'), style: const TextStyle(color: Colors.red, fontSize: 12)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
  }
}
