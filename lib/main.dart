import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/api_config.dart';
import 'db/database_helper.dart';
import 'db/daos/pending_operations_dao.dart';
import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'services/sync_manager.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.init(); // detecta emulador vs celular físico
  await DatabaseHelper.instance.database; // abre/crea la base local antes de runApp
  await PendingOperationsDao.resetEnCursoHuerfanas(); // recupera operaciones truncadas por un cierre abrupto
  await SyncManager.instance.refreshPendingCount(); // refleja pendientes de sesiones previas
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider.value(value: ConnectivityService.instance),
      ],
      child: const EventJuliacaApp(),
    ),
  );
}

class EventJuliacaApp extends StatelessWidget {
  const EventJuliacaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Juliaca',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF59E0B),
          surface: Color(0xFF1A1A1A),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        fontFamily: 'Roboto',
      ),
      home: const _Root(),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (auth.cargando) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event, color: Color(0xFFF59E0B), size: 56),
              SizedBox(height: 16),
              Text('Event Juliaca',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 24),
              CircularProgressIndicator(color: Color(0xFFF59E0B)),
            ],
          ),
        ),
      );
    }

    return auth.estaAutenticado ? const MainScreen() : const LoginScreen();
  }
}
