import 'package:flutter/material.dart';
import '../models/sede.dart';
import '../repositories/sedes_repository.dart';
import 'salas_screen.dart';

class SedesScreen extends StatefulWidget {
  const SedesScreen({super.key});

  @override
  State<SedesScreen> createState() => _SedesScreenState();
}

class _SedesScreenState extends State<SedesScreen> {
  List<Sede> _sedes = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final sedes = await SedesRepository.listar();
      setState(() => _sedes = sedes);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _mostrarFormulario({Sede? sede}) async {
    final nombreCtrl = TextEditingController(text: sede?.nombre ?? '');
    final dirCtrl = TextEditingController(text: sede?.direccion ?? '');
    final telCtrl = TextEditingController(text: sede?.telefono ?? '');
    final imgCtrl = TextEditingController(text: sede?.imagenUrl ?? '');

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sede == null ? 'Nueva sede' : 'Editar sede',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _field('Nombre *', nombreCtrl),
            const SizedBox(height: 12),
            _field('Dirección', dirCtrl),
            const SizedBox(height: 12),
            _field('Teléfono', telCtrl, type: TextInputType.phone),
            const SizedBox(height: 12),
            _field('URL de imagen', imgCtrl, type: TextInputType.url),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nombreCtrl.text.trim().isEmpty) return;
                  try {
                    final body = {
                      'nombre': nombreCtrl.text.trim(),
                      'direccion': dirCtrl.text.trim(),
                      'telefono': telCtrl.text.trim(),
                      'imagen_url': imgCtrl.text.trim(),
                    };
                    if (sede == null) {
                      await SedesRepository.crear(body);
                    } else {
                      await SedesRepository.actualizar(sede.id, body);
                    }
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(sede == null ? 'Crear sede' : 'Guardar cambios',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
    if (result == true) _cargar();
  }

  Future<void> _eliminar(Sede s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Eliminar sede', style: TextStyle(color: Colors.white)),
        content: Text('¿Eliminar "${s.nombre}"?\nSe eliminarán también sus salas.',
            style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await SedesRepository.eliminar(s.id);
        _cargar();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Sedes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.grey), onPressed: _cargar)],
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF59E0B),
        onPressed: () => _mostrarFormulario(),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  color: const Color(0xFFF59E0B),
                  onRefresh: _cargar,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: _sedes.length,
                    itemBuilder: (_, i) => _buildCard(_sedes[i]),
                  ),
                ),
    );
  }

  Widget _buildCard(Sede s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (s.imagenUrl != null)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(s.imagenUrl!, height: 140, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(height: 80, color: const Color(0xFF2A2A2A),
                    child: const Icon(Icons.location_on, color: Colors.grey, size: 40))),
          ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.nombre, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            if (s.direccion != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on_outlined, color: Color(0xFFF59E0B), size: 14),
                const SizedBox(width: 4),
                Expanded(child: Text(s.direccion!, style: const TextStyle(color: Colors.grey, fontSize: 12))),
              ]),
            ],
            if (s.telefono != null) ...[
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.phone_outlined, color: Color(0xFFF59E0B), size: 14),
                const SizedBox(width: 4),
                Text(s.telefono!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
            ],
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SalasScreen(sede: s))),
                  icon: const Icon(Icons.meeting_room, size: 16),
                  label: const Text('Ver salas'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Color(0xFFF59E0B)),
                onPressed: () => _mostrarFormulario(sede: s),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _eliminar(s),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {TextInputType type = TextInputType.text}) =>
      TextField(
        controller: ctrl, keyboardType: type, style: const TextStyle(color: Colors.white),
        autocorrect: false,
        decoration: InputDecoration(
          labelText: label, labelStyle: const TextStyle(color: Colors.grey),
          filled: true, fillColor: const Color(0xFF252525),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      );
}
