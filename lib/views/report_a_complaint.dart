import 'dart:io';
import 'package:gdg_hacksync/views/report_submit_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

class ReportAComplaint extends StatefulWidget {
  const ReportAComplaint({super.key});

  @override
  State<ReportAComplaint> createState() => _ReportAComplaintState();
}

class _ReportAComplaintState extends State<ReportAComplaint> {
  // Dark Mode Palette
  final Color _darkBg = const Color(0xFF121212);
  final Color _darkSurface = const Color(0xFF1E1E1E);
  final Color _textPrimary = Colors.white.withOpacity(0.9);
  final Color _textSecondary = Colors.white60;

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
  bool _isUploading = false;

  // Map & Location State
  final MapController _mapController = MapController();
  LatLng _currentPosition = const LatLng(0, 0);
  String _currentAddress = "Fetching location...";
  bool _isMapLoading = true;

  // Metadata
  final String _timestamp = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

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

    Position position = await Geolocator.getCurrentPosition();
    _updateLocation(LatLng(position.latitude, position.longitude));
  }

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
          _currentAddress = "${place.street ?? ''}, ${place.locality ?? ''}, ${place.postalCode ?? ''}";
        });
      }
    } catch (e) {
      setState(() => _currentAddress = "Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_imageFiles.length >= 5) {
      _showErrorSnackBar("Maximum 5 photos allowed");
      return;
    }

    try {
      if (source == ImageSource.gallery) {
        final List<XFile> selectedImages = await _picker.pickMultiImage();
        if (selectedImages.isNotEmpty) {
          setState(() {
            _imageFiles.addAll(selectedImages);
            if (_imageFiles.length > 5) {
              _imageFiles.removeRange(5, _imageFiles.length);
            }
          });
        }
      } else {
        final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
        if (photo != null) setState(() => _imageFiles.add(photo));
      }
    } catch (e) {
      _showErrorSnackBar("Error accessing source: $e");
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _darkSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text("Attach Photo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _textPrimary)),
              ),
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.blueAccent.withOpacity(0.1), child: const Icon(Icons.photo_library, color: Colors.blueAccent)),
                title: Text("Choose from Gallery", style: TextStyle(color: _textPrimary)),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
              ),
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.greenAccent.withOpacity(0.1), child: const Icon(Icons.camera_alt, color: Colors.greenAccent)),
                title: Text("Take a Photo", style: TextStyle(color: _textPrimary)),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _validateAndSubmit() async {
    if (_selectedIncidentType == null) { _showErrorSnackBar("Please select an incident type."); return; }
    if (_imageFiles.isEmpty) { _showErrorSnackBar("Please upload at least one photo."); return; }

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

    if (result == true && mounted) Navigator.pop(context);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        title: Text("New Complaint", style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: _darkBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                _buildRow(
                  label: "Type",
                  child: DropdownButtonFormField<String>(
                    dropdownColor: _darkSurface,
                    value: _selectedIncidentType,
                    style: TextStyle(color: _textPrimary, fontSize: 14),
                    decoration: _fieldDecoration("Choose category"),
                    // Added explicit hint property to ensure it uses high-contrast color
                    hint: Text(
                      "Choose category",
                      style: TextStyle(color: _textPrimary, fontSize: 14),
                    ),
                    items: _incidentTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: _isUploading ? null : (val) => setState(() => _selectedIncidentType = val),
                  ),
                ),
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
                          itemBuilder: (context, index) => index == _imageFiles.length ? _buildAddButton() : _buildImagePreview(index),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text("Add up to 5 clear photos", style: TextStyle(fontSize: 11, color: _textSecondary)),
                      ),
                    ],
                  ),
                ),
                _buildRow(
                  label: "Location",
                  child: Column(
                    children: [
                      Container(
                        height: 220,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                        child: _isMapLoading
                            ? const Center(child: CircularProgressIndicator())
                            : FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _currentPosition,
                            initialZoom: 15.0,
                            onTap: _isUploading ? null : (tapPos, point) => _updateLocation(point),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=gFtNu24T2QIe0IP18qvC',
                              userAgentPackageName: 'com.example.gdg_hacksync',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(point: _currentPosition, width: 40, height: 40, child: const Icon(Icons.location_on, color: Colors.redAccent, size: 40)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(_currentAddress, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueAccent.shade100)),
                      ),
                    ],
                  ),
                ),
                _buildRow(
                  label: "Time",
                  child: TextFormField(
                    initialValue: _timestamp,
                    readOnly: true,
                    decoration: _fieldDecoration(null).copyWith(fillColor: Colors.white.withOpacity(0.05), filled: true),
                    style: TextStyle(color: _textSecondary, fontSize: 14),
                  ),
                ),
                const Divider(height: 40, color: Colors.white10),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text("Submit as anonymous report", style: TextStyle(fontSize: 14, color: _textPrimary)),
                  value: _isAnonymous,
                  onChanged: _isUploading ? null : (val) => setState(() => _isAnonymous = val ?? false),
                  activeColor: Colors.blueAccent,
                  checkColor: Colors.white,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _validateAndSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: _isUploading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Submit Report", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isUploading)
            Container(color: Colors.black45, child: const Center(child: CircularProgressIndicator())),
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
          SizedBox(width: 70, child: Padding(padding: const EdgeInsets.only(top: 14), child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textSecondary)))),
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
        border: Border.all(color: Colors.white10),
        image: DecorationImage(image: FileImage(File(_imageFiles[index].path)), fit: BoxFit.cover),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: GestureDetector(
          onTap: _isUploading ? null : () => setState(() => _imageFiles.removeAt(index)),
          child: const Padding(
            padding: EdgeInsets.all(4.0),
            child: CircleAvatar(radius: 10, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 12, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _isUploading ? null : _showImageSourcePicker,
      child: Container(
        width: 90,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10, width: 2)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_outlined, color: Colors.blueAccent),
            const SizedBox(height: 4),
            Text("Add", style: TextStyle(fontSize: 11, color: Colors.blueAccent.shade100, fontWeight: FontWeight.w600))
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      // Updated hintStyle to ensure it is white and visible in dark mode
      hintStyle: const TextStyle(fontSize: 14, color: Colors.white),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5)),
    );
  }
}