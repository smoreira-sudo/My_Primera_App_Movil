import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void mostrarModalCierreServicio({
  required BuildContext context,
  required String citaId,
  required String clienteRef,
  required double precioSugerido,
  required Future<void> Function(double monto, String metodo, String notas, File? foto) onConfirmar,
}) {
  final TextEditingController precioController =
      TextEditingController(text: precioSugerido.toStringAsFixed(2));
  final TextEditingController notasController = TextEditingController();
  
  String metodoSeleccionado = 'efectivo';
  File? imagenSeleccionada;
  bool cargando = false; // Control de estado de carga
  final ImagePicker picker = ImagePicker();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setStateModal) {
          
          Future<void> seleccionarImagen(ImageSource source) async {
            try {
              // OPTIMIZACIÓN: Compresión automática (<300KB)
              final XFile? pickedFile = await picker.pickImage(
                source: source,
                imageQuality: 50, // Reduce la calidad al 50%
                maxWidth: 800,    // Redimensiona el ancho a un máximo de 800px
              );
              if (pickedFile != null) {
                setStateModal(() {
                  imagenSeleccionada = File(pickedFile.path);
                });
              }
            } catch (e) {
              debugPrint("Error seleccionando imagen: $e");
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Finalizar y Cobrar Servicio',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  // 1. Campo de Precio
                  TextField(
                    controller: precioController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: !cargando,
                    decoration: const InputDecoration(
                      labelText: 'Monto a Cobrar (\$)',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 2. Método de Pago
                  const Text('Método de Pago:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Efectivo'),
                        selected: metodoSeleccionado == 'efectivo',
                        onSelected: cargando ? null : (_) => setStateModal(() => metodoSeleccionado = 'efectivo'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Tarjeta'),
                        selected: metodoSeleccionado == 'tarjeta',
                        onSelected: cargando ? null : (_) => setStateModal(() => metodoSeleccionado = 'tarjeta'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Transfer.'),
                        selected: metodoSeleccionado == 'transferencia',
                        onSelected: cargando ? null : (_) => setStateModal(() => metodoSeleccionado = 'transferencia'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // 3. Recuadro de Foto del Corte
                  const Text('Foto del Resultado:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 130,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.shade100,
                    ),
                    child: imagenSeleccionada != null
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  imagenSeleccionada!,
                                  width: double.infinity,
                                  height: 130,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if (!cargando)
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black54,
                                    radius: 16,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.close, size: 18, color: Colors.white),
                                      onPressed: () {
                                        setStateModal(() => imagenSeleccionada = null);
                                      },
                                    ),
                                  ),
                                )
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.camera_alt, color: Colors.black),
                                label: const Text('Cámara', style: TextStyle(color: Colors.black)),
                                onPressed: cargando ? null : () => seleccionarImagen(ImageSource.camera),
                              ),
                              const VerticalDivider(indent: 20, endIndent: 20),
                              TextButton.icon(
                                icon: const Icon(Icons.photo_library, color: Colors.black),
                                label: const Text('Galería', style: TextStyle(color: Colors.black)),
                                onPressed: cargando ? null : () => seleccionarImagen(ImageSource.gallery),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 15),

                  // 4. Notas / Referencia
                  TextField(
                    controller: notasController,
                    enabled: !cargando,
                    decoration: const InputDecoration(
                      labelText: 'Notas / Referencia del corte (opcional)',
                      prefixIcon: Icon(Icons.note_alt_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 5. Botón Confirmar
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: cargando
                          ? null
                          : () async {
                              setStateModal(() => cargando = true);

                              final double montoFinal =
                                  double.tryParse(precioController.text) ?? precioSugerido;

                              // Llama a la función asíncrona de guardado
                              await onConfirmar(
                                montoFinal,
                                metodoSeleccionado,
                                notasController.text.trim(),
                                imagenSeleccionada,
                              );

                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                            },
                      child: cargando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Completar y Guardar Finanzas'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}