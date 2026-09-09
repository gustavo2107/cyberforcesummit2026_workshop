# Prompts de arranque

> Usa `00-reglas-de-anclaje.md` **antes** que cualquiera de estos.
> Un prompt sin las reglas produce un reporte bonito y sin valor probatorio.

---

## Bloque 1 — Reconocimiento

```
Tengo una captura de red en malware_exec.pcap. No te voy a decir de qué
entorno viene ni qué protocolo esperar.

Empieza por lo básico: cuántos paquetes, cuánto dura, qué hosts participan y
en qué puertos. Dame los comandos que usaste.
```

```
Con base solo en lo que acabas de medir: ¿cuál de los dos hosts dirías que es
el cliente y cuál el dispositivo? Justifícalo con algo medible. Si tu
razonamiento depende de saber qué protocolo es, dímelo en lugar de asumirlo.
```

## Bloque 2 — Forma del tráfico

```
Dame la distribución completa de comandos del protocolo en esta captura,
ordenada por frecuencia.
```

```
Dos comandos dominan el tráfico y aparecen emparejados. Dime cuáles son, qué
porcentaje representan, y qué hipótesis tienes sobre su función. Marca la
hipótesis como [INFERENCIA].
```

```
Filtra ese ruido de fondo y dime cuántas tramas quedan y qué comandos
aparecen en ellas.
```

## Bloque 3 — Secuencia

```
Construye una línea de tiempo de las tramas restantes. Agrúpalas en fases por
comportamiento y ponle nombre a cada fase. Cada fase debe indicar la trama de
inicio, la de fin y el tiempo relativo.
```

```
¿Hay algún patrón de comandos que se repita y que parezca marcar el inicio de
una operación de escritura? Si lo hay, muéstrame todas sus ocurrencias con
números de trama.
```

```
Para cada una de esas ocurrencias: ¿qué respondió el dispositivo? Cítame la
trama de respuesta y su código. No resumas: quiero el código de cada una.
```

```
¿Cuál es el último comando significativo que envía el cliente, y qué respondió
el dispositivo exactamente? Léelo con cuidado antes de interpretarlo.
```

## Bloque 4 — Estado del dispositivo

```
El comando de respuesta más frecuente trae información de estado. Enumera
todos los campos que el disector decodifica en él y dame el valor de cada uno.
```

```
¿Alguno de esos campos describe el estado de un control físico del equipo?
¿Cuál es su valor y cambia en algún momento de la captura? Verifícalo sobre
todas las tramas, no sobre una muestra.
```

```
Ese valor: ¿qué implica operativamente? Marca claramente qué parte de tu
respuesta es [EVIDENCIA] de esta captura y qué parte es [CONOCIMIENTO] de tu
entrenamiento sobre este tipo de equipo.
```

---

## Prompts que NO debes usar

Estos parecen útiles y arruinan el ejercicio:

- ❌ *"¿Qué malware es este?"* — invita al modelo a recitar entrenamiento
- ❌ *"Resume qué pasó"* — produce narrativa sin anclaje
- ❌ *"¿Es esto TRITON?"* — pregunta cerrada; el modelo dirá que sí y
  construirá la evidencia hacia atrás
- ❌ *"Dame los IOCs"* — en esta captura no hay IOCs útiles, y pedirlos es
  invitar a que los invente

La diferencia entre un buen prompt y uno malo en forense es la misma que entre
una buena y una mala pregunta en un interrogatorio: la pregunta cerrada obtiene
la respuesta que sugiere.
