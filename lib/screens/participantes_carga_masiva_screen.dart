import 'dart:typed_data';
import 'package:excel/excel.dart' as xls;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/participante_pendiente.dart';
import '../repositories/participantes_repository.dart';

const _kAmber = Color(0xFFF59E0B);
const _kBg = Color(0xFF0F0F0F);
const _kCard = Color(0xFF1A1A1A);
const _kBorder = Color(0xFF2A2A2A);
const _uuid = Uuid();

class ParticipantesCargaMasivaScreen extends StatefulWidget {
  final int eventoId;
  final String eventoNombre;

  const ParticipantesCargaMasivaScreen({
    super.key,
    required this.eventoId,
    required this.eventoNombre,
  });

  @override
  State<ParticipantesCargaMasivaScreen> createState() =>
      _ParticipantesCargaMasivaScreenState();
}

class _ParticipantesCargaMasivaScreenState
    extends State<ParticipantesCargaMasivaScreen> {
  final List<ParticipantePendiente> _pendientes = [];
  bool _enPreview = false;
  bool _guardando = false;
  int _progresoActual = 0;
  int _progresoTotal = 0;

  void _agregarPendientes(List<ParticipantePendiente> nuevos) {
    setState(() => _pendientes.addAll(nuevos));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${nuevos.length} fila(s) agregada(s) a la lista')),
    );
  }

  void _quitarPendiente(ParticipantePendiente p) {
    setState(() => _pendientes.removeWhere((x) => x.idLocal == p.idLocal));
  }

  Future<void> _guardarTodos() async {
    final validos = _pendientes.where((p) => p.esValido).toList();
    if (validos.isEmpty) return;

    setState(() {
      _guardando = true;
      _progresoActual = 0;
      _progresoTotal = validos.length;
    });

    int exitosos = 0;
    final fallidos = <String>[];

    for (var i = 0; i < validos.length; i++) {
      try {
        await ParticipantesRepository.crear(validos[i].toCrearBody(widget.eventoId));
        exitosos++;
      } catch (e) {
        fallidos.add('${validos[i].nombre}: $e');
      }
      if (mounted) setState(() => _progresoActual = i + 1);
    }

    if (!mounted) return;
    setState(() => _guardando = false);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCard,
        title: Text(
          fallidos.isEmpty ? 'Listo' : 'Carga completada con errores',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Guardados: $exitosos', style: const TextStyle(color: Colors.green)),
            if (fallidos.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Fallidos: ${fallidos.length}', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              ...fallidos.map((f) => Text(f,
                  style: const TextStyle(color: Colors.grey, fontSize: 12))),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Listo', style: TextStyle(color: _kAmber)),
          ),
        ],
      ),
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_enPreview ? 'Vista previa' : 'Agregar participantes',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text(widget.eventoNombre,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        leading: _enPreview
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.grey),
                onPressed: () => setState(() => _enPreview = false),
              )
            : null,
      ),
      body: _enPreview ? _buildPreview() : _buildTabs(),
      bottomNavigationBar: _enPreview || _pendientes.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kAmber,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => setState(() => _enPreview = true),
                    child: Text('Ver preview (${_pendientes.length})',
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTabs() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: _kAmber,
            labelColor: _kAmber,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Formulario'),
              Tab(text: 'Pegar texto'),
              Tab(text: 'Excel'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _TabFormulario(onAgregar: _agregarPendientes),
                _TabPegarTexto(onAgregar: _agregarPendientes),
                _TabExcel(onAgregar: _agregarPendientes),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final validos = _pendientes.where((p) => p.esValido).length;
    return Stack(
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: _kCard,
              child: Text('$validos válido(s) de ${_pendientes.length}',
                  style: const TextStyle(color: Colors.grey)),
            ),
            Expanded(
              child: _pendientes.isEmpty
                  ? const Center(
                      child: Text('Sin filas agregadas',
                          style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _pendientes.length,
                      itemBuilder: (_, i) {
                        final p = _pendientes[i];
                        return Dismissible(
                          key: ValueKey(p.idLocal),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.red.withValues(alpha: 0.3),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) => _quitarPendiente(p),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: _kCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: p.errorValidacion != null
                                    ? Colors.red.withValues(alpha: 0.5)
                                    : _kBorder,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.nombre.isEmpty ? '(sin nombre)' : p.nombre,
                                  style: TextStyle(
                                    color: p.errorValidacion != null
                                        ? Colors.red
                                        : Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (p.email != null)
                                  Text(p.email!,
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12)),
                                if (p.telefono != null)
                                  Text(p.telefono!,
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12)),
                                if (p.errorValidacion != null)
                                  Text(p.errorValidacion!,
                                      style: const TextStyle(
                                          color: Colors.red, fontSize: 11)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kAmber,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: validos == 0 ? null : _guardarTodos,
                    child: const Text('Guardar todos',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_guardando)
          Container(
            color: Colors.black.withValues(alpha: 0.6),
            child: Center(
              child: Container(
                width: 260,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value: _progresoTotal == 0
                          ? null
                          : _progresoActual / _progresoTotal,
                      color: _kAmber,
                      backgroundColor: _kBorder,
                    ),
                    const SizedBox(height: 12),
                    Text('Agregando $_progresoActual de $_progresoTotal...',
                        style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

int? _buscarColumna(List<String> headers, List<String> alias) {
  for (var i = 0; i < headers.length; i++) {
    if (alias.contains(headers[i])) return i;
  }
  return null;
}

String? _celda(List<xls.Data?> fila, int? idx) {
  if (idx == null || idx >= fila.length) return null;
  final v = fila[idx]?.value;
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

class _TabFormulario extends StatefulWidget {
  final void Function(List<ParticipantePendiente>) onAgregar;
  const _TabFormulario({required this.onAgregar});

  @override
  State<_TabFormulario> createState() => _TabFormularioState();
}

class _FilaFormulario {
  final nombreCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
}

class _TabFormularioState extends State<_TabFormulario> {
  final List<_FilaFormulario> _filas = [_FilaFormulario()];

  void _agregarFila() => setState(() => _filas.add(_FilaFormulario()));

  void _quitarFila(int i) {
    if (_filas.length == 1) return;
    setState(() => _filas.removeAt(i));
  }

  void _agregarALista() {
    final validas = _filas.where((f) => f.nombreCtrl.text.trim().isNotEmpty).toList();
    if (validas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa al menos un nombre')),
      );
      return;
    }
    final nuevos = validas
        .map((f) => ParticipantePendiente(
              idLocal: _uuid.v4(),
              nombre: f.nombreCtrl.text.trim(),
              email: f.emailCtrl.text.trim().isEmpty ? null : f.emailCtrl.text.trim(),
              telefono:
                  f.telefonoCtrl.text.trim().isEmpty ? null : f.telefonoCtrl.text.trim(),
              origen: 'manual',
            ))
        .toList();
    widget.onAgregar(nuevos);
    setState(() => _filas
      ..clear()
      ..add(_FilaFormulario()));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filas.length,
            itemBuilder: (_, i) {
              final f = _filas[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('Fila ${i + 1}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                          onPressed: () => _quitarFila(i),
                        ),
                      ],
                    ),
                    _campo('Nombre *', f.nombreCtrl),
                    const SizedBox(height: 8),
                    _campo('Email', f.emailCtrl),
                    const SizedBox(height: 8),
                    _campo('Teléfono', f.telefonoCtrl),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _agregarFila,
                  icon: const Icon(Icons.add, color: _kAmber),
                  label: const Text('Agregar fila', style: TextStyle(color: _kAmber)),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _kAmber),
              onPressed: _agregarALista,
              child: const Text('Agregar a la lista',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _campo(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        isDense: true,
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _kBorder)),
        border: const UnderlineInputBorder(borderSide: BorderSide(color: _kBorder)),
      ),
    );
  }
}

class _TabPegarTexto extends StatefulWidget {
  final void Function(List<ParticipantePendiente>) onAgregar;
  const _TabPegarTexto({required this.onAgregar});

  @override
  State<_TabPegarTexto> createState() => _TabPegarTextoState();
}

class _TabPegarTextoState extends State<_TabPegarTexto> {
  final _ctrl = TextEditingController();

  void _procesar() {
    final lineas = _ctrl.text.split('\n');
    final nuevos = <ParticipantePendiente>[];
    for (final linea in lineas) {
      if (linea.trim().isEmpty) continue;
      final partes = linea.split(',').map((p) => p.trim()).toList();
      final nombre = partes.isNotEmpty ? partes[0] : '';
      if (nombre.isEmpty) continue;
      nuevos.add(ParticipantePendiente(
        idLocal: _uuid.v4(),
        nombre: nombre,
        email: partes.length > 1 && partes[1].isNotEmpty ? partes[1] : null,
        telefono: partes.length > 2 && partes[2].isNotEmpty ? partes[2] : null,
        origen: 'texto',
      ));
    }
    if (nuevos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontraron filas válidas')),
      );
      return;
    }
    widget.onAgregar(nuevos);
    setState(() => _ctrl.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Una línea por participante: Nombre, Email, Teléfono',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: _ctrl,
              maxLines: null,
              minLines: 8,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: _kCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                hintText: 'Juan Pérez, juan@mail.com, 999999999',
                hintStyle: const TextStyle(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _kAmber),
              onPressed: _procesar,
              child: const Text('Procesar texto',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabExcel extends StatefulWidget {
  final void Function(List<ParticipantePendiente>) onAgregar;
  const _TabExcel({required this.onAgregar});

  @override
  State<_TabExcel> createState() => _TabExcelState();
}

class _TabExcelState extends State<_TabExcel> {
  List<ParticipantePendiente>? _resultado;
  String? _error;
  bool _cargando = false;

  Future<void> _elegirArchivo() async {
    setState(() {
      _error = null;
      _resultado = null;
    });
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final bytes = result.files.first.bytes;
    if (bytes == null) {
      setState(() => _error = 'No se pudo leer el archivo seleccionado');
      return;
    }

    setState(() => _cargando = true);
    try {
      final pendientes = _parsearExcel(bytes);
      if (pendientes.isEmpty) {
        setState(() => _error = 'El archivo está vacío o no tiene filas de datos');
      } else {
        setState(() => _resultado = pendientes);
      }
    } catch (e) {
      setState(() => _error = 'No se pudo procesar el archivo: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<ParticipantePendiente> _parsearExcel(Uint8List bytes) {
    final excel = xls.Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return [];
    final sheet = excel.tables[excel.tables.keys.first]!;
    final rows = sheet.rows;
    if (rows.isEmpty) return [];

    final headers = rows.first
        .map((c) => c?.value?.toString().trim().toLowerCase() ?? '')
        .toList();
    final idxNombre = _buscarColumna(headers, ['nombre']);
    final idxEmail = _buscarColumna(headers, ['email', 'correo']);
    final idxTelefono = _buscarColumna(headers, ['telefono', 'celular']);

    final pendientes = <ParticipantePendiente>[];
    for (var i = 1; i < rows.length; i++) {
      final fila = rows[i];
      if (fila.every((c) => c?.value == null)) continue;

      final nombre = idxNombre != null
          ? (_celda(fila, idxNombre) ?? '')
          : (_celda(fila, 0) ?? '');

      pendientes.add(ParticipantePendiente(
        idLocal: _uuid.v4(),
        nombre: nombre,
        email: _celda(fila, idxEmail),
        telefono: _celda(fila, idxTelefono),
        origen: 'excel',
        errorValidacion: nombre.isEmpty ? 'Fila sin nombre' : null,
      ));
    }
    return pendientes;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _cargando ? null : _elegirArchivo,
              icon: const Icon(Icons.upload_file, color: _kAmber),
              label: const Text('Elegir archivo .xlsx', style: TextStyle(color: _kAmber)),
            ),
          ),
          const SizedBox(height: 16),
          if (_cargando) const CircularProgressIndicator(color: _kAmber),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          if (_resultado != null) ...[
            Expanded(
              child: ListView.builder(
                itemCount: _resultado!.length,
                itemBuilder: (_, i) {
                  final p = _resultado![i];
                  return ListTile(
                    dense: true,
                    title: Text(p.nombre.isEmpty ? '(sin nombre)' : p.nombre,
                        style: TextStyle(
                            color: p.errorValidacion != null ? Colors.red : Colors.white)),
                    subtitle: Text(
                      [p.email, p.telefono].where((s) => s != null).join(' · '),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    trailing: p.errorValidacion != null
                        ? const Icon(Icons.error_outline, color: Colors.red, size: 18)
                        : const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _kAmber),
                onPressed: () {
                  widget.onAgregar(_resultado!);
                  setState(() => _resultado = null);
                },
                child: Text('Agregar ${_resultado!.length} fila(s) a la lista',
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
