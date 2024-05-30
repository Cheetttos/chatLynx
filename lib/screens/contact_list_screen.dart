import 'package:chatlynx/modelos/user_profile.dart';
import 'package:chatlynx/screens/chat_screen.dart';
import 'package:chatlynx/services/alert_service.dart';
import 'package:chatlynx/services/auth_service.dart';
import 'package:chatlynx/services/database_service.dart';
import 'package:chatlynx/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class ContactsListScreen extends StatefulWidget {
  const ContactsListScreen({Key? key}) : super(key: key);

  @override
  _ContactsListScreenState createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends State<ContactsListScreen> {
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late DatabaseService _databaseService;
  late NavigationService _navigationService;
  late AlertService _alertService;

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _databaseService = _getIt.get<DatabaseService>();
    _navigationService = _getIt.get<NavigationService>();
    _alertService = _getIt.get<AlertService>();
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () async {
                          bool chatExists =
                              await _databaseService.checkChatExists(
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
                        icon: const Icon(Icons.chat),
                      ),
                      /*IconButton(
                          onPressed: () {}, icon: const Icon(Icons.videocam)),*/
                    ],
                  ),
                );
              },
            );
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddContactDialog();
        },
        backgroundColor: const Color.fromRGBO(17, 117, 51, 51),
        label: const Text('Nuevo contacto'),
        icon: const Icon(Icons.add),
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showAddContactDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Agregar nuevo contacto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                  ),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo institucional',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Agregar'),
              onPressed: () async {
                String name = nameController.text.trim();
                String email = emailController.text.trim();

                // Verificar si el email está registrado
                bool isEmailRegistered =
                    await _databaseService.isEmailRegistered(email);

                if (!isEmailRegistered) {
                  _alertService.showToast(
                    text: "No se encontró el correo en nuestro sistema",
                    icon: Icons.warning_amber_outlined,
                  );
                  return;
                } else {
                  // Verificar si el contacto ya está registrado
                  bool isContactRegistered = await _databaseService
                      .isContactRegistered(_authService.user!.uid, email);

                  if (isContactRegistered) {
                    _alertService.showToast(
                      text: "Este contacto ya se encuentra registrado",
                      icon: Icons.warning_amber_outlined,
                    );
                    return;
                  } else {
                    // Si el email está registrado y el contacto no está registrado, proceder a agregarlo
                    if (email == _authService.user!.email) {
                      _alertService.showToast(
                        text: "No puedes registrarte como contacto",
                        icon: Icons.warning_amber_outlined,
                      );
                    } else {
                      await _databaseService.addContact(
                        _authService.user!.uid,
                        name,
                        email,
                      );
                    }

                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}
