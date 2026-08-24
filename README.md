# 💈 Exclusive Barber - Aplicación Móvil en Flutter

Proyecto desarrollado como parte de la evaluación de desarrollo de aplicaciones móviles. La aplicación consiste en un sistema de gestión para barberías (*Exclusive Barber*) que permite administrar citas, visualizar métricas de ingresos, revisar listas de clientes y configurar servicios mediante una interfaz moderna e intuitiva.

---

## 👤 Información del Autor
* **Estudiante:** Segundo alexander Moreira Mnedoza
* **Asignatura:** Desarrollo de Aplicaciones Móviles
* **IDE Utilizado:** Visual Studio Code
* **Lenguaje / Framework:** Dart / Flutter (Material Design 3)
* **Repositorio:** [Enlace público de GitHub]

---

## 🚀 Descripción del Proyecto
*Exclusive Barber* es una solución digital pensada para emprendimientos de barberos y estilistas independientes. La app proporciona un panel de control con métricas en tiempo real, agendamiento de citas, registro detallado de clientes con sus preferencias de corte, reporte básico de finanzas y gestión de perfil.

### Funcionalidades Clave
1. **Dashboard (Inicio):** Resumen de citas e ingresos diarios mediante tarjetas métricas.

![alt text](<Captura de pantalla 2026-08-23 223614.png>)


2. **Navegación Fluida:** Utiliza un `NavigationBar` (Bottom Navigation) con 5 secciones activas.

![alt text](<Captura de pantalla 2026-08-23 223614-1.png>)


3. **Manejo de Clientes y Agenda:** Vistas organizadas en formato de listas (`ListView.builder`) con avatares dinámicos.

![alt text](<Captura de pantalla 2026-08-23 230502.png>)

4. **Navegación entre Pantallas:** Uso de `Navigator.push` para abrir formularios y listas secundarias (`RegistrarClienteScreen` y `ServiciosScreen`).

![alt text](<Captura de pantalla 2026-08-23 230450.png>)

5. **Carga Eficiente de Imágenes:** Optimización de recursos usando paquetes de almacenamiento en caché para imágenes de red.
![alt text](<Captura de pantalla 2026-08-23 224553.png>)

---

## 🛠️ Requisitos Técnicos y Widgets Utilizados

### Widgets Principales de Flutter
* **Estructura y Layout:** `MaterialApp`, `Scaffold`, `SafeArea`, `Column`, `Row`, `Container`, `Card`, `Padding`, `SizedBox`.
* **Listas y Listados:** `ListView`, `ListView.builder`, `ListTile`.
* **Elementos Gráficos e Interactivos:** `CircleAvatar`, `Icon`, `Text`, `Switch`, `ClipRRect`.
* **Botones:** `FloatingActionButton`, `ElevatedButton`, `OutlinedButton`.

### Paquete Externo Instalado
Se integró el paquete oficial **`cached_network_image`** desde Pub.dev.
* **Propósito:** Cargar fotos de perfil e imágenes desde URLs de internet, almacenándolas en el almacenamiento local del dispositivo para evitar descargas repetidas y reducir el consumo de datos.
* **Librería agregada en `pubspec.yaml`:** `cached_network_image: ^3.3.1` (o versión actual).
![alt text](<Captura de pantalla 2026-08-23 225324.png>)

no se pudo instalar pos mas que intente
---

## 📁 Estructura del Proyecto

```text
my_primera_app_movil/
├── assets/
│   └── images/
│       └── corte.png              # Imagen local del logotipo/corte
├── capturas/                      # Carpeta con las evidencias para la entrega
│   ├── 01_flutter_doctor.png
│   ├── 02_vscode_proyecto.png
│   ├── 03_emulador_android.png
│   ├── 04_pubspec_paquete.png
│   ├── 05_github_repo.png
│   ├── 06_app_inicio.png
│   ├── 07_app_interaccion.png
│   └── 08_app_paquete_cached.png
├── lib/
│   ├── screens/
│   │   ├── registrar_cliente_screen.dart
│   │   └── servicios_screen.dart
│   └── main.dart                  # Punto de entrada principal y navegación
├── pubspec.yaml                   # Configuración de dependencias y assets
└── README.md                      # Documentación del proyecto