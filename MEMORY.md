# MEMORY.md — catfoodcheck_app

Registro de cambios, incidencias y estado. **Solo aditivo**: nunca borrar ni reescribir
entradas anteriores; corregir añadiendo una entrada nueva.

---

## 2026-10-16 — Creación de MEMORY.md

**Qué:** la app nació con un `AGENTS.md` exhaustivo (autoritativo: patrones de código,
workaround de build, verificación) pero sin registro de cambios; se crea este fichero para
alinearlo con el patrón de la carpeta.

**Estado a esta fecha (resumen del log + working tree):**

- Repo con commits históricos (2026-03: app inicial Flutter + migración `barcode_scan2` →
  `mobile_scanner`).
- **Cambios grandes sin commitear** en el working tree: `lib/main.dart` (+243 líneas),
  `test/widget_test.dart` ampliado (tests unitarios de `fetchProduct` con `MockClient`),
  `pubspec.yaml` (+1 dependencia), ajustes de permisos (`AndroidManifest.xml`, `Info.plist`).

**Incidencias conocidas (históricas y actuales):**

- **`flutter build apk` da OOM** en esta máquina (`-Xmx8G` en `gradle.properties` vs ~3.9 GB
  de RAM): el daemon de Gradle muere con *insufficient memory* y genera
  `android/hs_err_pid*.log` (borrarlos). **Workaround verificado** (documentado en el
  AGENTS.md): `JAVA_HOME` al JBR de Android Studio + `gradlew.bat assembleDebug` con
  `-Dorg.gradle.jvmargs=-Xmx2600m ...` (~5 min). Con 1.5 GB falla Jetifier por heap.
- El README de la app está **desactualizado**: dice `barcode_scan2`; el código usa
  `mobile_scanner` (el README del backend y este AGENTS.md son más fiables que la prosa).
- `ScannerPage` completa **no es testeable en headless** (`MobileScanner` requiere
  cámara/plugin) — los tests se centran en `fetchProduct`.

**Pendiente inmediato:** commitear y pushear el trabajo del working tree (una vez que el
contrato con el backend siga intacto).

**Relación con hermanos:** consume el backend de `catfoodcheck/` (URL hardcodeada en
`lib/main.dart`); cualquier cambio de contrato de `/scan/{ean}` exige cambiar **ambos repos**.
