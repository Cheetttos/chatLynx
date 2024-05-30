import 'dart:io';

import 'package:chatlynx/screens/image_view_screen.dart';
import 'package:chatlynx/screens/video_player_screen.dart';
import 'package:chatlynx/services/groups_firestore.dart';
import 'package:chatlynx/services/users_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:giphy_get/giphy_get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ConversationGroupsScreen extends StatefulWidget {
  final QueryDocumentSnapshot? groupData;

  const ConversationGroupsScreen({super.key, this.groupData});

  @override
  State<ConversationGroupsScreen> createState() =>
      _ConversationGroupsScreenState();
}

class _ConversationGroupsScreenState extends State<ConversationGroupsScreen> {
  final TextEditingController _messageController = TextEditingController();
  final UsersFirestore usersFirestore = UsersFirestore();
  //final MessagesFireStore messagesFireStore = MessagesFireStore();
  String userId = FirebaseAuth.instance.currentUser!.uid;
  String? nameCurrent = FirebaseAuth.instance.currentUser!.displayName;
  final ScrollController _scrollController = ScrollController();
  GroupsFirestore groups = GroupsFirestore();
  List<Map<String, dynamic>> _availableContacts = [];
  final List<Map<String, dynamic>> _selectedContacts = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableContacts();
  }

  void _loadAvailableContacts() async {
    String userIdCurrent = FirebaseAuth.instance.currentUser!.uid;
    List<Map<String, dynamic>> allContacts =
        await usersFirestore.obtenerContactosDisponibles(userIdCurrent);
    List<dynamic> members = widget.groupData!["members"];
    List memberEmails = members.map((member) => member['email']).toList();

    setState(() {
      _availableContacts = allContacts
          .where((contact) => !memberEmails.contains(contact['email']))
          .toList();
    });
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      File imageFile = File(pickedImage.path);
      // Subimos a almacenamiento de Storage
      Reference ref =
          FirebaseStorage.instanceFor(bucket: "gs://chat-82a68.appspot.com")
              .ref()
              .child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      UploadTask uploadTask = ref.putFile(imageFile);
      await uploadTask.whenComplete(() => null);
      // Obtenemos URL
      String imageUrl = await ref.getDownloadURL();
      print('URL de la imagen subida: $imageUrl');

      Map<String, dynamic> data = {
        'message': imageUrl,
        'senderUserName': nameCurrent,
        'hora': DateTime.now(),
        'senderId': userId,
        'type': 'image'
      };

      await groups.sendMessage(widget.groupData!["groupId"], data);
      _messageController.clear();
    }
  }

  Future<void> _pickImageFromCamera() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.camera);

    if (pickedImage != null) {
      File imageFile = File(pickedImage.path);
      // Subimos a almacenamiento de Storage
      Reference ref =
          FirebaseStorage.instanceFor(bucket: "gs://chat-82a68.appspot.com")
              .ref()
              .child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      UploadTask uploadTask = ref.putFile(imageFile);
      await uploadTask.whenComplete(() => null);
      // Obtenemos URL
      String imageUrl = await ref.getDownloadURL();
      print('URL de la imagen subida: $imageUrl');

      Map<String, dynamic> data = {
        'message': imageUrl,
        'senderUserName': nameCurrent,
        'hora': DateTime.now(),
        'senderId': userId,
        'type': 'image'
      };

      await groups.sendMessage(widget.groupData!["groupId"], data);

      _messageController.clear();
    }
  }

  Future<void> _pickVideoFromGallery() async {
    final picker = ImagePicker();
    final pickedVideo = await picker.pickVideo(source: ImageSource.gallery);

    if (pickedVideo != null) {
      File videoFile = File(pickedVideo.path);

      // Subimos el video almacenamiento de  Storage
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('videos/${DateTime.now().millisecondsSinceEpoch}.mp4');
      UploadTask uploadTask = ref.putFile(videoFile);
      await uploadTask.whenComplete(() => null);

      String videoUrl = await ref.getDownloadURL();
      print('URL del video subido: $videoUrl');

      Map<String, dynamic> data = {
        'message': videoUrl,
        'senderUserName': nameCurrent,
        'hora': DateTime.now(),
        'senderId': userId,
        'type': 'video'
      };

      await groups.sendMessage(widget.groupData!["groupId"], data);

      _messageController.clear();
    }
  }

  Future<void> _pickVideoFromCamera() async {
    final picker = ImagePicker();
    final pickedVideo = await picker.pickVideo(source: ImageSource.camera);

    if (pickedVideo != null) {
      File videoFile = File(pickedVideo.path);

      // Subimos el video almacenamiento de  Storage
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('videos/${DateTime.now().millisecondsSinceEpoch}.mp4');
      UploadTask uploadTask = ref.putFile(videoFile);
      await uploadTask.whenComplete(() => null);

      String videoUrl = await ref.getDownloadURL();
      print('URL del video subido: $videoUrl');

      Map<String, dynamic> data = {
        'message': videoUrl,
        'senderUserName': nameCurrent,
        'hora': DateTime.now(),
        'senderId': userId,
        'type': 'video'
      };

      await groups.sendMessage(widget.groupData!["groupId"], data);

      _messageController.clear();
    }
  }

  Future<void> _pickGif() async {
    final GiphyGif? gif = await GiphyGet.getGif(
      context: context,
      apiKey: 'ENrCgT8Nc7Jgjgkro9QIDbSJQrYnZZW5',
    );

    if (gif != null) {
      final gifUrl = gif.images!.original!.url; // GIF como archivo
      final response = await http.get(Uri.parse(gifUrl)); // Descargamos GIF
      final directory = await getTemporaryDirectory(); //Ruta temporal
      final gifFile = File('${directory.path}/temp.gif');
      await gifFile.writeAsBytes(response.bodyBytes);

      // Subir gif a firebase
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('gifs/${DateTime.now().millisecondsSinceEpoch}.gif');
      UploadTask uploadTask = ref.putFile(gifFile);
      await uploadTask.whenComplete(() => null);

      final uploadedGifUrl = await ref.getDownloadURL();

      Map<String, dynamic> data = {
        'message': uploadedGifUrl,
        'senderUserName': nameCurrent,
        'hora': DateTime.now(),
        'senderId': userId,
        'type': 'gif'
      };

      await groups.sendMessage(widget.groupData!["groupId"], data);

      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.90),
        foregroundColor: Colors.white,
        toolbarHeight: 70,
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImageViewScreen(
                      nombre: widget.groupData!["groupName"],
                      imageURL:
                          'https://t4.ftcdn.net/jpg/03/78/40/51/360_F_378405187_PyVLw51NVo3KltNlhUOpKfULdkUOUn7j.jpg',
                    ),
                  ),
                );
              },
              child: const CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(
                    'https://t4.ftcdn.net/jpg/03/78/40/51/360_F_378405187_PyVLw51NVo3KltNlhUOpKfULdkUOUn7j.jpg'),
              ),
            ),
            const SizedBox(
              width: 15,
            ),
            Expanded(
              child: Text(
                widget.groupData!["groupName"],
                overflow: TextOverflow.fade,
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w300),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            color: Colors.grey[700],
            onSelected: (String value) {
              if (value == 'ver_miembros') {
                showModalBottomSheet(
                  backgroundColor: Colors.grey[700],
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  builder: (BuildContext context) {
                    return StreamBuilder<DocumentSnapshot>(
                      stream: GroupsFirestore()
                          .groupsCollection
                          .doc(widget.groupData!["groupId"])
                          .snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<DocumentSnapshot> snapshot) {
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else {
                          List members = snapshot.data!['members'];
                          return Container(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.3,
                            ),
                            child: ListView.builder(
                              itemCount: members.length,
                              itemBuilder: (context, index) {
                                String memberName = members[index]['nombre'];
                                return ListTile(
                                  title: Text(memberName,
                                      style: GoogleFonts.poppins(
                                          color: Colors.white)),
                                  subtitle: Text(
                                    members[index]['email'],
                                    style: GoogleFonts.poppins(
                                        color: Colors.white54),
                                  ),
                                  leading: CircleAvatar(
                                    backgroundImage: NetworkImage(
                                        members[index]['photoURL']),
                                  ),
                                );
                              },
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              }
              if (value == 'add_miembros') {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return AlertDialog(
                          contentPadding: const EdgeInsets.all(9),
                          content: ExpansionTile(
                            // Lista desplegable
                            collapsedIconColor: Colors.black,
                            iconColor: Colors.black,
                            collapsedShape: const RoundedRectangleBorder(
                                side: BorderSide.none),
                            shape: const RoundedRectangleBorder(
                                side: BorderSide.none),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.contacts,
                                        color: Colors.black),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Selecciona los contactos',
                                      style: GoogleFonts.poppins(
                                          color: Colors.black, fontSize: 10),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  '${_availableContacts.length} disponibles', // Contador select contacts
                                  style: GoogleFonts.poppins(
                                      color: Colors.black, fontSize: 13),
                                ),
                              ],
                            ),
                            children: [
                              ..._availableContacts.map((contact) {
                                return CheckboxListTile(
                                  // Item
                                  title: Text(
                                    contact['nombre'],
                                    style: GoogleFonts.poppins(
                                        color: Colors.black, fontSize: 13),
                                  ),
                                  value: _selectedContacts.any(
                                      (selectedContact) =>
                                          selectedContact['nombre'] ==
                                          contact['nombre']),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedContacts.add(contact);
                                      } else {
                                        _selectedContacts.remove(contact);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                              ListTile(
                                title: Text(
                                  _selectedContacts.length ==
                                          _availableContacts.length
                                      ? 'Deseleccionar todos'
                                      : 'Seleccionar todos',
                                  textAlign: TextAlign.end,
                                  style: GoogleFonts.poppins(
                                      color: Colors.black, fontSize: 13),
                                ),
                                onTap: () {
                                  setState(() {
                                    if (_selectedContacts.length ==
                                        _availableContacts.length) {
                                      _selectedContacts.clear();
                                    } else {
                                      _selectedContacts.clear();
                                      _selectedContacts
                                          .addAll(_availableContacts);
                                    }
                                  });
                                },
                              ),
                              ElevatedButton(
                                onPressed: _selectedContacts.isNotEmpty
                                    ? () {
                                        String groupId =
                                            widget.groupData!["groupId"];
                                        GroupsFirestore()
                                            .addUserToGroup(
                                                groupId, _selectedContacts)
                                            .then((_) {
                                          Navigator.pop(context);
                                          var snackbar = SnackBar(
                                            content: Text(
                                              'Añadido correctamente',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: Colors.white),
                                            ),
                                            duration:
                                                const Duration(seconds: 3),
                                            backgroundColor: Colors.green,
                                            behavior: SnackBarBehavior.floating,
                                            margin: const EdgeInsets.only(
                                                bottom: 50,
                                                left: 20,
                                                right: 20),
                                          );
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(snackbar);
                                        });
                                      }
                                    : null,
                                child: Text(
                                  'Añadir al chat',
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              /*PopupMenuItem<String>(
                value: 'ver_miembros',
                child: ListTile(
                  leading: const Icon(
                    Icons.group,
                    color: Colors.white,
                  ),
                  title: Text(
                    'Ver miembros',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ),*/
              PopupMenuItem<String>(
                value: 'add_miembros',
                child: ListTile(
                  leading: const Icon(
                    Icons.person_add_alt_1_sharp,
                    color: Colors.white,
                  ),
                  title: Text(
                    'Agregar miembros',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          /*image: const DecorationImage(
            image: AssetImage("assets/fondo_ws.png"),
            fit: BoxFit.cover,
          ),*/
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey.shade900, Colors.black],
          ),
        ),
        child: Column(
          children: [
            Expanded(
                child: StreamBuilder(
              stream: groups.getMessages(widget.groupData!["groupId"]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  if (snapshot.hasError) {
                    return const Text('Error al cargar los mensajes');
                  } else {
                    if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          'No hay mensajes aún',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    } else {
                      Future.delayed(Duration(microseconds: 0)).then((_) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      });
                      return ListView.builder(
                        controller: _scrollController,
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var mensaje = snapshot.data!.docs[index];
                          String senderId = mensaje['senderId'];
                          bool isCurrentUser = senderId == userId;

                          //Convertimos fecha
                          Timestamp timestamp = mensaje['hora'];
                          DateTime dateTime = timestamp.toDate();
                          DateTime now = DateTime.now();
                          String formattedDate;
                          if (dateTime
                              .isAfter(now.subtract(const Duration(days: 1)))) {
                            formattedDate =
                                DateFormat('HH:mm a').format(dateTime);
                          } else if (dateTime
                              .isAfter(now.subtract(const Duration(days: 2)))) {
                            formattedDate =
                                'Ayer, ${DateFormat('HH:mm a').format(dateTime)}';
                          } else {
                            formattedDate =
                                DateFormat('dd/MM/yyyy').format(dateTime);
                          }

                          String senderFullName = mensaje['senderUserName'];
                          int lastSpaceIndex = senderFullName.lastIndexOf(' ');
                          String firstName = '';
                          String lastName = '';

                          if (lastSpaceIndex != -1) {
                            firstName =
                                senderFullName.substring(0, lastSpaceIndex);
                            lastName =
                                senderFullName.substring(lastSpaceIndex + 1);
                          } else {
                            firstName = senderFullName;
                          }
                          //Limitamos a 15 caract
                          if (firstName.length > 15) {
                            firstName = firstName.substring(0, 15) + '...';
                          }
                          if (lastName.length > 15) {
                            lastName = lastName.substring(0, 15) + '...';
                          }
                          String formattedSenderName = '$lastName $firstName ';

                          return Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 1, horizontal: 8),
                            child: Align(
                              alignment: isCurrentUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: ConstrainedBox(
                                //Para cuando el msj es muy largo
                                constraints: BoxConstraints(
                                  maxWidth: size.width * 0.75,
                                ),
                                child: IntrinsicWidth(
                                  //Ajuste al msj dinamicamente
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 8.0),
                                    decoration: BoxDecoration(
                                      color: isCurrentUser
                                          ? Colors.grey.shade800
                                          : const Color.fromRGBO(
                                              242, 247, 251, 1),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(
                                            isCurrentUser ? 16.0 : 0.0),
                                        topRight: Radius.circular(16.0),
                                        bottomLeft: Radius.circular(16.0),
                                        bottomRight: Radius.circular(
                                            isCurrentUser ? 0.0 : 16.0),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isCurrentUser
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isCurrentUser
                                              ? 'TÚ'
                                              : formattedSenderName,
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                        ),
                                        //Tipos de msj
                                        if (mensaje['type'] == 'image')
                                          InkWell(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ImageViewScreen(
                                                    imageURL:
                                                        mensaje['message'],
                                                    nombre: "",
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              margin: const EdgeInsets.only(
                                                  bottom: 5),
                                              child: Image.network(
                                                mensaje['message'],
                                                width: 200,
                                                height: 200,
                                              ),
                                            ),
                                          ),
                                        if (mensaje['type'] == 'video')
                                          Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 5, left: 8, right: 8),
                                            child: Align(
                                              alignment: isCurrentUser
                                                  ? Alignment.centerRight
                                                  : Alignment.centerLeft,
                                              child: SizedBox(
                                                width: size.width * 0.75,
                                                height: 200,
                                                child: VideoPlayerScreen(
                                                    videoUrl:
                                                        mensaje['message']),
                                              ),
                                            ),
                                          ),
                                        if (mensaje['type'] == 'gif')
                                          Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 5),
                                            child: Image.network(
                                              mensaje['message'],
                                              width: 200,
                                              height: 200,
                                            ),
                                          ),
                                        if (mensaje['type'] != 'image' &&
                                            mensaje['type'] != 'video' &&
                                            mensaje['type'] != 'gif')
                                          SelectableText(
                                            mensaje[
                                                'message'], // El texto del mensaje
                                            style: GoogleFonts.poppins(
                                              color: isCurrentUser
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 5.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                formattedDate,
                                                style: GoogleFonts.poppins(
                                                  color: Colors.grey,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              // const SizedBox(width: 4.0),
                                              // const Icon(
                                              //   Icons.done_all,
                                              //   color: Colors.blue,
                                              //   size: 16.0,
                                              // ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }
                  }
                }
              },
            )),
            //MENU PARA MENSAJE
            Container(
              margin: const EdgeInsets.only(
                  left: 10, right: 10, bottom: 15, top: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(left: 15, right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.grey[300],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              maxLines:
                                  null, //Eliminamos que el msj sea en 1 sola linea
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Mensaje',
                                hintStyle: GoogleFonts.poppins(),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.attach_file_rounded),
                                onPressed: () {
                                  showMenu(
                                    //Menu de multimedia
                                    context: context,
                                    position: const RelativeRect.fromLTRB(
                                        110, 680, 80, 0),
                                    items: [
                                      PopupMenuItem(
                                        child: ListTile(
                                          leading: const Icon(
                                              Icons.video_camera_back_rounded),
                                          title: const Text('Vídeo'),
                                          titleTextStyle: GoogleFonts.poppins(
                                              color: Colors.black),
                                          onTap: () {
                                            print('Añadir vídeo');
                                            Navigator.pop(context);
                                            showVideoOptions();
                                          },
                                        ),
                                      ),
                                      PopupMenuItem(
                                        child: ListTile(
                                          leading:
                                              const Icon(Icons.gif_box_rounded),
                                          title: Text('GIF'),
                                          titleTextStyle: GoogleFonts.poppins(
                                              color: Colors.black),
                                          onTap: () {
                                            print('Añadir gif');
                                            Navigator.pop(context);
                                            _pickGif();
                                          },
                                        ),
                                      ),
                                      // Agrega más opciones según sea necesario
                                    ],
                                    elevation: 8,
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.camera),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return SafeArea(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            ListTile(
                                              leading:
                                                  const Icon(Icons.camera_alt),
                                              title: Text(
                                                'Tomar foto',
                                                style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w300),
                                              ),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _pickImageFromCamera();
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.image),
                                              title: Text(
                                                'Seleccionar de galería',
                                                style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w300),
                                              ),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _pickImageFromGallery();
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded),
                    onPressed: () async {
                      String? userName =
                          FirebaseAuth.instance.currentUser!.displayName;
                      String? photoURLSender =
                          FirebaseAuth.instance.currentUser!.photoURL;
                      String message = _messageController.text;

                      // Creacion de msj
                      if (message.trim().isNotEmpty) {
                        Map<String, dynamic> data = {
                          'message': message,
                          'senderUserName': userName,
                          'hora': DateTime.now(),
                          'senderId': userId,
                          'type': 'text'
                        };

                        await groups.sendMessage(
                            widget.groupData!["groupId"], data);

                        print("Mensaje enviado ${message}");
                        _messageController.clear();
                      } else {
                        print("No vacios");
                      }
                    },
                    style: const ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll(Colors.green),
                      iconColor: MaterialStatePropertyAll(Colors.black),
                      padding: MaterialStatePropertyAll(EdgeInsets.all(13)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showVideoOptions() {
    showDialog(
        context: context,
        builder: ((context) {
          return AlertDialog(
            title: Text(
              "Seleccionar fuente de vídeo",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(
                    Icons.video_call_rounded,
                    size: 32,
                  ),
                  title: const Text('De cámara'),
                  titleTextStyle: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickVideoFromCamera();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.video_camera_back_rounded,
                    size: 28,
                  ),
                  title: const Text('De galería'),
                  titleTextStyle: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickVideoFromGallery();
                  },
                ),
              ],
            ),
          );
        }));
  }
}
