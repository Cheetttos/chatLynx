import 'package:chatlynx/screens/notification_screen.dart';
import 'package:chatlynx/services/navigation_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print('Title : ${message.notification?.title}');
  print('Body : ${message.notification?.body}');
  print('Payload : ${message.data}');
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final NavigationService _navigationService;
  
  FirebaseApi(this._navigationService); // Inicializa _navigationService aquí

  void handleMessage(RemoteMessage? message) {
    if (message == null) return;
    _navigationService.navigatiorKey?.currentState
        ?.pushNamed(NotificationScreen.route, arguments: message);
    //_navigationService.pushNamed('/notification');
  }

  Future initPushNotification() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
            alert: true, badge: true, sound: true);
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
  }

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    final fCMToken = await _firebaseMessaging.getToken();
    print('Token $fCMToken');
    initPushNotification();
  }
}
