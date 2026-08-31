import 'package:flutter/material.dart';
import '../main.dart'; // Importa el modelo Cita

class RegistrarClienteScreen extends StatefulWidget {
  const RegistrarClienteScreen({super.key});

  @override
  State<RegistrarClienteScreen> createState() => _RegistrarClienteScreenState();
}

class _RegistrarClienteScreenState extends State<RegistrarClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  // Lista de servicios con sus precios reales
  final List<Map<String, dynamic>> _servicios = [
    {'nombre': 'Corte degradado medio', 'precio': 15.0},
    {'nombre': 'Corte clásico con tijera', 'precio': 12.0},
    {'nombre': 'Barba Completa / Perfilado', 'precio': 8.0},
    {'nombre': 'Combo Corte + Barba', 'precio': 20.0},
  ];

  final List<String> _barberos = ['Alex', 'Mateo'];

  String _servicioSeleccionado = 'Corte degradado medio';
  double _precioSeleccionado = 15.0;
  String _barberoSeleccionado = 'Alex';

  void _guardarCliente() {
    if (_formKey.currentState!.validate()) {
      // Creamos la cita real con todos los valores seleccionados
      final nuevaCita = Cita(
        cliente: _nombreCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim().isEmpty ? 'Sin teléfono' : _telefonoCtrl.text.trim(),
        corte: _servicioSeleccionado,
        precio: _precioSeleccionado,
        barbero: _barberoSeleccionado,
        fecha: DateTime.now(),
      );

      // Notificación rápida
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cliente y servicio registrados con éxito'),
          backgroundColor: Colors.green,
        ),
      );

      // Retornamos la cita directamente al Main Navigation
      Navigator.pop(context, nuevaCita);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Cliente Presencial'),
        backgroundColor: const Color(0xFFF4EFE6),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CAMPOS DE TEXTO
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Cliente',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Ingresa el nombre del cliente' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (Opcional)',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // SELECCIÓN DE SERVICIO Y PRECIO
              const Text('Servicio Realizado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _servicioSeleccionado,
                    items: _servicios.map((serv) {
                      return DropdownMenuItem<String>(
                        value: serv['nombre'],
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(serv['nombre']),
                            Text(
                              '\$${serv['precio'].toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _servicioSeleccionado = val;
                          _precioSeleccionado = _servicios.firstWhere((s) => s['nombre'] == val)['precio'];
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // SELECCIÓN DE BARBERO
              const Text('Atendido por', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _barberoSeleccionado,
                    items: _barberos.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _barberoSeleccionado = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // BOTÓN GUARDAR
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _guardarCliente,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB89B77),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Completar Registro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}