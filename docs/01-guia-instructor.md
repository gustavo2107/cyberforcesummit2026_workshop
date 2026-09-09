# Guía del instructor — 120 minutos

> ⚠️ **SPOILERS.** Lee `03-rubrica.md` antes que esto.

---

## Antes del día

- [ ] Correr `scripts/verify-setup.sh` en tu máquina y en una máquina limpia
- [ ] Publicar el brief y el enlace de descarga **48 h antes** — que nadie
      descargue nada en el salón
- [ ] Grabar el video de respaldo del flujo completo (ver abajo)
- [ ] Imprimir el workbook: hay quien trabaja mejor en papel
- [ ] Verificar que el venue no bloquea GitHub ni el registry de contenedores
- [ ] Preparar dos mesas de rescate con el entorno ya corriendo, para quien
      llegue con la laptop en mal estado

**El video de respaldo no es opcional.** Si el WiFi del venue se cae o el
proveedor de IA tiene un mal día, el taller se convierte en una demo guiada y
sigue funcionando. Sin el video, se acaba.

---

## Minuto a minuto

### 0:00 – 0:10 · Encuadre

No digas TRITON. No digas Triconex. No digas petroquímica.

Plantea la pregunta del taller: *¿puede un asistente de IA hacer análisis
forense de verdad, o solo suena a que lo hace?* Y la regla de anclaje: trama y
comando, o no existe.

Di explícitamente que **al final se premia la lista de afirmaciones no
ancladas**, no la ausencia de errores. Si no lo dices al principio, nadie la
entrega con honestidad.

### 0:10 – 0:20 · Verificación de entorno

Todos corren `verify-setup.sh`. Los que fallen van a las mesas de rescate.
No arranques el bloque siguiente hasta que todos tengan salida `TRISTATION`.

**Trampa conocida:** si alguien corre tshark como root, el disector no carga y
verá `UDP`/`data`. Ver `setup/SETUP.md`.

### 0:20 – 0:35 · Bloques 1 y 2 del workbook

Reconocimiento y forma del tráfico. Aquí van rápido y se confían.

Circula y siembra la pregunta incómoda: *¿tu asistente te dijo qué protocolo es
antes de que tú se lo dijeras? ¿Cómo lo supo?*

### 0:35 – 1:05 · Bloque 3 — la secuencia

El bloque grande. Déjalos trabajar.

A los 20 minutos, si nadie ha llegado a la trama 892, lanza la pista desde el
frente sin dar la respuesta:

> *Revisen la última respuesta del dispositivo. Todos los equipos que ya me
> enseñaron su línea de tiempo la leyeron mal.*

### 1:05 – 1:25 · Bloque 4 — el estado del dispositivo

Aquí está el hallazgo. Cuesta más de lo que parece porque el dato es
**constante**: 338 respuestas idénticas se leen como ruido, y tanto los humanos
como los modelos descartan lo constante.

Pista escalonada si se atoran:
1. *El comando que más se repite trae más información de la que están usando.*
2. *Uno de esos campos describe algo físico.*

### 1:25 – 1:40 · Revelación y contraste

Ahora sí: es TRITON. Proyecta la rúbrica.

Orden que funciona: primero el caso y el sector, después la línea de tiempo
real contra la de ellos, y al final el `keyState`. Guarda la llave para el
cierre — es el momento en que la sala hace silencio.

Contrasta contra Dragos, FireEye y CISA. Y haz la pregunta honesta: *de todo lo
que dicen esos reportes, ¿cuánto está de verdad en 896 paquetes?*

### 1:40 – 1:55 · Bloque 6 — la inyección

Ver `05-inyeccion.md`. No lo adelantes.

### 1:55 – 2:00 · Cierre

Tres ideas, en este orden:

1. El anclaje no es burocracia: es la única defensa contra la alucinación **y**
   contra la inyección. Una regla, dos problemas.
2. La IA no reemplazó al analista: le quitó el parsing. El juicio de la trama
   892 lo puso un humano.
3. El control que habría detenido TRITON costaba cero pesos y consistía en
   girar una llave.

Cierre alineado al summit: *el futuro no está escrito.*

---

## Lo que puede salir mal

**Nadie llega a la trama 892.** Normal. Es el punto del ejercicio, no un
fracaso. Úsalo: la evidencia estaba ahí y nadie la leyó.

**Un equipo dice "TRITON" a los cinco minutos.** Va a pasar. No lo desinfles —
pregúntale *cómo* lo supo. Si fue el modelo de memoria, acabas de tener el
mejor ejemplo posible del experimento de contaminación, gratis y en vivo. Pídele
que lo demuestre con tramas y ve qué pasa.

**Se cae la conexión al proveedor de IA.** Video de respaldo, y el workbook se
puede completar con tshark a mano. El taller aguanta.

**Alguien objeta que el caso es de 2017.** Ver `04-lecturas.md`, sección de
vigencia: la alerta del FBI de 2022, los ciclos de vida de 20-30 años en SIS, y
los grupos que hoy mapean lazos de control. Ten esa diapositiva lista, porque
la objeción va a salir.
