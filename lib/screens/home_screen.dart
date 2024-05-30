import 'package:chatlynx/modelos/chat.dart';
import 'package:chatlynx/modelos/user_profile.dart';
import 'package:chatlynx/screens/add_group.dart';
import 'package:chatlynx/screens/chat_screen.dart';
import 'package:chatlynx/screens/config_screen.dart';
import 'package:chatlynx/screens/contact_list_screen.dart';
import 'package:chatlynx/screens/contacts_screen.dart';
import 'package:chatlynx/screens/group_screen.dart';
import 'package:chatlynx/services/alert_service.dart';
import 'package:chatlynx/services/auth_service.dart';
import 'package:chatlynx/services/database_service.dart';
import 'package:chatlynx/services/groups_firestore.dart';
import 'package:chatlynx/services/navigation_service.dart';
import 'package:chatlynx/services/storage_service.dart';
import 'package:chatlynx/widgets/chat_tile.dart';
import 'package:chatlynx/widgets/groups_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';

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

  final GroupsFirestore groups = GroupsFirestore();

  void _selectedOptionItemBottomNavigation(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> _buildWidgetOptions(String currentUid) {
    return <Widget>[
      buildGroupList(currentUid),
    ];
  }

  final TextEditingController _searchController = TextEditingController();
  List<Chat> filteredChats = [];
  List<Chat> chats = [];

  void filterChats(String query) {
    List<Chat> dummySearchList = List<Chat>.from(chats);
    if (query.isNotEmpty) {
      dummySearchList.clear();
      chats.forEach((chat) {
        if (chat.participants!.any((participant) =>
            participant.toLowerCase().contains(query.toLowerCase()))) {
          dummySearchList.add(chat);
        }
      });
      setState(() {
        filteredChats = dummySearchList;
      });
      return;
    } else {
      setState(() {
        filteredChats = List<Chat>.from(chats);
      });
    }
  }

  @override
  void initState() {
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
                    text: "Se ha cerrado la sesión",
                    icon: Icons.check,
                  );
                  _navigationService.pushReplacementNamed("/login");
                }
              },
              color: Colors.black,
              icon: const Icon(Icons.logout))
        ],
      ),
      body: Column(
        children: [
          Expanded(
              child: IndexedStack(
            index: _selectedIndex,
            children: [
              _chatsList(),
              buildGroupList(_authService.user!.uid),
              const ContactsListScreen(),
              const ConfigScreen()
            ],
          )),
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
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              heroTag: 'btn1',
              onPressed: () {
                _navigationService.push(MaterialPageRoute(
                    builder: (context) => const ContactScreen()));
              },
              backgroundColor: const Color.fromRGBO(17, 117, 51, 51),
              label: const Text('Nuevo chat'),
              icon: const Icon(Icons.chat),
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

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
          return Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: "Buscar en chats",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _searchController.clear(),
                  ),
                ),
                onChanged: (value) {
                  filterChats(value);
                },
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    UserProfile user = users[index].data();
                    if (user.uid == _authService.user!.uid) {
                      return const Center(
                          child: Text('aqui entra el container'));
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
                ),
              ),
            ],
          );
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

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

  Widget buildGroupList(String currentUid) {
    return Stack(
      children: [
        StreamBuilder(
          stream: groups.getGroups(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Text("Error al obtener datos");
            } else if (snapshot.hasData) {
              if (snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    "No tienes grupos aún",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              } else {
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> groupData = snapshot.data!.docs[index]
                        .data() as Map<String, dynamic>;
                    List<dynamic> members = groupData['members'];
                    if (groupData['admin'] == currentUid ||
                        members.any((member) => member['uid'] == currentUid)) {
                      return GroupsWidget(
                          groupData: snapshot.data!.docs[index]);
                    } else {
                      return SizedBox.shrink();
                    }
                  },
                );
              }
            } else {
              return const Text("No hay datos disponibles");
            }
          },
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FloatingActionButton(
              onPressed: () {
                _navigationService.push(
                  MaterialPageRoute(builder: (context) => AddGroupScreen()),
                );
              },
              child: Icon(Icons.add),
              backgroundColor: const Color.fromRGBO(17, 117, 51, 51),
            ),
          ),
        ),
      ],
    );
  }
}

