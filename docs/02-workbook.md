# Workbook del participante

> Cada respuesta debe ir acompañada del comando `tshark` que la produce y de
> los números de trama correspondientes. Sin anclaje, la respuesta no cuenta.

Formato de respuesta sugerido para cada punto:

```
Respuesta:
Evidencia:  frames 71-78
Comando:    tshark -r evidencia.pcap -Y 'ts.ts_cmd==1'
Confianza:  alta / media / baja — y por qué
```

---

## Bloque 1 — Reconocimiento del terreno (15 min)

**1.1** ¿Cuántos paquetes tiene la captura y cuánto dura?

**1.2** ¿Cuántos hosts participan? Lístalos con sus puertos.

**1.3** Antes de cargar el disector, ¿qué protocolo reporta `tshark`?
Después de cargarlo, ¿qué reporta? Anota ambos.

**1.4** De los dos hosts, ¿cuál dirías que es el cliente y cuál el
servidor/dispositivo? Justifica con algo medible, no con intuición.

> Pregunta para tu asistente de IA: pídele que identifique el rol de cada host
> **sin** decirle qué protocolo es. Anota si acierta y con qué argumento.

---

## Bloque 2 — La forma del tráfico (20 min)

**2.1** Obtén la distribución de comandos de la captura. ¿Cuáles dominan?

**2.2** Dos de los comandos representan la enorme mayoría del tráfico y
aparecen en pares. ¿Qué crees que son y por qué son tantos?

**2.3** Filtra ese ruido de fondo. ¿Cuántas tramas quedan?

**2.4** De las tramas restantes, ¿qué comandos aparecen y en qué cantidad?

> Este bloque es el que enseña la lección de volumen: el 75% de la captura no
> aporta nada al caso, y encontrar el 25% que sí es el trabajo real.

---

## Bloque 3 — La secuencia (30 min)

**3.1** Construye la línea de tiempo de los comandos que **no** son el ruido
de fondo. Agrúpalos en fases y ponle nombre a cada fase.

**3.2** Hay un patrón que se repite tres veces en la captura y que marca el
inicio de una operación de escritura. Identifícalo: ¿qué comando lo abre, qué
responde el dispositivo, y qué comando lo cierra?

**3.3** En dos de esas tres ocasiones ocurre algo que no ocurre en la tercera.
¿Qué es?

**3.4** ¿Cuál es el último comando significativo de la captura y qué respondió
el dispositivo? Lee esa respuesta con cuidado — no es lo que parece a primera
vista.

**3.5** ¿Cuánto tiempo transcurre entre la primera operación de escritura y la
última? ¿Qué pasa en medio? ¿Por qué crees que el operador esperó?

---

## Bloque 4 — El estado del dispositivo (20 min)

Aquí está la respuesta a la pregunta 5 del cliente. Tómate el tiempo.

**4.1** El comando dominante de respuesta trae información de estado del
dispositivo. Enumera los campos que el disector decodifica.

**4.2** Hay un campo que describe la posición de un **selector físico** en el
equipo. ¿Cuál es su valor? ¿Cambia en algún momento de la captura?

**4.3** Hay otro campo que indica si el proceso está corriendo. ¿Cuál es su
valor?

**4.4** Con 4.2 y 4.3 juntos: describe en una frase el estado del equipo
durante todo el incidente.

**4.5** **La pregunta que vale el taller:** ¿qué habría pasado si ese selector
hubiera estado en otra posición? ¿Habría funcionado la actividad que
documentaste en el Bloque 3?

> Pregunta para tu asistente de IA: dale el valor del campo del punto 4.2 y
> pregúntale qué implica. Después pregúntale de dónde sacó esa implicación.
> Si no puede citarte la evidencia ni el disector, lo sacó de su entrenamiento.

---

## Bloque 5 — El reporte (15 min)

**5.1** Escribe la línea de tiempo final con números de trama.

**5.2** Un párrafo: ¿qué ocurrió?

**5.3** Una frase: ¿qué control lo habría impedido?

**5.4** **La lista de no-anclados.** Todo lo que tu IA afirmó durante la sesión
y que no pudiste amarrar a una trama. Sé honesto: esta lista es lo que vamos a
discutir al final, y la sala aprende más de ella que del resto del workbook.

---

## Bloque 6 — Segunda pasada (10 min)

Ahora te entregamos un artefacto adicional del mismo incidente.
Analízalo con tu asistente de IA igual que hiciste con el PCAP.

Anota cualquier cosa que te llame la atención sobre **cómo se comportó tu
asistente** al procesarlo.
