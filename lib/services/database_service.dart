import 'package:chatlynx/modelos/chat.dart';
import 'package:chatlynx/modelos/message.dart';
import 'package:chatlynx/modelos/user_profile.dart';
import 'package:chatlynx/services/auth_service.dart';
import 'package:chatlynx/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

class DatabaseService {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  late AuthService _authService;
  late GetIt _getIt = GetIt.instance;

  CollectionReference? _usersCollection;
  CollectionReference? _chatsCollection;

  DatabaseService() {
    _authService = _getIt.get<AuthService>();
    _setupCollectionReferences();
  }

  void _setupCollectionReferences() {
    _usersCollection =
        _firebaseFirestore.collection('users').withConverter<UserProfile>(
              fromFirestore: (snapshots, _) => UserProfile.fromJson(
                snapshots.data()!,
              ),
              toFirestore: (userProfile, _) => userProfile.toJson(),
            );
    _chatsCollection = _firebaseFirestore
        .collection('chats')
        .withConverter<Chat>(
            fromFirestore: (snapshots, _) => Chat.fromJson(snapshots.data()!),
            toFirestore: (chat, _) => chat.toJson());
  }

  Future<void> createUserProfile({required UserProfile userProfile}) async {
    try {
      await _usersCollection?.doc(userProfile.uid).set(userProfile);
    } catch (e) {
      print('Error al crear el perfil de usuario: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot<UserProfile>> getUserProfiles() {
    return _usersCollection!
        .orderBy("mensajes.${_authService.user!.uid}", descending: true)
        .snapshots() as Stream<QuerySnapshot<UserProfile>>;
  }

  Future<bool> checkChatExists(String uid1, String uid2) async {
    String chatID = generateChatID(uid1: uid1, uid2: uid2);
    final result = await _chatsCollection?.doc(chatID).get();

    if (result != null) {
      return result.exists;
    }

    return false;
  }

  Future<void> createNewChat(String uid1, String uid2) async {
    String chatID = generateChatID(uid1: uid1, uid2: uid2);
    final docRef = _chatsCollection!.doc(chatID);
    final chat = Chat(
      id: chatID,
      participants: [uid1, uid2],
      messages: [],
    );
    await docRef.set(chat);
  }

  Future<void> generateTimestamps(
      String uid1, String uid2, Timestamp timestamp) async {
    final user1 = _usersCollection!.doc(uid1);
    final user2 = _usersCollection!.doc(uid2);

    // Obtener los datos del perfil de usuario 1
    final user1ProfileSnap = await user1.get();
    if (user1ProfileSnap.exists) {
      // Actualizar los mensajes en el perfil de usuario 1
      await user1.update({
        'mensajes.$uid2': timestamp,
      });
    }

    // Obtener los datos del perfil de usuario 2
    final user2ProfileSnap = await user2.get();
    if (user2ProfileSnap.exists) {
      // Actualizar los mensajes en el perfil de usuario 2
      await user2.update({
        'mensajes.$uid1': timestamp,
      });
    }
  }

  Future<void> sendChatMessage(
      String uid1, String uid2, Message message) async {
    String chatID = generateChatID(uid1: uid1, uid2: uid2);
    final docRef = _chatsCollection!.doc(chatID);
    final timestamp = Timestamp.now();

    // Actualizar el documento de chat
    await docRef.update({
      "messages": FieldValue.arrayUnion(
        [
          message.toJson(),
        ],
      ),
    });

    // Llamar al método generateTimestamps
    await generateTimestamps(uid1, uid2, timestamp);
  }

  Future<String> getCurrentUserName() async {
    String? currentUserUid = _authService.user?.uid;
    if (currentUserUid != null) {
      DocumentSnapshot<UserProfile> userDoc = await _usersCollection
          ?.doc(currentUserUid)
          .get() as DocumentSnapshot<UserProfile>;
      if (userDoc.exists) {
        UserProfile userProfile = userDoc.data()!;
        print(userProfile.name);
        return userProfile.name ??
            ''; // Devuelve el nombre del usuario o una cadena vacía si no tiene nombre
      }
    }
    return '';
  }

  Stream getChatData(String uid1, String uid2) {
    String chatID = generateChatID(uid1: uid1, uid2: uid2);
    return _chatsCollection?.doc(chatID).snapshots()
        as Stream<DocumentSnapshot<Chat>>;
  }

  Stream<DocumentSnapshot<Chat>> getChatStream(String uid1, String uid2) {
    String chatId = generateChatID(uid1: uid1, uid2: uid2);
    return _chatsCollection!
        .doc(chatId)
        .snapshots()
        .cast<DocumentSnapshot<Chat>>();
  }

  //contactos
  Future<bool> isEmailRegistered(String email) async {
    try {
      final querySnapshot = await _firebaseFirestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error al verificar el email: $e');
      return false;
    }
  }

  Future<bool> isContactRegistered(String userId, String contactEmail) async {
    try {
      final querySnapshot = await _firebaseFirestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .where('email', isEqualTo: contactEmail)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error al verificar el contacto: $e');
      return false;
    }
  }

  Future<void> addContact(
      String userId, String contactName, String contactEmail) async {
    try {
      // Si el email está registrado y el contacto no está registrado, proceder a agregarlo
      await _firebaseFirestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .add({
        'name': contactName,
        'email': contactEmail,
      });
    } catch (e) {
      print('Error al agregar el contacto: $e');
      rethrow;
    }
  }

  Stream<List<UserProfile>> getUserContacts(String userId) {
    return _firebaseFirestore
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .snapshots()
        .asyncMap((querySnapshot) async {
      List<UserProfile> contacts = [];
      for (var doc in querySnapshot.docs) {
        String contactEmail = doc.get('email');
        UserProfile? contact =
            (await getUserProfileByEmail(contactEmail)) as UserProfile?;
        contacts.add(contact!);
      }
      return contacts;
    });
  }

  Future<Object?> getUserProfileByEmail(String email) async {
    QuerySnapshot<Object?> querySnapshot =
        await _usersCollection!.where('email', isEqualTo: email).get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.data();
    } else {
      throw Exception('No se encontró un usuario con el correo $email');
    }
  }

  //CRUD usuario
  Future<void> updateUserName(String? uid, String newName) async {
    if (uid != null) {
      await _usersCollection?.doc(uid).update({'name': newName});
    }
  }

  Future<void> updateUserProfilePicUrl(
      String? uid, String newProfilePicUrl) async {
    if (uid != null) {
      await _usersCollection
          ?.doc(uid)
          .update({'profilePicUrl': newProfilePicUrl});
    }
  }
}
