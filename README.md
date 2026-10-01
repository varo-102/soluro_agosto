# Soluro ☀️

> Herramienta móvil integral para gestión ágil de cobros QR, generación instantánea de cotizaciones comerciales en PDF y directorio de sucursales con navegación rápida.

---

## 1. Descripción Ejecutiva y Propuesta de Valor

**Soluro** es una aplicación móvil desarrollada en Flutter diseñada para profesionales independientes, comercios y empresas que requieren agilidad comercial en el punto de contacto con clientes.

### Propuesta de Valor
* **Cobros QR con Monitoreo de Vencimiento:** Almacenamiento, visualización en pantalla completa y copia rápida al portapapeles de códigos QR bancarios, con alertas automáticas antes de su caducidad.
* **Cotizador Rápido y Generador de PDF Vectorial:** Creación de presupuestos con cálculo en tiempo real de subtotales, totales, adjuntos fotográficos comprimidos y exportación instantánea a formato PDF profesional listo para compartir vía WhatsApp, correo o impresión física.
* **Directorio de Direcciones y Sucursales:** Gestión de ubicaciones físicas con enlace directo a coordenadas en Google Maps y copia formateada en un solo toque.
* **Arquitectura Offline-First:** Funcionamiento total sin conexión a Internet mediante SQLite local, con soporte de copias de seguridad portables (`.soluro`) y preparado para sincronización multi-usuario en la nube (Soluro Pro / Firebase).

---

## 2. Stack Tecnológico

| Componente | Tecnología / Librería | Propósito |
| :--- | :--- | :--- |
| **Framework** | Flutter 3.x (Canal Estable) | Desarrollo móvil multiplataforma |
| **Lenguaje** | Dart 3.x (Null-Safety estricto) | Lógica de negocio y contratos |
| **Motor de Persistencia** | `sqflite: ^2.3.0` | Base de datos relacional local SQLite con WAL |
| **Capa de Abstracción** | Patrón Repositorio (`DataRepository`) | Desacople entre UI y capas de datos |
| **Gestión de Estado** | `ValueNotifier` + `StatefulWidget` reactivo | Reactividad ligera sin sobrecarga de dependencias |
| **Generación de Documentos**| `pdf: ^3.13.1` + `printing: ^5.13.1` | Maquetación vectorial y previsualización de PDF |
| **Optimización Multimedia** | `flutter_image_compress: ^2.3.0` | Compresión automática de fotografías a 800px / JPEG 70% |
| **Notificaciones Locales** | `flutter_local_notifications: ^17.0.0` | Avisos preventivos de expiración de códigos QR |
| **Acciones Rápidas** | `quick_actions: ^1.0.6` | Accesos directos en el launcher de Android (App Shortcuts) |
| **Copias de Seguridad** | `archive: ^4.0.0` | Empaquetado comprimido ZIP de base de datos y multimedia |

---

## 3. Requisitos Previos del Entorno

Para compilar y ejecutar el proyecto localmente se requiere:

* **Flutter SDK:** Versión `>= 3.13.0` (Probado en Flutter `3.47.x`).
* **Dart SDK:** Versión `>= 3.13.0`.
* **Java Development Kit (JDK):** Versión 17 (OpenLogic, Temurin u OpenJDK 17).
* **Android SDK:**
  * `compileSdkVersion`: **36**
  * `targetSdkVersion`: **36**
  * `minSdkVersion`: **21** (Android 5.0 Lollipop en adelante)
* **Editor recomendado:** VS Code con extensiones Flutter/Dart o Android Studio.

---

## 4. Guía Rápida de Configuración Local

### Paso 1: Clonar e instalar dependencias
Abre una terminal en la raíz del proyecto y descarga los paquetes requeridos:

```bash
flutter pub get
```

### Paso 2: Verificar la salud del entorno
Comprueba que no existan inconsistencias en el SDK o dependencias:

```bash
flutter doctor
flutter analyze
```

### Paso 3: Ejecutar la suite de pruebas unitarias e instrumentales
El proyecto cuenta con cobertura para serialización, cálculo de cotizaciones, persistencia SQLite y respaldos:

```bash
flutter test -j 1
```

### Paso 4: Ejecución en emulador o dispositivo físico
Conecta tu dispositivo Android (con depuración USB habilitada) o inicia un emulador:

```bash
# Modo Debug estándar
flutter run

# Modo Release para pruebas de rendimiento real
flutter run --release
```

---

## 5. Documentación Modular del Proyecto

Para obtener especificaciones técnicas profundas, consulta los manuales en la carpeta [`/docs`](docs/):

* 📐 **[Arquitectura y Flujo de Datos](docs/ARCHITECTURE.md):** Estructura del código, ciclo de vida de persistencia SQLite, modelo de soft-delete y catálogo de entidades.
* 🚀 **[Manual de Release para Google Play Store](docs/PLAYSTORE_RELEASE.md):** Configuración de firma (`key.properties`), compilación AAB, auditoría de permisos de Android y formulario de seguridad de datos.
* ⚙️ **[Configuración de Entorno y Servicios](docs/ENVIRONMENT_CONFIG.md):** Parámetros externos, preparación para Firebase (Soluro Pro) y buenas prácticas de seguridad.
