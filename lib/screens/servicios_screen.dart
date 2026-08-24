import 'package:flutter/material.dart';
import 'package:exclusive_barber/models/servicio_model.dart'; // O 'package:tu_proyecto/servicio_model.dart' según dónde guardaste el modelo

class ServiciosScreen extends StatefulWidget {
  const ServiciosScreen({super.key});

  @override
  State<ServiciosScreen> createState() => _ServiciosScreenState();
}

class _ServiciosScreenState extends State<ServiciosScreen> {
  // Lista dinámica de servicios (ahora sí se puede modificar)
  final List<Servicio> _servicios = [
    Servicio(id: '1', nombre: 'Corte Tradicional', precio: 12.00, duracionMinutos: 30),
    Servicio(id: '2', nombre: 'Corte + Barba', precio: 18.00, duracionMinutos: 45),
    Servicio(id: '3', nombre: 'Perfilado de Barba', precio: 8.00, duracionMinutos: 20),
  ];

  // Controladores para el formulario de nuevo servicio
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _duracionController = TextEditingController();

  void _agregarServicio() {
    final String nombre = _nombreController.text.trim();
    final double? precio = double.tryParse(_precioController.text);
    final int? duracion = int.tryParse(_duracionController.text);

    if (nombre.isNotEmpty && precio != null && duracion != null) {
      setState(() {
        _servicios.add(
          Servicio(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            nombre: nombre,
            precio: precio,
            duracionMinutos: duracion,
          ),
        );
      });

      _nombreController.clear();
      _precioController.clear();
      _duracionController.clear();
      Navigator.pop(context);
    }
  }

  void _sincronizarConWeb() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sincronizando servicios con la página web...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _mostrarFormularioNuevoServicio() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nuevo Servicio',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del servicio',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _precioController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Precio (\$)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _duracionController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duración (min)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _agregarServicio,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB89B77),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Guardar Servicio', style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Catálogo de Servicios'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            tooltip: 'Publicar cambios en la Web',
            onPressed: _sincronizarConWeb,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormularioNuevoServicio,
        backgroundColor: const Color(0xFFB89B77),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _servicios.isEmpty
          ? const Center(child: Text('No hay servicios registrados.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _servicios.length,
              itemBuilder: (context, index) {
                final servicio = _servicios[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFB89B77),
                      child: Icon(Icons.content_cut, color: Colors.white, size: 20),
                    ),
                    title: Text(servicio.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${servicio.duracionMinutos} min'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '\$${servicio.precio.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () {
                            setState(() {
                              _servicios.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}