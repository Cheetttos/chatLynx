import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  String? uid;
  String? name;
  String? pfpURL;
  Map<String, Timestamp>? mensajes;

  UserProfile({
    required this.uid,
    required this.name,
    required this.pfpURL,
    this.mensajes,
  });

  UserProfile.fromJson(Map<String, dynamic> json) {
    uid = json['uid'];
    name = json['name'];
    pfpURL = json['pfpURL'];

    // Comprobamos si el campo 'mensajes' existe y es un mapa
    if (json.containsKey('mensajes') &&
        json['mensajes'] is Map<String, dynamic>) {
      // Convertimos los valores del mapa a Timestamps si es posible
      mensajes =
          (json['mensajes'] as Map<String, dynamic>).map<String, Timestamp>(
        (key, value) => MapEntry(key, value as Timestamp),
      );
    } else {
      // Si no hay datos para 'mensajes', lo dejamos como null
      mensajes = null;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['pfpURL'] = pfpURL;
    data['uid'] = uid;
    // Convertimos los objetos Timestamp a enteros para almacenarlos en Firestore
    data['mensajes'] = mensajes?.map((key, value) => MapEntry(
        key, {'seconds': value.seconds, 'nanoseconds': value.nanoseconds}));
    return data;
  }

  String getMessageDisplay(String message) {
    // Comprueba si el mensaje es una URL de imagen
    if (isImageUrl(message)) {
      return '🖼 IMAGEN';
    } else {
      return message;
    }
  }

  // Método auxiliar para comprobar si una cadena es una URL de imagen
  bool isImageUrl(String url) {
    return url.contains('.jpg') || url.contains('.png') || url.contains('.png');
  }
}