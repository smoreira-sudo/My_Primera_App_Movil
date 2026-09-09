import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../main.dart'; // Importa modelos Barbero y Cita

class RegistrarClienteScreen extends StatefulWidget {
  const RegistrarClienteScreen({super.key});

  @override
  State<RegistrarClienteScreen> createState() => _RegistrarClienteScreenState();
}

class _RegistrarClienteScreenState extends State<RegistrarClienteScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _precioController = TextEditingController();

  String? _clienteIdSeleccionado;
  String? _servicioIdSeleccionado;
  String? _barberoIdSeleccionado;

  DateTime _fechaSeleccionada = DateTime.now();
  TimeOfDay _horaSeleccionada = TimeOfDay.now();

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _fechaSeleccionada = picked);
    }
  }

  Future<void> _seleccionarHora(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada,
    );
    if (picked != null) {
      setState(() => _horaSeleccionada = picked);
    }
  }

  void _guardarCita() async {
    if (_formKey.currentState!.validate()) {
      final String nombre = _nombreController.text.trim();
      final String telefono = _telefonoController.text.trim();

      // BÚSQUEDA Y PRECIO DEL SERVICIO
      String corte = 'Servicio General';
      double precioBaseServicio = 0.0;

      if (_servicioIdSeleccionado != null) {
        final docServicio = await FirebaseFirestore.instance
            .collection('servicios')
            .doc(_servicioIdSeleccionado)
            .get();

        if (docServicio.exists) {
          final dataServ = docServicio.data();
          corte = dataServ?['nombre'] ?? 'Servicio General';
          precioBaseServicio = (dataServ?['precio'] ?? 0).toDouble();
        }
      }

      final double precioManual = double.tryParse(_precioController.text.trim()) ?? 0.0;
      final double precioFinal = precioManual > 0 ? precioManual : precioBaseServicio;

      final String barberoId = _barberoIdSeleccionado ?? 'sin_asignar';

      final DateTime fechaHoraFinal = DateTime(
        _fechaSeleccionada.year,
        _fechaSeleccionada.month,
        _fechaSeleccionada.day,
        _horaSeleccionada.hour,
        _horaSeleccionada.minute,
      );

      const int duracionEstimada = 30;
      final DateTime fechaFinFinal = fechaHoraFinal.add(const Duration(minutes: duracionEstimada));

      String barberoNombre = 'Sin Asignar';

      // 1. VALIDACIONES DE BARBERO
      if (barberoId != 'sin_asignar') {
        final docBarbero = await FirebaseFirestore.instance.collection('barberos').doc(barberoId).get();

        if (docBarbero.exists) {
          final barbero = Barbero.fromFirestore(docBarbero);
          barberoNombre = barbero.nombre;

          final diaSemana = fechaHoraFinal.weekday;
          if (barbero.diasDescanso.contains(diaSemana)) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('⚠️ ${barbero.nombre} no trabaja el día seleccionado.'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
            return;
          }
        }

        final snapshotCitas = await FirebaseFirestore.instance
            .collection('citas')
            .where('barberoId', isEqualTo: barberoId)
            .get();

        final citasExistentes = snapshotCitas.docs.map((doc) => Cita.fromFirestore(doc)).toList();

        for (var c in citasExistentes) {
          if (c.estado != 'cancelada') {
            if (fechaHoraFinal.isBefore(c.fechaFin) && fechaFinFinal.isAfter(c.fechaHora)) {
              final horaConflicto = DateFormat('hh:mm a').format(c.fechaHora);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('⚠️ Solapamiento: $barberoNombre ya tiene cita reservada a las $horaConflicto.'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
              return;
            }
          }
        }
      }

      // 2. BUSCAR O REGISTRAR CLIENTE
      String clienteId = _clienteIdSeleccionado ?? '';

      // Si no se seleccionó de la lista desplegable, intentamos buscarlo por Teléfono o Nombre
      if (clienteId.isEmpty) {
        QuerySnapshot queryCliente;
        if (telefono.isNotEmpty) {
          queryCliente = await FirebaseFirestore.instance
              .collection('clientes')
              .where('telefono', isEqualTo: telefono)
              .limit(1)
              .get();
        } else {
          queryCliente = await FirebaseFirestore.instance
              .collection('clientes')
              .where('nombre', isEqualTo: nombre)
              .limit(1)
              .get();
        }

        if (queryCliente.docs.isNotEmpty) {
          clienteId = queryCliente.docs.first.id;
        } else {
          // Si no existe ni por teléfono ni por nombre, creamos el nuevo cliente
          final nuevoClienteRef = await FirebaseFirestore.instance.collection('clientes').add({
            'nombre': nombre,
            'telefono': telefono.isEmpty ? 'Sin teléfono' : telefono,
            'notasGenerales': 'Registrado desde cita presencial',
            'totalVisitas': 0, // Se sumará al completar la cita
            'ultimaVisita': FieldValue.serverTimestamp(),
            'fechaRegistro': FieldValue.serverTimestamp(),
            'barberiaId': 'barberia_default',
          });
          clienteId = nuevoClienteRef.id;
        }
      }

      // 3. GUARDAR CITA VINCULADA
      await FirebaseFirestore.instance.collection('citas').add({
        'cliente': nombre,
        'telefono': telefono,
        'clienteId': clienteId,
        'corte': corte,
        'precio': precioFinal,
        'barberoId': barberoId,
        'barbero': barberoNombre,
        'fechaHora': Timestamp.fromDate(fechaHoraFinal),
        'estado': 'pendiente',
        'duracionMinutos': duracionEstimada,
        'barberiaId': 'barberia_default',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Cita registrada correctamente!')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fechaFormat = DateFormat('dd/MM/yyyy').format(_fechaSeleccionada);
    final horaFormat = _horaSeleccionada.format(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Cita / Presencial'),
        backgroundColor: const Color(0xFFF4EFE6),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SELECTOR AUTOCOMPLETADO DE CLIENTES EXISTENTES
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('clientes').snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];

                  return DropdownButtonFormField<String>(
                    initialValue: _clienteIdSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar Cliente Registrado (Opcional)',
                      prefixIcon: Icon(Icons.person_search),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('-- O escribir un nuevo cliente abajo --'),
                      ),
                      ...docs.map((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final nom = data['nombre'] ?? 'Sin Nombre';
                        final tel = data['telefono'] ?? '';
                        return DropdownMenuItem<String>(
                          value: d.id,
                          child: Text('$nom ${tel.isNotEmpty ? "($tel)" : ""}'),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _clienteIdSeleccionado = val;
                        if (val != null) {
                          final clienteDoc = docs.firstWhere((d) => d.id == val);
                          final data = clienteDoc.data() as Map<String, dynamic>;
                          _nombreController.text = data['nombre'] ?? '';
                          _telefonoController.text = data['telefono'] ?? '';
                        }
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre del Cliente', prefixIcon: Icon(Icons.person)),
                validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Teléfono', prefixIcon: Icon(Icons.phone)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _seleccionarFecha(context),
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(fechaFormat),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _seleccionarHora(context),
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(horaFormat),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('servicios').snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];

                  return DropdownButtonFormField<String>(
                    initialValue: _servicioIdSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Servicio',
                      prefixIcon: Icon(Icons.content_cut),
                    ),
                    items: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final nombreServicio = data['nombre'] ?? 'Servicio';
                      final precioServicio = data['precio'] ?? 0;
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text('$nombreServicio (\$$precioServicio)'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _servicioIdSeleccionado = val),
                  );
                },
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('barberos').snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];

                  return DropdownButtonFormField<String>(
                    initialValue: _barberoIdSeleccionado ?? 'sin_asignar',
                    decoration: const InputDecoration(labelText: 'Barbero', prefixIcon: Icon(Icons.badge)),
                    items: [
                      const DropdownMenuItem(value: 'sin_asignar', child: Text('Sin Asignar (Bolsa General)')),
                      ...docs.map((d) {
                        final data = d.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: d.id,
                          child: Text(data['nombre'] ?? 'Sin nombre'),
                        );
                      }),
                    ],
                    onChanged: (val) => setState(() => _barberoIdSeleccionado = val),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _precioController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Precio (\$) (Opcional - Usará el valor del servicio)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardarCita,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB89B77),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Guardar Cita', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}