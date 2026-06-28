import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuditoriaScreen extends StatefulWidget {
  const AuditoriaScreen({super.key});
  @override
  State<AuditoriaScreen> createState() => _AuditoriaScreenState();
}

class _AuditoriaScreenState extends State<AuditoriaScreen> {
  List<Map<String, dynamic>> _registros = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final data = await ApiService.get('/auditoria');
      final lista = data is List ? data : data['data'] ?? [];
      setState(() => _registros = (lista as List).cast<Map<String, dynamic>>());
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Auditoría', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.grey), onPressed: _cargar)],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.grey)))
              : _registros.isEmpty
                  ? const Center(child: Text('Sin registros de auditoría', style: TextStyle(color: Colors.grey)))
                  : RefreshIndicator(
                      color: const Color(0xFFF59E0B),
                      onRefresh: _cargar,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _registros.length,
                        itemBuilder: (_, i) => _buildCard(_registros[i]),
                      ),
                    ),
    );
  }

  Widget _buildCard(Map<String, dynamic> r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.history, color: Color(0xFFF59E0B), size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r['accion'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13)),
          if (r['entidad'] != null)
            Text('${r['entidad']} #${r['entidad_id'] ?? ''}',
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
          Row(children: [
            if (r['ip'] != null)
              Text('IP: ${r['ip']}  ', style: const TextStyle(color: Colors.grey, fontSize: 10)),
            Flexible(child: Text(r['creado_en'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 10), overflow: TextOverflow.ellipsis)),
          ]),
        ])),
      ]),
    );
  }
}
