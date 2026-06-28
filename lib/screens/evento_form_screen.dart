import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../models/sede.dart';
import '../repositories/eventos_repository.dart';
import '../repositories/sedes_repository.dart';

class EventoFormScreen extends StatefulWidget {
  final Evento? evento;
  const EventoFormScreen({super.key, this.evento});

  @override
  State<EventoFormScreen> createState() => _EventoFormScreenState();
}

class _EventoFormScreenState extends State<EventoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _precio = TextEditingController();
  final _cliente = TextEditingController();
  final _telefono = TextEditingController();
  final _desc = TextEditingController();

  String _tipo = 'gratuito';
  String _estado = 'proximo';
  String? _fecha;
  String? _horaInicio;
  String? _horaFin;
  int? _sedeId;

  List<Sede> _sedes = [];
  bool _guardando = false;
  bool get _editando => widget.evento != null;

  @override
  void initState() {
    super.initState();
    _cargarSedes();
    if (_editando) {
      final e = widget.evento!;
      _nombre.text = e.nombre;
      _precio.text = e.precio.toString();
      _cliente.text = e.nombreCliente ?? '';
      _telefono.text = e.telefonoCliente ?? '';
      _desc.text = e.descripcion ?? '';
      _tipo = e.tipo;
      _estado = e.estado;
      _fecha = e.fecha;
      _horaInicio = e.horaInicio;
      _horaFin = e.horaFin;
      _sedeId = e.sedeId;
    }
  }

  Future<void> _cargarSedes() async {
    try {
      final sedes = await SedesRepository.listar();
      setState(() => _sedes = sedes);
    } catch (_) {}
  }

  Future<void> _seleccionarFecha() async {
    final hoy = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha != null ? DateTime.tryParse(_fecha!) ?? hoy : hoy,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFFF59E0B)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _fecha =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _seleccionarHora(bool esInicio) async {
    final parsed = esInicio ? _horaInicio : _horaFin;
    TimeOfDay inicial = TimeOfDay.now();
    if (parsed != null && parsed.contains(':')) {
      final parts = parsed.split(':');
      inicial = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0);
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: inicial,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFFF59E0B)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final str =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() => esInicio ? _horaInicio = str : _horaFin = str);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fecha == null) {
      _snack('Selecciona la fecha del evento', isError: true);
      return;
    }
    if (_horaInicio == null || _horaFin == null) {
      _snack('Selecciona horario de inicio y fin', isError: true);
      return;
    }
    setState(() => _guardando = true);
    try {
      final body = {
        'nombre': _nombre.text.trim(),
        'fecha': _fecha,
        'hora_inicio': _horaInicio,
        'hora_fin': _horaFin,
        'tipo': _tipo,
        'precio': double.tryParse(_precio.text) ?? 0,
        'nombre_cliente': _cliente.text.trim(),
        'telefono_cliente': _telefono.text.trim(),
        'descripcion': _desc.text.trim(),
        'estado': _estado,
        if (_sedeId != null) 'sede_id': _sedeId,
      };
      if (_editando) {
        await EventosRepository.actualizar(widget.evento!.id, body);
      } else {
        await EventosRepository.crear(body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  @override
  void dispose() {
    _nombre.dispose();
    _precio.dispose();
    _cliente.dispose();
    _telefono.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(_editando ? 'Editar evento' : 'Nuevo evento',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _guardando ? null : _guardar,
            child: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF59E0B)))
                : const Text('Guardar',
                    style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _campo('Nombre del evento *', _nombre, required: true),
            const SizedBox(height: 14),
            // Fecha
            _seccion('Fecha y horario'),
            GestureDetector(
              onTap: _seleccionarFecha,
              child: _infoTile(Icons.calendar_today, 'Fecha',
                  _fecha ?? 'Seleccionar fecha'),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _seleccionarHora(true),
                  child: _infoTile(Icons.access_time, 'Inicio',
                      _horaInicio ?? '--:--'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _seleccionarHora(false),
                  child: _infoTile(Icons.access_time_filled, 'Fin',
                      _horaFin ?? '--:--'),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            _seccion('Tipo de evento'),
            Row(children: [
              Expanded(child: _opcion('gratuito', 'Gratuito', Icons.card_giftcard)),
              const SizedBox(width: 8),
              Expanded(child: _opcion('pagado', 'Pagado', Icons.paid)),
            ]),
            if (_tipo == 'pagado') ...[
              const SizedBox(height: 14),
              _campo('Precio (S/)', _precio,
                  keyboardType: TextInputType.number),
            ],
            const SizedBox(height: 14),
            _seccion('Estado'),
            _dropdown('Estado', _estado, ['proximo', 'activo', 'completado'],
                (v) => setState(() => _estado = v!)),
            const SizedBox(height: 14),
            _seccion('Sede'),
            _sedes.isEmpty
                ? const Text('Cargando sedes...',
                    style: TextStyle(color: Colors.grey))
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: DropdownButton<int>(
                      value: _sedeId, isExpanded: true,
                      dropdownColor: const Color(0xFF1A1A1A),
                      style: const TextStyle(color: Colors.white),
                      hint: const Text('Sin sede', style: TextStyle(color: Colors.grey)),
                      underline: const SizedBox(),
                      items: [
                        const DropdownMenuItem<int>(value: null, child: Text('Sin sede', style: TextStyle(color: Colors.grey))),
                        ..._sedes.map((s) => DropdownMenuItem(value: s.id, child: Text(s.nombre))),
                      ],
                      onChanged: (v) => setState(() => _sedeId = v),
                    ),
                  ),
            const SizedBox(height: 14),
            _seccion('Datos del cliente'),
            _campo('Nombre del cliente', _cliente),
            const SizedBox(height: 10),
            _campo('Teléfono del cliente', _telefono,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 14),
            _seccion('Descripción'),
            _campo('Descripción (opcional)', _desc, maxLines: 3),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _seccion(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label.toUpperCase(),
            style: const TextStyle(
                color: Color(0xFFF59E0B),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
      );

  Widget _campo(String label, TextEditingController ctrl,
      {bool required = false,
      TextInputType keyboardType = TextInputType.text,
      int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: _deco(label),
      autocorrect: false,
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? 'Campo requerido' : null
          : null,
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(children: [
        Icon(icon, color: const Color(0xFFF59E0B), size: 18),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ]),
      ]),
    );
  }

  Widget _opcion(String value, String label, IconData icon) {
    final sel = _tipo == value;
    return GestureDetector(
      onTap: () => setState(() => _tipo = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: sel
              ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: sel ? const Color(0xFFF59E0B) : const Color(0xFF2A2A2A),
          ),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: sel ? const Color(0xFFF59E0B) : Colors.grey),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: sel ? const Color(0xFFF59E0B) : Colors.grey,
                  fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
        ]),
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> opciones,
      void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: const Color(0xFF1A1A1A),
      style: const TextStyle(color: Colors.white),
      decoration: _deco(label),
      items: opciones
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: onChanged,
    );
  }

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFF59E0B))),
      );
}
