import 'package:chatlynx/modelos/user_profile.dart';
import 'package:chatlynx/screens/chat_screen.dart';
import 'package:chatlynx/services/alert_service.dart';
import 'package:chatlynx/services/auth_service.dart';
import 'package:chatlynx/services/database_service.dart';
import 'package:chatlynx/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

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
        title: const Text('Grupos'),
      ),
      body: StreamBuilder<List<String>>(
        stream: _databaseService.getUserGroups(_authService.user!.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("Error al cargar los grupos"),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            final groups = snapshot.data!;
            return ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final groupName = groups[index];
                return ListTile(
                  title: Text(groupName),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _showDeleteGroupDialog(groupName),
                        icon: const Icon(Icons.delete),
                      ),
                      IconButton(
                        onPressed: () => _showAddContactDialog(groupName),
                        icon: const Icon(Icons.person_add),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Aquí puedes agregar la lógica para navegar a la pantalla del grupo
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
        onPressed: () {
          _showAddGroupDialog();
        },
        backgroundColor: const Color.fromRGBO(17, 117, 51, 51),
        label: const Text('Nuevo grupo'),
        icon: const Icon(Icons.add),
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showAddContactDialog(String groupName) {
    TextEditingController emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Agregar contacto al grupo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
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
                String email = emailController.text.trim();
                await _databaseService.addContactToGroup(email, groupName);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddGroupDialog() {
    TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Crear nuevo grupo'),
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
                await _databaseService
                    .addGroup(name); // Solo pasa el nombre del grupo
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteGroupDialog(String groupName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar grupo'),
          content: Text('¿Seguro que quieres eliminar el grupo $groupName?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Eliminar'),
              onPressed: () async {
                await _databaseService.deleteGroup(groupName);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
