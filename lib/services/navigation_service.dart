import 'package:chatlynx/screens/config_screen.dart';
import 'package:chatlynx/screens/contact_list_screen.dart';
import 'package:chatlynx/screens/contacts_screen.dart';
import 'package:chatlynx/screens/group_screen.dart';
import 'package:chatlynx/screens/home_screen.dart';
import 'package:chatlynx/screens/login_screen.dart';
import 'package:chatlynx/screens/register_screen.dart';
import 'package:chatlynx/screens/edit_profile_screen.dart';
import 'package:flutter/material.dart';

class NavigationService {
  late GlobalKey<NavigatorState> _navigatorKey;

  final Map<String, Widget Function(BuildContext)> _routes = {
    "/login": (context) => const LoginScreen(),
    "/home": (context) => const HomeScreen(),
    "/register": (context) => const RegisterScreen(),
    '/edit': (context) => const EditScreen(),
    "/config": (context) => const ConfigScreen(),
    "/contact": (context) => const ContactScreen(),
    "/group": (context) => const GroupScreen(),
  };

  GlobalKey<NavigatorState>? get navigatiorKey {
    return _navigatorKey;
  }

  Map<String, Widget Function(BuildContext)> get routes {
    return _routes;
  }

  NavigationService() {
    _navigatorKey = GlobalKey<NavigatorState>();
  }

  void push(MaterialPageRoute route) {
    _navigatorKey.currentState?.push(route);
  }

  void pushNamed(String routeName) {
    _navigatorKey.currentState?.pushNamed(routeName);
  }

  void pushReplacementNamed(String routeName) {
    _navigatorKey.currentState?.pushReplacementNamed(routeName);
  }

  void goBack() {
    _navigatorKey.currentState?.pop();
  }
}
