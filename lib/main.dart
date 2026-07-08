import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/admin_dashboard.dart';
import 'presentation/widgets/loading_spinner.dart';

import 'package:toastification/toastification.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
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

    // Extract URL parameters
    final uri = Uri.base;
    final String? viewMemberId = uri.queryParameters['memberId'];

    final localeProvider = Provider.of<LocaleProvider>(context);

    return ToastificationWrapper(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Poondurai Kaadai Kulam',
        locale: localeProvider.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5D1712)),
          scrollbarTheme: ScrollbarThemeData(
            thumbColor: MaterialStateProperty.all(const Color(0xFF5D1712)),
            trackColor: MaterialStateProperty.all(const Color(0x225D1712)),
            radius: const Radius.circular(8),
            thickness: MaterialStateProperty.all(6),
          ),
        ),
        home: _isLoggedIn!
            ? AdminDashboard(
                userId: _userId,
                userName: _userName ?? 'User',
                userRole: _userRole ?? 3,
                initialViewMemberId: viewMemberId,
              )
            : LoginPage(redirectMemberId: viewMemberId),
      ),
    );
  }
}

