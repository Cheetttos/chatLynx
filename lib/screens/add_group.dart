import 'package:chatlynx/services/groups_firestore.dart';
import 'package:chatlynx/services/users_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddGroupScreen extends StatefulWidget {
  const AddGroupScreen({super.key});

  @override
  State<AddGroupScreen> createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends State<AddGroupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final UsersFirestore usersFirestore = UsersFirestore();
  final UsersFirestore _usersFirestore = UsersFirestore();
  List<Map<String, dynamic>> _availableContacts = [];
  final List<Map<String, dynamic>> _selectedContacts = [];
  GroupsFirestore groupsFirestore = GroupsFirestore();

  @override
  void initState() {
    super.initState();
    _loadAvailableContacts();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  void _loadAvailableContacts() async {
    String userIdCurrent = FirebaseAuth.instance.currentUser!.uid;
    String? userId = userIdCurrent;
    List<Map<String, dynamic>> contacts =
        await _usersFirestore.obtenerContactosDisponibles(userId);
    Map<String, dynamic>? currentUser;
    try {
      currentUser = contacts.firstWhere((contact) => contact['uid'] == userId);
    } catch (e) {
      print('El usuario actual no se encontró en la lista de contactos');
    }

    if (currentUser != null) {
      setState(() {
        _availableContacts = contacts;
        _selectedContacts.add(currentUser!);
      });
    }
  }

  // Validamos el nombre del grupo
  String? _validateGroupName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa el nombre del grupo';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    var googleData =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage("assets/fondo_ws.png"),
                fit: BoxFit.cover,
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.green.shade900],
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: AppBar(
              leadingWidth: 75,
              toolbarHeight: 70,
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top +
                kToolbarHeight +
                10, // Posición desde la parte superior
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.only(bottom: 10, left: 20, right: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        child: Image.asset(
                          "assets/tecelaya.png",
                          height: 150,
                        ),
                      ),
                      Center(
                          child: Text(
                        "Crea un nuevo grupo",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 28),
                      )),
                      const SizedBox(
                        height: 30,
                      ),
                      TextFormField(
                        style: GoogleFonts.poppins(color: Colors.white),
                        controller: _groupNameController,
                        decoration: InputDecoration(
                            errorStyle:
                                GoogleFonts.poppins(color: Colors.red.shade300),
                            labelStyle:
                                GoogleFonts.poppins(color: Colors.white),
                            labelText: 'Nombre'),
                        validator: _validateGroupName,
                      ),
                      const SizedBox(height: 60),
                      ExpansionTile(
                        // Lista desplegable
                        collapsedIconColor: Colors.white,
                        iconColor: Colors.white,
                        collapsedShape:
                            const RoundedRectangleBorder(side: BorderSide.none),
                        shape:
                            const RoundedRectangleBorder(side: BorderSide.none),

                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.contacts, color: Colors.white),
                                const SizedBox(width: 10),
                                Text(
                                  'Selecciona los contactos',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Text(
                              '${_selectedContacts.length} seleccionados', // Contador select contacts
                              style: GoogleFonts.poppins(
                                  color: Colors.white, fontSize: 14),
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
                                    color: Colors.white, fontSize: 14),
                              ),
                              value: _selectedContacts.any((selectedContact) =>
                                  selectedContact['nombre'] ==
                                  contact['nombre']),
                              onChanged: (bool? value) {
                                // Deshabilitar el checkbox del usuario actual
                                if (contact['uid'] ==
                                    FirebaseAuth.instance.currentUser!.uid) {
                                  return; // No realizar cambios si es el usuario actual
                                }
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
                                  color: Colors.white, fontSize: 14),
                            ),
                            onTap: () {
                              setState(() {
                                if (_selectedContacts.length ==
                                    _availableContacts.length) {
                                  _selectedContacts.clear();
                                  _selectedContacts.add(
                                      _availableContacts.firstWhere((contact) =>
                                          contact['uid'] ==
                                          FirebaseAuth
                                              .instance.currentUser!.uid));
                                } else {
                                  _selectedContacts.clear();
                                  _selectedContacts.addAll(_availableContacts);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 60),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            groupsFirestore
                                .createGroup(_selectedContacts,
                                    _groupNameController.text)
                                .then((_) {
                              FocusScope.of(context).unfocus();
                              var snackbar = SnackBar(
                                content: Text(
                                  'Grupo creado: ${_groupNameController.text}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 14, color: Colors.white),
                                ),
                                duration: const Duration(seconds: 3),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.only(
                                    bottom: 50, left: 20, right: 20),
                              );
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(snackbar);
                              _groupNameController.clear();
                              Navigator.pop(context);
                            });
                          }
                        },
                        style: const ButtonStyle(
                          padding: MaterialStatePropertyAll(EdgeInsets.all(15)),
                        ),
                        child: Text(
                          'Crear grupo',
                          style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
