import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/admin_dashboard.dart';
import 'presentation/widgets/loading_spinner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? _isLoggedIn;
  String? _userName;
  int? _userRole;
  dynamic _userId;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      if (_isLoggedIn!) {
        _userId = prefs.getInt('userId');
        _userName = prefs.getString('userName');
        _userRole = prefs.getInt('userRole');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const Scaffold(body: LoadingSpinner(message: 'Initializing...')),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Poondurai Kaadai Kulam',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      ),
      home: _isLoggedIn!
          ? AdminDashboard(
              userId: _userId,
              userName: _userName ?? 'User',
              userRole: _userRole ?? 3,
            )
          : const LoginPage(),
    );
  }
}

