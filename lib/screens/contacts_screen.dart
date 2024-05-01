import 'package:chatlynx/modelos/user_profile.dart';
import 'package:chatlynx/screens/chat_screen.dart';
import 'package:chatlynx/services/auth_service.dart';
import 'package:chatlynx/services/database_service.dart';
import 'package:chatlynx/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({Key? key}) : super(key: key);

  @override
  _ContactScreenState createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late DatabaseService _databaseService;
  late NavigationService _navigationService;

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _databaseService = _getIt.get<DatabaseService>();
    _navigationService = _getIt.get<NavigationService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contactos'),
      ),
      body: StreamBuilder<List<UserProfile>>(
        stream: _databaseService.getUserContacts(_authService.user!.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("Error al cargar contactos"),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            final contacts = snapshot.data!;
            return ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: contact.pfpURL != null
                        ? NetworkImage(contact.pfpURL!)
                        : null,
                    child: contact.pfpURL == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(contact.name ?? ''),
                  subtitle: Text(contact.email ?? ''),
                  onTap: () async {
                    bool chatExists = await _databaseService.checkChatExists(
                      _authService.user!.uid,
                      contact.uid!,
                    );
                    if (chatExists) {
                      _navigationService.push(
                        MaterialPageRoute(
                          builder: (context) {
                            return ChatPage(
                              chatUser: contact,
                            );
                          },
                        ),
                      );
                    } else {
                      await _databaseService.createNewChat(
                        _authService.user!.uid,
                        contact.uid!,
                      );
                      _navigationService.push(
                        MaterialPageRoute(
                          builder: (context) {
                            return ChatPage(
                              chatUser: contact,
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
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}
