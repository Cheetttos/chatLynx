import 'package:chatlynx/modelos/user_profile.dart';
import 'package:chatlynx/screens/add_group.dart';
import 'package:chatlynx/screens/chat_group_screen.dart';
import 'package:chatlynx/screens/chat_screen.dart';
import 'package:chatlynx/widgets/groups_widget.dart';
import 'package:chatlynx/services/alert_service.dart';
import 'package:chatlynx/services/auth_service.dart';
import 'package:chatlynx/services/database_service.dart';
import 'package:chatlynx/services/navigation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatlynx/services/groups_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({Key? key}) : super(key: key);

  @override
  _GroupScreenState createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late DatabaseService _databaseService;
  late NavigationService _navigationService;
  late AlertService _alertService;

  final GroupsFirestore groups = GroupsFirestore();

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
    final String currentUid = _authService.user!.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grupos'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: groups.getGroups(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("Error al cargar los grupos"),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            final groups = snapshot.data!;
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final groupName = snapshot.data!.docs[index].get('groupName');
                return ListTile(
                  leading: Icon(Icons.group, color: Colors.black),
                  title: Text(
                    groupName,
                    style: TextStyle(color: Colors.black),
                  ),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ConversationGroupsScreen(
                        groupData: snapshot.data!.docs[index],
                      ),
                    ));
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'btn2',
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const AddGroupScreen(),
          ));
        },
        backgroundColor: Color.fromRGBO(17, 117, 51, 0.804),
        label: const Text('Nuevo grupo'),
        icon: const Icon(Icons.add),
        foregroundColor: Colors.white,
      ),
    );
  }
}

