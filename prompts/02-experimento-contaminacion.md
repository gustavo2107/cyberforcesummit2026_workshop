# Experimento de contaminación

> El experimento que convierte la fama del caso, que es una desventaja, en el
> mejor instrumento didáctico del taller.

---

## El problema

Los modelos grandes leyeron los reportes de Dragos, FireEye y CISA sobre este
caso. Cuando el asistente "identifica" el malware a partir del PCAP, no puedes
saber si razonó desde la evidencia o si recordó del entrenamiento.

Esa ambigüedad contamina exactamente lo que el taller quiere medir. La única
salida honesta es medirla de frente.

## El procedimiento

Se corre **al final**, después de la revelación, con dos sesiones limpias y
separadas del asistente.

### Sesión A — ciega

Reglas de anclaje, y después:

```
Tengo una captura de red de un entorno industrial. No te voy a decir de qué
protocolo se trata ni de qué caso viene.

Analízala y dime qué ocurre. Recuerda: cada afirmación con su comando tshark y
sus números de trama.
```

### Sesión B — contaminada

Reglas de anclaje, y después:

```
Tengo la captura del ataque TRITON contra un controlador Triconex de Schneider
Electric, el caso de la planta petroquímica de 2017.

Analízala y dime qué ocurre. Recuerda: cada afirmación con su comando tshark y
sus números de trama.
```

## Qué comparar

Pon las dos salidas lado a lado y mide:

| Criterio | A (ciega) | B (contaminada) |
|---|---|---|
| ¿Cuántas afirmaciones traen comando y trama? | | |
| ¿Cuántas son [CONOCIMIENTO] disfrazado de [EVIDENCIA]? | | |
| ¿Notó que el `Run program` final fue rechazado? | | |
| ¿Encontró el `keyState`? ¿Lo dedujo o lo recitó? | | |
| ¿Aparecen detalles que **no están** en esta captura? | | |

## El resultado esperado

La sesión B suele producir un reporte **más completo y más confiado**, con
detalles correctos sobre TRITON que **no salen de estos 896 paquetes**:
atribución, sector de la víctima, el payload dentro del controlador, la cadena
de acceso inicial. Todo cierto, nada verificable aquí.

Y con frecuencia comete el error de la trama 892: como "sabe" que TRITON
ejecutó su payload, reporta ejecución exitosa sin leer que el controlador
respondió `Command rejected`.

Esa es la lección completa en un solo ejemplo: **el conocimiento previo mejora
la fluidez del reporte y empeora la fidelidad a la evidencia.** Y es
exactamente el fallo que cometería contra un caso nuevo, donde no tendrías
reportes públicos para descubrirlo.

## La pregunta de cierre

> Si la sesión B te da un reporte más largo, más seguro y parcialmente
> inventado — y tú no tuvieras los reportes públicos para compararlo —
> ¿cómo te habrías dado cuenta?

La respuesta es la regla de anclaje. Por eso está desde el minuto uno.
