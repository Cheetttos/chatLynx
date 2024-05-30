import 'package:chatlynx/api/firebase_api.dart';
import 'package:chatlynx/services/auth_service.dart';
import 'package:chatlynx/services/navigation_service.dart';
import 'package:chatlynx/settings/app_value_notifier.dart';
import 'package:chatlynx/utils.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  await setup();
  runApp(MainApp());
}

Future<void> setup() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupFirebase();
  await registerServices();
  await Firebase.initializeApp(
  );
  final navigationService = GetIt.instance
      .get<NavigationService>(); // Obtén la instancia de NavigationService
  await FirebaseApi(navigationService)
      .initNotifications(); // Pasa la instancia de NavigationService al constructor de FirebaseApi
}

// ignore: must_be_immutable
class MainApp extends StatelessWidget {
  final GetIt _getIt = GetIt.instance;
  late NavigationService _navigationService;
  late AuthService _authService;

  MainApp({super.key}) {
    _navigationService = _getIt.get<NavigationService>();
    _authService = _getIt.get<AuthService>();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AppValueNotifier.banTheme,
      builder: (context, value, child) {
        return MaterialApp(
          navigatorKey: _navigationService.navigatiorKey,
          title: 'ChatLynx',
          theme: value
              ? ThemeData(
                  colorScheme: ColorScheme.fromSeed(
                      seedColor: const Color.fromRGBO(17, 117, 51, 51)),
                  useMaterial3: true,
                  textTheme: GoogleFonts.montserratTextTheme(),
                )
              : ThemeData.dark(),
          initialRoute: _authService.user != null ? "/home" : "/login",
          routes: _navigationService.routes,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
