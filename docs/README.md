# Índice de documentación

## Orden de lectura para el instructor

Si vas a impartir el taller, léelos en este orden:

1. **[04-lecturas.md](04-lecturas.md)** — las fuentes primarias. Empieza aquí,
   semanas antes. Sin haber leído el tratado de FireEye sobre TriStation, el
   PCAP no te va a decir nada.
2. **[03-rubrica.md](03-rubrica.md)** ⚠️ — la verdad de referencia, verificada
   comando por comando. Es el documento más importante del repositorio.
3. **[07-laboratorio-vm.md](07-laboratorio-vm.md)** — construye la VM y
   verifícala. Hazlo pronto: si algo falla, quieres saberlo con semanas de
   margen.
4. **[06-herramientas.md](06-herramientas.md)** — qué hace cada pieza y por qué
   está elegida así.
5. **[01-guia-instructor.md](01-guia-instructor.md)** ⚠️ — el guion minuto a
   minuto.
6. **[05-inyeccion.md](05-inyeccion.md)** ⚠️ — el ejercicio final.
7. **[08-publicacion.md](08-publicacion.md)** — qué hacer el día que el
   repositorio pase a público, y por qué se publica completo. Léelo cuando
   termine el summit.
8. **[00-brief-escenario.md](00-brief-escenario.md)** y
   **[02-workbook.md](02-workbook.md)** — lo que van a recibir los
   participantes. Léelos al final, con ojos de participante.

## Lo que se reparte

| Cuándo | Qué |
|---|---|
| 48 h antes | `00-brief-escenario.md`, `07-laboratorio-vm.md`, huellas SHA-256 |
| Al inicio | `02-workbook.md`, `prompts/00-reglas-de-anclaje.md`, `prompts/01-baseline.md` |
| En la revelación | `03-rubrica.md`, `04-lecturas.md` |
| Al cierre | `prompts/02-experimento-contaminacion.md` |

## Lo que NO se reparte antes de tiempo

Los archivos marcados ⚠️ contienen las respuestas: `01-guia-instructor.md`,
`03-rubrica.md` y `05-inyeccion.md`.

Si vas a publicar este repositorio a los participantes antes del evento,
considera mantener esos tres en una rama separada o en un repositorio privado
distinto — basta con que alguien curiosee el árbol de archivos para que el
taller pierda la mitad de su valor.

## Mapa rápido

```
00-brief-escenario     El escenario que reciben. Sin spoilers.
01-guia-instructor  ⚠️  Minuto a minuto, qué puede salir mal.
02-workbook            Las preguntas, en 6 bloques.
03-rubrica          ⚠️  Respuestas verificadas + cómo calificar.
04-lecturas            Fuentes primarias y datos de vigencia.
05-inyeccion        ⚠️  El ejercicio de prompt injection.
06-herramientas        La cadena técnica y por qué.
07-laboratorio-vm      Provisión de la VM, paso a paso.
08-publicacion         Checklist para pasar el repo a público.
```
