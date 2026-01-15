import 'dart:io';
import 'dart:convert'; // Added for JSON encoding
import 'package:gdg_hacksync/views/report_submit_loader.dart';
import 'package:http/http.dart' as http; // Added for API requests

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gdg_hacksync/utils/upload_user_complaint.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ReportAComplaint extends StatefulWidget {
  const ReportAComplaint({super.key});

  @override
  State<ReportAComplaint> createState() => _ReportAComplaintState();
}

class _ReportAComplaintState extends State<ReportAComplaint> {
  // Form State
  String? _selectedIncidentType;
  final List<String> _incidentTypes = [
    "Road damage / pothole",
    "Water leakage",
    "Street lighting",
    "Garbage / sanitation",
    "Public building damage",
    "Drainage / flooding",
    "Other",
  ];

  final List<XFile> _imageFiles = [];
  final ImagePicker _picker = ImagePicker();
  bool _isAnonymous = false;
  bool _isUploading = false; // Loader state

  // Map & Location State
  final MapController _mapController = MapController();
  LatLng _currentPosition = const LatLng(0, 0); // Default placeholder
  String _currentAddress = "Fetching location...";
  bool _isMapLoading = true;

  // Metadata
  final String _timestamp = DateFormat(
    'yyyy-MM-dd HH:mm',
  ).format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  /// Handles GPS permissions and initial fetch
  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _currentAddress = "Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _currentAddress = "Location permission denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _currentAddress = "Location permissions are permanently denied.");
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    _updateLocation(LatLng(position.latitude, position.longitude));
  }

  /// Updates marker, centers map, and fetches address
  Future<void> _updateLocation(LatLng position) async {
    setState(() {
      _currentPosition = position;
      _isMapLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mapController.camera.center != position) {
        _mapController.move(position, 15.0);
      }
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentAddress =
          "${place.street ?? ''}, ${place.locality ?? ''}, ${place.postalCode ?? ''}";
        });
      }
    } catch (e) {
      setState(
            () => _currentAddress =
        "Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}",
      );
    }
  }

  Future<void> _pickImages() async {
    if (_imageFiles.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maximum 5 photos allowed")),
      );
      return;
    }
    final List<XFile> selectedImages = await _picker.pickMultiImage();
    if (selectedImages.isNotEmpty) {
      setState(() {
        // Add only up to 5 images total
        _imageFiles.addAll(selectedImages);
        if (_imageFiles.length > 5) {
          _imageFiles.removeRange(5, _imageFiles.length);
        }
      });
    }
  }

  /// Validation logic and Submission handling
  /// Validation logic and Navigation to Progress Page
  Future<void> _validateAndSubmit() async {
    // 1. Check Incident Type
    if (_selectedIncidentType == null) {
      _showErrorSnackBar("Please select an incident type.");
      return;
    }

    // 2. Check Photos
    if (_imageFiles.isEmpty) {
      _showErrorSnackBar("Please upload at least one photo of the issue.");
      return;
    }

    // 3. Check Location
    if (_currentPosition.latitude == 0 && _currentPosition.longitude == 0) {
      _showErrorSnackBar("Location data is missing. Please wait for GPS.");
      return;
    }

    // Navigate to the Submission Progress Page
    // We await the result to see if we should close this screen too (e.g. on success)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubmissionProgressPage(
          isAnonymous: _isAnonymous,
          currentPosition: _currentPosition,
          imageFiles: _imageFiles,
          incidentType: _selectedIncidentType!,
        ),
      ),
    );

    // If result is true, it means submission was successful
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Complaint submitted successfully!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Close the Report Form
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "New Complaint",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                // Incident Type
                _buildRow(
                  label: "Type",
                  child: DropdownButtonFormField<String>(
                    value: _selectedIncidentType,
                    decoration: _fieldDecoration("Choose category"),
                    items: _incidentTypes
                        .map(
                          (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t, style: const TextStyle(fontSize: 14)),
                      ),
                    )
                        .toList(),
                    onChanged: _isUploading
                        ? null
                        : (val) => setState(() => _selectedIncidentType = val),
                  ),
                ),

                // Images
                _buildRow(
                  label: "Photos",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _imageFiles.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _imageFiles.length) {
                              return _buildAddButton();
                            }
                            return _buildImagePreview(index);
                          },
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Upload up to 5 clear photos",
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),

                // Location
                _buildRow(
                  label: "Location",
                  child: Column(
                    children: [
                      Container(
                        height: 220,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: _isMapLoading
                            ? const Center(child: CircularProgressIndicator())
                            : FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _currentPosition,
                            initialZoom: 15.0,
                            onTap: _isUploading
                                ? null
                                : (tapPosition, point) => _updateLocation(point),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                              'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=gFtNu24T2QIe0IP18qvC',
                              userAgentPackageName: 'com.example.gdg_hacksyn',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _currentPosition,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          _currentAddress,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Date Time (Read Only)
                _buildRow(
                  label: "Time",
                  child: TextFormField(
                    initialValue: _timestamp,
                    readOnly: true,
                    decoration: _fieldDecoration(
                      null,
                    ).copyWith(fillColor: Colors.grey.shade50, filled: true),
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ),

                const Divider(height: 40),

                // Anonymity
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    "Submit as anonymous report",
                    style: TextStyle(fontSize: 14),
                  ),
                  value: _isAnonymous,
                  onChanged: _isUploading
                      ? null
                      : (val) => setState(() => _isAnonymous = val ?? false),
                  activeColor: Colors.blueAccent,
                  controlAffinity: ListTileControlAffinity.leading,
                ),

                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _validateAndSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent.shade700,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: _isUploading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      "Submit Report",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          // Full screen loader overlay (Optional: can use the button loader instead)
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildRow({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildImagePreview(int index) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        image: DecorationImage(
          image: FileImage(File(_imageFiles[index].path)),
          fit: BoxFit.cover,
        ),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: GestureDetector(
          onTap: _isUploading
              ? null
              : () => setState(() => _imageFiles.removeAt(index)),
          child: const Padding(
            padding: EdgeInsets.all(4.0),
            child: CircleAvatar(
              radius: 10,
              backgroundColor: Colors.black54,
              child: Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _isUploading ? null : _pickImages,
      child: Container(
        width: 90,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200, width: 2),
        ),
        child: const Icon(Icons.add_a_photo_outlined, color: Colors.blueAccent),
      ),
    );
  }

  InputDecoration _fieldDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
      ),
    );
  }
}