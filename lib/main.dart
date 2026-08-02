import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/theme_provider.dart';
import 'services/background_service.dart';
import 'services/local_storage_service.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';
import 'views/home/home_screen.dart';
import 'views/settings/passcode_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env configuration file if present
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {}

  // Initialize Local Storage
  final prefs = await SharedPreferences.getInstance();
  final storage = LocalStorageService(prefs);

  // Initialize Supabase
  await SupabaseService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(storage)),
        ChangeNotifierProvider(create: (_) => AuthProvider(storage)),
        ChangeNotifierProvider(create: (_) => ChatProvider(storage)),
      ],
      child: const DuoChatApp(),
    ),
  );

  // Initialize Android/iOS 24/7 Foreground Background Notification Service
  BackgroundServiceHandler.initializeService();
}

class DuoChatApp extends StatefulWidget {
  const DuoChatApp({Key? key}) : super(key: key);

  @override
  State<DuoChatApp> createState() => _DuoChatAppState();
}

class _DuoChatAppState extends State<DuoChatApp> {
  bool _isUnlocked = false;

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    final showLock = theme.isPasscodeEnabled && !_isUnlocked;

    return MaterialApp(
      title: 'DuoChat - 2-Person WhatsApp Clone',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: theme.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: showLock
          ? PasscodeScreen(
              onUnlocked: () {
                setState(() {
                  _isUnlocked = true;
                });
              },
            )
          : const HomeScreen(),
    );
  }
}
