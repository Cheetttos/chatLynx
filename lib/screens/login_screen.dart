import 'package:chatlynx/const.dart';
import 'package:chatlynx/services/alert_service.dart';
import 'package:chatlynx/services/auth_service.dart';
import 'package:chatlynx/services/navigation_service.dart';
import 'package:chatlynx/widgets/custom_form_field.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _loginFormKey = GlobalKey();
  final GetIt _getIt = GetIt.instance;

  String? email, password;

  late AuthService _authService;
  late NavigationService _navigationService;
  late AlertService _alertService;

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();
    _alertService = _getIt.get<AlertService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(child: _buildUI()),
    );
  }

  Widget _buildUI() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20.0),
        child: Column(
          children: [
            _headerText(),
            _loginForm(),
            Image.asset(
              'images/tecnm-login.png',
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
            const SizedBox(
              height: 10,
            ),
            _createAnAccountLink(),
          ],
        ),
      ),
    );
  }

  Widget _headerText() {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      child: const Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              "ChatLynx Tecnm Celaya",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(17, 117, 51, 51),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _loginForm() {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.40,
      width: MediaQuery.sizeOf(context).width * 0.90,
      margin: EdgeInsets.symmetric(
          vertical: MediaQuery.sizeOf(context).height * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.black,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Form(
        key: _loginFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: MediaQuery.sizeOf(context).width * 0.8,
              child: CustomFormField(
                hintText: "Email",
                height: MediaQuery.sizeOf(context).height * 0.08,
                validationRegExp: emailValidation,
                onSaved: (value) {
                  setState(() {
                    email = value;
                  });
                },
              ),
            ),
            Container(
              width: MediaQuery.sizeOf(context).width * 0.8,
              child: CustomFormField(
                  height: MediaQuery.sizeOf(context).height * 0.08,
                  hintText: "Password",
                  validationRegExp: passValidation,
                  obscureText: true,
                  onSaved: (value) {
                    setState(() {
                      password = value;
                    });
                  }),
            ),
            _loginButton(),
          ],
        ),
      ),
    );
  }

  Widget _loginButton() {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.8,
      child: MaterialButton(
        onPressed: () async {
          if (_loginFormKey.currentState?.validate() ?? false) {
            _loginFormKey.currentState?.save();
            bool result = await _authService.login(email!, password!);
            if (result) {
              _navigationService.pushReplacementNamed("/home");
            } else {
              _alertService.showToast(
                  text: "Error al iniciar sesion, intenta otra vez!",
                  icon: Icons.error);
            }
          }
        },
        color: const Color.fromRGBO(17, 117, 51, 51),
        elevation: 5,
        child: const Text(
          "Iniciar Sesion",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }

  Widget _createAnAccountLink() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("¿No tienes una cuenta? "),
        GestureDetector(
          onTap: () {
            _navigationService.pushNamed("/register");
          },
          child: const Text(
            "Registrarse",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(17, 117, 51, 51),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
