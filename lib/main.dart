import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'services/fcm_service.dart';
import 'utils/web_utils.dart';
import 'presentation/pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb) {
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
        home: SplashScreen(redirectMemberId: viewMemberId),
      ),
    );
  }
}
