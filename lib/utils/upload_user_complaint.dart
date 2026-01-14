import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

class UploadUserComplaint {

  static Future<List<String>> getImageslink(List<XFile> selectedImages, String userId) async {
    List<String> imageUrls = [];

    // 1. Get a reference to Firebase Storage
    final storageRef = FirebaseStorage.instance.ref();

    try {
      for (XFile image in selectedImages) {
        // 2. Create a unique filename (timestamp helps avoid overwriting)
        String fileName = "${DateTime.now().millisecondsSinceEpoch}_$userId";

        // 3. Define the path: images_gdg / userId / fileName
        final imageRef = storageRef.child("images_gdg/$userId/$fileName");

        // 4. Upload the file
        File file = File(image.path);
        UploadTask uploadTask = imageRef.putFile(file);

        // 5. Wait for completion and get the URL
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        imageUrls.add(downloadUrl);
      }
    } catch (e) {
      print("Error uploading images: $e");
    }

    print(imageUrls);
    return imageUrls;
  }


  static Future<void> upload(
    bool isAnonymous,
    LatLng location,
    List<XFile> photos,
    DateTime timestamp,
    String type,
    userId,
  ) async {
    try {
      var collection = FirebaseFirestore.instance.collection('reports');

      List<String> userImages = await getImageslink(photos, userId);

      await collection.add({
        'isAnonymous': isAnonymous,
        'location': GeoPoint(location.latitude, location.longitude),
        'photos': userImages,
        'timestamp': timestamp,
        'type': type,
        'userId': userId,
      });
    } catch (e) {
      rethrow;
    }
  }
}
