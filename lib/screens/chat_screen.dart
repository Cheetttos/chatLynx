import 'dart:io';

import 'package:chatlynx/modelos/chat.dart';
import 'package:chatlynx/modelos/message.dart';
import 'package:chatlynx/modelos/user_profile.dart';
import 'package:chatlynx/screens/video_call_screen.dart';
import 'package:chatlynx/services/alert_service.dart';
import 'package:chatlynx/services/auth_service.dart';
import 'package:chatlynx/services/database_service.dart';
import 'package:chatlynx/services/media_service.dart';
import 'package:chatlynx/services/navigation_service.dart';
import 'package:chatlynx/services/storage_service.dart';
import 'package:chatlynx/services/webrtc_service.dart';
import 'package:chatlynx/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:giphy_picker/giphy_picker.dart';
//import 'package:giphy_picker/giphy_picker.dart';
import 'package:path/path.dart';

import '../services/notification_service.dart';

class ChatPage extends StatefulWidget {
  final UserProfile chatUser;

  const ChatPage({super.key, required this.chatUser});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final GetIt _getIt = GetIt.instance;

  Future<void> _makeVideoCall() async {
    String callName = generateChatID(uid1: currentUser!.id, uid2: otherUser!.id);

    // Enviar notificación de llamada entrante al usuario B
    await _notificationService.sendCallNotification(
      receiverUserId: otherUser!.id,
      callerName: currentUser!.firstName ?? '',
      callerProfilePicture: currentUser!.profileImage ?? '',
      channelName: callName,
    );

    // Abrir la pantalla de videollamada para el usuario A
    _navigationService.push(
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(
          channelName: callName,
          participantIds: [currentUser!.id, otherUser!.id],
          participantNames: [
            currentUser!.firstName ?? 'Usuario actual',
            otherUser!.firstName ?? 'Otro usuario'
          ],
          participantProfilePictures: [
            currentUser!.profileImage ??
                'https://example.com/default-profile-picture.png',
            otherUser!.profileImage ??
                'https://example.com/default-profile-picture.png'
          ],
        ),
      ),
    );
  }

  ChatUser? currentUser, otherUser;

  late AuthService _authService;
  late DatabaseService _databaseService;
  late MediaService _mediaService;
  late StorageService _storageService;
  late AlertService _alertService;
  late NavigationService _navigationService;
  late NotificationService _notificationService;
  final WebRTCService _webrtcService = WebRTCService();
  String callName = '';

  //GiphyGif? _gif;

  Object? get checkSelfPermission => null;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _authService = _getIt.get<AuthService>();
    _databaseService = _getIt.get<DatabaseService>();
    _mediaService = _getIt.get<MediaService>();
    _storageService = _getIt.get<StorageService>();
    _alertService = _getIt.get<AlertService>();
    _navigationService = _getIt.get<NavigationService>();
    _webrtcService.initialize();

    currentUser = ChatUser(
      id: _authService.user!.uid,
      firstName: _authService.user!.displayName,
    );

    otherUser = ChatUser(
      id: widget.chatUser.uid!,
      firstName: widget.chatUser.name,
      profileImage: widget.chatUser.pfpURL,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.chatUser.name!,
        ),
        actions: <Widget>[
          IconButton(onPressed: () {}, icon: const Icon(Icons.call)),
          IconButton(
            onPressed: () async {
              String callName =
                  generateChatID(uid1: currentUser!.id, uid2: otherUser!.id);

              _navigationService.push(
                MaterialPageRoute(
                  builder: (context) => VideoCallScreen(
                    channelName: callName,
                    participantIds: [currentUser!.id, otherUser!.id],
                    participantNames: [
                      currentUser!.firstName ?? 'Usuario actual',
                      otherUser!.firstName ?? 'Otro usuario'
                    ],
                    participantProfilePictures: [
                      currentUser!.profileImage ??
                          'https://example.com/default-profile-picture.png',
                      otherUser!.profileImage ??
                          'https://example.com/default-profile-picture.png'
                    ],
                  ),
                ),
              );
            }
            

            ,
            icon: const Icon(Icons.video_chat),
          )
        ],
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return StreamBuilder(
      stream: _databaseService.getChatData(currentUser!.id, otherUser!.id),
      builder: (context, snapshot) {
        Chat? chat = snapshot.data?.data();
        List<ChatMessage> messages = [];
        if (chat != null && chat.messages != null) {
          messages = _generateChatMessagesList(
            chat.messages!,
          );
        }
        return DashChat(
          messageOptions: const MessageOptions(
            showOtherUsersAvatar: true,
            showTime: true,
            showOtherUsersName: true,
            currentUserContainerColor: Color.fromRGBO(17, 117, 51, 51),
          ),
          inputOptions: InputOptions(
              trailing: [
                _mediaMessageMenu(),
                IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.sticky_note_2_rounded,
                      color: Color.fromRGBO(17, 117, 51, 51),
                    ))
              ],
              alwaysShowSend: true,
              inputDecoration: InputDecoration(
                hintText: 'Escribe un mensaje',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                fillColor: Colors.grey[200],
                filled: true,
                border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.elliptical(30, 30))),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              )),
          currentUser: currentUser!,
          onSend: (message) {
            _sendMessage(message);
          },
          messages: messages,
        );
      },
    );
  }

  Future<void> _sendMessage(ChatMessage chatMessage) async {
    if (chatMessage.medias?.isNotEmpty ?? false) {
      if (chatMessage.medias!.first.type == MediaType.image) {
        Message message = Message(
          senderID: chatMessage.user.id,
          content: chatMessage.medias!.first.url,
          messageType: MessageType.Image,
          sentAt: Timestamp.fromDate(chatMessage.createdAt),
        );
        await _databaseService.sendChatMessage(
          currentUser!.id,
          otherUser!.id,
          message,
        );
      }
    } else {
      Message message = Message(
        senderID: currentUser!.id,
        content: chatMessage.text,
        messageType: MessageType.Text,
        sentAt: Timestamp.fromDate(chatMessage.createdAt),
      );

      await _databaseService.sendChatMessage(
        currentUser!.id,
        otherUser!.id,
        message,
      );
    }
  }

  List<ChatMessage> _generateChatMessagesList(List<Message> message) {
    List<ChatMessage> chatMessages = message.map((m) {
      if (m.messageType == MessageType.Image) {
        return ChatMessage(
            user: m.senderID == currentUser!.id ? currentUser! : otherUser!,
            createdAt: m.sentAt!.toDate(),
            medias: [
              ChatMedia(
                url: m.content!,
                fileName: "",
                type: MediaType.image,
              ),
            ]);
      } else {
        return ChatMessage(
          user: m.senderID == currentUser!.id ? currentUser! : otherUser!,
          text: m.content!,
          createdAt: m.sentAt!.toDate(),
        );
      }
    }).toList();
    chatMessages.sort(
      (a, b) {
        return b.createdAt.compareTo(a.createdAt);
      },
    );
    return chatMessages;
  }

  Widget _mediaMessageButton() {
    return IconButton(
        onPressed: () {},
        icon: const Icon(
          Icons.image,
          color: Color.fromRGBO(17, 117, 51, 51),
        ));
  }

  Widget _cameraMessageButton() {
    return IconButton(onPressed: () {}, icon: Icon(Icons.camera_alt_rounded));
  }

  Widget _mediaMessageMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.attach_file_rounded,
          color: Color.fromRGBO(17, 117, 51, 51)),
      constraints: const BoxConstraints.tightFor(width: 50, height: 190),
      color: const Color.fromRGBO(17, 117, 51, 51),
      onSelected: (String result) {},
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: "camera",
          child: Icon(
            Icons.camera_alt_rounded,
            color: Colors.white,
          ),
          onTap: () async {
            File? file = await _mediaService.getImageFromCamera();
            if (file != null) {
              String chatID = generateChatID(
                uid1: currentUser!.id,
                uid2: otherUser!.id,
              );
              String? downloadURL = await _storageService.uploadImageToChat(
                  file: file, chatId: chatID);

              if (downloadURL != null) {
                ChatMessage chatMessage = ChatMessage(
                  user: currentUser!,
                  createdAt: DateTime.now(),
                  medias: [
                    ChatMedia(
                      url: downloadURL,
                      fileName: "",
                      type: MediaType.image,
                    )
                  ],
                );
                _sendMessage(chatMessage);
              }
            }
          },
        ),
        PopupMenuItem<String>(
          value: "image",
          child: const Icon(
            Icons.image,
            color: Colors.white,
          ),
          onTap: () async {
            File? file = await _mediaService.getImageFromGallery();
            if (file != null) {
              String chatID = generateChatID(
                uid1: currentUser!.id,
                uid2: otherUser!.id,
              );
              String? downloadURL = await _storageService.uploadImageToChat(
                  file: file, chatId: chatID);

              if (downloadURL != null) {
                ChatMessage chatMessage = ChatMessage(
                  user: currentUser!,
                  createdAt: DateTime.now(),
                  medias: [
                    ChatMedia(
                      url: downloadURL,
                      fileName: "",
                      type: MediaType.image,
                    )
                  ],
                );
                _sendMessage(chatMessage);
              }
            }
          },
        ),
        PopupMenuItem<String>(
          value: 'gif',
          child: const Icon(
            Icons.gif_box_rounded,
            color: Colors.white,
          ),
          onTap: () async {
            final gif = await GiphyPicker.pickGif(
              title: const Text('Elige el gif'),
              lang: 'es',
              context: context,
              fullScreenDialog: false,
              showPreviewPage: false,
              apiKey: '27QECRzAV8AnNukBUE1jt7Jh2B2QUtJC',
            );
            print(gif);
            if (gif != null) {
              String chatID =
                  generateChatID(uid1: currentUser!.id, uid2: otherUser!.id);
              String? downloadURL = await _storageService.uploadGifToChat(
                  gif: gif, chatId: chatID);
              if (downloadURL != null) {
                ChatMessage chatMessage = ChatMessage(
                  user: currentUser!,
                  createdAt: DateTime.now(),
                  medias: [
                    /*ChatMedia(
                      url: downloadURL,
                      fileName: '',
                      type: MediaType.gif,
                    )*/
                  ],
                );
                _sendMessage(chatMessage);
              }
            } else {
              _alertService.showToast(
                text: 'No se ha seleccionado ningún gif',
                icon: Icons.error_outline_rounded,
              );
            }
          },
        ),
      ],
    );
  }
}
