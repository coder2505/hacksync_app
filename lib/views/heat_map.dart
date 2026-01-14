import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

// --- DUMMY DATA SCHEME ---
class IncidentData {
  final String title;
  final String contractor;
  final String reportedTime;
  final int intensity; // 1 to 5 (1-2: Yellow, 3-5: Red)
  final LatLng position;

  IncidentData({
    required this.title,
    required this.contractor,
    required this.reportedTime,
    required this.intensity,
    required this.position,
  });
}

final List<IncidentData> dummyIncidents = [
  IncidentData(
    title: "Road Surface Collapse",
    contractor: "Mumbai Roadworks Dept.",
    reportedTime: "3 hours ago",
    intensity: 5,
    position: const LatLng(19.1650, 72.8520),
  ),
  IncidentData(
    title: "Overflowing Drain",
    contractor: "BMC Drainage Division",
    reportedTime: "6 hours ago",
    intensity: 4,
    position: const LatLng(19.1605, 72.8475),
  ),
  IncidentData(
    title: "Fallen Tree Blocking Road",
    contractor: "Green Mumbai Authority",
    reportedTime: "1 hour ago",
    intensity: 3,
    position: const LatLng(19.1682, 72.8551),
  ),
  IncidentData(
    title: "Open Manhole",
    contractor: "Urban Safety Cell",
    reportedTime: "45 mins ago",
    intensity: 5,
    position: const LatLng(19.1578, 72.8503),
  ),
  IncidentData(
    title: "Illegal Garbage Dump",
    contractor: "Clean Mumbai Mission",
    reportedTime: "10 hours ago",
    intensity: 2,
    position: const LatLng(19.1624, 72.8580),
  ),
  IncidentData(
    title: "Damaged Footpath",
    contractor: "City Infra Projects",
    reportedTime: "2 days ago",
    intensity: 3,
    position: const LatLng(19.1701, 72.8489),
  ),
  IncidentData(
    title: "Water Logging After Rain",
    contractor: "Monsoon Control Unit",
    reportedTime: "20 mins ago",
    intensity: 4,
    position: const LatLng(19.1559, 72.8536),
  ),
];

class HeatMap extends StatefulWidget {
  const HeatMap({super.key});

  @override
  State<HeatMap> createState() => _HeatMapState();
}

class _HeatMapState extends State<HeatMap> {
  final MapController _mapController = MapController();

  // Default coordinates (used as fallback or initial state)
  LatLng _currentPosition = const LatLng(28.6139, 77.2090);
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  /// Entry point for location logic
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

  /// Handles GPS permissions and coordinate fetching
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

  /// Safely moves the map after build is complete
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

  /// Shows the incident details bottom sheet
  void _showIncidentDetails(IncidentData data) {
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
                      data.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: data.intensity >= 3 ? Colors.red.shade100 : Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Intensity: ${data.intensity}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: data.intensity >= 3 ? Colors.red.shade900 : Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _detailRow(Icons.engineering, "Contractor", data.contractor),
              const SizedBox(height: 8),
              _detailRow(Icons.access_time, "Reported", data.reportedTime),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("View Full Report"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text("$label: ", style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
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
          FlutterMap(
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
              )
              ,
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
                      shadows: [Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                    ),
                  ),
                  // Incident dummy markers
                  ...dummyIncidents.map((incident) => Marker(
                    point: incident.position,
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _showIncidentDetails(incident),
                      child: Icon(
                        Icons.person_pin_circle,
                        color: incident.intensity >= 3 ? Colors.red : Colors.amber,
                        size: 40,
                        shadows: const [Shadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                    ),
                  )),
                ],
              ),
            ],
          ),

          // Loading Overlay
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