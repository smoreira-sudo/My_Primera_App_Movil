# 💈 Exclusive Barber - Aplicación Móvil en Flutter

Proyecto desarrollado como parte de la evaluación de desarrollo de aplicaciones móviles (**Actividad Integradora 2: Navegación, Persistencia y Nuevos Widgets**). La aplicación consiste en un sistema de gestión para barberías (*Exclusive Barber*) que permite administrar citas, visualizar métricas de ingresos, revisar listas de clientes y registrar personal mediante una interfaz moderna e intuitiva.

---

## 👤 Información del Autor
* **Estudiante:** Segundo Alexander Moreira Mendoza
* **Asignatura:** Desarrollo de Aplicaciones Móviles
* **IDE Utilizado:** Visual Studio Code
* **Lenguaje / Framework:** Dart / Flutter (Material Design 3)
* **Repositorio:** [Enlace público de GitHub]

---

## 🚀 Descripción del Proyecto
*Exclusive Barber* es una solución digital pensada para emprendimientos de barberos y estilistas independientes. La app proporciona un panel de control con métricas en tiempo real, agendamiento de citas, registro detallado de clientes con sus preferencias de corte, reporte básico de finanzas y gestión de perfil.

### 🩺 Verificación del Entorno (Flutter Doctor)
![Flutter Doctor](Captura%20de%20pantalla%202026-08-23%20164030.png)

---

## 📸 Resumen de Cambios y Avances Recientes (Actividad Integradora 2)

### 📦 1. Renombrado e Integración de Backend (`pubspec.yaml`)
* **Identificador de la App:** Se cambió el nombre oficial del paquete a `exclusive_barber` en el archivo `pubspec.yaml` para darle identidad de marca propia al proyecto.
  ![Nombre del Paquete](Captura%20de%20pantalla%202026-08-30%20235214.png)

* **Integración de Backend:** Se agregaron las dependencias de `firebase_core` y `cloud_firestore` para conectar la aplicación a la nube, permitiendo la persistencia y sincronización de datos en tiempo real de citas, barberos y clientes.
  ![Configuración Firebase](Captura%20de%20pantalla%202026-08-30%20230346.png)

* **Manejo de Fechas (`intl`):** Formateo e internacionalización de fechas en español para la agenda de citas.

* **Carga de Imágenes en Red (`cached_network_image`):** Gestión eficiente y renderizado de imágenes desde internet con almacenamiento en caché local.

---

### 🎨 2. Rediseño del Sistema de Colores (Paleta Premium)
Se actualizó la identidad visual para brindar una apariencia moderna, elegante y profesional:
* **Negro Mate (`#1A1A1A` / `0xFF1A1A1A`):** Aplicado a textos principales, encabezados y elementos visuales de mayor peso.
* **Café Tostado / Dorado (`#8C704B` / `0xFF8C704B`):** Utilizado en botones de acción principales (`ElevatedButton`, `FloatingActionButton`), acentos de la navegación e íconos activos.
* **Blanco Hueso (`#F7F5F0` / `0xFFF7F5F0`):** Fondo general de las pantallas (`scaffoldBackgroundColor`) y tarjetas neutras.

---

### 🖼️ 3. Actualización de Recursos e Imágenes
* **Gestión de Assets:** Configuración de la carpeta `assets/images/` en el archivo `pubspec.yaml` para soportar imágenes locales (como `logo1.png` y `corte.png`).
  ![Assets Config](assets/images/Captura%20de%20pantalla%202026-08-30%20234019.png)

* **Integración Visual:** Implementación del logotipo e imágenes representativas en la pantalla de inicio y tarjeta de perfil general.
  ![Interfaz 1](Captura%20de%20pantalla%202026-08-30%20224405.png)
  ![Interfaz 2](Captura%20de%20pantalla%202026-08-30%20223356.png)
  ![Interfaz 3](assets/images/Captura%20de%20pantalla%202026-08-30%20224723.png)

---

### 🛠️ 4. Mantenimiento de la Arquitectura y Navegación
* **Lógica Preservada:** Se mantuvo el 100% de las funciones de estado (`_agregarCita`, `_agregarBarbero`, `_selectDate`, `_mostrarTrabajosBarbero`).
* **Flujo de Navegación:** Navegación por pestañas inferiores (`NavigationBar`) para las secciones principales y navegación apilada con `Navigator.push` hacia las vistas secundarias (`RegistrarClienteScreen` y `ServiciosScreen`).

---

## 🛠️ Requisitos Técnicos y Widgets Utilizados

### Widgets Principales de Flutter
* **Estructura y Layout:** `MaterialApp`, `Scaffold`, `SafeArea`, `Column`, `Row`, `Container`, `Card`, `Padding`, `SizedBox`.
* **Listas y Listados:** `ListView`, `ListView.builder`, `ListTile`.
* **Elementos Gráficos e Interactivos:** `CircleAvatar`, `Icon`, `Text`, `Switch`, `ClipRRect`.
* **Botones:** `FloatingActionButton`, `ElevatedButton`, `OutlinedButton`.

---

## 📁 Estructura del Proyecto

```text
exclusive_barber/
├── assets/
│   └── images/
│       ├── logo1.png              # Logotipo oficial
│       └── corte.png              # Imagen local representativa
├── capturas/                      # Evidencias del proyecto
├── lib/
│   ├── screens/
│   │   ├── registrar_cliente_screen.dart
│   │   ├── servicios_screen.dart
│   │   └── clientes_screen.dart
│   └── main.dart                  # Punto de entrada principal y navegación
├── pubspec.yaml                   # Configuración de dependencias y assets
└── README.md                      # Documentación oficial del proyecto