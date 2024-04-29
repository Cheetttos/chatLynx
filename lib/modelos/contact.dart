import 'package:cloud_firestore/cloud_firestore.dart';

class Contact {
  String? uid;
  String? name;
  String? email;
  String? pfpURL;

  Contact({
    required this.uid,
    required this.name,
    required this.email,
    required this.pfpURL,
  });

  // Método para convertir un documento de Firebase en una instancia de Contacto
  factory Contact.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Contact(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      pfpURL: data['pfpURL'] ?? '',

    );
  }

  // Método para convertir un Contacto en un mapa para subirlo a Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'pfpURL': pfpURL,
    };
  }
}
