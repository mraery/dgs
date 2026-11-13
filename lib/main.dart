import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/exam_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/welcome_screen.dart';
import 'services/ad_service.dart';
import 'services/friends_quest_service.dart';
import 'services/smart_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase/hesap girişi arka planda başlar; internet yavaşsa açılış ekranı beklemez.
  // Karşılama ekranı (WelcomeScreen) hazır olmasını kendisi bekler.
  FriendsQuestService.instance.ensureInitialized();
  await Future.wait([
    AdService.instance.initialize(),
    SmartNotificationService.instance.initialize(),
  ]);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(
    const ProviderScope(
      child: DgsQuestApp(),
    ),
  );
}

class DgsQuestApp extends ConsumerWidget {
  const DgsQuestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseTextTheme = Theme.of(context).textTheme;
    final activeExam = ref.watch(examConfigProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: '${activeExam.title} - ${activeExam.description}',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: activeExam.primaryColor,
          brightness: Brightness.light,
          primary: activeExam.primaryColor,
          secondary: activeExam.secondaryColor,
          surface: Colors.white,
          onSurface: const Color(0xFF1E293B),
          error: const Color(0xFFFF4B4B),
        ),
        textTheme: GoogleFonts.nunitoTextTheme(baseTextTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1E293B),
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121216),
        cardColor: const Color(0xFF1E1E26),
        colorScheme: ColorScheme.fromSeed(
          seedColor: activeExam.primaryColor,
          brightness: Brightness.dark,
          primary: activeExam.primaryColor,
          secondary: activeExam.secondaryColor,
          surface: const Color(0xFF1E1E26),
          onSurface: const Color(0xFFF8FAFC),
          error: const Color(0xFFFF5252),
        ),
        textTheme: GoogleFonts.nunitoTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF18181F),
          foregroundColor: Color(0xFFF8FAFC),
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}

typedef YksQuestApp = DgsQuestApp;
typedef YksifyApp = DgsQuestApp;
typedef YksPatikaApp = DgsQuestApp;
typedef YksPatikaAppAlias = DgsQuestApp;
typedef YksCepteApp = DgsQuestApp;
typedef YksLingoApp = DgsQuestApp;
