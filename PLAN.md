# PLAN.md — catfoodcheck_app

App MVP **funcional y desplegable** (APK) — no es un proyecto por fases. Este plan documenta
el estado y el mantenimiento previsto. Patrones de código, verificación y workaround de build
viven en [AGENTS.md](./AGENTS.md) (autoritativo).

## Estado

- ✅ App Flutter: escanea EAN → consulta el backend → dice si la marca cumple WSAVA.
- ✅ Verificación en verde: `flutter analyze` → `flutter test` (unitarios de `fetchProduct`
  con `MockClient`, sin cámara ni red).
- ✅ Build APK posible con el workaround de memoria del AGENTS.md.
- ⚠️ **Cambios grandes sin commitear** en `lib/main.dart` y tests (ver MEMORY.md).

## Mantenimiento previsto

1. **Commitear el trabajo pendiente** del working tree tras verificar analyze + test en verde.
2. **Contrato con el backend `catfoodcheck/`:** la URL está hardcodeada en `lib/main.dart`;
   cambiar la API implica cambiar ambos repos (el contrato está congelado en el AGENTS.md
   del backend: 200 + `{"error": ...}` para no encontrado).
3. **README desactualizado** (`barcode_scan2` vs `mobile_scanner` real): corregirlo cuando
   toque el repo (baja prioridad, el código manda).
4. **Si amplía la API:** ampliar el sealed `ScanResult` (y su test) con cada resultado nuevo.

## Ideas futuras (no comprometidas)

- Historial local de escaneos.
- Modo offline (respuesta cacheada del último resultado).
- Publicación en Play Store (hoy solo APK manual; requeriría el tramo Bubblewrap/keystore de
  la carpeta — ver incidencias de `quiz-historia/MEMORY.md`).

## Fuera de alcance

Backend propio, cuentas, multi-producto/catálogo — es el cliente MVP de un solo flujo.
