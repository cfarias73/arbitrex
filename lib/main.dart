import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/feed_provider.dart';
import 'theme/app_theme.dart';
import 'router.dart';
import 'services/notification_service.dart';
import 'services/analytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase
  await Supabase.initialize(
    url: 'https://eassewkcalbkcebmksgp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVhc3Nld2tjYWxia2NlYm1rc2dwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIzMTczMzksImV4cCI6MjA4Nzg5MzMzOX0.yF3QekyO2qYchgedYgfJYXvGNMgpdXoDxxAQFlvbpag',
  );

  // Inicializar Firebase, Notificaciones y Analytics
  try {
    // Si falla por falta de configuración, no detenemos el arranque
    await Firebase.initializeApp();
    await NotificationService.initialize();
    await AnalyticsService.initialize();
  } catch (e) {
    debugPrint('Service tracking init warning: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
      ],
      child: const PolyfoxApp(),
    ),
  );
}

class PolyfoxApp extends StatelessWidget {
  const PolyfoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Polyfox',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
    );
  }
}
