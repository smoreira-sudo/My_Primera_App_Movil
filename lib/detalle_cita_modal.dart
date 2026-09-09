import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DetalleCitaModal extends StatefulWidget {
  final Map<String, dynamic> citaData;
  final String citaId;

  const DetalleCitaModal({
    super.key,
    required this.citaData,
    required this.citaId,
  });

  @override
  State<DetalleCitaModal> createState() => _DetalleCitaModalState();
}

class _DetalleCitaModalState extends State<DetalleCitaModal> {
  final TextEditingController _notasController = TextEditingController();
  bool _editandoNotas = false;
  bool _guardando = false;
  String? _clienteDocId;
  String? _fotoUrl;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  // Carga segura combinando la cita actual y la ficha del cliente
  Future<void> _cargarDatosIniciales() async {
    // 1. Prioridad directa de la cita (incluyendo 'fotoCorte' que viene de Firestore)
    String? fotoDeCita = widget.citaData['fotoCorte'] ?? 
                         widget.citaData['fotoUrl'] ?? 
                         widget.citaData['fotoReferenciaUrl'];
    
    setState(() {
      _fotoUrl = fotoDeCita;
      _notasController.text = widget.citaData['notasCorte'] ?? 
                              widget.citaData['notas'] ?? 
                              'Sin especificaciones grabadas.';
    });

    final clienteNombre = widget.citaData['clienteNombre'] ?? widget.citaData['cliente'] ?? '';
    final clienteTelefono = widget.citaData['telefono'] ?? '';

    if (clienteNombre.isEmpty && clienteTelefono.isEmpty) return;

    try {
      QuerySnapshot snapshot;
      if (clienteTelefono.toString().isNotEmpty) {
        snapshot = await FirebaseFirestore.instance
            .collection('clientes')
            .where('telefono', isEqualTo: clienteTelefono)
            .limit(1)
            .get();
      } else {
        snapshot = await FirebaseFirestore.instance
            .collection('clientes')
            .where('nombre', isEqualTo: clienteNombre)
            .limit(1)
            .get();
      }

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;

        if (mounted) {
          setState(() {
            _clienteDocId = doc.id;
            _notasController.text = data['notasCorte'] ??
                widget.citaData['notasCorte'] ??
                widget.citaData['notas'] ??
                'Sin especificaciones grabadas.';
            
            // Si el cliente tiene foto, la usa; si no, mantiene la de la cita
            _fotoUrl = data['fotoCorte'] ??
                data['ultimaFotoCorteUrl'] ??
                data['fotoReferenciaUrl'] ??
                data['fotoUrl'] ??
                fotoDeCita;
          });
        }
      }
    } catch (e) {
      debugPrint("Error al cargar datos del cliente: $e");
    }
  }

  Future<void> _guardarNotas() async {
    setState(() => _guardando = true);
    try {
      await FirebaseFirestore.instance
          .collection('citas')
          .doc(widget.citaId)
          .update({
            'notasCorte': _notasController.text.trim(),
            'notas': _notasController.text.trim(),
          });

      if (_clienteDocId != null) {
        await FirebaseFirestore.instance
            .collection('clientes')
            .doc(_clienteDocId)
            .update({'notasCorte': _notasController.text.trim()});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Notas de corte actualizadas con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _editandoNotas = false;
          _guardando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _guardando = false);
      }
    }
  }

  // Modal para ver foto ampliada en pantalla completa
  void _mostrarFotoGrande(String fotoUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: Center(
                child: fotoUrl.startsWith('data:image')
                    ? Image.memory(base64Decode(fotoUrl.split(',').last))
                    : Image.network(fotoUrl),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirFotoCorte(String? fotoUrl) {
    if (fotoUrl == null || fotoUrl.isEmpty) {
      return _buildFotoPlaceholder();
    }

    Widget imagen;
    if (fotoUrl.startsWith('data:image')) {
      try {
        final bytes = base64Decode(fotoUrl.split(',').last);
        imagen = Image.memory(
          bytes,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFotoPlaceholder(),
        );
      } catch (e) {
        return _buildFotoPlaceholder();
      }
    } else {
      imagen = Image.network(
        fotoUrl,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFotoPlaceholder(),
      );
    }

    return GestureDetector(
      onTap: () => _mostrarFotoGrande(fotoUrl),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          imagen,
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.fullscreen, color: Colors.white, size: 20),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cliente = widget.citaData['clienteNombre'] ?? widget.citaData['cliente'] ?? 'Cliente';
    final servicio = widget.citaData['corte'] ?? widget.citaData['servicio'] ?? 'Servicio general';
    final barbero = widget.citaData['barberoNombre'] ?? widget.citaData['barbero'] ?? 'Sin asignar';
    final hora = widget.citaData['hora'] ?? '';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F0EB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$servicio • $barbero',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hora.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB8977E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      hora,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Foto de Referencia del Corte',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _construirFotoCorte(_fotoUrl),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Instrucciones y Preferencias',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _editandoNotas ? Icons.close : Icons.edit_note,
                    color: const Color(0xFFB8977E),
                  ),
                  onPressed: () {
                    setState(() {
                      _editandoNotas = !_editandoNotas;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _editandoNotas
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextField(
                            controller: _notasController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Ej: Usa la 1.5 a los lados, degradado bajo...',
                              border: InputBorder.none,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: _guardando ? null : _guardarNotas,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB8977E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: _guardando
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.save, size: 18, color: Colors.white),
                            label: const Text(
                              'Guardar Cambios',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.content_cut, size: 20, color: Color(0xFFB8977E)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _notasController.text.isNotEmpty
                                  ? _notasController.text
                                  : 'Sin especificaciones grabadas.',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFotoPlaceholder() {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, size: 36, color: Color(0xFFB8977E)),
          SizedBox(height: 8),
          Text(
            'Sin foto de referencia guardada',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}