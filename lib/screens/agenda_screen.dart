import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Modales del proyecto
import '../detalle_cita_modal.dart';
import '../cierre_servicio_modal.dart';

// ==========================================
// MODELO DE DATOS: BARBERO
// ==========================================
class Barbero {
  final String id;
  final String nombre;
  final String especialidad;
  final List<int> diasDescanso;

  Barbero({
    required this.id,
    required this.nombre,
    required this.especialidad,
    required this.diasDescanso,
  });

  factory Barbero.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Barbero(
      id: doc.id,
      nombre: data['nombre'] ?? 'Sin Nombre',
      especialidad: data['especialidad'] ?? 'General',
      diasDescanso: List<int>.from(data['diasDescanso'] ?? []),
    );
  }
}

// ==========================================
// MODELO DE DATOS: CITA
// ==========================================
class Cita {
  final String id;
  final String cliente;
  final String corte;
  final double precio;
  final DateTime fechaHora;
  final String estado;
  final String barbero;

  Cita({
    required this.id,
    required this.cliente,
    required this.corte,
    required this.precio,
    required this.fechaHora,
    required this.estado,
    required this.barbero,
  });

  factory Cita.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime fecha = DateTime.now();
    if (data['fechaHora'] != null) {
      if (data['fechaHora'] is Timestamp) {
        fecha = (data['fechaHora'] as Timestamp).toDate();
      } else if (data['fechaHora'] is String) {
        fecha = DateTime.tryParse(data['fechaHora']) ?? DateTime.now();
      }
    }

    return Cita(
      id: doc.id,
      cliente:
          data['clienteNombre'] ?? data['cliente'] ?? 'Cliente Desconocido',
      corte: data['corte'] ?? data['servicio'] ?? 'Servicio Estándar',
      precio: (data['precio'] ?? 0.0).toDouble(),
      fechaHora: fecha,
      estado: data['estado'] ?? 'pendiente',
      barbero: data['barberoNombre'] ?? data['barbero'] ?? 'Sin Asignar',
    );
  }
}

// ==========================================
// PANTALLA PRINCIPAL: AGENDA SCREEN
// ==========================================
Widget _buildTarjetaComisionBarbero(String uidBarbero) {
  final ahora = DateTime.now();
  final inicioHoy = DateTime(ahora.year, ahora.month, ahora.day);
  final finHoy = DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('citas')
        .where('barbero', isEqualTo: uidBarbero)
        .where('estado', isEqualTo: 'completada')
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const SizedBox.shrink();
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Sin comisiones registradas para este barbero.'),
          ),
        );
      }

      // Filtrado manual de fechas para evitar bloqueos de índice en Firestore
      final citasHoy = snapshot.data!.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['fechaHora'] == null) return false;
        final fecha = (data['fechaHora'] as Timestamp).toDate();
        return fecha.isAfter(inicioHoy) && fecha.isBefore(finHoy);
      }).toList();

      double totalGenerado = 0.0;
      for (var doc in citasHoy) {
        final data = doc.data() as Map<String, dynamic>;
        totalGenerado +=
            (data['precio'] ?? data['montoCobrado'] ?? 0).toDouble();
      }

      final comision = totalGenerado * 0.50;

      return Card(
        color: Colors.amber.shade100,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          leading: const Icon(Icons.monetization_on, color: Colors.amber),
          title:
              Text('Comisión de Hoy (50%): \$${comision.toStringAsFixed(2)}'),
          subtitle: Text(
              'Total generado: \$${totalGenerado.toStringAsFixed(2)} (${citasHoy.length} citas)'),
        ),
      );
    },
  );
}

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  String _vistaSeleccionada = 'hoy'; // 'hoy', 'proximas', 'historial'
  DateTime? _fechaFiltroPendientes;
  DateTimeRange? _rangoFechaHistorial;

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'en_proceso':
        return Colors.blue;
      case 'completada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getTextoEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_proceso':
        return 'En Sillón';
      case 'completada':
        return 'Completada';
      case 'cancelada':
        return 'Cancelada';
      default:
        return estado;
    }
  }

  Future<void> _seleccionarFechaPendientes() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaFiltroPendientes ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _fechaFiltroPendientes = picked;
      });
    }
  }

  Future<void> _seleccionarRangoFechas() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _rangoFechaHistorial ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
    );
    if (picked != null) {
      setState(() {
        _rangoFechaHistorial = picked;
      });
    }
  }

  Future<void> cambiarEstadoCita(
    String citaId,
    String nuevoEstado,
    String clienteRef, {
    double? monto,
    String? metodoPago,
    String? notas,
    File? fotoFile,
  }) async {
    try {
      Map<String, dynamic> updateData = {'estado': nuevoEstado};

      if (nuevoEstado == 'en_proceso') {
        updateData['inicioAtencion'] = FieldValue.serverTimestamp();
      } else if (nuevoEstado == 'completada') {
        updateData['finAtencion'] = FieldValue.serverTimestamp();
        if (monto != null) updateData['montoCobrado'] = monto;
        if (metodoPago != null) updateData['metodoPago'] = metodoPago;
        if (notas != null) updateData['notas'] = notas;
        if (fotoFile != null) {
          final bytes = await fotoFile.readAsBytes();
          updateData['fotoCorte'] =
              'data:image/jpeg;base64,${base64Encode(bytes)}';
        }

        // Sumar visita al cliente
        if (clienteRef.isNotEmpty) {
          final clienteDoc =
              FirebaseFirestore.instance.collection('clientes').doc(clienteRef);
          final snap = await clienteDoc.get();
          if (snap.exists) {
            await clienteDoc.update({'totalVisitas': FieldValue.increment(1)});
          }
        }
      }

      await FirebaseFirestore.instance
          .collection('citas')
          .doc(citaId)
          .update(updateData);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cambiar estado: $e')),
        );
      }
    }
  }

  void _asignarBarbero(BuildContext context, Cita cita) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Asignar Barbero'),
          content: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('barberos').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final docs = snapshot.data!.docs;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nombre = data['nombre'] ?? 'Sin nombre';
                  return ListTile(
                    title: Text(nombre),
                    onTap: () async {
                      await FirebaseFirestore.instance
                          .collection('citas')
                          .doc(cita.id)
                          .update({
                        'barbero': doc.id,
                        'barberoNombre': nombre,
                      });
                      if (context.mounted) Navigator.pop(context);
                    },
                  );
                }).toList(),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _agendarClientePresencial({
    required String nombre,
    required String telefono,
    required String servicio,
    required String barberoId,
    required String barberoNombre,
    required DateTime fechaHora,
    String? clienteId,
    double? precio,
  }) async {
    try {
      String idClienteFinal = clienteId ?? '';

      // Si NO se seleccionó un cliente registrado, lo creamos en la colección 'clientes'
      if (idClienteFinal.isEmpty && nombre.isNotEmpty) {
        final nuevoClienteRef =
            await FirebaseFirestore.instance.collection('clientes').add({
          'nombre': nombre,
          'telefono': telefono,
          'totalVisitas': 0, // Inicia en 0 hasta que complete su primera cita
          'creadoEn': FieldValue.serverTimestamp(),
        });
        idClienteFinal = nuevoClienteRef.id;
      }

      // Guardamos la cita vinculada al ID del cliente
      await FirebaseFirestore.instance.collection('citas').add({
        'clienteNombre': nombre,
        'clienteId': idClienteFinal,
        'telefono': telefono,
        'corte': servicio,
        'precio': precio ?? 0.0,
        'barbero': barberoId,
        'barberoNombre': barberoNombre,
        'fechaHora': Timestamp.fromDate(fechaHora),
        'estado': 'pendiente',
        'creadoEn': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cita y cliente registrados con éxito')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al agendar: $e')),
        );
      }
    }
  }

  void _mostrarModalAgendamientoRapido(BuildContext context) {
    final nombreCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    final precioCtrl = TextEditingController();

    String? clienteSeleccionadoId;
    String? servicioSeleccionado;
    String barberoSeleccionado = 'sin_asignar';
    String barberoNombreSeleccionado = 'Sin Asignar';
    DateTime fechaSeleccionada = DateTime.now();
    TimeOfDay horaSeleccionada = TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF9F6F0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            final DateTime fechaHoraFinal = DateTime(
              fechaSeleccionada.year,
              fechaSeleccionada.month,
              fechaSeleccionada.day,
              horaSeleccionada.hour,
              horaSeleccionada.minute,
            );

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 20,
                left: 20,
                right: 20,
              ),
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
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const Text(
                      'Registrar Cita / Presencial',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('clientes')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final docs = snapshot.data?.docs ?? [];
                        return DropdownButtonFormField<String>(
                          initialValue: clienteSeleccionadoId,
                          decoration: const InputDecoration(
                            labelText:
                                'Seleccionar Cliente Registrado (Opcional)',
                            prefixIcon: Icon(Icons.person_search),
                          ),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text(
                                  '-- O escribir un nuevo cliente abajo --'),
                            ),
                            ...docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return DropdownMenuItem<String>(
                                value: doc.id,
                                child: Text(data['nombre'] ?? 'Sin Nombre'),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            setStateModal(() {
                              clienteSeleccionadoId = val;
                              if (val != null) {
                                final clientDoc =
                                    docs.firstWhere((d) => d.id == val);
                                final cData =
                                    clientDoc.data() as Map<String, dynamic>;
                                nombreCtrl.text = cData['nombre'] ?? '';
                                telefonoCtrl.text = cData['telefono'] ?? '';
                              }
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nombreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Cliente',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: telefonoCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: fechaSeleccionada,
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 1)),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 90)),
                              );
                              if (picked != null) {
                                setStateModal(() => fechaSeleccionada = picked);
                              }
                            },
                            icon: const Icon(Icons.calendar_today,
                                size: 18, color: Color(0xFFB89B77)),
                            label: Text(DateFormat('dd/MM/yyyy')
                                .format(fechaSeleccionada)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: horaSeleccionada,
                              );
                              if (picked != null) {
                                setStateModal(() => horaSeleccionada = picked);
                              }
                            },
                            icon: const Icon(Icons.access_time,
                                size: 18, color: Color(0xFFB89B77)),
                            label: Text(horaSeleccionada.format(context)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('servicios')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final docs = snapshot.data?.docs ?? [];
                        return DropdownButtonFormField<String>(
                          initialValue: servicioSeleccionado,
                          hint: const Text('Seleccionar Servicio'),
                          decoration: const InputDecoration(
                            labelText: 'Servicio',
                            prefixIcon: Icon(Icons.content_cut),
                          ),
                          isExpanded: true,
                          items: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final nombre = data['nombre'] ?? 'Servicio';
                            final precio = (data['precio'] ?? 0.0).toDouble();
                            return DropdownMenuItem<String>(
                              value: nombre,
                              child: Text('$nombre (\$$precio)'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setStateModal(() {
                              servicioSeleccionado = val;
                              if (val != null && docs.isNotEmpty) {
                                final servDoc = docs.firstWhere((d) =>
                                    d.data() != null &&
                                    (d.data() as Map)['nombre'] == val);
                                final sData =
                                    servDoc.data() as Map<String, dynamic>;
                                precioCtrl.text =
                                    (sData['precio'] ?? 0.0).toString();
                              }
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('barberos')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final docs = snapshot.data?.docs ?? [];
                        return DropdownButtonFormField<String>(
                          initialValue: barberoSeleccionado,
                          decoration: const InputDecoration(
                            labelText: 'Barbero',
                            prefixIcon: Icon(Icons.badge),
                          ),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String>(
                              value: 'sin_asignar',
                              child: Text('Sin Asignar (Bolsa General)'),
                            ),
                            ...docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return DropdownMenuItem<String>(
                                value: doc.id,
                                child: Text(data['nombre'] ?? 'Barbero'),
                              );
                            }),
                          ],
                          // AHORA:
                          onChanged: (val) {
                            if (val != null) {
                              setStateModal(() {
                                barberoSeleccionado = val;
                                if (val == 'sin_asignar') {
                                  barberoNombreSeleccionado = 'Sin Asignar';
                                } else {
                                  final bDoc =
                                      docs.firstWhere((d) => d.id == val);
                                  final bData =
                                      bDoc.data() as Map<String, dynamic>;
                                  barberoNombreSeleccionado =
                                      bData['nombre'] ?? 'Barbero';
                                }
                              });
                            }
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: precioCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText:
                            'Precio (\$) (Opcional - Usará el valor del servicio)',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB89B77),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25)),
                        ),
                        onPressed: () async {
                          if (nombreCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Por favor ingresa el nombre del cliente')),
                            );
                            return;
                          }

                          final double pMonto =
                              double.tryParse(precioCtrl.text.trim()) ?? 0.0;

                          Navigator.pop(context);

                          await _agendarClientePresencial(
                            nombre: nombreCtrl.text.trim(),
                            telefono: telefonoCtrl.text.trim(),
                            servicio:
                                servicioSeleccionado ?? 'Corte Tradicional',
                            barberoId: barberoSeleccionado,
                            barberoNombre: barberoNombreSeleccionado,
                            fechaHora: fechaHoraFinal,
                            clienteId: clienteSeleccionadoId,
                            precio: pMonto,
                          );
                        },
                        child: const Text('Guardar Cita',
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? email = FirebaseAuth.instance.currentUser?.email;
    final bool esAdmin = email ==
        'alexandericardo21@outlook.com'; // Reemplaza 'admin@gmail.com' por el correo de tu cuenta admin
    final Query queryCitas =
        (_vistaSeleccionada == 'hoy' || _vistaSeleccionada == 'proximas')
            ? FirebaseFirestore.instance
                .collection('citas')
                .where('estado', whereIn: ['pendiente', 'en_proceso'])
            : FirebaseFirestore.instance
                .collection('citas')
                .where('estado', whereIn: ['completada', 'cancelada']);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!esAdmin)
                _buildTarjetaComisionBarbero(
                    FirebaseAuth.instance.currentUser?.uid ?? ''),
              const Text('Agenda de Citas',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'hoy',
                        label: Text('Hoy'),
                        icon: Icon(Icons.today),
                      ),
                      ButtonSegment<String>(
                        value: 'proximas',
                        label: Text('Pendientes'),
                        icon: Icon(Icons.calendar_month),
                      ),
                      ButtonSegment<String>(
                        value: 'historial',
                        label: Text('Historial'),
                        icon: Icon(Icons.history),
                      ),
                    ],
                    selected: {_vistaSeleccionada},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _vistaSeleccionada = newSelection.first;
                      });
                    },
                  ),
                ),
              ),
              if (_vistaSeleccionada == 'proximas') ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _seleccionarFechaPendientes,
                        icon: const Icon(Icons.filter_alt,
                            color: Color(0xFFB89B77)),
                        label: Text(
                          _fechaFiltroPendientes == null
                              ? 'Ver Todo el Pendiente'
                              : 'Día: ${DateFormat('dd/MM/yyyy').format(_fechaFiltroPendientes!)}',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFB89B77)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    if (_fechaFiltroPendientes != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.redAccent),
                        tooltip: 'Mostrar todas las pendientes',
                        onPressed: () {
                          setState(() {
                            _fechaFiltroPendientes = null;
                          });
                        },
                      ),
                    ]
                  ],
                ),
              ],
              if (_vistaSeleccionada == 'historial') ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _seleccionarRangoFechas,
                        icon: const Icon(Icons.date_range,
                            color: Color(0xFFB89B77)),
                        label: Text(
                          _rangoFechaHistorial == null
                              ? 'Mostrar Todo el Historial'
                              : '${DateFormat('dd/MM/yy').format(_rangoFechaHistorial!.start)} - ${DateFormat('dd/MM/yy').format(_rangoFechaHistorial!.end)}',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFB89B77)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    if (_rangoFechaHistorial != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.redAccent),
                        tooltip: 'Ver todo sin filtro',
                        onPressed: () {
                          setState(() {
                            _rangoFechaHistorial = null;
                          });
                        },
                      ),
                    ]
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: queryCitas.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFB89B77)));
                    }

                    if (snapshot.hasError) {
                      return Center(
                          child:
                              Text('Error al cargar citas: ${snapshot.error}'));
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Center(child: Text(_obtenerMensajeVacio()));
                    }

                    var citasConData = docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      final cita = Cita.fromFirestore(doc);
                      return {'cita': cita, 'data': data, 'doc': doc};
                    }).toList();

                    citasConData.sort((a, b) => (a['cita'] as Cita)
                        .fechaHora
                        .compareTo((b['cita'] as Cita).fechaHora));

                    final ahora = DateTime.now();

                    if (_vistaSeleccionada == 'hoy') {
                      citasConData = citasConData.where((item) {
                        final c = item['cita'] as Cita;
                        return c.fechaHora.year == ahora.year &&
                            c.fechaHora.month == ahora.month &&
                            c.fechaHora.day == ahora.day;
                      }).toList();
                    } else if (_vistaSeleccionada == 'proximas') {
                      if (_fechaFiltroPendientes != null) {
                        citasConData = citasConData.where((item) {
                          final c = item['cita'] as Cita;
                          return c.fechaHora.year ==
                                  _fechaFiltroPendientes!.year &&
                              c.fechaHora.month ==
                                  _fechaFiltroPendientes!.month &&
                              c.fechaHora.day == _fechaFiltroPendientes!.day;
                        }).toList();
                      }
                    } else if (_vistaSeleccionada == 'historial' &&
                        _rangoFechaHistorial != null) {
                      citasConData = citasConData.where((item) {
                        final c = item['cita'] as Cita;
                        return c.fechaHora.isAfter(_rangoFechaHistorial!.start
                                .subtract(const Duration(seconds: 1))) &&
                            c.fechaHora.isBefore(_rangoFechaHistorial!.end
                                .add(const Duration(seconds: 1)));
                      }).toList();
                    }

                    if (citasConData.isEmpty) {
                      return Center(child: Text(_obtenerMensajeVacio()));
                    }

                    return ListView.builder(
                      itemCount: citasConData.length,
                      itemBuilder: (context, index) {
                        final item = citasConData[index];
                        final cita = item['cita'] as Cita;
                        final docData = item['data'] as Map<String, dynamic>;

                        final horaStr =
                            DateFormat('hh:mm a').format(cita.fechaHora);
                        final fechaStr =
                            DateFormat('dd/MM/yyyy').format(cita.fechaHora);

                        final String clienteRef = docData['clienteId'] ??
                            docData['clienteReferencia'] ??
                            cita.cliente;
                        final String nombreMostrar = docData['clienteNombre'] ??
                            docData['cliente'] ??
                            cita.cliente;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(24)),
                                ),
                                builder: (context) => DetalleCitaModal(
                                  citaData: docData,
                                  citaId: cita.id,
                                ),
                              );
                            },
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getColorEstado(cita.estado)
                                    .withValues(alpha: 0.2),
                                child: Icon(Icons.access_time,
                                    color: _getColorEstado(cita.estado)),
                              ),
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      nombreMostrar,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getColorEstado(cita.estado)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _getTextoEstado(cita.estado),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: _getColorEstado(cita.estado),
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                  '${cita.corte} • \$${cita.precio.toStringAsFixed(2)}\nHora: $horaStr ($fechaStr)\nBarbero: ${cita.barbero}'),
                              isThreeLine: true,
                              trailing: PopupMenuButton<String>(
                                onSelected: (val) async {
                                  if (cita.estado == 'completada' && !esAdmin) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Las citas completadas son registros financieros y no se pueden modificar.',
                                          ),
                                        ),
                                      );
                                    }
                                    return;
                                  }

                                  if (val == 'eliminar') {
                                    await FirebaseFirestore.instance
                                        .collection('citas')
                                        .doc(cita.id)
                                        .delete();
                                  } else if (val == 'asignar_barbero') {
                                    _asignarBarbero(context, cita);
                                  } else if (val == 'completada') {
                                    final bool pasoPorSillon =
                                        cita.estado == 'en_proceso' ||
                                            docData['inicioAtencion'] != null;

                                    if (!pasoPorSillon) {
                                      await cambiarEstadoCita(
                                          cita.id, 'en_proceso', clienteRef);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'La cita cambió a "En Sillón". Haz clic en Completar nuevamente para finalizar el servicio.',
                                            ),
                                          ),
                                        );
                                      }
                                    } else {
                                      mostrarModalCierreServicio(
                                        context: context,
                                        citaId: cita.id,
                                        clienteRef: clienteRef,
                                        precioSugerido: cita.precio,
                                        onConfirmar:
                                            (monto, metodo, notas, foto) async {
                                          await cambiarEstadoCita(
                                            cita.id,
                                            'completada',
                                            clienteRef,
                                            monto: monto,
                                            metodoPago: metodo,
                                            notas: notas,
                                            fotoFile: foto,
                                          );
                                        },
                                      );
                                    }
                                  } else {
                                    await cambiarEstadoCita(
                                        cita.id, val, clienteRef);
                                  }
                                },
                                itemBuilder: (context) => [
                                  if (cita.estado != 'completada' ||
                                      esAdmin) ...[
                                    const PopupMenuItem(
                                        value: 'asignar_barbero',
                                        child: Row(children: [
                                          Icon(Icons.person_add_alt_1,
                                              size: 18),
                                          SizedBox(width: 8),
                                          Text('Asignar Barbero')
                                        ])),
                                    const PopupMenuDivider(),
                                    const PopupMenuItem(
                                        value: 'pendiente',
                                        child: Text('Estado: Pendiente')),
                                    const PopupMenuItem(
                                        value: 'en_proceso',
                                        child: Text('Estado: En Sillón')),
                                    const PopupMenuItem(
                                        value: 'completada',
                                        child: Text('Estado: Completada')),
                                    const PopupMenuItem(
                                        value: 'cancelada',
                                        child: Text('Estado: Cancelada')),
                                  ],
                                  if (esAdmin) ...[
                                    const PopupMenuDivider(),
                                    const PopupMenuItem(
                                        value: 'eliminar',
                                        child: Text('Eliminar Cita',
                                            style:
                                                TextStyle(color: Colors.red))),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarModalAgendamientoRapido(context),
        backgroundColor: const Color(0xFFB89B77),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Agendar Presencial',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  String _obtenerMensajeVacio() {
    if (_vistaSeleccionada == 'hoy') {
      return 'No hay citas programadas para el día de hoy.';
    } else if (_vistaSeleccionada == 'proximas') {
      return _fechaFiltroPendientes != null
          ? 'No hay citas pendientes para el día seleccionado.'
          : 'No tienes citas pendientes registradas.';
    } else if (_vistaSeleccionada == 'historial') {
      return 'No hay citas registradas en el historial para estas fechas.';
    }
    return 'No hay citas disponibles.';
  }
}

Widget construirFotoCorte(String? fotoUrl) {
  if (fotoUrl == null || fotoUrl.isEmpty) {
    return const Icon(Icons.image_not_supported, color: Colors.grey, size: 40);
  }

  if (fotoUrl.startsWith('data:image')) {
    try {
      final bytes = base64Decode(fotoUrl.split(',').last);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(bytes, width: 80, height: 80, fit: BoxFit.cover),
      );
    } catch (e) {
      return const Icon(Icons.broken_image, size: 40);
    }
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.network(fotoUrl, width: 80, height: 80, fit: BoxFit.cover),
  );
}
