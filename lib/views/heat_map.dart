import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// --- MODEL ---
class ComplaintReport {
  final String id;
  final String type;
  final GeoPoint location;
  final String? imageUrl;
  final DateTime timestamp;
  final bool isAnonymous;
  final String userId;
  final int upvotes;

  ComplaintReport({
    required this.id,
    required this.type,
    required this.location,
    this.imageUrl,
    required this.timestamp,
    required this.isAnonymous,
    required this.userId,
    this.upvotes = 0,
  });

  factory ComplaintReport.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    List<dynamic> photos = data['photos'] ?? [];
    String? imgUrl = photos.isNotEmpty ? photos[0].toString() : null;

    return ComplaintReport(
      id: doc.id,
      type: data['type'] ?? 'Unknown Issue',
      location: data['location'] is GeoPoint
          ? data['location']
          : const GeoPoint(0, 0),
      imageUrl: imgUrl,
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isAnonymous: data['isAnonymous'] ?? false,
      userId: data['userId'] ?? 'Unknown',
      upvotes: data['upvotes'] ?? 0,
    );
  }
}

class HeatMap extends StatefulWidget {
  const HeatMap({super.key});

  @override
  State<HeatMap> createState() => _HeatMapState();
}

class _HeatMapState extends State<HeatMap> {
  final MapController _mapController = MapController();
  LatLng _currentPosition = const LatLng(19.0760, 72.8777);
  bool _isLoadingLocation = true;

  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Road', 'Sanitation', 'Electrical', 'Water', 'Others'];

  // Dark Mode Palette
  final Color _darkBg = const Color(0xFF121212);
  final Color _darkSurface = const Color(0xFF1E1E1E);
  final Color _textPrimary = Colors.white.withOpacity(0.9);
  final Color _textSecondary = Colors.white70;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      Position position = await _determinePosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
      _safeMapMove(_currentPosition, 15.0);
    } catch (e) {
      debugPrint("Location error: $e");
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Location permissions are denied');
    }
    return await Geolocator.getCurrentPosition();
  }

  void _safeMapMove(LatLng center, double zoom) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _mapController.move(center, zoom);
      } catch (e) {
        debugPrint("Map move failed: $e");
      }
    });
  }

  // Softened Colors for Dark Mode
  String _getNormalizedCategory(String type) {
    final t = type.toLowerCase();
    if (t.contains('road') || t.contains('pothole')) return 'Road';
    if (t.contains('garbage') || t.contains('sanitation')) return 'Sanitation';
    if (t.contains('electric')) return 'Electrical';
    if (t.contains('water') || t.contains('leak')) return 'Water';
    return 'Others';
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Road': return Colors.redAccent.shade100;
      case 'Sanitation': return Colors.orangeAccent.shade100;
      case 'Electrical': return Colors.amberAccent.shade100;
      case 'Water': return Colors.lightBlueAccent.shade100;
      default: return Colors.purpleAccent.shade100;
    }
  }

  void _showIncidentDetails(ComplaintReport report) {
    final category = _getNormalizedCategory(report.type);
    final color = _getCategoryColor(category);

    showModalBottomSheet(
      context: context,
      backgroundColor: _darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(report.type, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textPrimary)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: Text("${report.upvotes} Upvotes", style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _detailRow(Icons.category_outlined, "Category", category),
              const SizedBox(height: 10),
              _detailRow(Icons.person_outline, "Reported By", report.isAnonymous ? 'Anonymous' : report.userId),
              const SizedBox(height: 10),
              _detailRow(Icons.access_time, "Time", _getTimeAgo(report.timestamp)),
              const SizedBox(height: 24),
              if (report.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(report.imageUrl!, height: 160, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white10,
                    foregroundColor: _textPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text("Dismiss"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return DateFormat('MMM d').format(dateTime);
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _textSecondary),
        const SizedBox(width: 12),
        Text("$label: ", style: TextStyle(color: _textSecondary)),
        Text(value, style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w500)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: _darkSurface,
            child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: _darkSurface,
              child: IconButton(icon: const Icon(Icons.my_location, color: Colors.blueAccent, size: 20), onPressed: () => _initLocation()),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('reports').snapshots(),
              builder: (context, snapshot) {
                List<Marker> reportMarkers = [];
                if (snapshot.hasData) {
                  var reports = snapshot.data!.docs.map((doc) => ComplaintReport.fromFirestore(doc)).toList();
                  if (_selectedCategory != 'All') {
                    reports = reports.where((r) => _getNormalizedCategory(r.type) == _selectedCategory).toList();
                  }
                  reportMarkers = reports.map((report) {
                    final color = _getCategoryColor(_getNormalizedCategory(report.type));
                    return Marker(
                      point: LatLng(report.location.latitude, report.location.longitude),
                      width: 50,
                      height: 50,
                      child: GestureDetector(
                        onTap: () => _showIncidentDetails(report),
                        child: Icon(Icons.location_on, color: color, size: 40, shadows: const [Shadow(color: Colors.black45, blurRadius: 8)]),
                      ),
                    );
                  }).toList();
                }

                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition,
                    initialZoom: 13.0,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                      'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=gFtNu24T2QIe0IP18qvC',
                      userAgentPackageName: 'com.example.gdg_hacksync',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentPosition,
                          width: 60,
                          height: 60,
                          child: const Icon(Icons.person_pin_circle, color: Colors.blueAccent, size: 45, shadows: [Shadow(color: Colors.black26, blurRadius: 10)]),
                        ),
                        ...reportMarkers,
                      ],
                    ),
                  ],
                );
              }
          ),

          // --- CATEGORY FILTERS ---
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  final color = category == 'All' ? Colors.blueGrey : _getCategoryColor(category);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black87 : _textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      selected: isSelected,
                      selectedColor: color,
                      backgroundColor: _darkSurface,
                      elevation: 4,
                      pressElevation: 0,
                      shadowColor: Colors.black45,
                      side: BorderSide(color: isSelected ? Colors.transparent : Colors.white10),
                      onSelected: (bool selected) {
                        if (selected) setState(() => _selectedCategory = category);
                      },
                    ),
                  );
                },
              ),
            ),
          ),

          // Loading Overlay
          if (_isLoadingLocation)
            Container(
              color: Colors.black87,
              child: Center(
                child: Card(
                  color: _darkSurface,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.blueAccent),
                        const SizedBox(height: 16),
                        Text("Locating you...", style: TextStyle(color: _textPrimary)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Zoom Controls
          Positioned(
            bottom: 40,
            right: 20,
            child: Column(
              children: [
                _mapActionButton(Icons.add, () {
                  _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
                }),
                const SizedBox(height: 12),
                _mapActionButton(Icons.remove, () {
                  _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapActionButton(IconData icon, VoidCallback onPressed) {
    return FloatingActionButton.small(
      heroTag: null,
      backgroundColor: _darkSurface,
      elevation: 4,
      onPressed: onPressed,
      child: Icon(icon, color: Colors.blueAccent),
    );
  }
}