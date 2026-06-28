import 'package:flutter/material.dart';
import '../models/recurso.dart';
import '../repositories/recursos_repository.dart';

class RecursosScreen extends StatefulWidget {
  const RecursosScreen({super.key});

  @override
  State<RecursosScreen> createState() => _RecursosScreenState();
}

class _RecursosScreenState extends State<RecursosScreen> {
  List<Recurso> _recursos = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final recursos = await RecursosRepository.listar();
      setState(() => _recursos = recursos);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _mostrarFormulario({Recurso? recurso}) async {
    final nombreCtrl = TextEditingController(text: recurso?.nombre ?? '');
    final catCtrl = TextEditingController(text: recurso?.categoria ?? '');
    final cantCtrl = TextEditingController(text: recurso?.cantidad.toString() ?? '1');
    final descCtrl = TextEditingController(text: recurso?.descripcion ?? '');
    String estado = recurso?.estado ?? 'disponible';

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(recurso == null ? 'Nuevo recurso' : 'Editar recurso',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _field('Nombre *', nombreCtrl),
              const SizedBox(height: 12),
              _field('Categoría', catCtrl),
              const SizedBox(height: 12),
              _field('Cantidad', cantCtrl, type: TextInputType.number),
              const SizedBox(height: 12),
              _field('Descripción', descCtrl),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(10)),
                child: DropdownButton<String>(
                  value: estado, isExpanded: true,
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white),
                  underline: const SizedBox(),
                  items: ['disponible', 'en_uso', 'mantenimiento']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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
                        'categoria': catCtrl.text.trim(),
                        'cantidad': int.tryParse(cantCtrl.text) ?? 1,
                        'descripcion': descCtrl.text.trim(),
                        'estado': estado,
                      };
                      if (recurso == null) {
                        await RecursosRepository.crear(body);
                      } else {
                        await RecursosRepository.actualizar(recurso.id, body);
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
                  child: Text(recurso == null ? 'Crear recurso' : 'Guardar',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
    if (result == true) _cargar();
  }

  Future<void> _eliminar(Recurso r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Eliminar recurso', style: TextStyle(color: Colors.white)),
        content: Text('¿Eliminar "${r.nombre}"?', style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await RecursosRepository.eliminar(r.id);
        _cargar();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
        title: const Text('Recursos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.grey), onPressed: _cargar)],
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
              : _recursos.isEmpty
                  ? const Center(child: Text('No hay recursos registrados', style: TextStyle(color: Colors.grey)))
                  : RefreshIndicator(
                      color: const Color(0xFFF59E0B),
                      onRefresh: _cargar,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _recursos.length,
                        itemBuilder: (_, i) => _buildCard(_recursos[i]),
                      ),
                    ),
    );
  }

  Widget _buildCard(Recurso r) {
    Color estadoColor;
    switch (r.estado) {
      case 'en_uso': estadoColor = Colors.orange; break;
      case 'mantenimiento': estadoColor = Colors.red; break;
      default: estadoColor = Colors.green;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: estadoColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.inventory_2, color: estadoColor),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          if (r.categoria != null && r.categoria!.isNotEmpty)
            Text(r.categoria!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Row(children: [
            Text('x${r.cantidad}  ', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: estadoColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: Text(r.estado, style: TextStyle(color: estadoColor, fontSize: 10)),
            ),
          ]),
        ])),
        IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.grey), onPressed: () => _mostrarFormulario(recurso: r)),
        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _eliminar(r)),
      ]),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {TextInputType type = TextInputType.text}) =>
      TextField(
        controller: ctrl, keyboardType: type, style: const TextStyle(color: Colors.white),
        decoration: _deco(label), autocorrect: false,
      );

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Colors.grey),
        filled: true, fillColor: const Color(0xFF252525),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      );
}
