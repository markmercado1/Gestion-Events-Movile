import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../repositories/eventos_repository.dart';
import 'evento_form_screen.dart';
import 'participantes_screen.dart';

class EventosScreen extends StatefulWidget {
  const EventosScreen({super.key});

  @override
  State<EventosScreen> createState() => _EventosScreenState();
}

class _EventosScreenState extends State<EventosScreen> {
  List<Evento> _eventos = [];
  bool _cargando = true;
  String? _error;
  String _filtroEstado = 'todos';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final estado = _filtroEstado == 'todos' ? null : _filtroEstado;
      final eventos = await EventosRepository.listar(estado: estado);
      setState(() => _eventos = eventos);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _abrirFormulario({Evento? evento}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EventoFormScreen(evento: evento)),
    );
    if (result == true) {
      _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(evento == null ? 'Evento creado' : 'Evento actualizado'),
          backgroundColor: Colors.green,
        ));
      }
    }
  }

  Future<void> _eliminar(Evento e) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Eliminar evento', style: TextStyle(color: Colors.white)),
        content: Text('¿Eliminar "${e.nombre}"?\nSe eliminarán también sus participantes y pagos.',
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
        await EventosRepository.eliminar(e.id);
        _cargar();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Evento eliminado'), backgroundColor: Colors.orange));
        }
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $err'), backgroundColor: Colors.red));
        }
      }
    }
  }

  void _verParticipantes(Evento e) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ParticipantesScreen(eventoId: e.id, eventoNombre: e.nombre)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Eventos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.grey), onPressed: _cargar),
        ],
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF59E0B),
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: Column(children: [
        _buildFiltros(),
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
              : _error != null
                  ? _buildError()
                  : _eventos.isEmpty
                      ? const Center(child: Text('No hay eventos', style: TextStyle(color: Colors.grey)))
                      : RefreshIndicator(
                          color: const Color(0xFFF59E0B),
                          onRefresh: _cargar,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                            itemCount: _eventos.length,
                            itemBuilder: (_, i) => _buildCard(_eventos[i]),
                          ),
                        ),
        ),
      ]),
    );
  }

  Widget _buildFiltros() {
    const opciones = ['todos', 'activo', 'proximo', 'completado'];
    return Container(
      height: 48,
      color: const Color(0xFF1A1A1A),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: opciones.map((op) => GestureDetector(
          onTap: () { setState(() => _filtroEstado = op); _cargar(); },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _filtroEstado == op ? const Color(0xFFF59E0B) : const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(child: Text(
              op[0].toUpperCase() + op.substring(1),
              style: TextStyle(
                color: _filtroEstado == op ? Colors.black : Colors.grey,
                fontSize: 13, fontWeight: FontWeight.w500,
              ),
            )),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildCard(Evento e) {
    Color estadoColor;
    switch (e.estado) {
      case 'activo': estadoColor = Colors.green; break;
      case 'completado': estadoColor = Colors.grey; break;
      default: estadoColor = const Color(0xFFF59E0B);
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        collapsedIconColor: Colors.grey,
        iconColor: const Color(0xFFF59E0B),
        title: Row(children: [
          Expanded(child: Text(e.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: estadoColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
            child: Text(e.estado, style: TextStyle(color: estadoColor, fontSize: 11)),
          ),
        ]),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('${e.fecha}  •  ${e.horaInicio} - ${e.horaFin}',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Divider(color: Color(0xFF2A2A2A)),
              _fila('Tipo', e.tipo),
              if (e.tipo == 'pagado') _fila('Precio', 'S/ ${e.precio}'),
              if (e.nombreCliente != null && e.nombreCliente!.isNotEmpty)
                _fila('Cliente', e.nombreCliente!),
              if (e.telefonoCliente != null && e.telefonoCliente!.isNotEmpty)
                _fila('Teléfono', e.telefonoCliente!),
              if (e.nombreSede != null) _fila('Sede', e.nombreSede!),
              _fila('Participantes', e.participantes.toString()),
              if (e.descripcion != null && e.descripcion!.isNotEmpty)
                _fila('Descripción', e.descripcion!),
              const SizedBox(height: 12),
              // Botones de acción
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _verParticipantes(e),
                    icon: const Icon(Icons.people, size: 16),
                    label: Text('Participantes (${e.participantes})'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _abrirFormulario(evento: e),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Editar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF59E0B),
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _eliminar(e),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Eliminar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _fila(String label, String valor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
      Expanded(child: Text(valor, style: const TextStyle(color: Colors.white, fontSize: 13))),
    ]),
  );

  Widget _buildError() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, color: Colors.grey, size: 48),
      const SizedBox(height: 12),
      Text(_error!, style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: _cargar,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
        child: const Text('Reintentar', style: TextStyle(color: Colors.black)),
      ),
    ]),
  );
}
