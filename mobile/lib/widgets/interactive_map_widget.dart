import 'dart:async';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_theme.dart';
import '../services/api_service.dart';
import '../utils/url_helper.dart';

enum MapLayerType { standard, topo }

class InteractiveSacredMap extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final int initialZoom;
  final double height;
  final bool isPicker; // true = devotee picks location, false = purohit tracks devotee
  final String? devoteeName;
  final String? poojaType;
  final String? venueAddress;
  final Function(double lat, double lng, String resolvedAddress, String city)? onLocationChanged;

  const InteractiveSacredMap({
    super.key,
    this.initialLat = 18.5204, // Default: Pune, Maharashtra
    this.initialLng = 73.8567,
    this.initialZoom = 14,
    this.height = 290,
    this.isPicker = true,
    this.devoteeName,
    this.poojaType,
    this.venueAddress,
    this.onLocationChanged,
  });

  @override
  State<InteractiveSacredMap> createState() => _InteractiveSacredMapState();
}

class _InteractiveSacredMapState extends State<InteractiveSacredMap> {
  late double _mapLat;
  late double _mapLng;
  late int _zoomLevel;
  MapLayerType _currentLayer = MapLayerType.standard;

  String _resolvedAddress = '';
  String _currentCity = 'Pune';
  bool _isReverseGeocoding = false;
  Timer? _debounceTimer;

  final TextEditingController _searchController = TextEditingController();

  static const List<Map<String, dynamic>> sacredCities = [
    {'name': 'Sangli', 'region': 'Maharashtra', 'lat': 16.8524, 'lng': 74.5815},
    {'name': 'Pune', 'region': 'Maharashtra', 'lat': 18.5204, 'lng': 73.8567},
    {'name': 'Satara', 'region': 'Maharashtra', 'lat': 17.6805, 'lng': 73.9937},
    {'name': 'Mumbai', 'region': 'Maharashtra', 'lat': 19.0760, 'lng': 72.8777},
    {'name': 'Nashik / Trimbak', 'region': 'Maharashtra', 'lat': 19.9975, 'lng': 73.7898},
    {'name': 'Varanasi (Kashi)', 'region': 'Uttar Pradesh', 'lat': 25.3176, 'lng': 82.9739},
    {'name': 'Ayodhya', 'region': 'Uttar Pradesh', 'lat': 26.7922, 'lng': 82.1998},
    {'name': 'Ujjain (Mahakal)', 'region': 'Madhya Pradesh', 'lat': 23.1765, 'lng': 75.7885},
    {'name': 'Haridwar', 'region': 'Uttarakhand', 'lat': 29.9457, 'lng': 78.1642},
    {'name': 'Tirupati (Balaji)', 'region': 'Andhra Pradesh', 'lat': 13.6288, 'lng': 79.4192},
    {'name': 'Somnath', 'region': 'Gujarat', 'lat': 20.8880, 'lng': 70.4012},
    {'name': 'Puri (Jagannath)', 'region': 'Odisha', 'lat': 19.8135, 'lng': 85.8312},
    {'name': 'Bengaluru', 'region': 'Karnataka', 'lat': 12.9716, 'lng': 77.5946},
    {'name': 'New Delhi', 'region': 'NCR', 'lat': 28.6139, 'lng': 77.2090},
    {'name': 'Hyderabad', 'region': 'Telangana', 'lat': 17.3850, 'lng': 78.4867},
  ];

  @override
  void initState() {
    super.initState();
    _mapLat = widget.initialLat;
    _mapLng = widget.initialLng;
    _zoomLevel = widget.initialZoom;
    _resolvedAddress = widget.venueAddress ?? '';

    // Infer city from initial coordinates if available
    _findClosestCity();

    if (widget.isPicker && _resolvedAddress.isEmpty) {
      _triggerReverseGeocode();
    }
  }

  void _findClosestCity() {
    double minDistance = double.infinity;
    String matchedCity = _currentCity;
    for (final c in sacredCities) {
      final double lat = c['lat'] as double;
      final double lng = c['lng'] as double;
      final double dist = (lat - _mapLat) * (lat - _mapLat) + (lng - _mapLng) * (lng - _mapLng);
      if (dist < minDistance) {
        minDistance = dist;
        matchedCity = c['name'] as String;
      }
    }
    if (minDistance < 0.5) {
      _currentCity = matchedCity;
    }
  }

  @override
  void didUpdateWidget(covariant InteractiveSacredMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialLat != widget.initialLat || oldWidget.initialLng != widget.initialLng) {
      setState(() {
        _mapLat = widget.initialLat;
        _mapLng = widget.initialLng;
        _resolvedAddress = widget.venueAddress ?? '';
      });
      _findClosestCity();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _triggerReverseGeocode() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      setState(() => _isReverseGeocoding = true);
      try {
        final res = await ApiService.reverseGeocode(_mapLat, _mapLng);
        if (mounted && res != null) {
          final display = res['display_name'] ?? '';
          final city = res['city'] ?? '';
          setState(() {
            _resolvedAddress = display;
            if (city.isNotEmpty) _currentCity = city;
            _isReverseGeocoding = false;
          });
          widget.onLocationChanged?.call(_mapLat, _mapLng, _resolvedAddress, _currentCity);
        } else if (mounted) {
          setState(() => _isReverseGeocoding = false);
        }
      } catch (_) {
        if (mounted) setState(() => _isReverseGeocoding = false);
      }
    });
  }

  void _panMapByPixels(double dx, double dy) {
    final int n = 1 << _zoomLevel;
    final double totalWorldPixels = n * 256.0;

    double currentWorldX = ((_mapLng + 180.0) / 360.0) * totalWorldPixels;
    final double sinLat = sin(_mapLat * pi / 180.0).clamp(-0.9999, 0.9999);
    double currentWorldY = (0.5 - log((1.0 + sinLat) / (1.0 - sinLat)) / (4.0 * pi)) * totalWorldPixels;

    currentWorldX -= dx;
    currentWorldY -= dy;

    final double newLng = ((currentWorldX / totalWorldPixels) * 360.0) - 180.0;
    final double normY = (0.5 - (currentWorldY / totalWorldPixels)).clamp(-0.499, 0.499);
    final double expVal = exp(4.0 * pi * normY);
    final double newSinLat = (expVal - 1.0) / (expVal + 1.0);
    final double newLat = (asin(newSinLat.clamp(-0.9999, 0.9999)) * 180.0 / pi).clamp(-85.0, 85.0);

    setState(() {
      _mapLng = ((newLng + 180.0) % 360.0) - 180.0;
      _mapLat = newLat;
    });
  }

  void _pinAtViewportPosition(double touchX, double touchY, double width, double height) {
    if (!widget.isPicker) return;
    final double dx = touchX - (width / 2.0);
    final double dy = touchY - (height / 2.0);
    _panMapByPixels(-dx, -dy);
    _triggerReverseGeocode();
  }

  void _zoomIn() {
    if (_zoomLevel < 18) {
      setState(() => _zoomLevel++);
    }
  }

  void _zoomOut() {
    if (_zoomLevel > 4) {
      setState(() => _zoomLevel--);
    }
  }

  void _jumpToCity(Map<String, dynamic> city) {
    setState(() {
      _currentCity = city['name'];
      _mapLat = city['lat'];
      _mapLng = city['lng'];
      _zoomLevel = 14;
    });
    if (widget.isPicker) {
      _triggerReverseGeocode();
    }
  }

  void _searchLocation() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return;

    for (final c in sacredCities) {
      final name = (c['name'] as String).toLowerCase();
      final region = (c['region'] as String).toLowerCase();
      if (name.contains(q) || region.contains(q)) {
        _jumpToCity(c);
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Showing map center for "${_searchController.text.trim()}". Drag map to adjust exact pin.')),
    );
  }

  void _openGoogleMapsNavigation() {
    // If tracking/viewer mode: open direct turn-by-turn directions to destination
    // If picker mode: open location search query
    final url = widget.isPicker
        ? 'https://www.google.com/maps/search/?api=1&query=$_mapLat,$_mapLng'
        : 'https://www.google.com/maps/dir/?api=1&destination=$_mapLat,$_mapLng';
    openWebUrl(url);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.isPicker ? 'Opening Google Maps venue preview...' : 'Opening Google Maps navigation...'),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getTileUrl(int z, int x, int y) {
    switch (_currentLayer) {
      case MapLayerType.topo:
        // OpenTopoMap - elevation & topology (Free, open source)
        return 'https://tile.opentopomap.org/$z/$x/$y.png';
      case MapLayerType.standard:
        // OpenStreetMap Standard - 100% Free, Reliable, Zero Watermarks or API Keys
        final sub = ['a', 'b', 'c'][Random().nextInt(3)];
        return 'https://$sub.tile.openstreetmap.org/$z/$x/$y.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode 1: Devotee Location Picker Controls
        if (widget.isPicker) ...[
          // Quick Search Box
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search city or temple area...',
                      hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.primarySaffron),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 14),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _searchLocation(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _searchLocation,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  backgroundColor: AppTheme.primaryDark,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Find', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Sacred City Quick Filter Chips
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: sacredCities.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, idx) {
                final c = sacredCities[idx];
                final isSel = _currentCity.toLowerCase() == (c['name'] as String).toLowerCase();
                return ChoiceChip(
                  label: Text(
                    c['name'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      color: isSel ? Colors.white : AppTheme.textDark,
                    ),
                  ),
                  selected: isSel,
                  selectedColor: AppTheme.primarySaffron,
                  backgroundColor: AppTheme.surfaceElevated,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                  onSelected: (_) => _jumpToCity(c),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Clean Slippy Map Canvas
        _buildCleanMapCanvas(height: widget.height),
        const SizedBox(height: 8),

        // Venue & GPS Location Feedback Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.sacredGold.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    widget.isPicker ? Icons.my_location : Icons.navigation_rounded,
                    color: AppTheme.primarySaffron,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_mapLat.toStringAsFixed(4)}° N, ${_mapLng.toStringAsFixed(4)}° E',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                    ),
                  ),
                  if (_isReverseGeocoding)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primarySaffron),
                    ),
                  const SizedBox(width: 8),
                  // Open in Google Maps Button
                  InkWell(
                    onTap: _openGoogleMapsNavigation,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade400),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_in_new, size: 13, color: Colors.green.shade800),
                          const SizedBox(width: 4),
                          Text(
                            widget.isPicker ? 'Verify in Google Maps' : 'Google Maps Directions',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_resolvedAddress.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  _resolvedAddress,
                  style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCleanMapCanvas({required double height}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;

        final int n = 1 << _zoomLevel;
        final double totalPixels = n * 256.0;

        final double worldX = ((_mapLng + 180.0) / 360.0) * totalPixels;
        final double sinLat = sin(_mapLat * pi / 180.0).clamp(-0.9999, 0.9999);
        final double worldY = (0.5 - log((1.0 + sinLat) / (1.0 - sinLat)) / (4.0 * pi)) * totalPixels;

        final double originX = worldX - (width / 2.0);
        final double originY = worldY - (height / 2.0);

        final int startTx = (originX / 256.0).floor();
        final int endTx = ((originX + width) / 256.0).floor();
        final int startTy = (originY / 256.0).floor();
        final int endTy = ((originY + height) / 256.0).floor();

        final List<Widget> tileWidgets = [];
        for (int tx = startTx; tx <= endTx; tx++) {
          for (int ty = startTy; ty <= endTy; ty++) {
            final double tileLeft = tx * 256.0 - originX;
            final double tileTop = ty * 256.0 - originY;
            final int safeTx = ((tx % n) + n) % n;
            final int safeTy = ty.clamp(0, n - 1);
            final String tileUrl = _getTileUrl(_zoomLevel, safeTx, safeTy);

            tileWidgets.add(
              Positioned(
                left: tileLeft,
                top: tileTop,
                width: 256,
                height: 256,
                child: Image.network(
                  tileUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFF6F3EE),
                    child: const Center(
                      child: Icon(Icons.temple_hindu, color: Colors.black12, size: 28),
                    ),
                  ),
                ),
              ),
            );
          }
        }

        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: const Color(0xFFF6F3EE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.sacredGold.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // 1. Gesture Listener for map navigation (mouse wheel zoom & smooth pan)
                Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerSignal: (pointerSignal) {
                    if (pointerSignal is PointerScrollEvent) {
                      if (pointerSignal.scrollDelta.dy < 0) {
                        _zoomIn();
                      } else if (pointerSignal.scrollDelta.dy > 0) {
                        _zoomOut();
                      }
                    }
                  },
                  onPointerMove: (e) {
                    _panMapByPixels(e.delta.dx, e.delta.dy);
                  },
                  onPointerUp: (_) {
                    if (widget.isPicker) {
                      _triggerReverseGeocode();
                    }
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) {
                      _pinAtViewportPosition(details.localPosition.dx, details.localPosition.dy, width, height);
                    },
                    child: Stack(
                      children: tileWidgets,
                    ),
                  ),
                ),

                // 2. Center Sacred Pin Marker (Tip precisely calibrated to center coordinates)
                Positioned.fill(
                  child: Center(
                    child: FractionalTranslation(
                      translation: const Offset(0.0, -0.42),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.isPicker ? AppTheme.primaryDark : Colors.red.shade900,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
                            ),
                            child: Text(
                              widget.isPicker
                                  ? '📍 Tap or Drag to Pin Venue'
                                  : '🕉️ ${widget.devoteeName ?? "Devotee Venue"}',
                              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Icon(
                            Icons.location_on,
                            size: 42,
                            color: widget.isPicker ? AppTheme.primarySaffron : Colors.redAccent,
                            shadows: const [Shadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2))],
                          ),
                          Container(
                            width: 6,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Floating Modern Zoom & Recenter Controls (Bottom-Right)
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Recenter to initial/city coordinates
                      _buildFloatingMapButton(
                        icon: Icons.my_location,
                        tooltip: 'Recenter Map',
                        onTap: () {
                          setState(() {
                            _mapLat = widget.initialLat;
                            _mapLng = widget.initialLng;
                          });
                          _findClosestCity();
                          if (widget.isPicker) _triggerReverseGeocode();
                        },
                      ),
                      const SizedBox(height: 6),
                      // Zoom In
                      _buildFloatingMapButton(
                        icon: Icons.add,
                        tooltip: 'Zoom In',
                        onTap: _zoomIn,
                      ),
                      const SizedBox(height: 6),
                      // Zoom Out
                      _buildFloatingMapButton(
                        icon: Icons.remove,
                        tooltip: 'Zoom Out',
                        onTap: _zoomOut,
                      ),
                    ],
                  ),
                ),

                // 4. Style Toggle & Active Zoom Badge (Top-Right)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Toggle between Standard OSM and Topographic
                      InkWell(
                        onTap: () {
                          setState(() {
                            _currentLayer = _currentLayer == MapLayerType.standard
                                ? MapLayerType.topo
                                : MapLayerType.standard;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            border: Border.all(color: AppTheme.sacredGold.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _currentLayer == MapLayerType.standard ? Icons.map_outlined : Icons.terrain_outlined,
                                size: 14,
                                color: AppTheme.primaryDark,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _currentLayer == MapLayerType.standard ? 'Standard' : 'Topo',
                                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Zoom factor tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.sacredGold.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '${_zoomLevel}x',
                          style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),

                // 5. Direct Google Maps Navigation Pill (Top-Left)
                Positioned(
                  left: 10,
                  top: 10,
                  child: InkWell(
                    onTap: _openGoogleMapsNavigation,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.navigation_rounded, size: 13, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            widget.isPicker ? 'Google Maps' : 'Navigate',
                            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingMapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: AppTheme.primaryDark),
        ),
      ),
    );
  }
}
