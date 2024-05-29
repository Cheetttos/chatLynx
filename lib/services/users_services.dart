import 'package:cloud_firestore/cloud_firestore.dart';

class UsersFirestore {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener referencia a la colección principal de usuarios
  CollectionReference get usersCollection => _firestore.collection('users');

  Stream<QuerySnapshot> consultar() {
    return usersCollection.snapshots();
  }

  Future<void> insertar(Map<String, dynamic> data) async {
    return usersCollection.doc().set(data);
  }

  Future<void> actualizar(Map<String, dynamic> data, String id) async {
    return usersCollection.doc(id).update(data);
  }

  Future<void> borrar(String id) async {
    return usersCollection.doc(id).delete();
  }

  // Crear subcolección "contactos" para un usuario específico
  Future<void> crearSubcoleccionContactos(String userId, data) async {
    try {
      // Obtener referencia al documento del usuario
      DocumentReference userDocRef = usersCollection.doc(userId);

      // Acceder a la subcolección "contactos" dentro del documento del usuario
      CollectionReference contactosCollection =
          userDocRef.collection('contactos');

      // Crear un documento en la subcolección
      await contactosCollection.doc().set(data);
    } catch (error) {
      print('Error al crear subcolección de contactos: $error');
    }
  }

  Future<String?> encontrarUserIdPorUid(String uid) async {
    try {
      QuerySnapshot snapshot =
          await usersCollection.where('uid', isEqualTo: uid).get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      } else {
        return null;
      }
    } catch (error) {
      print('Error al encontrar userId por uid: $error');
      return null;
    }
  }

  Future<QuerySnapshot?> encontrarUsuarioPorEmail(String email) async {
    try {
      QuerySnapshot snapshot =
          await usersCollection.where('email', isEqualTo: email).get();
      return snapshot; // Devuelve el QuerySnapshot con los datos del usuario
    } catch (error) {
      print('Error al encontrar usuario por email: $error');
      return null;
    }
  }

  Future<bool> existeCorreoEnContactos(String? userId, String email) async {
    try {
      // Obtener referencia a la subcolección "contactos" dentro del documento del usuario
      CollectionReference contactosCollection =
          usersCollection.doc(userId).collection('contactos');

      // Realizar una consulta para verificar si existe un documento con el correo dado
      QuerySnapshot snapshot =
          await contactosCollection.where('email', isEqualTo: email).get();

      // Si la consulta devuelve al menos un documento, el correo existe en la subcolección
      return snapshot.docs.isNotEmpty;
    } catch (error) {
      print('Error al verificar si el correo existe en contactos: $error');
      return false;
    }
  }

  Stream<QuerySnapshot> consultarContactos(String userId) {
    CollectionReference contactosCollection =
        usersCollection.doc(userId).collection('contactos');
    return contactosCollection.snapshots();
  }

  Future<List<Map<String, String>>> obtenerContactosDisponibles(
      String userId) async {
    try {
      // Obtener referencia
      String? userIdEncontrado = await encontrarUserIdPorUid(userId);
      DocumentReference userDocRef = usersCollection.doc(userIdEncontrado);

      CollectionReference contactosCollection =
          usersCollection.doc(userIdEncontrado).collection('contactos');
      QuerySnapshot snapshot = await contactosCollection.get();

      List<Map<String, String>> availableContacts = [];
      snapshot.docs.forEach((doc) {
        Map<String, String> contactData = {
          'nombre': doc['nombre'],
          'uid': doc['uid'],
          'email': doc['email'],
          'photoURL': doc['photoURL'],
        };
        availableContacts.add(contactData);
      });
      print('the available contacts $availableContacts');
      return availableContacts;
    } catch (error) {
      print('Error al obtener contactos disponibles: $error');
      return [];
    }
  }
}
