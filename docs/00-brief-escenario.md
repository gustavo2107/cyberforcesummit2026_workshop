# Brief del escenario

> Documento para participantes. No contiene la respuesta.
>
> **El escenario, la empresa y todos los datos de contexto son ficticios y
> fueron generados para este laboratorio.** La única excepción es la captura de
> red, que es evidencia auténtica de un caso público. Ver
> `evidence/datos-sinteticos/README.md`.

---

## Situación

Trabajas en el equipo de respuesta a incidentes de una consultora. Tu cliente
es **Industrias ACME de México, S.A. de C.V.** — empresa ficticia — que te
contrata para su **Planta ACME-1** tras una serie de eventos que no logra
explicar: paros de proceso no programados y discrepancias entre lo que el
personal de planta observa en campo y lo que reportan las consolas.

El área de TI del cliente no encuentra nada. El área de operaciones insiste en
que "algo está mal con los sistemas de seguridad".

## Lo que te entregan

Una captura de tráfico de un segmento de la red industrial, tomada por el
integrador durante una ventana de mantenimiento. Son **896 paquetes en poco
más de siete minutos**, entre dos direcciones IP.

Eso es todo. No hay logs de endpoint, no hay imágenes de disco, no hay reporte
del fabricante. Tienes la red y nada más.

## Lo que el cliente quiere saber

1. ¿Hubo actividad no autorizada en esta captura, o es mantenimiento normal?
2. Si la hubo: ¿qué se hizo exactamente, en qué orden y en qué momento?
3. ¿Qué equipo la originó y contra qué equipo?
4. ¿La actividad tuvo éxito?
5. ¿Qué control habría impedido esto?

La pregunta 5 es la que el cliente va a pagar. Las otras cuatro son el camino.

## Tus herramientas

- `tshark` con un disector de protocolo cargado
- Un asistente de IA conectado a `tshark` vía MCP
- El workbook en `docs/02-workbook.md`

## La regla

**Toda afirmación que entregues tiene que citar la trama que la sostiene.**

Si tu asistente de IA afirma algo y no puedes señalar el número de trama y el
comando de `tshark` que lo demuestra, esa afirmación no existe. No la escribas
en tu reporte.

Esta regla no es burocracia. Es el instrumento de medición del taller.

## Entregable

Al final de la sesión, cada equipo entrega:

- Una línea de tiempo de la actividad, con números de trama
- Una hipótesis de qué ocurrió, en un párrafo
- Una recomendación de control, en una frase
- Una lista de las afirmaciones que su IA hizo y **no** pudieron anclar

La última lista es la más interesante de todas. No la omitas.
