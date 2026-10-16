# AGENTS.md

## Qué es esto

App Flutter MVP: escanea el código de barras de un producto de comida para gato y consulta el backend para decir si la marca cumple las directrices WSAVA. Un solo fichero de código Dart; el resto son plataformas de scaffolding.

- **Todo el código vive en `lib/main.dart`** (`CatFoodCheckApp` → `ScannerPage`). No hay módulos, servicios ni capas.
- `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/` son generadas por Flutter; no las toques salvo que el cambio sea explícitamente de plataforma (permisos de cámara, iconos, nombre de paquete).

## Backend acoplado

- La URL del backend está **hardcodeada** en `lib/main.dart` (línea ~39): `https://catfoodcheck.onrender.com/scan/$barcode`. No hay variable de entorno ni config por flavor.
- El backend vive en el repo hermano `catfoodcheck/` (FastAPI, desplegado en Render). Si cambias el contrato del endpoint (`product`, `brand`, `wsava`), cambia ambos repos.
- Escaneo con `mobile_scanner` (⚠️ el README dice `barcode_scan2`: está desactualizado; el código real usa `mobile_scanner`).

## Comandos

```bash
flutter pub get        # instalar dependencias
flutter run            # en dispositivo/emulador conectado
flutter analyze        # lint + comprobación de tipos (ver estado actual)
flutter test           # pruebas (ver estado actual)
flutter build apk      # APK en build/app/outputs/flutter-apk/
```

En Windows, `flutter` funciona directamente desde PowerShell (no aplica el problema de shims `.ps1` de otros repos de esta carpeta).

## Verificación

Orden: `flutter analyze` → `flutter test` (ambos en verde; el test de `fetchProduct` usa `MockClient` de `package:http/testing.dart` y no necesita cámara ni red).

- `test/widget_test.dart` contiene tests **unitarios** de `fetchProduct`, no widget tests. `ScannerPage` completa no es testeable en headless porque `MobileScanner` requiere la cámara/plugin.
- `fetchProduct` nunca lanza: devuelve un `ScanResult` (sealed) → `ProductResult` / `NotFoundResult` / `TimeoutResult` / `NetworkErrorResult` / `InvalidBodyResult`. Si amplías la API, amplía este sealed y su test.

## `flutter build apk` en esta máquina: OOM garantizado

- `android/gradle.properties` pide `-Xmx8G` pero la máquina tiene ~3.9 GB de RAM: el daemon de Gradle muere con *"insufficient memory"* (genera `android/hs_err_pid*.log` — borrarlos).
- **Workaround verificado** (JAVA_HOME no está en el shell; Flutter lo resuelve solo, gradlew no):

```powershell
$env:JAVA_HOME='C:\Program Files\Android\Android Studio\jbr'
cd android
.\gradlew.bat assembleDebug "-Dorg.gradle.jvmargs=-Xmx2600m -XX:MaxMetaspaceSize=384m -XX:ReservedCodeCacheSize=256m"
```

- Con 1.5 GB falla Jetifier (*Java heap space*); 2600m funciona (build ~5 min). Si bajara la RAM, cierra Android Studio antes.
- Los outputs van a `build/app/outputs/` (Flutter redirige el build dir de Gradle), no a `android/app/build/`.

## Patrones del código (`lib/main.dart`)

- **`MobileScannerController` propio** en `_ScannerPageState`: `detectionSpeed: normal` + `detectionTimeoutMs: 500` + `formats: [ean13, ean8, upcA, upcE]` (solo formatos de comida; menos trabajo de ML Kit). En `mobile_scanner` 5.x `formats`/`detectionSpeed` van en el **controller**, no en el widget `MobileScanner`. No uses `DetectionSpeed.noDuplicates`: impide volver a escanear el mismo producto.
- **Anti-bucle de API**: `onDetect` se ignora mientras `_scanned == true`; solo el botón "Scan again" (`_resetScan`) lo reactiva. Sin este freeze, la cámara re-llama a Render con el mismo código en bucle (Render free se duerme → cold starts).
- El cliente `http.Client` es inyectable por `ScannerPage(client: ...)`; si se omite, se crea y se hace `close()` en `dispose`.

## Git

- Rama local `main` con upstream configurado; `git push` / `git pull` normales funcionan (no hace falta `HEAD:main`, a diferencia de otros repos de esta carpeta padre).
- Sin CI, sin pre-commit, sin `opencode.json` ni otros ficheros de instrucciones.

## ⚠️ Seguridad: datos sensibles — NUNCA al repo

- **Prohibido subir a git**: keystores de Android (`*.keystore`, `*.jks`), claves de firma, claves API/tokens, ficheros `.env` y credenciales (aquí no hay aún keystore propio, pero el patrón es el mismo para toda la carpeta; si algún día se publica en Play Store, seguir el de `quiz-historia`: keystore gitignored + contraseña en `%USERPROFILE%\.bubblewrap\`).
- **Cómo se guardan**: en rutas **fuera del repo** o en variables de entorno; **nunca** en `lib/main.dart` ni en configuración trackeada. `.env` (si se usa) debe estar en `.gitignore`.
- **Antes de cada commit grande:** revisar `git status` y comprobar `git ls-files | Select-String -Pattern '(keystore|\.env|secret|passw|token|key)'` → debe salir vacío (vigilar `AndroidManifest.xml` e `Info.plist`, que se están tocando ahora mismo).
- **Si algo se sube por error:** rotar la credencial **inmediatamente** — borrar el commit no basta (el historial, clones y forks conservan el dato).
- Auditoría recurrente: `git log --all --diff-filter=A --name-only` detecta ficheros que alguna vez se trackearon (auditoría 2026-10-16: los 10 proyectos de la carpeta, limpios).

## Memoria y plan

- **[MEMORY.md](./MEMORY.md)** — registro **solo aditivo** de cambios e incidencias (workaround de OOM, README desactualizado, estado del working tree). Tras cada cambio relevante, **añadir** una entrada; nunca borrar ni reescribir entradas anteriores.
- **[PLAN.md](./PLAN.md)** — estado y mantenimiento previsto. Este `AGENTS.md` sigue siendo autoritativo para patrones de código y verificación.
