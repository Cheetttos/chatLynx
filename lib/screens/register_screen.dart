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
 return Center( 
    child: Text(
      "Inicia Tu Cuenta Lince",
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Colors.green,
      ),
    ),
 );
}

  Widget _registerForm() {
 return Container(
    height: MediaQuery.sizeOf(context).height * 0.60,
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
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
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
              height: MediaQuery.sizeOf(context).height * 0.1,
              validationRegExp: NAME_VALIDATION_REGEX,
              onSaved: (value) {
                setState(() {
                 name = value;
                });
              },
            ),
            CustomFormField(
              hintText: "Correo Electronico",
              height: MediaQuery.sizeOf(context).height * 0.1,
              validationRegExp: EMAIL_VALIDATION_REGEX,
              onSaved: (value) {
                setState(() {
                 email = value;
                });
              },
            ),
            CustomFormField(
              hintText: "Contraseña",
              height: MediaQuery.sizeOf(context).height * 0.1,
              validationRegExp: PASSWORD_VALIDATION_REGEX,
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
          width: MediaQuery.of(context).size.width * 0.2, // Reducido el tamaño de la imagen
          height: MediaQuery.of(context).size.width * 0.2, // Reducido el tamaño de la imagen
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10), // Añade bordes redondeados
            image: DecorationImage(
              fit: BoxFit.cover,
              image: FileImage(selectedImage!),
            ),
          ),
        ),
      SizedBox(width: 20), // Espacio entre la imagen y el botón
      FloatingActionButton.extended(
        onPressed: () async {
          File? file = await _mediaService.getImageFromGallery();
          if (file != null) {
            setState(() {
              selectedImage = file;
            });
          }
        },
        backgroundColor: Colors.green,
        label: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () async {
                File? file = await _mediaService.getImageFromGallery();
                if (file != null) {
                 setState(() {
                    selectedImage = file;
                 });
                }
              },
              child: Row(
                children: [
                 Padding(
                    padding: const EdgeInsets.only(right: 5.0),
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

  Widget _registerButton() {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      child: MaterialButton(
        color: Theme.of(context).colorScheme.primary,
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
                    ),
                  );
                  _alertService.showToast(
                    text: "Usuario Registrado Correctamente!",
                    icon: Icons.check,
                  );
                  _navigationService.goBack();
                  _navigationService.pushReplacementNamed("/home");
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
      const Text("¿Ya tienes una cuenta? "),
      TextButton(
        onPressed: () {
          _navigationService.goBack();
        },
        child: Text(
          "Iniciar Sesión",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ),
    ],
 );
}
}