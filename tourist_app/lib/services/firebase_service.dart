import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static FirebaseFirestore get firestoreInstance => FirebaseFirestore.instance;

  // This function is now more generic to handle different alert types
  static Future<void> sendAlert({
    required String touristId,
    required double latitude,
    required double longitude,
    required String alertType,
    required String title,
  }) async {
    try {
      await firestoreInstance.collection('alerts').add({
        'title': title,
        'type': alertType,
        'status':
            'active', // Statuses can now be 'active', 'acknowledged', or 'resolved'
        'touristId': touristId,
        'lat': latitude,
        'lng': longitude,
        'locationName': 'Near Current Location',
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('$title alert sent successfully!');
    } catch (e) {
      print('Error sending alert: $e');
    }
  }
}
