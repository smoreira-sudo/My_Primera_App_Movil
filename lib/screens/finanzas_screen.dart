// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FinanzasScreen extends StatefulWidget {
  const FinanzasScreen({super.key});

  @override
  State<FinanzasScreen> createState() => _FinanzasScreenState();
}

class _FinanzasScreenState extends State<FinanzasScreen> {
  String _filtroSeleccionado = 'Esta Semana';
  DateTimeRange? _rangoPersonalizado;
  final double _porcentajeComision = 0.50;

  DateTime meSuprimeDias(DateTime fecha, int dias) {
    return fecha.subtract(Duration(days: dias));
  }

  Future<void> _seleccionarRangoFechas() async {
    final DateTimeRange? rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _rangoPersonalizado ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFB8977E),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (rango != null) {
      setState(() {
        _rangoPersonalizado = rango;
        _filtroSeleccionado = 'Personalizado';
      });
    }
  }

  void _mostrarDetalleBarbero(
    BuildContext context,
    String nombreBarbero,
    List<Map<String, dynamic>> citas,
  ) {
    final double totalGenerado = citas.fold(
      0.0,
      (acumulado, item) =>
          acumulado + ((item['monto'] ?? item['precio']) ?? 0.0).toDouble(),
    );
    final double comision = totalGenerado * _porcentajeComision;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFFF8F5F2),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                nombreBarbero,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cortes realizados: ${citas.length}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  Text(
                    'Comisión total: \$${comision.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFFB8977E),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: citas.isEmpty
                    ? const Center(child: Text('No hay registros de citas'))
                    : ListView.builder(
                        itemCount: citas.length,
                        itemBuilder: (context, index) {
                          final cita = citas[index];
                          final precio =
                              ((cita['monto'] ?? cita['precio']) ?? 0.0)
                                  .toDouble();
                          final servicio = cita['servicio'] ?? 'Corte general';
                          final cliente = cita['clienteNombre'] ??
                              cita['cliente'] ??
                              'Cliente';

                          final rawFecha = cita['fechaHora'] ?? cita['fecha'];
                          String fechaTexto = 'Sin fecha';
                          if (rawFecha is Timestamp) {
                            fechaTexto = DateFormat('dd/MM/yyyy hh:mm a')
                                .format(rawFecha.toDate());
                          } else if (rawFecha is String) {
                            final parsed = DateTime.tryParse(rawFecha);
                            if (parsed != null) {
                              fechaTexto = DateFormat('dd/MM/yyyy hh:mm a')
                                  .format(parsed);
                            }
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(
                                servicio,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text('$cliente • $fechaTexto'),
                              trailing: Text(
                                '\$${precio.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _generarReportePdf({
    required double totalIngresos,
    required double ticketPromedio,
    required int totalCortes,
    required double promedioCitasDiarias,
    required Map<String, double> ingresosPorBarbero,
    required Map<String, List<Map<String, dynamic>>> citasPorBarbero,
    required Map<String, double> desgloseMetodos,
    required Map<String, String> nombresBarberosMap,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Reporte de Finanzas',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Text('Filtro: $_filtroSeleccionado'),
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Resumen General',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                    'Ingresos Totales: \$${totalIngresos.toStringAsFixed(2)}'),
                pw.Text('Total Cortes: $totalCortes'),
                pw.Text(
                    'Ticket Promedio: \$${ticketPromedio.toStringAsFixed(2)}'),
                pw.Text(
                    'Promedio Citas Diarias: ${promedioCitasDiarias.toStringAsFixed(1)}'),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Desglose Métodos de Pago',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                    'Efectivo: \$${(desgloseMetodos['efectivo'] ?? 0.0).toStringAsFixed(2)}'),
                pw.Text(
                    'Tarjeta: \$${(desgloseMetodos['tarjeta'] ?? 0.0).toStringAsFixed(2)}'),
                pw.Text(
                    'Transferencia: \$${(desgloseMetodos['transferencia'] ?? 0.0).toStringAsFixed(2)}'),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Rendimiento por Barbero',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                ...ingresosPorBarbero.entries.map((entry) {
                  final idBarbero = entry.key;
                  final nombre = nombresBarberosMap[idBarbero] ?? idBarbero;
                  final totalGenerado = entry.value;
                  final comision = totalGenerado * _porcentajeComision;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(nombre),
                        pw.Text(
                            'Total: \$${totalGenerado.toStringAsFixed(2)} | Comisión: \$${comision.toStringAsFixed(2)}'),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('usuarios').get(),
      builder: (context, usuariosSnapshot) {
        final Map<String, String> mapaBarberosNombres = {};
        if (usuariosSnapshot.hasData) {
          for (var doc in usuariosSnapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final nombre =
                data['nombre'] ?? data['nombreCompleto'] ?? data['displayName'];
            if (nombre != null) {
              mapaBarberosNombres[doc.id] = nombre.toString();
            }
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('citas').snapshots(),
          builder: (context, snapshot) {
            double totalIngresos = 0.0;
            int totalCortes = 0;
            double ticketPromedio = 0.0;
            double promedioCitasDiarias = 0.0;
            Map<String, double> ingresosPorBarbero = {};
            Map<String, List<Map<String, dynamic>>> citasPorBarbero = {};
            Map<String, double> ingresosTotalesPorDia = {};
            int sumaMinutosTotales = 0;
            int citasConTiempoValido = 0;
            int promedioAtencion = 0;

            double totalEfectivo = 0.0;
            double totalTarjeta = 0.0;
            double totalTransferencia = 0.0;

            if (snapshot.hasData) {
              final docs = snapshot.data!.docs;
              final ahora = DateTime.now().toLocal();

              final docsFiltrados = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                if ((data['estado'] ?? '') != 'completada') return false;

                final rawFecha = data['fechaHora'] ?? data['fecha'];
                if (rawFecha == null) return false;

                DateTime? fechaDoc;
                if (rawFecha is Timestamp) {
                  fechaDoc = rawFecha.toDate().toLocal();
                } else if (rawFecha is String) {
                  fechaDoc = DateTime.tryParse(rawFecha)?.toLocal();
                }

                if (fechaDoc == null) return false;

                if (_filtroSeleccionado == 'Hoy') {
                  return fechaDoc.year == ahora.year &&
                      fechaDoc.month == ahora.month &&
                      fechaDoc.day == ahora.day;
                } else if (_filtroSeleccionado == 'Este Mes') {
                  return fechaDoc.year == ahora.year &&
                      fechaDoc.month == ahora.month;
                } else if (_filtroSeleccionado == 'Esta Semana') {
                  final diferenciaDias =
                      meSuprimeDias(ahora, 0).difference(fechaDoc).inDays;
                  return diferenciaDias >= 0 && diferenciaDias < 7;
                } else if (_filtroSeleccionado == 'Personalizado' &&
                    _rangoPersonalizado != null) {
                  final inicio = DateTime(
                    _rangoPersonalizado!.start.year,
                    _rangoPersonalizado!.start.month,
                    _rangoPersonalizado!.start.day,
                  );
                  final fin = DateTime(
                    _rangoPersonalizado!.end.year,
                    _rangoPersonalizado!.end.month,
                    _rangoPersonalizado!.end.day,
                    23,
                    59,
                    59,
                  );
                  return fechaDoc.isAfter(
                          inicio.subtract(const Duration(seconds: 1))) &&
                      fechaDoc.isBefore(fin);
                }

                return true;
              }).toList();

              totalCortes = docsFiltrados.length;

              for (var doc in docsFiltrados) {
                final data = doc.data() as Map<String, dynamic>;
                sumaMinutosTotales = 0;
                citasConTiempoValido = 0;
                final precio =
                    ((data['monto'] ?? data['precio']) ?? 0.0).toDouble();

                final idOClaveBarbero =
                    data['barberoId'] ?? data['barbero'] ?? 'Sin asignar';

                String nombreMostrar =
                    data['barberoNombre'] ?? data['nombreBarbero'] ?? '';
                if (nombreMostrar.isEmpty) {
                  nombreMostrar =
                      mapaBarberosNombres[idOClaveBarbero] ?? idOClaveBarbero;
                }

                final metodo = (data['metodoPago'] ?? data['metodo'] ?? '')
                    .toString()
                    .toLowerCase();

                totalIngresos += precio;

                if (metodo.contains('efectivo')) {
                  totalEfectivo += precio;
                } else if (metodo.contains('tarjeta')) {
                  totalTarjeta += precio;
                } else if (metodo.contains('transferencia')) {
                  totalTransferencia += precio;
                } else {
                  totalEfectivo += precio;
                }

                ingresosPorBarbero[idOClaveBarbero] =
                    (ingresosPorBarbero[idOClaveBarbero] ?? 0.0) + precio;

                citasPorBarbero.putIfAbsent(idOClaveBarbero, () => []).add({
                  ...data,
                  'nombreBarberoResuelto': nombreMostrar,
                });

                final rawFecha = data['fechaHora'] ?? data['fecha'];
                DateTime? fechaDoc;
                if (rawFecha is Timestamp) {
                  fechaDoc = rawFecha.toDate().toLocal();
                } else if (rawFecha is String) {
                  fechaDoc = DateTime.tryParse(rawFecha)?.toLocal();
                }

                if (fechaDoc != null) {
                  final String claveDia =
                      DateFormat('yyyy-MM-dd').format(fechaDoc);
                  ingresosTotalesPorDia[claveDia] =
                      (ingresosTotalesPorDia[claveDia] ?? 0.0) + precio;
                }
              }

              if (totalCortes > 0) {
                ticketPromedio = totalIngresos / totalCortes;
              }

              final int diasConDatos = ingresosTotalesPorDia.length;
              if (diasConDatos > 0) {
                promedioCitasDiarias = totalCortes / diasConDatos;
              }
              promedioAtencion = citasConTiempoValido > 0
                  ? (sumaMinutosTotales / citasConTiempoValido).round()
                  : 0;
            }

            final Map<String, double> desgloseMetodos = {
              'efectivo': totalEfectivo,
              'tarjeta': totalTarjeta,
              'transferencia': totalTransferencia,
            };

            return Scaffold(
              backgroundColor: const Color(0xFFF8F5F2),
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: const Text(
                  'Finanzas & Reportes',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 22),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.black),
                    onPressed: () => _generarReportePdf(
                      totalIngresos: totalIngresos,
                      ticketPromedio: ticketPromedio,
                      totalCortes: totalCortes,
                      promedioCitasDiarias: promedioCitasDiarias,
                      ingresosPorBarbero: ingresosPorBarbero,
                      citasPorBarbero: citasPorBarbero,
                      desgloseMetodos: desgloseMetodos,
                      nombresBarberosMap: mapaBarberosNombres,
                    ),
                  ),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: const [
                        'Hoy',
                        'Esta Semana',
                        'Este Mes',
                        'Personalizado'
                      ].map((filtro) {
                        final bool selected = _filtroSeleccionado == filtro;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Row(
                              children: [
                                if (selected)
                                  const Icon(Icons.check,
                                      size: 16, color: Colors.white),
                                if (selected) const SizedBox(width: 4),
                                Text(filtro),
                              ],
                            ),
                            selected: selected,
                            selectedColor: const Color(0xFFB8977E),
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : Colors.black87,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            onSelected: (bool isSelected) {
                              if (filtro == 'Personalizado') {
                                _seleccionarRangoFechas();
                              } else {
                                setState(() {
                                  _filtroSeleccionado = filtro;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _buildMetricCard(
                        titulo: 'Ingresos Totales',
                        valor: '\$${totalIngresos.toStringAsFixed(2)}',
                      ),
                      _buildMetricCard(
                        titulo: 'Ticket Promedio',
                        valor: '\$${ticketPromedio.toStringAsFixed(2)}',
                      ),
                      _buildMetricCard(
                        titulo: 'Total Cortes',
                        valor: '$totalCortes',
                        icon: Icons.content_cut,
                        iconColor: Colors.orange,
                      ),
                      _buildMetricCard(
                        titulo: 'Citas / Día',
                        valor: promedioCitasDiarias.toStringAsFixed(1),
                        icon: Icons.trending_up,
                        iconColor: Colors.purple,
                      ),
                      _buildMetricCard(
                        titulo: 'Tiempo Medio',
                        valor: '$promedioAtencion min',
                        icon: Icons.timer,
                        iconColor: Colors.blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  IngresosPorDiaExpandableCard(
                      docs: snapshot.hasData ? snapshot.data!.docs : const []),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Desglose por Método de Pago',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _itemMetodoPago(
                              icon: Icons.payments_outlined,
                              titulo: 'Efectivo',
                              monto: totalEfectivo,
                              color: Colors.green,
                            ),
                            _itemMetodoPago(
                              icon: Icons.credit_card,
                              titulo: 'Tarjeta',
                              monto: totalTarjeta,
                              color: Colors.blue,
                            ),
                            _itemMetodoPago(
                              icon: Icons.account_balance_outlined,
                              titulo: 'Transferencia',
                              monto: totalTransferencia,
                              color: Colors.orange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Comisiones del Equipo (50%)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Toca un barbero para ver sus tiempos y cortes',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  if (ingresosPorBarbero.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                            'No hay datos disponibles para el rango seleccionado.'),
                      ),
                    )
                  else
                    ...ingresosPorBarbero.entries.map((entry) {
                      final claveBarbero = entry.key;
                      final totalGenerado = entry.value;
                      final comision = totalGenerado * _porcentajeComision;
                      final listaCitas = citasPorBarbero[claveBarbero] ?? [];

                      final barberoNombre = listaCitas.isNotEmpty
                          ? (listaCitas.first['nombreBarberoResuelto'] ??
                              mapaBarberosNombres[claveBarbero] ??
                              claveBarbero)
                          : (mapaBarberosNombres[claveBarbero] ?? claveBarbero);

                      final inicial = barberoNombre.isNotEmpty
                          ? barberoNombre[0].toUpperCase()
                          : 'A';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFB8977E),
                            child: Text(
                              inicial,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            barberoNombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            '${listaCitas.length} cortes | Generado: \$${totalGenerado.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Comisión',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                  ),
                                  Text(
                                    '\$${comision.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right,
                                  color: Colors.grey),
                            ],
                          ),
                          onTap: () => _mostrarDetalleBarbero(
                              context, barberoNombre, listaCitas),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String titulo,
    required String valor,
    IconData? icon,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 4),
          ],
          Text(
            titulo,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemMetodoPago({
    required IconData icon,
    required String titulo,
    required double monto,
    required Color color,
  }) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          titulo,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 2),
        Text(
          '\$${monto.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }
}

class IngresosPorDiaExpandableCard extends StatefulWidget {
  final List<QueryDocumentSnapshot> docs;

  const IngresosPorDiaExpandableCard({super.key, required this.docs});

  @override
  State<IngresosPorDiaExpandableCard> createState() =>
      _IngresosPorDiaExpandableCardState();
}

class _IngresosPorDiaExpandableCardState
    extends State<IngresosPorDiaExpandableCard> {
  bool _estaExpandido = false;

  @override
  Widget build(BuildContext context) {
    // 1. Filtrar citas completadas
    final completadas = widget.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return (data['estado'] ?? 'pendiente') == 'completada';
    }).toList();

    // 2. Agrupar ingresos por fecha
    Map<String, double> ingresosPorDia = {};
    for (var doc in completadas) {
      final data = doc.data() as Map<String, dynamic>;
      final double precio = (data['precio'] ?? 0.0).toDouble();
      final rawFecha = data['fechaHora'] ?? data['fecha'];

      String diaClave = 'Fecha no definida';
      if (rawFecha is Timestamp) {
        final f = rawFecha.toDate().toLocal();
        diaClave = '${f.day}/${f.month}/${f.year}';
      } else if (rawFecha is String && rawFecha.isNotEmpty) {
        diaClave = rawFecha.split(' ')[0];
      }

      ingresosPorDia[diaClave] = (ingresosPorDia[diaClave] ?? 0.0) + precio;
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _estaExpandido = !_estaExpandido;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F0EB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        const Icon(Icons.bar_chart, color: Color(0xFFB8977E)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ingresos Totales por Día (Barbería)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Suma global de todos los barberos',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _estaExpandido ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: [
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    const SizedBox(height: 12),
                    ingresosPorDia.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'No hay ingresos completados en este período.',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          )
                        : Column(
                            children: ingresosPorDia.entries.map((entry) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '\$${entry.value.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ],
                ),
                crossFadeState: _estaExpandido
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
