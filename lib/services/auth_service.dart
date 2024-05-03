import 'package:chatlynx/services/alert_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  late AlertService _alertService;

  User? _user;

  User? get user {
    return _user;
  }

  AuthService() {
    _firebaseAuth.authStateChanges().listen(authStateChangesStreamListener);
  }

  Future<bool> login(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);

      if (credential.user != null) {
        if (credential.user!.emailVerified) {
          _user = credential.user;
          return true;
        }
      }
      return false;
    } catch (e) {
      print(e);
    }

    return false;
  }

  Future<bool> signup(String email, String password) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      if (credential.user != null) {
        credential.user!.sendEmailVerification();
        _user = credential.user;
        return true;
      }
    } catch (e) {
      print(e);
    }
    return false;
  }

  Future<bool> logout() async {
    try {
      await _firebaseAuth.signOut();
      return true;
    } catch (e) {
      print(e);
    }

    return false;
  }

  void authStateChangesStreamListener(User? user) {
    if (user != null) {
      _user = user;
    } else {
      _user = null;
    }
  }

  Future<void> requestPermissions() async {
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      _alertService.showToast(text: 'No se podrá realizar la llamada');
    }

    status = await Permission.camera.request();
    if (!status.isGranted) {
      _alertService.showToast(text: 'No se podrá realizar la llamada');
    }
  }
}
