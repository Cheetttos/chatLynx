import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

class StorageService {
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  StorageService();

  Future<String?> uploadUserPfp({
    required File file,
    required String uid,
  }) async {
    Reference fileRef = _firebaseStorage
        .ref('users/pfps')
        .child('$uid${p.extension(file.path)}');
    UploadTask task = fileRef.putFile(file);
    return task.then((p) {
      if (p.state == TaskState.success) {
        return fileRef.getDownloadURL();
      }
      return null;
    });
  }

  Future<String?> uploadImageToChat(
      {required File file, required String chatId}) async {
    Reference fileRef = _firebaseStorage
        .ref('chats/$chatId')
        .child('${DateTime.now().toIso8601String()}${p.extension(file.path)}');
    UploadTask task = fileRef.putFile(file);
    return task.then((p) {
      if (p.state == TaskState.success) {
        return fileRef.getDownloadURL();
      }
      return null;
    });
  }

  Future<String?> getUserProfilePicUrl(String uid) async {
    Reference profilePicRef = _firebaseStorage.ref('users/pfps/$uid.jpg');

    try {
      String downloadUrl = await profilePicRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      // Manejar el caso cuando no hay imagen de perfil para el usuario
      return null;
    }
  }
}
