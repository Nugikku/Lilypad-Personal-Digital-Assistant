import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_shell.dart';
import 'screens/notes_screen.dart';
import 'screens/profile_screen.dart';

final ValueNotifier<int> globalRefreshTrigger = ValueNotifier<int>(0);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Failed to load .env: $e");
  }
  // TODO: Ganti dengan URL dan Anon Key dari dasbor Supabase Anda
  await Supabase.initialize(
    url: 'https://lifbpoeqwghiuoshcoka.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxpZmJwb2Vxd2doaXVvc2hjb2thIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc5ODk3MDUsImV4cCI6MjA5MzU2NTcwNX0.gOJ1Jz0Sc9t-UjojbTi-RHKFz-3r7vL5xezZ784xOms',
  );

  runApp(
    DevicePreview(enabled: false, builder: (context) => const LilypadApp()),
  );
}

class LilypadApp extends StatelessWidget {
  const LilypadApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      title: 'Lilypad',
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: AppTheme.lightTheme,
      initialRoute: session != null ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainShell(),
        '/notes': (context) => const NotesScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
