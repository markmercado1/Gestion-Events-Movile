import 'package:flutter/material.dart';
import '../models/sala.dart';
import '../models/sede.dart';
import '../repositories/salas_repository.dart';

class SalasScreen extends StatefulWidget {
  final Sede sede;
  const SalasScreen({super.key, required this.sede});

  @override
  State<SalasScreen> createState() => _SalasScreenState();
}

class _SalasScreenState extends State<SalasScreen> {
  List<Sala> _salas = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final salas = await SalasRepository.listar(sedeId: widget.sede.id);
      setState(() => _salas = salas);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _mostrarFormulario({Sala? sala}) async {
    final nombreCtrl = TextEditingController(text: sala?.nombre ?? '');
    final capacidadCtrl = TextEditingController(text: sala?.capacidad?.toString() ?? '');
    String estado = sala?.estado ?? 'disponible';

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sala == null ? 'Nueva sala' : 'Editar sala',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _field('Nombre de la sala', nombreCtrl),
              const SizedBox(height: 12),
              _field('Capacidad (personas)', capacidadCtrl, type: TextInputType.number),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF252525),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButton<String>(
                  value: estado,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white),
                  underline: const SizedBox(),
                  items: ['disponible', 'ocupada', 'mantenimiento']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setModal(() => estado = v!),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nombreCtrl.text.trim().isEmpty) return;
                    try {
                      final body = {
                        'nombre': nombreCtrl.text.trim(),
                        'sede_id': widget.sede.id,
                        'capacidad': int.tryParse(capacidadCtrl.text) ?? 0,
                        'estado': estado,
                      };
                      if (sala == null) {
                        await SalasRepository.crear(body);
                      } else {
                        await SalasRepository.actualizar(sala.id, body);
                      }
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    } catch (e) {
                      if (ctx.mounted) Navigator.pop(ctx, false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(sala == null ? 'Crear sala' : 'Guardar cambios',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result == true) _cargar();
  }

  Future<void> _eliminar(Sala sala) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Eliminar sala', style: TextStyle(color: Colors.white)),
        content: Text('¿Eliminar "${sala.nombre}"?',
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
        await SalasRepository.eliminar(sala.id);
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Salas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text(widget.sede.nombre, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
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
              : _salas.isEmpty
                  ? const Center(child: Text('No hay salas registradas', style: TextStyle(color: Colors.grey)))
                  : RefreshIndicator(
                      color: const Color(0xFFF59E0B),
                      onRefresh: _cargar,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _salas.length,
                        itemBuilder: (_, i) => _buildCard(_salas[i]),
                      ),
                    ),
    );
  }

  Widget _buildCard(Sala s) {
    Color estadoColor;
    switch (s.estado) {
      case 'ocupada': estadoColor = Colors.orange; break;
      case 'mantenimiento': estadoColor = Colors.red; break;
      default: estadoColor = Colors.green;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: estadoColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.meeting_room, color: estadoColor),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          if (s.capacidad != null)
            Text('${s.capacidad} personas', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: estadoColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(s.estado, style: TextStyle(color: estadoColor, fontSize: 11)),
          ),
        ])),
        IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.grey), onPressed: () => _mostrarFormulario(sala: s)),
        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _eliminar(s)),
      ]),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType type = TextInputType.text}) =>
      TextField(
        controller: ctrl,
        keyboardType: type,
        style: const TextStyle(color: Colors.white),
        decoration: _deco(label),
        autocorrect: false,
      );

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF252525),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      );
}
