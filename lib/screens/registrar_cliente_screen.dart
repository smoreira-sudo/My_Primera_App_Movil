import 'package:flutter/material.dart';
import 'package:my_primera_app_movil/models/cliente_model.dart';

class RegistrarClienteScreen extends StatefulWidget {
  const RegistrarClienteScreen({super.key});

  @override
  State<RegistrarClienteScreen> createState() => _RegistrarClienteScreenState();
}

class _RegistrarClienteScreenState extends State<RegistrarClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _recetaController = TextEditingController();
  bool _aplicarPromocion = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Cliente Presencial'),
        backgroundColor: const Color(0xFFB89B77),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Ingrese el nombre' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono / WhatsApp',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Ingrese el teléfono' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _recetaController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Receta de Corte (Opcional)',
                  hintText: 'Ej: Máquina 2 a los lados, tijera arriba',
                  prefixIcon: Icon(Icons.content_cut),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('¿Aplicar Promoción Directa?'),
                subtitle: const Text('Descuento especial por registro rápido'),
                value: _aplicarPromocion,
                activeThumbColor: const Color(0xFFB89B77),
                onChanged: (val) {
                  setState(() {
                    _aplicarPromocion = val;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Se usan exactamente los nombres de tu modelo (recetaCorte y tienePromocion)
                    final nuevoCliente = Cliente(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      nombre: _nombreController.text.trim(),
                      telefono: _telefonoController.text.trim(),
                      recetaCorte: _recetaController.text.trim().isEmpty 
                          ? null 
                          : _recetaController.text.trim(),
                      tienePromocion: _aplicarPromocion,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Cliente ${nuevoCliente.nombre} registrado con éxito')),
                    );

                    Navigator.pop(context, nuevoCliente);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB89B77),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Guardar Cliente', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}