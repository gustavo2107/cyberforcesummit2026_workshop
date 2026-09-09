# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).

## [0.2.0] — 2026-09-09

Enfoque en laboratorio sobre VM Linux y documentación de nivel profesional.

### Agregado
- `docs/07-laboratorio-vm.md` — provisión de la VM paso a paso, con
  especificación, distribución a participantes y lista de verificación previa
- `docs/06-herramientas.md` — la cadena técnica, criterios de elección y lo que
  el taller deliberadamente no usa
- `docs/README.md` — índice, orden de lectura y qué se reparte cuándo
- `scripts/bootstrap-vm.sh` — provisión idempotente de cero a verificada,
  con detección de gestor de paquetes y rechazo explícito de ejecución como root
- `Makefile` — objetivos `bootstrap`, `evidence`, `verify`, `stats`, `triton`,
  `clean`, `check-docs`
- `.editorconfig`

### Cambiado
- La VM Linux nativa es ahora la ruta principal del laboratorio; Docker queda
  como alternativa
- `README.md` reescrito: tabla de ficha, inicio rápido con `make`, objetivos
  documentados

## [0.1.0] — 2026-09-09

Versión inicial.

### Agregado
- Brief del escenario, workbook de 6 bloques y rúbrica verificada contra la
  evidencia ejecutando `tshark` con el disector TriStation
- Guía del instructor minuto a minuto, con modos de falla conocidos
- Diseño del ejercicio de inyección sobre artefactos sintéticos, preservando la
  integridad de la evidencia real
- Prompts con reglas de anclaje y experimento de contaminación por entrenamiento
- `fetch-evidence.sh` y `verify-setup.sh`
- Entorno Docker con usuario sin privilegios
- `NOTICE.md` con licencias, procedencia y la nota sobre atribución de la
  víctima

### Hallazgos verificados que sostienen la rúbrica
- 896 paquetes, 435.39 s, `192.168.1.88` ↔ `192.168.1.2` sobre UDP/1502
- 75% del tráfico es polling de estado (comandos 19/108)
- Detección de TRITON en las tramas 75 y 887, firmas `0x423c976f` y `0xdfa1288d`
- El `Run program` final (trama 891) fue respondido con `Command rejected`
  (trama 892)
- `keyState = 0x01 [Program]` constante en las 338 respuestas de estado: la
  llave física del controlador nunca salió de posición PROGRAM
