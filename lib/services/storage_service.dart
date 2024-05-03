import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:giphy_picker/giphy_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

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

  Future<String?> uploadGifToChat(
      {required GiphyGif gif, required String chatId}) async {
    try {
      final Reference gifRef = FirebaseStorage.instance
          .ref('chats/$chatId')
          .child(
              '${DateTime.now().toIso8601String()}.${p.extension(gif.url!)}');
      final UploadTask uploadTask =
          gifRef.putFile(await DefaultCacheManager().getSingleFile(gif.url!));
      final snapshot = await uploadTask.whenComplete(() => null);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error al subir el GIF: $e');
      return null;
    }
  }
}
