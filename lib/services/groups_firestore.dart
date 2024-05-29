import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupsFirestore {
  String userId = FirebaseAuth.instance.currentUser!.uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get groupsCollection => _firestore.collection('groups');

  Future<void> createGroup(
      List<Map<String, dynamic>> contactos, String groupName) async {
    try {
      DocumentReference newGroupDocRef = await groupsCollection.add({
        'admin': userId,
        'groupId': '',
        'groupName': groupName,
        'members': contactos,
      });

      String groupId = newGroupDocRef.id;

      await newGroupDocRef.update({'groupId': groupId});

      await insertUsersWithGroupId(groupId, contactos);
    } catch (error) {
      print('Error al crear el grupo: $error');
    }
  }

  Stream<QuerySnapshot> getGroups() {
    return groupsCollection.snapshots();
  }

  Future<void> insertUsersWithGroupId(
      String groupId, List<Map<String, dynamic>> contactos) async {
    try {
      CollectionReference usersCollection = _firestore.collection('users');

      for (var contacto in contactos) {
        var querySnapshot = await usersCollection
            .where('uid', isEqualTo: contacto['uid'])
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          var userDoc = querySnapshot.docs.first;
          await userDoc.reference.set(
              {
                'groups': FieldValue.arrayUnion([groupId])
              },
              SetOptions(
                  merge:
                      true)); //Utilizar SetOptions para fusionar el nuevo campo con los existentes
        } else {
          // El documento del usuario no existe
          print('El usuario con UID ${contacto['uid']} no existe.');
        }
      }
    } catch (error) {
      print('Error al actualizar usuarios con groupId: $error');
    }
  }

  Future<void> sendMessage(String groupId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .add(data);
      print('Message sent successfully.');
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Stream<QuerySnapshot> getMessages(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('hora', descending: false)
        .snapshots();
  }

  Future<void> addUserToGroup(
    String groupId,
    List<Map<String, dynamic>> contactos,
  ) async {
    try {
      DocumentReference groupDocRef =
          _firestore.collection('groups').doc(groupId);

      for (var contacto in contactos) {
        await groupDocRef.update({
          'members': FieldValue.arrayUnion([contacto]),
        });

        CollectionReference usersCollection = _firestore.collection('users');
        var userQuerySnapshot = await usersCollection
            .where('uid', isEqualTo: contacto['uid'])
            .get();

        if (userQuerySnapshot.docs.isNotEmpty) {
          var userDoc = userQuerySnapshot.docs.first;
          await userDoc.reference.set({
            'groups': FieldValue.arrayUnion([groupId]),
          }, SetOptions(merge: true));

          await insertUsersWithGroupId(groupId, contactos);
        } else {
          print('El usuario con UID ${contacto['uid']} no existe.');
        }
      }

      print('Usuario añadido al grupo exitosamente.');
    } catch (error) {
      print('Error al añadir usuario al grupo: $error');
    }
  }
}
