import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class SimpleNavScreen extends StatefulWidget {
  const SimpleNavScreen({super.key});

  @override
  State<SimpleNavScreen> createState() => _SimpleNavScreenState();
}

class _SimpleNavScreenState extends State<SimpleNavScreen> {
  final MapController _mapController = MapController();

  // Dark Mode Palette
  final Color _darkBg = const Color(0xFF121212);
  final Color _darkSurface = const Color(0xFF1E1E1E);
  final Color _textPrimary = Colors.white.withOpacity(0.9);
  final Color _textSecondary = Colors.white60;

  // -- STATE --
  LatLng? _currentLocation;
  LatLng? _destination;
  List<LatLng> _routePoints = [];
  bool _isLoading = false;

  // Store the actual hazard data objects found on the route
  List<Map<String, dynamic>> _hazardsOnRoute = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position pos = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
      });
      _mapController.move(_currentLocation!, 15);
    } catch (e) {
      debugPrint("Location Permission Error: $e");
    }
  }

  Future<void> _getRoute(LatLng dest) async {
    if (_currentLocation == null) return;

    setState(() {
      _destination = dest;
      _isLoading = true;
      _hazardsOnRoute = []; // Clear previous list
    });

    // OSRM Public Server
    final start = "${_currentLocation!.longitude},${_currentLocation!.latitude}";
    final end = "${dest.longitude},${dest.latitude}";
    final url = Uri.parse('http://router.project-osrm.org/route/v1/driving/$start;$end?overview=full&geometries=geojson');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final geometry = data['routes'][0]['geometry']['coordinates'] as List;

        List<LatLng> points = geometry.map((e) => LatLng(e[1], e[0])).toList();

        setState(() {
          _routePoints = points;
        });

        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(points),
            padding: const EdgeInsets.all(50),
          ),
        );

        _calculateHazardsOnRoute(points);
      }
    } catch (e) {
      debugPrint("Route Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _calculateHazardsOnRoute(List<LatLng> routePath) async {
    final snapshot = await FirebaseFirestore.instance.collection('reports').get();

    const Distance distanceCalc = Distance();
    List<Map<String, dynamic>> detected = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['location'] is GeoPoint) {
        final geo = data['location'] as GeoPoint;
        final hazardLoc = LatLng(geo.latitude, geo.longitude);

        // Check intersection with route
        for (int i = 0; i < routePath.length; i += 5) {
          if (distanceCalc.as(LengthUnit.Meter, hazardLoc, routePath[i]) < 50) {
            // Store useful data for the list
            detected.add({
              'type': data['type'] ?? 'Hazard',
              'location': hazardLoc,
              'image': (data['photos'] != null && (data['photos'] as List).isNotEmpty)
                  ? data['photos'][0]
                  : null,
            });
            break;
          }
        }
      }
    }

    setState(() {
      _hazardsOnRoute = detected;
    });

    if (detected.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ Found ${detected.length} hazards! Check the list below."),
          backgroundColor: Colors.redAccent.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        title: const Text("Plan your trip"),
        backgroundColor: _darkSurface,
        foregroundColor: _textPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // --- 1. MAP LAYER ---
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(19.0760, 72.8777),
              initialZoom: 13,
              onTap: (tapPosition, point) => _getRoute(point),
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=gFtNu24T2QIe0IP18qvC',
                userAgentPackageName: 'com.example.gdg_hacksync',
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5,
                      color: Colors.blueAccent.shade200,
                    ),
                  ],
                ),
              // Stream all markers (visual reference)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('reports').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final markers = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (data['location'] is! GeoPoint) return null;
                    final geo = data['location'] as GeoPoint;
                    return Marker(
                      point: LatLng(geo.latitude, geo.longitude),
                      width: 40, height: 40,
                      child: const Icon(Icons.warning_rounded, color: Colors.redAccent, size: 30),
                    );
                  }).whereType<Marker>().toList();
                  return MarkerLayer(markers: markers);
                },
              ),
              // User & Destination
              MarkerLayer(
                markers: [
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 50, height: 50,
                      child: const Icon(Icons.my_location, color: Colors.blueAccent, size: 30),
                    ),
                  if (_destination != null)
                    Marker(
                      point: _destination!,
                      width: 50, height: 50,
                      child: const Icon(Icons.location_on, color: Colors.greenAccent, size: 40),
                    ),
                ],
              ),
            ],
          ),

          // --- 2. LOADING ---
          if (_isLoading)
            Center(
              child: Card(
                color: _darkSurface,
                child: const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(color: Colors.blueAccent),
                ),
              ),
            ),

          // --- 3. BOTTOM SHEET (HAZARDS LIST) ---
          if (_hazardsOnRoute.isNotEmpty)
            DraggableScrollableSheet(
              initialChildSize: 0.25,
              minChildSize: 0.15,
              maxChildSize: 0.6,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: _darkSurface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(color: Colors.black54, blurRadius: 10, offset: const Offset(0, -2))
                    ],
                  ),
                  child: Column(
                    children: [
                      // Handle Bar
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 5),
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.redAccent.shade100, size: 28),
                            const SizedBox(width: 10),
                            Text(
                              "${_hazardsOnRoute.length} Hazards on Route",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary),
                            ),
                          ],
                        ),
                      ),

                      // List
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: _hazardsOnRoute.length,
                          itemBuilder: (context, index) {
                            final hazard = _hazardsOnRoute[index];
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: hazard['image'] != null
                                    ? Image.network(hazard['image'], width: 50, height: 50, fit: BoxFit.cover)
                                    : Container(
                                  width: 50, height: 50,
                                  color: Colors.white10,
                                  child: const Icon(Icons.broken_image, color: Colors.white24),
                                ),
                              ),
                              title: Text(
                                hazard['type'],
                                style: TextStyle(fontWeight: FontWeight.w600, color: _textPrimary),
                              ),
                              subtitle: Text("Tap to view on map", style: TextStyle(color: _textSecondary, fontSize: 12)),
                              trailing: Icon(Icons.arrow_forward_ios, size: 14, color: _textSecondary),
                              onTap: () {
                                _mapController.move(hazard['location'], 17);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          // --- 4. EMPTY STATE HINT ---
          if (_destination == null)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Card(
                color: _darkSurface.withOpacity(0.95),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Tap anywhere on the map to start navigation.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600, color: _textPrimary),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _hazardsOnRoute.isEmpty
          ? FloatingActionButton(
        onPressed: _getCurrentLocation,
        backgroundColor: _darkSurface,
        foregroundColor: Colors.blueAccent,
        child: const Icon(Icons.gps_fixed),
      )
          : null,
    );
  }
}