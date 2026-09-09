# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).

## [0.6.0] — 2026-09-09

### Agregado
- `docs/09-mapeo-attack.md` — mapeo a MITRE ATT&CK for ICS v19.2, verificado
  contra las páginas vivas, con dos tablas separadas: lo demostrable con la
  captura (8 técnicas) y lo documentado por los reportes (~30)

### Corregido
- **La referencia a MITRE era incorrecta.** El repositorio citaba a Triton como
  S0013 en el wiki `collaborate.mitre.org/attackics`, descontinuado. En el
  ATT&CK actual **S0013 es PlugX**. Las referencias correctas son S1009
  (software) y C0030 (campaña)

### Determinación analítica registrada
- El download se mapea a **T0843.003 Program Append**, no a .001 ni .002:
  `runState = Running` durante toda la captura descarta Download All, y el uso
  de `Allocate program` apunta a append sobre edición. Corroborado por S1009
  (`SafeAppendProgramMod`) y por el mapeo de MITRE de la campaña C0030

## [0.5.0] — 2026-09-09

### Agregado
- Tres diagramas Mermaid, renderizados nativamente por GitHub:
  - `README.md` — la cadena técnica, mostrando la bifurcación entre trabajar
    con y sin el disector, que es donde vive todo el diseño del taller
  - `README.md` — cómo transcurren las 2 horas, con los tres bloques donde
    ocurre el aprendizaje resaltados
  - `docs/03-rubrica.md` — la secuencia del ataque en cuatro fases, con el
    `keyState` constante separado como condición y no como paso

### Cambiado
- Se retira la sección de higiene del README; las instrucciones para activar el
  hook se reubican en `docs/06-herramientas.md`

## [0.4.0] — 2026-09-09

Higiene del repositorio y preparación para publicación.

### Agregado
- `.githooks/pre-commit` — bloquea commits que contengan tokens, llaves
  privadas, datos personales, o intentos de versionar la evidencia de terceros.
  Usa gitleaks si está disponible y, si no, corre comprobaciones básicas sin
  dependencias
- `.gitleaks.toml` — configuración extendida sobre las reglas por defecto
- `scripts/install-hooks.sh` y objetivo `make hooks`
- `docs/08-publicacion.md` — checklist para pasar el repositorio a público, con
  el registro de por qué se publica completo (incluida la rúbrica)

### Razonamiento registrado
- El repositorio se publicará completo: quien vaya a replicar el taller
  necesita la rúbrica y la guía del instructor. El riesgo de que los
  participantes lleguen a las respuestas se resuelve por temporalidad —el
  repositorio permanece privado hasta que termine la sesión— y no por
  ocultamiento

## [0.3.0] — 2026-09-09

Anonimización y etiquetado explícito de datos sintéticos, previo a publicación.

### Cambiado
- `evidence/companion/` renombrada a `evidence/datos-sinteticos/`, y sus
  archivos con prefijo `sintetico-`, para que la naturaleza ficticia sea
  evidente desde el árbol de archivos
- La organización del escenario es ahora explícitamente ficticia: *Industrias
  ACME de México, S.A. de C.V.*, Planta ACME-1
- `LICENSE`: titular genérico en lugar de un nombre personal
- Avisos de datos sintéticos en `README.md`, `NOTICE.md`,
  `docs/00-brief-escenario.md` y `evidence/datos-sinteticos/README.md`

### Eliminado
- Nombres de personas y direcciones de correo de todos los archivos
- Nombres de personas y correos de los metadatos de los commits
- Identificadores de sesión de los mensajes de commit

### Convenciones adoptadas
- Sin nombres de personas en ningún artefacto: las tareas y tickets se asignan
  a áreas responsables
- Direcciones IP del escenario en rango privado RFC 1918
- "ACME" como marcador de entidad ficticia

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
