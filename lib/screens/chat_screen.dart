import 'dart:io';

import 'package:chatlynx/modelos/chat.dart';
import 'package:chatlynx/modelos/message.dart';
import 'package:chatlynx/modelos/user_profile.dart';
import 'package:chatlynx/services/auth_service.dart';
import 'package:chatlynx/services/database_service.dart';
import 'package:chatlynx/services/media_service.dart';
import 'package:chatlynx/services/storage_service.dart';
import 'package:chatlynx/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

class ChatPage extends StatefulWidget {
  final UserProfile chatUser;

  const ChatPage({super.key, required this.chatUser});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final GetIt _getIt = GetIt.instance;

  ChatUser? currentUser, otherUser;

  late AuthService _authService;
  late DatabaseService _databaseService;
  late MediaService _mediaService;
  late StorageService _storageService;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _authService = _getIt.get<AuthService>();
    _databaseService = _getIt.get<DatabaseService>();
    _mediaService = _getIt.get<MediaService>();
    _storageService = _getIt.get<StorageService>();
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
        onPressed: () async {
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
      onSelected: (String result) {
        switch (result) {
          case "camera":
            _cameraMessageButton();
            break;
          case "image":
            _mediaMessageButton();
            break;
          case "gif":
            // Lógica para seleccionar un gif
            break;
          default:
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: "camera",
          child: Icon(
            Icons.camera_alt_rounded,
            color: Colors.white,
          ),
        ),
        const PopupMenuItem<String>(
          value: "image",
          child: Icon(
            Icons.image,
            color: Colors.white,
          ),
        ),
        const PopupMenuItem<String>(
          value: "gif",
          child: Icon(
            Icons.gif_box_rounded,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
