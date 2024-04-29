import 'dart:io';
import 'package:chatlynx/const.dart';
import 'package:chatlynx/modelos/user_profile.dart';
import 'package:chatlynx/services/alert_service.dart';
import 'package:chatlynx/services/auth_service.dart';
import 'package:chatlynx/services/database_service.dart';
import 'package:chatlynx/services/media_service.dart';
import 'package:chatlynx/services/navigation_service.dart';
import 'package:chatlynx/services/storage_service.dart';
import 'package:chatlynx/widgets/custom_form_field.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _registerFormKey = GlobalKey();
  final GetIt _getIt = GetIt.instance;

  late AuthService _authService;
  late MediaService _mediaService;
  late NavigationService _navigationService;
  late StorageService _storageService;
  late DatabaseService _databaseService;
  late AlertService _alertService;

  File? selectedImage;
  bool isLoading = false;
  String? email, password, name;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _mediaService = _getIt.get<MediaService>();
    _navigationService = _getIt.get<NavigationService>();
    _authService = _getIt.get<AuthService>();
    _storageService = _getIt.get<StorageService>();
    _databaseService = _getIt.get<DatabaseService>();
    _alertService = _getIt.get<AlertService>();
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
            if (!isLoading) _registerForm(),
            if (!isLoading) _loginAccountLink(),
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
        "Inicia Tu Cuenta Lince",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Color.fromRGBO(17, 117, 51, 51),
        ),
      ),
    );
  }

  Widget _registerForm() {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.56,
      margin: EdgeInsets.symmetric(
        vertical: MediaQuery.sizeOf(context).height * 0.05,
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
              CustomFormField(
                hintText: "Nombre",
                height: MediaQuery.sizeOf(context).height * 0.06,
                validationRegExp: nameValidation,
                onSaved: (value) {
                  setState(() {
                    name = value;
                  });
                },
              ),
              CustomFormField(
                hintText: "Correo Electronico",
                height: MediaQuery.sizeOf(context).height * 0.06,
                validationRegExp: emailValidation,
                onSaved: (value) {
                  setState(() {
                    email = value;
                  });
                },
              ),
              CustomFormField(
                hintText: "Contraseña",
                height: MediaQuery.sizeOf(context).height * 0.06,
                validationRegExp: passValidation,
                obscureText: true,
                onSaved: (value) {
                  setState(() {
                    password = value;
                  });
                },
              ),
              _registerButton(),
            ],
          ),
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

  Widget _registerButton() {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      child: MaterialButton(
        color: const Color.fromRGBO(17, 117, 51, 51),
        onPressed: () async {
          setState(() {
            isLoading = true;
          });
          try {
            if (selectedImage != null &&
                    _registerFormKey.currentState!.validate() ??
                false) {
              _registerFormKey.currentState?.save();
              bool result = await _authService.signup(email!, password!);
              if (result) {
                String? pfpURL = await _storageService.uploadUserPfp(
                  file: selectedImage!,
                  uid: _authService.user!.uid,
                );
                if (pfpURL != null) {
                  await _databaseService.createUserProfile(
                    userProfile: UserProfile(
                        uid: _authService.user!.uid,
                        name: name,
                        pfpURL: pfpURL,
                        email: email),
                  );
                  _alertService.showToast(
                    text:
                        "Usuario Registrado Correctamente, verifica tu correo!",
                    icon: Icons.check,
                  );
                  _navigationService.goBack();
                  _navigationService.pushReplacementNamed("/login");
                } else {
                  throw Exception("No fue posible subir la foto de usuario");
                }
              } else {
                throw Exception("No fue posible registrar al usuario");
              }
            } else {
              _alertService.showToast(
                text: "Elige una imagen porfavor",
                icon: Icons.warning,
              );
            }
          } catch (e) {
            print(e);
            _alertService.showToast(
              text: "Error al registrarse, intentalo de nuevo",
              icon: Icons.error,
            );
          }
          setState(() {
            isLoading = false;
          });
        },
        child: const Text(
          "Registrarse",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _loginAccountLink() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image(
          image: const AssetImage("images/tecnm-login.png"),
          height: MediaQuery.sizeOf(context).height * 0.13,
        ),
        const Text("¿Ya tienes una cuenta? "),
        TextButton(
          onPressed: () {
            _navigationService.goBack();
          },
          child: const Text(
            "Iniciar Sesión",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(17, 117, 51, 51),
            ),
          ),
        ),
      ],
    );
  }
}
