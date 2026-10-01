# Configuración de Entornos y Servicios Externos

**Proyecto:** Soluro  
**Módulo:** Gestión de Credenciales y Servicios de Terceros (`docs/ENVIRONMENT_CONFIG.md`)

---

## 1. Auditoría de Variables de Entorno y Endpoints

### Estado Actual del Proyecto (Tier Gratuito / Offline-First)
* **Variables de entorno (`.env`):** No se requieren en la versión actual. La aplicación no contiene llaves de API hardcodeadas ni dependencias de backend remoto en tiempo de ejecución.
* **Endpoints remotos:** Cero endpoints HTTP activos. Toda la persistencia de datos (códigos QR, direcciones y cotizaciones) se ejecuta localmente mediante el motor SQLite interno.
* **Cero SDKs de telemetría o publicidad:** No se incluyen librerías de analítica externa (Firebase Analytics, Mixpanel, AdMob), lo que simplifica la aprobación en Google Play Store y garantiza máxima privacidad al usuario.

---

## 2. Configuración de Servicios Nativos y de Terceros

### A. Google Maps y Esquemas de URL (`url_launcher`)
* **Uso:** El módulo de sucursales ([lib/screens/direcciones/direcciones_list_screen.dart](file:///c:/soluro_app/aplicacion_soluro_ago/lib/screens/direcciones/direcciones_list_screen.dart)) permite abrir coordenadas directamente en Google Maps mediante `url_launcher`.
* **Configuración en [android/app/src/main/AndroidManifest.xml](file:///c:/soluro_app/aplicacion_soluro_ago/android/app/src/main/AndroidManifest.xml):**
  Para cumplir con los requisitos de visibilidad de paquetes en Android 11+ (API 30+), el manifiesto incluye la directiva `<queries>`:
  ```xml
  <queries>
      <intent>
          <action android:name="android.intent.action.VIEW" />
          <data android:scheme="https" />
      </intent>
  </queries>
  ```

---

### B. Canal de Notificaciones Locales (`flutter_local_notifications`)
* **Servicio:** [lib/services/notification_service.dart](file:///c:/soluro_app/aplicacion_soluro_ago/lib/services/notification_service.dart).
* **Propósito:** Alertas locales para recordar al usuario la expiración de sus códigos QR.
* **Parámetros del canal en Android:**
  * **Channel ID:** `qr_expiration_channel`
  * **Channel Name:** `Vencimiento de Códigos QR`
  * **Description:** `Notificaciones para alertar sobre la expiración de cobros QR`
  * **Importance:** `Importance.high`
  * **Priority:** `Priority.high`
  * **Icono nativo:** `@mipmap/ic_launcher`

---

### C. Accesos Directos del Launcher (Quick Actions / App Shortcuts)
* **Servicio:** [lib/services/quick_actions_service.dart](file:///c:/soluro_app/aplicacion_soluro_ago/lib/services/quick_actions_service.dart).
* **Propósito:** Al mantener presionado el icono de Soluro en la pantalla de inicio de Android, se despliegan accesos rápidos a los códigos QR más recientes o de uso frecuente.
* **Integración en [lib/main.dart](file:///c:/soluro_app/aplicacion_soluro_ago/lib/main.dart#L42-L51):** El manejador intercepta el identificador `qr_{id}` y abre inmediatamente [FullScreenQRViewer](file:///c:/soluro_app/aplicacion_soluro_ago/lib/screens/qr/full_screen_qr_viewer.dart).

---

## 3. Preparación de Arquitectura para Soluro Pro (Firebase Cloud Backup)

El proyecto cuenta con la clase [SyncDataRepository](file:///c:/soluro_app/aplicacion_soluro_ago/lib/repositories/sync_data_repository.dart) y los modelos con campos de sincronización (`is_synced`, `sync_status`, `last_synced_at`, `user_id`) para incorporar la versión Pro.

### Pasos para Activar Firebase en la Versión Pro:

1. **Crear el proyecto en Google Firebase Console:**
   * Registrar la aplicación con el package name oficial: `com.getsoluro.soluro`.
   * Registrar las huellas digitales SHA-1 y SHA-256 de las firmas de debug y release.
2. **Descargar y ubicar `google-services.json`:**
   * Ubicar el archivo en la ruta protegida:
     ```
     android/app/google-services.json
     ```
3. **Vincular el Gradle Plugin de Google Services:**
   * En `android/build.gradle.kts`:
     ```kotlin
     plugins {
         id("com.google.gms.google-services") version "4.4.2" apply false
     }
     ```
   * En `android/app/build.gradle.kts`:
     ```kotlin
     plugins {
         id("com.google.gms.google-services")
     }
     ```
4. **Instalar paquetes en `pubspec.yaml`:**
   ```yaml
   firebase_core: ^3.6.0
   firebase_auth: ^5.3.1
   cloud_firestore: ^5.4.4
   ```
5. **Activar en tiempo de ejecución:**
   * En [lib/repositories/repository_provider.dart](file:///c:/soluro_app/aplicacion_soluro_ago/lib/repositories/repository_provider.dart), inicializar `SyncDataRepository` cuando el usuario inicie sesión con su suscripción Pro.

---

## 4. Política de Seguridad y Archivos Sensibles (`.gitignore`)

Para prevenir filtraciones accidentales de credenciales o claves privadas de producción, verifica que los siguientes patrones estén declarados en [.gitignore](file:///c:/soluro_app/aplicacion_soluro_ago/.gitignore):

```gitignore
# Android Keystore & Signing
*.jks
*.keystore
android/key.properties

# Google Services / Firebase (Credenciales confidenciales)
android/app/google-services.json
ios/Runner/GoogleService-Info.plist

# Variables de entorno locales
.env
.env.*
```
