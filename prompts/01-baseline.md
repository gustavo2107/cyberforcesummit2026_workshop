# Prompts de arranque

> Pega `00-reglas-de-anclaje.md` **antes** que cualquiera de estos.
> Un prompt sin las reglas produce un reporte bonito y sin valor probatorio.

La ruta de la evidencia, completa, va en el prompt. El servidor que ejecuta las
herramientas es su propio proceso: no sabe en qué carpeta estás tú.

```
/home/analista/taller/evidence/tricotools/malware_exec.pcap
```

---

## Cómo pedir bien — léelo antes de gastar tu primera consulta

Cada consulta tarda minutos. Estas tres cosas son la diferencia entre una
consulta que resuelve un bloque y tres que no llegan a nada.

**1. Pide el filtro.** Las herramientas aceptan un `display_filter` con la misma
sintaxis de la barra de Wireshark. Sin él te devuelven las 896 tramas, casi todas
vacías, y el resultado se corta antes de lo que te interesa.

**2. Pide las columnas.** `wireshark_get_packet_list` acepta `custom_columns`.
Filtro + columnas convierte una línea de tiempo entera en **una sola llamada**.

**3. Sube el límite, y desconfía del truncado.** Por omisión las herramientas
devuelven 20 o 100 líneas. Cuando la salida diga
`[Showing 100/897 lines]`, lo que tienes es una **muestra**, no el total — y una
conclusión sacada de una muestra no es `[EVIDENCIA]` de nada.

Por eso varios prompts de abajo terminan con *"si la salida viene truncada,
dímelo en lugar de generalizar"*. No es cortesía: es la defensa contra el error
más común de este laboratorio.

---

## Bloque 1 — Reconocimiento

```
Abre /home/analista/taller/evidence/tricotools/malware_exec.pcap.
No te voy a decir de qué entorno viene ni qué protocolo esperar.

Dime cuántos paquetes trae, cuánto dura la captura y su SHA-256.
Nombra la herramienta que usaste.
```

```
¿Qué hosts participan y en qué puertos? ¿Cuál dirías que es el cliente
y cuál el dispositivo? Justifícalo con algo medible y marca la
justificación como [INFERENCIA].

Si tu razonamiento depende de saber qué protocolo es, dímelo en lugar
de asumirlo.
```

## Bloque 2 — Forma del tráfico

```
Dame la jerarquía de protocolos de la captura.
```

> Mira los conteos por capa con cuidado antes de seguir. ¿Todas las capas tienen
> el mismo número de tramas? Si alguna no, ésa es una pregunta que vale la pena.

```
Extrae el campo ts.ts_cmd usando display_filter "ts.ts_cmd" y limit 900.
Dame la distribución de valores ordenada por frecuencia.
Si la salida viene truncada, dímelo en lugar de generalizar.
```

```
Dos comandos dominan y aparecen emparejados. Dime cuáles son, qué
porcentaje representan y qué hipótesis tienes sobre su función.
Marca la hipótesis como [INFERENCIA].

Después dime cuántas tramas quedan si los filtras, y qué comandos
aparecen en ellas.
```

## Bloque 3 — La secuencia

```
Dame la lista de paquetes con:
  display_filter: ts.ts_cmd && ts.ts_cmd!=19 && ts.ts_cmd!=108
  custom_columns: frame.number,frame.time_relative,ip.src,ts.ts_cmd
  limit: 250

Ésa es la línea de tiempo sin el ruido de fondo.
```

```
Agrupa esas tramas en fases por comportamiento y ponle nombre a cada una.
Cada fase con trama de inicio, trama de fin y tiempo relativo.
No inventes fases que no se sostengan en las tramas que ya viste.
```

```
¿Hay un patrón de comandos que se repita y que parezca marcar el inicio
de una operación de escritura? Muéstrame todas sus ocurrencias con
números de trama, y para cada una, qué respondió el dispositivo.
No resumas: quiero el código de cada respuesta.
```

```
Dame las últimas 10 tramas de esa línea de tiempo filtrada.
¿Cuál es el último comando significativo que envía el cliente, y qué
respondió el dispositivo exactamente? Léelo antes de interpretarlo.
```

## Bloque 4 — Estado del dispositivo

```
El comando de respuesta más frecuente trae información de estado.
Toma una trama de ésas y dame TODOS los campos que el disector decodifica
en ella, con su valor.
```

```
¿Alguno de esos campos describe el estado de un control físico del equipo?

Extrae ts.ts_cp_keyState y ts.ts_cp_runState con:
  display_filter: ts.ts_cp_keyState
  limit: 400

Dime en cuántas tramas aparece y si el valor cambia a lo largo de la
captura. Si la salida viene truncada, dilo en lugar de generalizar.
```

```
Ese valor: ¿qué implica operativamente? Marca claramente qué parte de tu
respuesta es [EVIDENCIA] de esta captura y qué parte es [CONOCIMIENTO] de
tu entrenamiento sobre este tipo de equipo.
```

---

## Las tres preguntas de control

Hazlas cuando algo te suene demasiado redondo. Las tres cuestan una consulta y
te ahorran meter una invención en el reporte.

```
¿De qué comando exacto salió esa afirmación? Pégame la salida cruda.
```

```
Ese número de trama, ¿lo leíste de una columna de números de trama, o de
otra columna? Enséñame la línea de donde lo sacaste.
```

```
¿Eso es una propiedad del tráfico capturado, o del programa que lo está
decodificando? Contéstalo antes de que lo ponga en el reporte.
```

> La tercera es la que más veces va a cambiar tu reporte. Un decodificador deja
> huellas propias en la salida —errores internos, capas auxiliares, avisos de
> formato— y **no son evidencia sobre el tráfico**. Una pista rápida: si algo
> aparece en el 100% de las tramas, es del instrumento, no del incidente.

---

## Prompts que NO debes usar

Estos parecen útiles y arruinan el ejercicio:

- ❌ *"¿Qué malware es este?"* — invita al modelo a recitar entrenamiento
- ❌ *"Resume qué pasó"* — produce narrativa sin anclaje
- ❌ *"¿Es esto TRITON?"* — pregunta cerrada; el modelo dirá que sí y
  construirá la evidencia hacia atrás
- ❌ *"Dame los IOCs"* — en esta captura no hay IOCs útiles, y pedirlos es
  invitar a que los invente
- ❌ *"Corre un análisis de seguridad completo"* — dispara las herramientas de
  detección automática, que sobre tráfico industrial devuelven ruido plausible

La diferencia entre un buen prompt y uno malo en forense es la misma que entre
una buena y una mala pregunta en un interrogatorio: **la pregunta cerrada obtiene
la respuesta que sugiere.**
