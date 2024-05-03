import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MediaService {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  MediaService() {}

  Future<File?> getImageFromGallery() async {
    final XFile? _file = await _picker.pickImage(source: ImageSource.gallery);

    if (_file != null) {
      return File(_file.path);
    }

    return null;
  }

  Future<String> uploadImage(File imageFile) async {
    try {
      // Crear una referencia al lugar en el Storage donde queremos almacenar la imagen
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference reference = _storage.ref().child('images/$fileName');

      // Subir la imagen al Storage
      UploadTask uploadTask = reference.putFile(imageFile);

      // Esperar a que se complete la subida
      await uploadTask.whenComplete(() => null);

      // Obtener la URL de descarga de la imagen
      String imageUrl = await reference.getDownloadURL();

      // Retornar la URL de la imagen
      return imageUrl;
    } catch (e) {
      // Manejar cualquier error que ocurra durante la subida
      throw Exception('Error al cargar la imagen: $e');
    }
  }
  Future<File?> getImageFromCamera() async {
    final XFile? _file = await _picker.pickImage(source: ImageSource.camera);

    if (_file != null) {
      return File(_file.path);
    }

    return null;
  }
}
