# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).

## [0.14.0] — 2026-09-10

`docs/10-ejecucion.md` se reescribe con el guion completo de la sesion. Era el
documento mas desactualizado del repositorio: seguia mostrando cinco lineas de
`verify-setup.sh` cuando ya son ocho, y su pregunta de control le pedia al
modelo un `tshark -r malware_exec.pcap` que el modelo no ejecuta —llama
herramientas MCP, con ruta absoluta.

### Agregado — seccion 4, las nueve herramientas

Tabla de las 9 habilitadas con que hace cada una y **su equivalente en
`tshark`**, para que el instructor pueda traducir en voz alta lo que ve en
pantalla. Mas los tres parametros que cambian todo:

- `display_filter` — filtra **antes** de devolver. Sin el llegan 896 lineas
- `custom_columns` — convierte la linea de tiempo en **una sola llamada**
- `limit` / `offset` — por omision 20 en `get_packet_list`, 100 en
  `extract_fields`. Es la trampa que produjo el `[Showing 100/897 lines]` del
  que el modelo generalizo

### Agregado — seccion 5, el guion consulta por consulta

Doce consultas en orden. Cada una trae:

- **el texto que se pega**, con la ruta absoluta
- **que herramienta debe llamar** el modelo
- **que debe salir** — la verdad de referencia
- **el comando `tshark` con el que el instructor lo comprueba** mientras circula

Incluye la consulta que ensenia la tecnica —filtro mas columnas para la linea de
tiempo— y la consulta 12, donde el modelo traduce *key* como "tecla" y el taller
se cierra solo.

### Cambiado — la pregunta de control (paso 3.3)

Pasa a ser una sola consulta que valida **tres cosas a la vez**: que aparezca
`tristation` entre los protocolos, que sean 896 tramas, y que el SHA-256 cuadre
con la huella del repositorio. Cadena de custodia y disector en un solo turno.

### Agregado — los comandos del cliente

Tabla de `/mc`, `/sc`, `/t`, `/cc`, `/m`, `/h`, `/q`. Con la advertencia sobre
`/cc`: borra el contexto acumulado, y el laboratorio depende de que el modelo
recuerde lo que ya midio.

### Reescrito — `prompts/01-baseline.md`

- Ruta absoluta en todos los prompts
- Nueva seccion "Como pedir bien", con las tres tecnicas que ahorran consultas
- **Las tres preguntas de control** que el participante se hace a si mismo:
  de que comando salio, de que columna salio, y si es propiedad del trafico o
  del decodificador
- Un prompt prohibido mas: "corre un analisis de seguridad completo", que
  dispara la deteccion automatica

### Cambiado — Plan B con explicaciones

Cada bloque de `tshark` lleva ahora que hace cada comando, y se agrega una tabla
de las seis banderas con las que se hace todo el laboratorio.

## [0.13.0] — 2026-09-10

Segunda corrida completa en la VM, esta vez recorriendo el flujo del workbook.
Todo lo que sigue esta verificado corriendo y es reproducible con `seed 42`.

### Corregido — la trampa del flag `-m`

- **`ollmcp -m triton-analista` NO carga el modelo afinado.** `ollama` etiqueta
  el modelo como `triton-analista:latest` y `ollmcp` compara la cadena completa:
  avisa en una sola linea —`Requested model triton-analista is not available —
  using qwen3.5:4b instead`— y **arranca con el modelo base**
- Es la trampa mas silenciosa del laboratorio: las herramientas funcionan, el
  disector se hereda, las respuestas se ven bien. Lo que se pierde es el
  `SYSTEM` del `Modelfile` — o sea, exactamente lo que el taller mide
- El arranque correcto es **`ollmcp -j setup/mcp-config.minimo.json`**, sin
  `-m`: el `config.json` ya trae el modelo. Corregido en README, `docs/06`,
  `docs/07`, `docs/10`, `SETUP.md`, el `Modelfile` y `bootstrap-vm.sh`
- Comprobacion de un vistazo: el prompt del cliente debe decir
  `triton-analista/…`, no `qwen3.5/…`

### Agregado — `setup/ollmcp-config.json`

La configuracion del cliente tal como quedo verificada. Se instala con
`cp setup/ollmcp-config.json ~/.config/ollmcp/config.json` y trae:

- `num_ctx 8192`, `temperature 0.1`, `seed 42`
- **La curaduria de herramientas: 9 habilitadas de 52.** Las 43 apagadas
  incluyen toda la deteccion automatica del servidor —`detect_beaconing`,
  `detect_port_scan`, `extract_credentials`, `yara_scan`— que sobre esta captura
  no produce hallazgos, produce ruido plausible. El propio servidor recomienda
  tres de ellas al abrir el archivo, y un modelo pequeno sigue recomendaciones:
  la curaduria es lo que impide que el taller se vuelva una caceria de falsos
  positivos
- HIL activo, `loopLimit 7`, razonamiento visible

### Reescrito — `docs/03`, los modos de falla del analista

La seccion de artefactos pasa a ser el catalogo completo, con las salidas
textuales. Tesis en una frase: **el modelo extrae bien y explica mal**.

Tres familias, todas observadas:

- **A · Artefacto de la herramienta leido como propiedad del trafico** — el bug
  de Lua (`TriStation.lua:611`), el aviso de *padding* de Ethernet, y
  `_ws.lua.fake` ofrecido como "posible inyeccion de codigo". El argumento que
  los mata a los tres: **aparece en 896 de 896 tramas**; un indicador presente
  en el 100% de una captura no distingue nada
- **B · Columna mal leida convertida en dato duro** — la columna `Frequency` de
  *expert info* leida como numero de trama: el modelo escribio "(frame 2)" con
  etiqueta `[EVIDENCIA]`. **Las tramas son la 75 y la 887.** Tambien afirmo "en
  todas las tramas" sobre una salida truncada en `[Showing 500/897 lines]`
- **C · Etiqueta mal puesta** — marco `[CONOCIMIENTO]` sobre evidencia real y
  `[EVIDENCIA]` sobre lo inventado. Las etiquetas no son la verificacion: son el
  sitio donde se aplica

Y el caso central, sobre el hallazgo mismo: pedido de extraer `ts_cp_keyState`,
el modelo **acerto el valor constante `0x01` y tradujo *key* como "tecla"** en
vez de llave fisica. El disector entrega el campo; el significado lo pone el
humano. Es la tesis del taller demostrada sobre su propia respuesta.

Se agrega tambien el A/B contra el modelo base, que salio de una corrida
accidental: misma pregunta, misma evidencia, mismas 9 herramientas. Sin el
`SYSTEM`, el modelo respondio "el protocolo principal es **UDP**" teniendo
`eth:ethertype:ip:udp:tristation` en la mano.

### Cambiado — `docs/10`

- Pegar `prompts/00-reglas-de-anclaje.md` pasa de refuerzo a **requisito**: el
  `SYSTEM` del `Modelfile` por si solo no basta. En el ensayo el modelo respondio
  sin una sola etiqueta hasta que se le recordaron
- Anadida la comprobacion del prompt del cliente antes de cada sesion

### Notas de la herramienta

- `wireshark_get_file_info` imprime el **SHA-256**, que cuadra con la huella del
  repositorio: mejor pregunta de control que la anterior, valida cadena de
  custodia y disector de un tiro
- `extract_fields` devuelve una linea por trama, vacias incluidas: 896 lineas de
  las que solo 338 traen dato. Conviene filtrar antes de extraer
- La jerarquia de protocolos muestra `ts.crc16` en 895 y `text` en 1 — una trama
  sin CRC y con capa de texto, casi con seguridad la misma del error de Lua.
  Buena pista para el Bloque 2

## [0.12.0] — 2026-09-10

Primera corrida completa del laboratorio con el modelo local en la VM, de punta
a punta. Todo lo que sigue está verificado corriendo, no leído de una fuente.

### Corregido — el servidor MCP

- **`mcp-wireshark` 0.5.0 NO funciona.** Instala limpio con `pipx` sobre Python
  3.12.3 y revienta al listar herramientas:
  `AttributeError: 'Server' object has no attribute 'list_tools'`. Es
  incompatibilidad con el SDK actual de MCP; no hay flag que lo arregle
- **El servidor del taller es ahora `wireshark-mcp`**
  ([bx33661](https://github.com/bx33661/Wireshark-MCP)), `pipx install
  wireshark-mcp`. Es el único que se probó hasta la salida
- `setup/mcp-config.minimo.json` y `mcp-config.example.json` apuntan a él.
  `mcp-wireshark` queda en el archivo de ejemplo marcado como no funcional
- `scripts/bootstrap-vm.sh` lo instala solo, y el mensaje de cierre ya no manda
  a elegir servidor ni usa `--mcp-server`

> Se documentaba `mcp-wireshark` como "el más simple" habiendo comprobado sólo
> que **se instalaba**. Instalar no es funcionar. La regla que queda para este
> repositorio: nada se marca como verificado si la prueba no llegó a la salida.

### Verificado — la cadena completa

- `ollmcp` → `wireshark-mcp` → `tshark` del sistema → `TriStation.lua`
- **El disector se hereda**, que era la incógnita que decidía si el taller era
  viable. La prueba es el campo `frame.protocols`:
  `"eth:ethertype:ip:udp:tristation"`
- Documentado en `docs/07` §7.6 y `docs/10` §3.3 como comprobación explícita

### Agregado — `docs/07` §7.5.1, fijar los parámetros en el cliente

- `ollmcp` lleva su **propia** configuración de modelo. Puede arrancar sin
  enviar `num_ctx`, `temperature` ni `seed` —se ven como `-` en el panel `/mc`—
  y entonces el afinado del `Modelfile` **no se aplica**
- Procedimiento: fijarlos en `/mc`, guardar con `/sc`; queda en
  `~/.config/ollmcp/config.json`
- Ese archivo tiene que estar **dentro de la OVA** antes de exportarla, o cada
  participante arranca con una configuración distinta. Añadido a la lista de
  verificación de `docs/07` §10 y al paquete offline de `docs/11`

### Agregado — `docs/03`, los artefactos de la herramienta

La sección nueva más importante del repositorio, y sale de lo que de verdad
hizo el modelo en el ensayo: **un hallazgo crítico correcto envuelto en dos
sobreinterpretaciones plausibles**.

- Acertó las dos tramas con `TRITON malware detected!`
- Leyó `Lua Error: TriStation.lua:611: negative length in tvb range` y concluyó
  "paquetes corruptos". Es un **bug del disector** —dispara una vez, siempre la
  misma trama— no una propiedad del tráfico
- Leyó `Didn't find padding of zeros...` y lo ofreció como posible
  "manipulación del paquete". Es un aviso normal de Wireshark sobre el relleno
  de la trama Ethernet
- Las reglas de anclaje **no atrapan esto**: el modelo etiquetó las dos como
  `[EVIDENCIA]` y, en su lógica, lo eran. Falta la pregunta siguiente —*¿es una
  propiedad del tráfico o del decodificador?*— que ahora es criterio de
  calificación con peso alto

### Agregado — artefactos de la herramienta y ritmo

- La numeración de herramientas cambia entre versiones del servidor: se dicta
  el **nombre**, nunca el número
- Pedir la lista de paquetes con `limit: 1` devuelve cabeceras, no contenido
- El resumen de *expert info* da frecuencias, **no números de trama**
- **Cada consulta tardó del orden de tres minutos** sobre CPU en la VM de
  referencia. Los tiempos de los bloques se dejan como están —dependen por
  entero del equipo de cada quien— pero ahora la guía manda medirlo en el
  ensayo y **decirlo en voz alta**: sin ese aviso alguien reinicia el cliente a
  media consulta y pierde todo lo anclado

## [0.11.2] — 2026-09-10

### Corregido y verificado
- **El flag de `ollmcp` para apuntar al servidor es `--servers-json` (`-j`)**,
  no `--mcp-server`. Estaba marcado como no verificado y resultó equivocado:
  `--mcp-server` existe, pero espera la ruta a un script `.py` o `.js`, no el
  nombre de un binario, y responde `Server script not found`
- Para un servidor instalado como binario en el PATH —como `mcp-wireshark`— la
  vía es el archivo JSON
- Documentado que hay que usar `mcp-config.minimo.json` y no el de ejemplo: éste
  lleva comentarios dentro del JSON que un parser estricto rechaza

## [0.11.1] — 2026-09-10

### Verificado
- **`mcp-wireshark` 0.5.0 instala correctamente con `pipx`** en Ubuntu 24.04 con
  Python 3.12.3. El binario queda en `~/.local/bin/mcp-wireshark`. Es el primer
  eslabón de la cadena del modelo local que pasa de "documentado desde fuentes"
  a "verificado corriendo"
- La versión queda fijada en la documentación, igual que tshark 4.2.2

### Agregado
- `setup/mcp-config.minimo.json` — configuración sin comentarios ni claves
  auxiliares, por si el cliente rechaza el JSON comentado del archivo de ejemplo

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
