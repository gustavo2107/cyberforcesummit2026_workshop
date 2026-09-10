# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).

## [0.11.0] — 2026-09-10

### Cambiado
- `docs/07` §7.5 pasa de un marcador `<paquete-del-mcp-elegido>` a los
  **comandos reales de los tres servidores MCP**, tomados de sus repositorios:
  `pipx install mcp-wireshark`, `pipx install wireshark-mcp`, y el `git clone` +
  `npm install` de WireMCP. Con un ejemplo completo de punta a punta usando el
  más simple
- `setup/mcp-config.example.json` trae ahora una configuración funcional para
  `mcp-wireshark` y las dos alternativas listas para intercambiar, en lugar de
  marcadores de posición
- La tabla de `docs/06` incluye la columna de instalación

### Nota
- Los dos servidores en Python se instalan con `pipx` por la misma razón que
  `ollmcp`: PEP 668, y son aplicaciones de línea de comandos
- La sintaxis exacta del parámetro de `ollmcp` para apuntar al servidor queda
  marcada como "confirmar con `ollmcp --help`": no está verificada

## [0.10.3] — 2026-09-10

### Corregido
- `docs/07`, paso 7.4: el bloque de instalación de `ollmcp` no incluía
  `sudo apt install -y pipx`. Quien saltara directo a esa sección se topaba con
  `pipx: command not found` — el mismo tropiezo que la corrección anterior
  pretendía evitar. El bloque es ahora autocontenido
- Documentado el segundo tropiezo de la misma secuencia: tras instalarlo,
  `ollmcp` queda en `~/.local/bin` y no aparece hasta `exec $SHELL`. Con la
  comprobación por ruta directa para distinguir "no se instaló" de "no está en
  el PATH"
- `setup/SETUP.md` amplía la trampa de PEP 668 con ambos casos

> Las dos correcciones salieron de aprovisionar la VM de verdad. Ninguna se
> habría encontrado leyendo la documentación.

## [0.10.2] — 2026-09-10

### Corregido
- **`pip install --user` fallaba en Ubuntu 24.04.** Desde esa versión rige
  PEP 668: el Python del sistema lo gestiona apt y pip se rechaza con
  `externally-managed-environment`. El bootstrap y la documentación usaban ese
  comando en cinco lugares, así que la instalación del cliente MCP fallaba en
  la plataforma que el propio repositorio recomienda
- `ollmcp` se instala ahora con **pipx**, que además es la vía correcta para una
  aplicación de línea de comandos: entorno aislado y binario en el PATH
- `crcmod` se toma del repositorio del sistema (`python3-crcmod`), con
  `--break-system-packages` como último recurso — es una librería, no una
  aplicación, así que pipx no aplica
- `pipx` agregado a los paquetes base
- Nueva trampa documentada en `setup/SETUP.md`

> Encontrado al provisionar la VM por primera vez. Es el tipo de falla que sólo
> aparece corriendo el procedimiento completo en la plataforma real.

## [0.10.1] — 2026-09-09

### Cambiado
- Se retira del `SYSTEM` del Modelfile la tabla de códigos de comando de
  TriStation. Era defendible —es la misma traducción que el disector imprime—
  pero si hay que argumentar por qué algo no es una fuga, es mejor quitarlo. El
  disector traduce los códigos solo, así que la tabla no aportaba nada
- El `SYSTEM` ahora es verificablemente limpio: no contiene `keyState`, ni las
  tramas 75 y 887, ni `Run program`, ni `Command rejected`, ni código alguno.
  Sólo método: que el disector traduce por él, y cómo descubrir los campos
  con `tshark -V`

## [0.10.0] — 2026-09-09

### Agregado
- `setup/Modelfile` — variante afinada del modelo para trabajo forense. Los
  valores por omisión de Ollama hacen fallar este laboratorio por razones de
  configuración, no del modelo:
  - `num_ctx` por omisión es **2048 tokens**. Un solo `tshark -V` ya son
    cientos, y una línea de tiempo de 216 tramas no cabe: el modelo pierde la
    evidencia a media sesión y, como no sabe decir "se me olvidó", rellena
  - `temperature` por omisión es **0.8**, un ajuste para escritura creativa que
    fabrica justo la confabulación que el taller enseña a detectar
- El afinado sube el contexto a 8192, baja la temperatura a 0.1 con seed fijo
  —lo que hace el taller reproducible y el video de respaldo fiel a lo que ve
  la sala— e incorpora las reglas de anclaje y la instrucción de llamar una
  herramienta a la vez, contra la debilidad conocida de los modelos pequeños
  encadenando llamadas dependientes
- `bootstrap-vm.sh` lo crea; `verify-setup.sh` avisa si falta

### Sin alterar
- **No se toca el disector, la evidencia ni la detección de TRITON.** El
  `SYSTEM` da referencia de protocolo, no respuestas: los códigos de comando son
  los que el disector ya imprime, y para descubrir los campos le dice al modelo
  que corra `tshark -V` en lugar de listárselos. No menciona el `keyState`, ni
  las tramas 75 y 887, ni que el `Run program` final fue rechazado

## [0.9.0] — 2026-09-09

El laboratorio pasa a correr con un modelo de lenguaje **local**.

### Cambiado
- **Todo el análisis corre ahora en la propia VM.** Sin cuentas, sin tokens y
  sin depender de la red del venue durante el taller. La evidencia nunca sale de
  la máquina, que en un taller de forense OT importa
- **Specs de la VM revisadas:** de 2 vCPU / 2 GB a **4 vCPU / 8 GB mínimo**
  (16 GB recomendado) y 30 GB de disco. Con 2 GB el modelo no arranca
- `scripts/bootstrap-vm.sh` instala Ollama, descarga los pesos e instala el
  cliente MCP. Se omite con `SIN_MODELO=1` para quien prefiera la nube
- `scripts/verify-setup.sh` reporta el estado del modelo sin hacer fallar la
  verificación, porque la ruta con proveedor en la nube sigue siendo válida
- `docs/07`, `docs/10` y `docs/11` reescritos en consecuencia

### Decisión registrada
- Runtime **Ollama**, modelo de referencia **Qwen3.5 4B**, cliente **`ollmcp`**
- El modelo se eligió por su desempeño llamando herramientas, no por su prosa:
  97.5% de acierto sobre 40 casos deterministas de tool calling, primer lugar
  por encima de modelos cinco veces mayores, en 3.4 GB
- Efecto secundario documentado: un modelo de 4B sabe menos de TRITON que uno de
  frontera. Eso limpia el análisis a ciegas y debilita el experimento de
  contaminación, que conviene correr aparte contra un modelo grande

### Sin verificar
- **La cadena Ollama + modelo + cliente MCP no está verificada de punta a
  punta**, a diferencia del resto del repositorio. Está documentada desde
  fuentes y marcada como tal en `docs/07-laboratorio-vm.md`. Hay que validarla
  en la VM antes del taller

## [0.8.0] — 2026-09-09

### Agregado
- `docs/11-descargas.md` — inventario completo de todo lo que hay que descargar.
  Las instrucciones estaban repartidas en seis archivos y no había una lista
  consolidada, que es justo lo que se necesita para pre-descargar y no depender
  del WiFi del venue
- Pesos medidos donde se pudo medir (tricotools 484 KB, gitleaks 7.8 MB),
  huellas SHA-256 de verificación, y cómo pre-descargar los `.deb` con
  `apt-get -d` para armar un paquete offline
- Sección explícita de lo que **no** se descarga: el laboratorio no usa ni
  distribuye binarios de malware

## [0.7.0] — 2026-09-09

### Agregado
- `docs/10-ejecucion.md` — cierra el hueco entre "el entorno funciona" y "estoy
  impartiendo el taller". El repositorio documentaba bien la provisión de la VM,
  pero cuando `verify-setup.sh` daba verde no decía qué seguía: la secuencia
  estaba repartida entre el workbook, la guía del instructor y los prompts, sin
  que nada indicara el orden
- **Plan B sin IA**: los comandos `tshark` que completan cada bloque del
  workbook a mano, verificados uno por uno contra la evidencia. El laboratorio
  ya no depende de que el proveedor de IA esté disponible

### Cambiado
- El README enlaza a `10-ejecucion.md` justo después del inicio rápido, para que
  nadie termine el bootstrap sin saber a dónde ir

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
