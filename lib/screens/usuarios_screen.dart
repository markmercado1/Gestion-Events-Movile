import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});
  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  List<Map<String, dynamic>> _usuarios = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final data = await ApiService.get('/usuarios');
      final lista = data is List ? data : data['data'] ?? [];
      setState(() => _usuarios = (lista as List).cast<Map<String, dynamic>>());
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cambiarRol(int id, String rolActual) async {
    String nuevoRol = rolActual;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Cambiar rol', style: TextStyle(color: Colors.white)),
        content: StatefulBuilder(
          builder: (ctx, setModal) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(10)),
            child: DropdownButton<String>(
              value: nuevoRol, isExpanded: true,
              dropdownColor: const Color(0xFF1A1A1A),
              style: const TextStyle(color: Colors.white),
              underline: const SizedBox(),
              items: ['admin', 'organizador', 'usuario']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setModal(() => nuevoRol = v!),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ApiService.put('/usuarios/$id/rol', {'rol': nuevoRol});
                nav.pop();
                _cargar();
              } catch (e) {
                nav.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Usuarios', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.grey), onPressed: _cargar)],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  color: const Color(0xFFF59E0B),
                  onRefresh: _cargar,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _usuarios.length,
                    itemBuilder: (_, i) => _buildCard(_usuarios[i]),
                  ),
                ),
    );
  }

  Widget _buildCard(Map<String, dynamic> u) {
    final rol = u['rol'] ?? 'usuario';
    Color rolColor;
    switch (rol) {
      case 'admin': rolColor = const Color(0xFFF59E0B); break;
      case 'organizador': rolColor = Colors.blue; break;
      default: rolColor = Colors.grey;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: rolColor.withValues(alpha: 0.2),
          child: Text((u['email'] as String? ?? '?')[0].toUpperCase(),
              style: TextStyle(color: rolColor, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(u['email'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: rolColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Text(rol, style: TextStyle(color: rolColor, fontSize: 11)),
          ),
        ])),
        IconButton(
          icon: const Icon(Icons.manage_accounts, color: Colors.grey),
          onPressed: () => _cambiarRol(u['id'], rol),
        ),
      ]),
    );
  }
}
