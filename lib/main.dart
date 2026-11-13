import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'services/fcm_service.dart';
import 'utils/web_utils.dart';
import 'presentation/pages/splash_screen.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  Map<String, dynamic>? initialAuth;
  if (kIsWeb) {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      initialAuth = {
        'isLoggedIn': isLoggedIn,
        'userId': prefs.getInt('userId'),
        'userName': prefs.getString('userName'),
        'userRole': prefs.getInt('userRole'),
      };
    } catch (e) {
      debugPrint("Auth read error: $e");
    }
  } else {
    try {
      await Firebase.initializeApp();
      await FcmService.initialize();
    } catch (e) {
      debugPrint("Firebase initialization failed: $e");
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: MyApp(initialAuth: initialAuth),
    ),
  );
}

class MyApp extends StatefulWidget {
  final Map<String, dynamic>? initialAuth;
  const MyApp({super.key, this.initialAuth});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyFirstFrame();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Extract URL parameters (e.g. memberId for deep linking or web redirect)
    final uri = Uri.base;
    final String? viewMemberId = uri.queryParameters['memberId'];

    final localeProvider = Provider.of<LocaleProvider>(context);

    // On Web, skip redundant Dart SplashScreen since web/index.html already handles preloading.
    // Mount AdminDashboard or LoginPage directly so startup completes in 3-4s.
    Widget homeScreen;
    if (kIsWeb) {
      final bool isLoggedIn = widget.initialAuth?['isLoggedIn'] ?? false;
      if (isLoggedIn) {
        homeScreen = AdminDashboard(
          userId: widget.initialAuth?['userId'],
          userName: widget.initialAuth?['userName'] ?? 'User',
          userRole: widget.initialAuth?['userRole'] ?? 3,
          initialViewMemberId: viewMemberId,
        );
      } else {
        homeScreen = LoginPage(redirectMemberId: viewMemberId);
      }
    } else {
      homeScreen = SplashScreen(redirectMemberId: viewMemberId);
    }

    return ToastificationWrapper(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => AppLocalizations.of(context)?.appTitle ?? 'Poondurai Kaadai Kulam',
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
        home: homeScreen,
      ),
    );
  }
}
