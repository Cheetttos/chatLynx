// notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> sendCallNotification({
    required String receiverUserId,
    required String callerName,
    required String callerProfilePicture,
    required String channelName,
  }) async {
    // Enviar notificación de llamada entrante al usuario B utilizando FCM
    await _firebaseMessaging.sendMessage(
      to: receiverUserId, // ID del usuario B
      data: {
        'type': 'call',
        'callerName': callerName,
        'callerProfilePicture': callerProfilePicture,
        'channelName': channelName,
      },
    );
  }
}