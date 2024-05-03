import 'package:chatlynx/services/alert_service.dart';
import 'package:chatlynx/services/auth_service.dart';
import 'package:chatlynx/services/database_service.dart';
import 'package:chatlynx/services/navigation_service.dart';
import 'package:chatlynx/services/storage_service.dart';
import 'package:chatlynx/settings/app_value_notifier.dart';
import 'package:day_night_switcher/day_night_switcher.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';


class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _configScreenState();
}

class _configScreenState extends State<ConfigScreen> {
  bool isDarkMode = false;

  final GetIt _getIt = GetIt.instance;

  late AuthService _authService;
  late NavigationService _navigationService;
  late AlertService _alertService;
  late DatabaseService _databaseService;
  late StorageService _storageService;

  String currentUserName = '';
  String? _currentUserProfilePicUrl;

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
        title: const Text("Ajustes"),
      ),
      body: Center(
        child: Column(
          children: [
            // Contenido de la pantalla
            DayNightSwitcher(
              isDarkModeEnabled: AppValueNotifier.banTheme.value,
              onStateChanged: (isDark) {
                AppValueNotifier.banTheme.value = isDark;
              },
            ),
            _buildUserInfoWidget(),
            ElevatedButton(
              onPressed: () {
                _navigateToEditScreen(context);
              },
              child: const Text('Editar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade400, width: 5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Columna para la imagen del perfil
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _currentUserProfilePicUrl == null
                  ? const CircleAvatar(
                      minRadius: 45,
                      child: Icon(Icons.person),
                    )
                  : CircleAvatar(
                      minRadius: 45,
                      backgroundImage: NetworkImage(_currentUserProfilePicUrl!),
                    ),
            ],
          ),
          const SizedBox(width: 16.0),
          // Columna para el nombre y el correo electrónico
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentUserName,
                style: const TextStyle(fontSize: 20.0),
              ),

              Text(
                _authService.user?.email ?? '',
                style: const TextStyle(fontSize: 14.0, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
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

  void _navigateToEditScreen(BuildContext context) {
    Navigator.pushNamed(context, '/edit');
  }
}
