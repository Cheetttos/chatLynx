import 'package:chatlynx/modelos/chat.dart';
import 'package:chatlynx/modelos/user_profile.dart';
import 'package:chatlynx/screens/chat_screen.dart';
import 'package:chatlynx/screens/config_screen.dart';
import 'package:chatlynx/services/alert_service.dart';
import 'package:chatlynx/services/auth_service.dart';
import 'package:chatlynx/services/database_service.dart';
import 'package:chatlynx/services/navigation_service.dart';
import 'package:chatlynx/services/storage_service.dart';
import 'package:chatlynx/widgets/chat_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GetIt _getIt = GetIt.instance;

  int _selectedIndex = 0;
  late AuthService _authService;
  late NavigationService _navigationService;
  late AlertService _alertService;
  late DatabaseService _databaseService;
  late StorageService _storageService;

  String currentUserName = '';
  String? _currentUserProfilePicUrl;

  void _selectedOptionItemBottomNavigation(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();
    _alertService = _getIt.get<AlertService>();
    _databaseService = _getIt.get<DatabaseService>();
    _storageService = _getIt.get<StorageService>();

    _fetchCurrentUserName();
    _fetchCurrentUserProfilePic();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ChatLynx"),
        actions: [
          IconButton(
              onPressed: () async {
                bool result = await _authService.logout();
                if (result) {
                  _alertService.showToast(
                    text: "Cerrando Sesión",
                    icon: Icons.check,
                  );
                  _navigationService.pushReplacementNamed("/login");
                }
              },
              color: Colors.red,
              icon: const Icon(Icons.logout))
        ],
      ),
      //drawer: _buildLateralMenu(),
      body: //_buildUI(),
          Column(
        children: [
          Expanded(
              child: IndexedStack(
            index: _selectedIndex,
            children: [
              _chatsList(),
              Container(),
              Container(),
              const ConfigScreen()
            ],
          ))
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        unselectedItemColor: Colors.white38,
        selectedItemColor: Colors.white,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: "Chats",
              backgroundColor: Color.fromRGBO(17, 117, 51, 51)),
          BottomNavigationBarItem(
              icon: Icon(Icons.group_rounded),
              label: "Grupos",
              backgroundColor: Color.fromRGBO(17, 117, 51, 51)),
          BottomNavigationBarItem(
              icon: Icon(Icons.contacts_rounded),
              label: "Contactos",
              backgroundColor: Color.fromRGBO(17, 117, 51, 51)),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: "Ajustes",
              backgroundColor: Color.fromRGBO(17, 117, 51, 51))
        ],
        currentIndex: _selectedIndex,
        onTap: _selectedOptionItemBottomNavigation,
      ),
    );
  }

  /*Widget _buildUI() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 15.0,
          vertical: 20.0,
        ),
        child: _chatsList(),
      ),
    );
  }*/

  Widget _chatsList() {
    return StreamBuilder(
      stream: _databaseService.getUserProfiles(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text("Error al cargar datos"),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          final users = snapshot.data!.docs;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              UserProfile user = users[index].data();
              if (user.uid == _authService.user!.uid) {
                return Container();
              } else {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: StreamBuilder<DocumentSnapshot<Chat>>(
                    stream: _databaseService.getChatStream(
                      _authService.user!.uid,
                      user.uid!,
                    ),
                    builder: (context, chatSnapshot) {
                      return _buildChatTile(chatSnapshot, user);
                    },
                  ),
                );
              }
            },
          );
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

/*  Widget _buildLateralMenu() {
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            currentAccountPicture: _currentUserProfilePicUrl == null
                ? const CircleAvatar(
                    child: Icon(Icons.person),
                  )
                : CircleAvatar(
                    backgroundImage: NetworkImage(_currentUserProfilePicUrl!),
                  ),
            accountName: Text(
              currentUserName,
              style: TextStyle(
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
            accountEmail: Text(
              _authService.user?.email ?? '',
              style: TextStyle(
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
*/

  Widget _buildChatTile(
      AsyncSnapshot<DocumentSnapshot<Chat>> chatSnapshot, UserProfile user) {
    if (chatSnapshot.hasData && chatSnapshot.data != null) {
      Chat? chat = chatSnapshot.data?.data() as Chat?;
      if (chat != null) {
        String lastMessage = chat.messages?.isNotEmpty ?? false
            ? chat.messages!.last.content ?? 'Sin mensaje'
            : 'No hay mensajes';
        return ChatTile(
          userProfile: user,
          lastMessage: lastMessage,
          onTap: () async {
            await _databaseService.checkChatExists(
              _authService.user!.uid,
              user.uid!,
            );
            _navigationService.push(
              MaterialPageRoute(
                builder: (context) {
                  return ChatPage(
                    chatUser: user,
                  );
                },
              ),
            );
          },
        );
      } else {
        return ChatTile(
          userProfile: user,
          lastMessage: 'No hay datos de chat disponibles.',
          onTap: () async {
            await _databaseService.createNewChat(
              _authService.user!.uid,
              user.uid!,
            );

            _navigationService.push(
              MaterialPageRoute(
                builder: (context) {
                  return ChatPage(
                    chatUser: user,
                  );
                },
              ),
            );
          },
        );
      }
    } else {
      return ChatTile(
        userProfile: user,
        lastMessage: 'Cargando...',
        onTap: () async {
          // Lógica de onTap
        },
      );
    }
  }

  Future<void> _fetchCurrentUserName() async {
    String userName = await _databaseService.getCurrentUserName();
    setState(() {
      currentUserName = userName;
    });
  }

  Future<void> _fetchCurrentUserProfilePic() async {
    String? uid = _authService.user?.uid;
    if (uid != null) {
      String? profilePicUrl = await _storageService.getUserProfilePicUrl(uid);
      setState(() {
        _currentUserProfilePicUrl = profilePicUrl;
      });
    }
  }
}
