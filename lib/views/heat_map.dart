import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// --- MODEL (Matches your Firestore Schema) ---
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

  // Default coordinates (Mumbai as fallback)
  LatLng _currentPosition = const LatLng(19.0760, 72.8777);
  bool _isLoadingLocation = true;

  // Filter State
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Road', 'Sanitation', 'Electrical', 'Water', 'Others'];

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
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
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

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _safeMapMove(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _safeMapMove(_mapController.camera.center, currentZoom - 1);
  }

  // --- Helper to categorize raw types ---
  String _getNormalizedCategory(String type) {
    final t = type.toLowerCase();
    if (t.contains('road') || t.contains('pothole') || t.contains('collapse') || t.contains('traffic')) return 'Road';
    if (t.contains('garbage') || t.contains('sanitation') || t.contains('trash') || t.contains('dump')) return 'Sanitation';
    if (t.contains('electric') || t.contains('light') || t.contains('lamp')) return 'Electrical';
    if (t.contains('water') || t.contains('leak') || t.contains('drain') || t.contains('flood')) return 'Water';
    return 'Others';
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Road': return Colors.red;
      case 'Sanitation': return Colors.brown;
      case 'Electrical': return Colors.amber.shade700;
      case 'Water': return Colors.blue;
      default: return Colors.purple;
    }
  }

  void _showIncidentDetails(ComplaintReport report) {
    final category = _getNormalizedCategory(report.type);
    final color = _getCategoryColor(category);
    final timeAgo = _getTimeAgo(report.timestamp);
    final reporterName = report.isAnonymous ? 'Anonymous' : report.userId;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      report.type,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${report.upvotes} Upvotes",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _detailRow(Icons.category, "Category", category),
              const SizedBox(height: 8),
              _detailRow(Icons.person, "Reported By", reporterName),
              const SizedBox(height: 8),
              _detailRow(Icons.access_time, "Time", timeAgo),

              const SizedBox(height: 24),

              if (report.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    report.imageUrl!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_,__,___) => const SizedBox(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Close"),
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
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text("$label: ", style: const TextStyle(color: Colors.grey)),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.my_location, color: Colors.blueAccent),
                onPressed: () => _initLocation(),
              ),
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
                  // 1. Convert docs to models
                  var reports = snapshot.data!.docs
                      .map((doc) => ComplaintReport.fromFirestore(doc))
                      .toList();

                  // 2. Filter based on Selected Category
                  if (_selectedCategory != 'All') {
                    reports = reports.where((r) => _getNormalizedCategory(r.type) == _selectedCategory).toList();
                  }

                  // 3. Create Markers
                  reportMarkers = reports.map((report) {
                    final category = _getNormalizedCategory(report.type);
                    final color = _getCategoryColor(category);

                    return Marker(
                      point: LatLng(report.location.latitude, report.location.longitude),
                      width: 45,
                      height: 45,
                      child: GestureDetector(
                        onTap: () => _showIncidentDetails(report),
                        child: Icon(
                          Icons.location_on,
                          color: color,
                          size: 45,
                          shadows: const [
                            Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                          ],
                        ),
                      ),
                    );
                  }).toList();
                }

                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition,
                    initialZoom: 13.0,
                    maxZoom: 18.0,
                    minZoom: 3.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                      'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=gFtNu24T2QIe0IP18qvC',
                      userAgentPackageName: 'com.example.gdg_hacksync',
                    ),

                    // Markers Layer
                    MarkerLayer(
                      markers: [
                        // User location marker
                        Marker(
                          point: _currentPosition,
                          width: 50,
                          height: 50,
                          child: const Icon(
                            Icons.person_pin_circle,
                            color: Colors.blueAccent,
                            size: 45,
                            shadows: [
                              Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                            ],
                          ),
                        ),
                        // Firestore Report Markers
                        ...reportMarkers,
                      ],
                    ),
                  ],
                );
              }
          ),

          // --- CATEGORY FILTERS ---
          Positioned(
            top: 100, // Just below AppBar area
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
                  final color = category == 'All' ? Colors.grey.shade800 : _getCategoryColor(category);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          )
                      ),
                      selected: isSelected,
                      selectedColor: category == 'All' ? Colors.black87 : color,
                      backgroundColor: Colors.white,
                      elevation: 2,
                      side: BorderSide(
                        color: isSelected ? Colors.transparent : Colors.grey.shade300,
                      ),
                      onSelected: (bool selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ),

          // Loading Overlay (Only for initial GPS fetch)
          if (_isLoadingLocation)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Locating you..."),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: "zoom_in_btn",
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add, color: Colors.blueAccent),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: "zoom_out_btn",
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove, color: Colors.blueAccent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}