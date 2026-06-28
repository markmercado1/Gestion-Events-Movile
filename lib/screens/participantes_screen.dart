import 'package:flutter/material.dart';
import '../models/participante.dart';
import '../repositories/participantes_repository.dart';
import 'participantes_carga_masiva_screen.dart';

class ParticipantesScreen extends StatefulWidget {
  final int eventoId;
  final String eventoNombre;

  const ParticipantesScreen({
    super.key,
    required this.eventoId,
    required this.eventoNombre,
  });

  @override
  State<ParticipantesScreen> createState() => _ParticipantesScreenState();
}

class _ParticipantesScreenState extends State<ParticipantesScreen> {
  List<Participante> _participantes = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final participantes =
          await ParticipantesRepository.listar(eventoId: widget.eventoId);
      setState(() => _participantes = participantes);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _marcarAsistencia(int id, bool asistio) async {
    try {
      await ParticipantesRepository.marcarAsistencia(id, !asistio);
      _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentes = _participantes.where((p) => p.asistio).length;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Participantes',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text(widget.eventoNombre,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _cargar,
          ),
        ],
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_participantes_carga_masiva',
        backgroundColor: const Color(0xFFF59E0B),
        onPressed: () async {
          final resultado = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => ParticipantesCargaMasivaScreen(
                eventoId: widget.eventoId,
                eventoNombre: widget.eventoNombre,
              ),
            ),
          );
          if (resultado == true) _cargar();
        },
        child: const Icon(Icons.person_add, color: Colors.black),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.grey)))
              : Column(
                  children: [
                    if (_participantes.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: const Color(0xFF1A1A1A),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _stat('Total', _participantes.length.toString(), Colors.white),
                            _stat('Presentes', presentes.toString(), Colors.green),
                            _stat('Ausentes',
                                (_participantes.length - presentes).toString(),
                                Colors.red),
                          ],
                        ),
                      ),
                    Expanded(
                      child: _participantes.isEmpty
                          ? const Center(
                              child: Text('Sin participantes registrados',
                                  style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _participantes.length,
                              itemBuilder: (_, i) =>
                                  _buildCard(_participantes[i]),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _stat(String label, String valor, Color color) {
    return Column(
      children: [
        Text(valor,
            style: TextStyle(
                color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildCard(Participante p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: p.asistio
              ? Colors.green.withValues(alpha: 0.3)
              : const Color(0xFF2A2A2A),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: p.asistio
                ? Colors.green.withValues(alpha: 0.2)
                : const Color(0xFF2A2A2A),
            child: Text(
              p.nombre.isNotEmpty ? p.nombre[0].toUpperCase() : '?',
              style: TextStyle(
                  color: p.asistio ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.nombre,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                if (p.email != null)
                  Text(p.email!,
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 12)),
                if (p.telefono != null)
                  Text(p.telefono!,
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _marcarAsistencia(p.id, p.asistio),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: p.asistio
                    ? Colors.green.withValues(alpha: 0.15)
                    : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                p.asistio ? 'Presente' : 'Ausente',
                style: TextStyle(
                    color: p.asistio ? Colors.green : Colors.grey,
                    fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
