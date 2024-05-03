import 'dart:io';
import 'package:chatlynx/const.dart';
import 'package:chatlynx/modelos/user_profile.dart';
import 'package:chatlynx/services/alert_service.dart';
import 'package:chatlynx/services/auth_service.dart';
import 'package:chatlynx/services/database_service.dart';
import 'package:chatlynx/services/media_service.dart';
import 'package:chatlynx/services/navigation_service.dart';
import 'package:chatlynx/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

class EditScreen extends StatefulWidget {
  const EditScreen({Key? key}) : super(key: key);

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final GlobalKey<FormState> _registerFormKey = GlobalKey();
  final GetIt _getIt = GetIt.instance;

  late AuthService _authService;
  late MediaService _mediaService;
  late NavigationService _navigationService;
  late StorageService _storageService;
  late DatabaseService _databaseService;
  late AlertService _alertService;

  String currentUserName = '';

  File? selectedImage;
  bool isLoading = false;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mediaService = _getIt.get<MediaService>();
    _navigationService = _getIt.get<NavigationService>();
    _authService = _getIt.get<AuthService>();
    _storageService = _getIt.get<StorageService>();
    _databaseService = _getIt.get<DatabaseService>();
    _alertService = _getIt.get<AlertService>();

    _fetchCurrentUserName();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _buildUi(),
    );
  }

  Widget _buildUi() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 15.0,
          vertical: 20.0,
        ),
        child: Column(
          children: [
            _headerText(),
            if (!isLoading) _editForm(),
            if (isLoading)
              const Expanded(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _headerText() {
    return const Center(
      child: Text(
        "Editar Datos Cuenta Lince",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Color.fromRGBO(17, 117, 51, 51),
        ),
      ),
    );
  }

  Widget _pfpSelectionField() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (selectedImage != null)
          Container(
            width: MediaQuery.of(context).size.width * 0.2,
            height: MediaQuery.of(context).size.width * 0.2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                fit: BoxFit.cover,
                image: FileImage(selectedImage!),
              ),
            ),
          ),
        const SizedBox(width: 20),
        FloatingActionButton.extended(
          onPressed: () async {
            await _showImagePickerOptions();
          },
          backgroundColor: const Color.fromRGBO(17, 117, 51, 51),
          label: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () async {
                  await _showImagePickerOptions();
                },
                child: const Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 5.0),
                      child: Icon(
                        Icons.add_a_photo,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Seleccionar',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _editForm() {
    String initialEmail = _authService.user?.email ?? '';

    return Container(
      height: MediaQuery.of(context).size.height * 0.56,
      margin: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.height * 0.05,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.black,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _registerFormKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _pfpSelectionField(),
              TextFormField(
                controller:
                    _nameController, // Usar el controlador para el nombre
                decoration: InputDecoration(
                  hintText: currentUserName,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un nombre';
                  }
                  return null;
                },
              ),
              TextFormField(
                initialValue: initialEmail,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: "Correo Electronico",
                ),
              ),
              _registerButton(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showImagePickerOptions() async {
    final ImagePicker _picker = ImagePicker();
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Seleccionar imagen'),
        content: const Text(
            '¿Deseas tomar una foto o seleccionar una de la galería?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Tomar foto'),
            onPressed: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          TextButton(
            child: const Text('Seleccionar de galería'),
            onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
        ],
      ),
    );

    if (source != null) {
      final XFile? file = await _picker.pickImage(source: source);
      if (file != null) {
        setState(() {
          selectedImage = File(file.path);
        });
      }
    }
  }

  Future<void> _updateUserData(String newName, String newProfilePicUrl) async {
  String? uid = _authService.user?.uid;
  if (uid != null) {
    // Actualizar el nombre del usuario
    await _databaseService.updateUserName(uid, newName);

    // Actualizar la URL de la imagen de perfil del usuario
    await _databaseService.updateUserProfilePicUrl(uid, newProfilePicUrl);
  }

  // Navegar de regreso a ConfigScreen
  Navigator.pop(context, {'name': newName, 'profilePicUrl': newProfilePicUrl});
}

  Widget _registerButton() {
  return SizedBox(
    width: MediaQuery.of(context).size.width,
    child: MaterialButton(
      color: const Color.fromRGBO(17, 117, 51, 51),
      onPressed: () async {
        // Obtener el nuevo nombre del usuario y la nueva imagen de perfil
        String newName = _nameController.text;
        String newProfilePicUrl = selectedImage != null ? await _storageService.uploadImage(selectedImage!) : '';

        // Actualizar los datos del usuario
        await _updateUserData(newName, newProfilePicUrl);
      },
      child: const Text(
        "Guardar",
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    ),
  );
}

  Future<void> _fetchCurrentUserName() async {
    String userName = await _databaseService.getCurrentUserName();
    setState(() {
      currentUserName = userName;
    });
  }
}