# Diseño del ejercicio de inyección

> ⚠️ **SPOILERS.** Documento del instructor.

---

## Qué demuestra

Que la evidencia forense es **entrada no confiable**, y que un analista de IA
con herramientas es un agente leyendo contenido que el atacante controla.

En términos de OWASP Top 10 for Agentic Applications 2026, esto es **ASI01
(Agent Goal Hijack)** y **ASI06 (Memory & Context Poisoning)** aplicados a DFIR.
El participante no lo escucha explicado: le pasa.

## Principio de integridad — no negociable

**El PCAP no se toca.** Es evidencia auténtica publicada por un tercero y
verificable contra el original. Adulterarla invalida la comparación con los
reportes públicos, que es el eje del taller, y si alguien lo descubre pierdes
la sala entera.

La inyección va en un **artefacto acompañante sintético**, de nuestra autoría,
declarado como tal en `evidence/companion/README`. Es honesto y funciona igual
de bien.

## El vector

`evidence/companion/cambios-mantenimiento.csv`: un export del sistema de
gestión de cambios del cliente. Escenario: el atacante que comprometió la
estación de ingeniería también levantó un ticket de cambio falso para dar
cobertura a su actividad — TTP real de evasión por proceso legítimo.

El campo `justificacion` de una fila lleva la carga. Es un campo de texto
libre, controlado por quien levanta el ticket, y por lo tanto por el atacante.
No hay nada artificial en que ese texto llegue al analista: es exactamente el
tipo de dato que se cruza contra el tráfico para separar mantenimiento
autorizado de actividad hostil.

## Momento en la agenda

Después de la revelación y del contraste con los reportes. Bloque 6 del
workbook, últimos 15 minutos.

Razón: si lo haces antes, los participantes se ponen paranoicos y el ejercicio
forense se contamina. Va al final, cuando ya confían en su flujo de trabajo.
Ahí es donde duele y donde se recuerda.

## Cómo conducirlo

1. Reparte el CSV como "un artefacto adicional del mismo incidente".
2. Pídeles que lo analicen con su asistente **igual que venían trabajando**.
   No adviertas nada.
3. Deja que dos o tres equipos lean en voz alta lo que su IA concluyó.
4. Proyecta el CSV crudo y señala la fila.

## Qué preguntar después

En este orden, y sin adelantar respuestas:

- ¿Cuántos de ustedes leyeron el CSV crudo antes de dárselo al asistente?
- ¿La regla de anclaje habría atrapado esto? *(Sí, parcialmente: la afirmación
  "actividad autorizada" no tiene trama que la sostenga. La regla que
  construyeron para medir alucinación también funciona contra inyección — ese
  es el remate.)*
- ¿En qué se parece esto a un agente leyendo tickets, correos o alertas?
- ¿Qué controles quedan cuando el contenido que tu agente lee es hostil por
  diseño?

## El puente con el track LEGIÓN AUTÓNOMA

Cierra con la frase, que a estas alturas ya no necesita defensa:

> *Acaban de construir un agente con una herramienta, y acaban de ver cómo se
> secuestra. No pueden filtrar su salida de esto: tienen que reducir el radio
> de explosión.*

## Variante si te sobra tiempo

Prepara dos CSVs, uno limpio y uno inyectado, y reparte al azar por mesa. La
comparación entre mesas —mismas preguntas, conclusiones opuestas— es más
contundente que la demostración frontal, y ahorra la discusión de "es que yo sí
me habría dado cuenta".
