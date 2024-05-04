import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
//import 'package:giphy_picker/giphy_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class StorageService {
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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

  Future<String> uploadImage(File imageFile) async {
    try {
      // Generar un nombre de archivo único para la imagen
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      // Referencia al directorio donde se almacenarán las imágenes de perfil
      Reference reference = _storage.ref().child('users/pfps/$fileName.jpg');
      // Subir la imagen al servicio de almacenamiento
      UploadTask uploadTask = reference.putFile(imageFile);
      // Obtener la URL de descarga de la imagen
      TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      // Manejar cualquier error que ocurra durante la carga de la imagen
      print('Error uploading image: $e');
      throw e;
    }
  }
/*
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
  }*/
}
