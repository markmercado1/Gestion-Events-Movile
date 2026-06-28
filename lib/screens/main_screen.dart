import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'eventos_screen.dart';
import 'sedes_screen.dart';
import 'pagos_screen.dart';
import 'cotizaciones_screen.dart';
import 'recursos_screen.dart';
import 'usuarios_screen.dart';
import 'auditoria_screen.dart';
import '../widgets/sync_status_banner.dart';
import 'sync_errors_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _indice = 0;

  final List<Widget> _pantallas = const [
    DashboardScreen(),
    EventosScreen(),
    SedesScreen(),
    PagosScreen(),
    CotizacionesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthService>().usuario;
    return Scaffold(
      body: Column(children: [
        const SyncStatusBanner(),
        Expanded(child: IndexedStack(index: _indice, children: _pantallas)),
      ]),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
        ),
        child: BottomNavigationBar(
          currentIndex: _indice,
          onTap: (i) => setState(() => _indice = i),
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFFF59E0B),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.event_outlined), activeIcon: Icon(Icons.event), label: 'Eventos'),
            BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), activeIcon: Icon(Icons.location_on), label: 'Sedes'),
            BottomNavigationBarItem(icon: Icon(Icons.payments_outlined), activeIcon: Icon(Icons.payments), label: 'Pagos'),
            BottomNavigationBarItem(icon: Icon(Icons.description_outlined), activeIcon: Icon(Icons.description), label: 'Cotizaciones'),
          ],
        ),
      ),
      drawer: _buildDrawer(context, usuario),
    );
  }

  Widget _buildDrawer(BuildContext context, dynamic usuario) {
    final esAdmin = usuario?.esAdmin ?? false;
    return Drawer(
      backgroundColor: const Color(0xFF1A1A1A),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
              const CircleAvatar(
                backgroundColor: Colors.black26, radius: 28,
                child: Icon(Icons.person, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 8),
              Text(usuario?.email ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
              Text((usuario?.rol ?? '').toUpperCase(),
                  style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold)),
            ]),
          ),
          // Navegación principal
          _drawerTitulo('PRINCIPAL'),
          _drawerItem(Icons.dashboard, 'Dashboard', 0),
          _drawerItem(Icons.event, 'Eventos', 1),
          _drawerItem(Icons.location_on, 'Sedes', 2),
          _drawerItem(Icons.payments, 'Pagos', 3),
          _drawerItem(Icons.description, 'Cotizaciones', 4),
          const Divider(color: Color(0xFF2A2A2A)),
          // Pantallas secundarias
          _drawerTitulo('GESTIÓN'),
          _drawerItemNav(Icons.inventory_2, 'Recursos', () => _irA(const RecursosScreen())),
          _drawerItemNav(Icons.sync_problem, 'Errores de sincronización',
              () => _irA(const SyncErrorsScreen())),
          if (esAdmin) ...[
            const Divider(color: Color(0xFF2A2A2A)),
            _drawerTitulo('ADMINISTRACIÓN'),
            _drawerItemNav(Icons.people, 'Usuarios', () => _irA(const UsuariosScreen())),
            _drawerItemNav(Icons.history, 'Auditoría', () => _irA(const AuditoriaScreen())),
          ],
          const Divider(color: Color(0xFF2A2A2A)),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              await context.read<AuthService>().logout();
            },
          ),
        ],
      ),
    );
  }

  void _irA(Widget pantalla) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
  }

  Widget _drawerTitulo(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
    child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.5)),
  );

  Widget _drawerItem(IconData icon, String label, int index) {
    final sel = _indice == index;
    return ListTile(
      leading: Icon(icon, color: sel ? const Color(0xFFF59E0B) : Colors.grey),
      title: Text(label, style: TextStyle(color: sel ? const Color(0xFFF59E0B) : Colors.white)),
      selected: sel,
      selectedTileColor: const Color(0xFFF59E0B).withValues(alpha: 0.1),
      onTap: () { Navigator.pop(context); setState(() => _indice = index); },
    );
  }

  Widget _drawerItemNav(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
      onTap: onTap,
    );
  }
}
