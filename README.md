#  Exclusive Barber - Aplicación Móvil en Flutter

Proyecto desarrollado como parte de la evaluación de desarrollo de
aplicaciones móviles. La aplicación consiste en un sistema de gestión
para barberías (**Exclusive Barber**) que permite administrar citas,
visualizar métricas de ingresos, revisar listas de clientes y configurar
servicios mediante una interfaz moderna e intuitiva.

------------------------------------------------------------------------

##  Información del Autor

-   **Estudiante:** Segundo Alexander Moreira Mendoza
-   **Asignatura:** Desarrollo de Aplicaciones Móviles
-   **IDE Utilizado:** Visual Studio Code
-   **Lenguaje / Framework:** Dart / Flutter (Material Design 3)
-   **Repositorio:** \[Enlace público de GitHub\]

------------------------------------------------------------------------

##  Descripción del Proyecto

**Exclusive Barber** es una solución digital pensada para
emprendimientos de barberos y estilistas independientes. La app
proporciona un panel de control con métricas en tiempo real,
agendamiento de citas, registro detallado de clientes con sus
preferencias de corte, reporte básico de finanzas y gestión de perfil.

### FLUTTER DOCTOR

![Captura de pantalla 2026-08-23
164030.png](Captura%20de%20pantalla%202026-08-23%20164030.png)

------------------------------------------------------------------------

##  Funcionalidades Clave

### 1. Dashboard (Inicio)

Resumen de citas e ingresos diarios mediante tarjetas métricas.

![Captura de pantalla 2026-08-23
223614.png](Captura%20de%20pantalla%202026-08-23%20223614.png)

### 2. Navegación Fluida

Utiliza un `NavigationBar` (Bottom Navigation) con 5 secciones activas.

![Captura de pantalla 2026-08-23
223614-1.png](Captura%20de%20pantalla%202026-08-23%20223614-1.png)

### 3. Manejo de Clientes y Agenda

Vistas organizadas en formato de listas (`ListView.builder`) con
avatares dinámicos.

![Captura de pantalla 2026-08-23
230502.png](Captura%20de%20pantalla%202026-08-23%20230502.png)

### 4. Navegación entre Pantallas

Uso de `Navigator.push` para abrir formularios y listas secundarias
(`RegistrarClienteScreen` y `ServiciosScreen`).

![Captura de pantalla 2026-08-23
230450.png](Captura%20de%20pantalla%202026-08-23%20230450.png)

### 5. Carga Eficiente de Imágenes

Optimización de recursos usando paquetes de almacenamiento en caché para
imágenes de red.

![Captura de pantalla 2026-08-23
224553.png](Captura%20de%20pantalla%202026-08-23%20224553.png)

------------------------------------------------------------------------

##  Requisitos Técnicos y Widgets Utilizados

### Widgets Principales de Flutter

-   **Estructura y Layout:** `MaterialApp`, `Scaffold`, `SafeArea`,
    `Column`, `Row`, `Container`, `Card`, `Padding`, `SizedBox`.
-   **Listas y Listados:** `ListView`, `ListView.builder`, `ListTile`.
-   **Elementos Gráficos e Interactivos:** `CircleAvatar`, `Icon`,
    `Text`, `Switch`, `ClipRRect`.
-   **Botones:** `FloatingActionButton`, `ElevatedButton`,
    `OutlinedButton`.

### Paquete Externo Instalado

Se integró el paquete oficial **`cached_network_image`** desde Pub.dev.

-   **Propósito:** Cargar fotos de perfil e imágenes desde URLs de
    internet, almacenándolas en el almacenamiento local del dispositivo
    para evitar descargas repetidas y reducir el consumo de datos.
-   **Librería agregada en `pubspec.yaml`:**
    `cached_network_image: ^3.3.1` (o versión actual).

![Captura de pantalla 2026-08-23
225324.png](Captura%20de%20pantalla%202026-08-23%20225324.png)


#  Exclusive Barber App

Aplicación móvil desarrollada en **Flutter** para la gestión integral y
operativa de una barbería profesional. La aplicación permite administrar
citas, clientes presenciales, registro de personal (barberos), control
de finanzas en tiempo real y personalización de servicios.

**Actividad Integradora 2**

------------------------------------------------------------------------

#  Navegación y Nuevos Widgets

## Resumen de Cambios y Avances Recientes

### 1. Integración de Paquetes Externos y Configuración (`pubspec.yaml`)

-   **Identificador de la App:** Se cambió el nombre oficial del paquete
    a `exclusive_barber` en el archivo `pubspec.yaml` para darle
    identidad de marca propia al proyecto.

![Captura de pantalla 2026-08-30
235214.png](Captura%20de%20pantalla%202026-08-30%20235214.png)

-   **Integración de Backend:** Se agregaron los paquetes oficiales
    `firebase_core` y `cloud_firestore` para conectar la aplicación a la
    nube, permitiendo guardar y sincronizar la información de las citas,
    barberos y clientes en tiempo real.

![Captura de pantalla 2026-08-30
230346.png](Captura%20de%20pantalla%202026-08-30%20230346.png)

-   **Manejo de Fechas (`intl`):** Formateo e internacionalización de
    fechas en español para la agenda de citas.
-   **Carga de Imágenes en Red (`cached_network_image`):** Gestión
    eficiente y renderizado de imágenes desde internet con
    almacenamiento en caché.

------------------------------------------------------------------------

### 2. Rediseño del Sistema de Colores (Paleta Premium)

Se actualizó la identidad visual para brindar una apariencia moderna,
elegante y profesional:

-   **Negro Mate (`#1A1A1A` / `0xFF1A1A1A`):** Aplicado a textos
    principales, encabezados y elementos visuales de mayor peso.
-   **Café Tostado / Dorado (`#8C704B` / `0xFF8C704B`):** Utilizado en
    botones de acción principales (`ElevatedButton`,
    `FloatingActionButton`), acentos de la navegación e íconos activos.
-   **Blanco Hueso (`#F7F5F0` / `0xFFF7F5F0`):** Fondo general de las
    pantallas (`scaffoldBackgroundColor`) y tarjetas neutras.

------------------------------------------------------------------------

### 3. Actualización de Recursos e Imágenes

-   **Gestión de Assets:** Configuración de la carpeta `assets/images/`
    en el archivo `pubspec.yaml` para soportar múltiples imágenes (como
    `logo1.png` y `corte.png`).

![Captura de pantalla 2026-08-30
234019.png](Captura%20de%20pantalla%202026-08-30%20234019.png)

-   **Integración Visual:** Implementación del logotipo e imágenes
    representativas en la pantalla de inicio y tarjeta del perfil
    general.

![Captura de pantalla 2026-08-30
224405.png](Captura%20de%20pantalla%202026-08-30%20224405.png)

![Captura de pantalla 2026-08-30
223356.png](Captura%20de%20pantalla%202026-08-30%20223356.png)

![Captura de pantalla 2026-08-30
224723.png](Captura%20de%20pantalla%202026-08-30%20224723.png)

------------------------------------------------------------------------

### 4. Mantenimiento de la Arquitectura

-   **Lógica Preservada:** Se mantuvo el 100% de las funciones de estado
    (`_agregarCita`, `_agregarBarbero`, `_selectDate`,
    `_mostrarTrabajosBarbero`).
-   **Flujo de Navegación:** Navegación por pestañas inferiores
    (`NavigationBar`) para las secciones principales y navegación
    apilada con `Navigator.push` hacia las vistas secundarias
    (`RegistrarClienteScreen` y `ServiciosScreen`).

------------------------------------------------------------------------

## Requisitos Técnicos y Widgets Utilizados

### Widgets Principales de Flutter

-   **Estructura y Layout:** `MaterialApp`, `Scaffold`, `SafeArea`,
    `Column`, `Row`, `Container`, `Card`, `Padding`, `SizedBox`.
-   **Listas y Listados:** `ListView`, `ListView.builder`, `ListTile`.
-   **Elementos Gráficos e Interactivos:** `CircleAvatar`, `Icon`,
    `Text`, `Switch`, `ClipRRect`.
-   **Botones:** `FloatingActionButton`, `ElevatedButton`,
    `OutlinedButton`.

------------------------------------------------------------------------

## Estructura del Proyecto

``` text
my_primera_app_movil/

├── assets/
│   └── images/
│       ├── logo1.png              # Logotipo oficial
│       └── corte.png              # Imagen local representativa

├── lib/
│   ├── screens/
│   │   ├── registrar_cliente_screen.dart
│   │   ├── servicios_screen.dart
│   │   └── clientes_screen.dart
│   └── main.dart                  # Punto de entrada principal y navegación

├── pubspec.yaml                   # Configuración de dependencias y assets
└── README.md                      # Documentación del proyecto
```

------------------------------------------------------------------------

#  Avance Actividad Integradora 3

## Resumen de Trabajos Realizados

Se completó la infraestructura en la nube mediante **Firebase**, la
optimización de la experiencia de usuario (UI/UX) con vistas
desplazables (*scrolling*), el almacenamiento de multimedia, y la
refactorización integral del módulo de Finanzas y Reportes en Flutter.
Además, se realizó la sincronización y resolución de conflictos en el
repositorio remoto de GitHub.

------------------------------------------------------------------------

## Detalle de Avances e Integraciones

### 1. Configuración de Servicios Cloud en Firebase

-   **Proyecto de Pruebas:** Vinculación exitosa del proyecto
    `Barberia-prueba` (`ID: barberia-prueba-16754`) y despliegue del
    archivo de credenciales `google-services.json` en `android/app/`.
-   **Cloud Firestore:** Base de datos NoSQL activa en edición
    **Standard** (`(default)`), configurada en modo de prueba para
    operaciones de lectura/escritura en tiempo real.
-   **Firebase Authentication:** Habilitado el método **Correo
    electrónico / Contraseña** y gestión de roles (`rol: "admin"` /
    `rol: "barbero"`).
-   **Firebase Storage (Carga de Fotos a la Nube):** Integración de
    almacenamiento remoto para la gestión de imágenes de perfil y fotos
    de trabajos/cortes, optimizando la persistencia de multimedia
    directamente en la nube.

------------------------------------------------------------------------

## Evolución del Módulo "Finanzas & Reportes" (Antes vs. Después)

Se rediseñó por completo el panel financiero para ofrecer métricas clave
en tiempo real:

### Versión Anterior (Vista Básica)

-   Presentaba una interfaz estática limitada únicamente a los ingresos
    diarios, número de citas y promedios simples sin filtros.

### Versión Actualizada (Finanzas & Reportes Avanzado)

-   **Filtros Temporales:** Selección dinámica por *Hoy*, *Esta Semana*,
    *Este Mes* y *Personalizado*.
-   **Métricas Avanzadas:** Desglose automático de *Ingresos Totales*,
    *Ticket Promedio*, *Total de Cortes*, *Citas / Día* y *Tiempo Medio*
    de atención.
-   **Ingresos Totales por Día:** Despliegue dinámico de la suma global
    del negocio.
-   **Desglose por Método de Pago:** Visualización de ingresos
    segregados según la vía de cobro (*Efectivo*, *Tarjeta*,
    *Transferencia*).
-   **Generación de Reportes:** Exportación de resúmenes financieros en
    formato PDF.

------------------------------------------------------------------------

## Mejoras en Interfaz de Usuario (UI/UX) y Scroll Independiente

-   **Separación de Pantallas y Scroll:** Implementación de vistas
    desplazables independientes (`CustomScrollView` /
    `SingleChildScrollView`) en la pantalla de Finanzas y listados
    principales.
-   **Optimización de Renderizado:** Eliminación de errores de
    desbordamiento de píxeles (*overflow*) al navegar entre pantallas en
    dispositivos de distintos tamaños.
-   **Barra de Navegación Refactorizada:** Ajuste de íconos e
    indicadores visuales activos para una navegación más fluida.
![Captura 2026-09-08 202457](Captura%20de%20pantalla%202026-09-08%20202457.png)
![Captura 2026-09-08 202617](Captura%20de%20pantalla%202026-09-08%20202617.png)
![Captura 2026-09-08 202651](Captura%20de%20pantalla%202026-09-08%20202651.png)
![Captura 2026-09-08 202825](Captura%20de%20pantalla%202026-09-08%20202825.png)
![Captura 2026-09-08 202916](Captura%20de%20pantalla%202026-09-08%20202916.png)
![Captura 2026-09-08 203153](Captura%20de%20pantalla%202026-09-08%20203153.png)
![Captura 2026-09-08 203407](Captura%20de%20pantalla%202026-09-08%20203407.png)
![Captura 2026-09-08 203503](Captura%20de%20pantalla%202026-09-08%20203503.png)
![Captura 2026-09-08 203630](Captura%20de%20pantalla%202026-09-08%20203630.png)
![Captura 2026-09-08 203704](Captura%20de%20pantalla%202026-09-08%20203704.png)
![Captura 2026-09-08 204141](Captura%20de%20pantalla%202026-09-08%20204141.png)
![Captura 2026-09-08 204220](Captura%20de%20pantalla%202026-09-08%20204220.png)
![Captura 2026-09-08 204641](Captura%20de%20pantalla%202026-09-08%20204641.png)
![Captura 2026-09-08 205747](Captura%20de%20pantalla%202026-09-08%20205747.png)
![Captura 2026-09-08 210202](Captura%20de%20pantalla%202026-09-08%20210202.png)
![Captura 2026-09-08 210526](Captura%20de%20pantalla%202026-09-08%20210526.png)
![Captura 2026-09-08 210801](Captura%20de%20pantalla%202026-09-08%20210801.png)
![Captura 2026-09-08 210930](Captura%20de%20pantalla%202026-09-08%20210930.png)
![Captura 2026-09-08 210945](Captura%20de%20pantalla%202026-09-08%20210945.png)
![Captura 2026-09-08 211000](Captura%20de%20pantalla%202026-09-08%20211000.png)
![Captura 2026-09-08 211057](Captura%20de%20pantalla%202026-09-08%20211057.png)
![Captura 2026-09-08 211115](Captura%20de%20pantalla%202026-09-08%20211115.png)
![Captura 2026-09-08 211639](Captura%20de%20pantalla%202026-09-08%20211639.png)
![Captura 2026-09-08 211811](Captura%20de%20pantalla%202026-09-08%20211811.png)
![Captura 2026-09-08 211831](Captura%20de%20pantalla%202026-09-08%20211831.png)
![Captura 2026-09-08 211901](Captura%20de%20pantalla%202026-09-08%20211901.png)
![Captura 2026-09-08 211916](Captura%20de%20pantalla%202026-09-08%20211916.png)