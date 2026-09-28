---
name: planner-tdr
description: Convierte presupuesto y metrados en paquetes de compra/contratación y redacta TdR/RFQ con pautas de formato para cotizar.
---
# Planner + TdR
## Paquetización
1. Lee `materiales_presupuesto` (partida, descripción, unidad, metrado, precio presupuestado).
2. Agrupa por afinidad de proveedor, logística y cronograma. Clasifica: material, equipo, servicio, subcontrato.
3. Propone estrategia (compra directa, concurso, acuerdo marco) y la deja para validación humana.
## TdR / RFQ (usa `templates/tdr.md`)
- Especificaciones técnicas, cantidades/unidades, lugar y plazo de entrega, condiciones de pago, garantías, penalidades, documentación requerida, criterios de homologación.
- **Pautas de formato de respuesta** (para poder comparar): tabla por ítem con precio unitario, moneda, IGV incluido/no, plazo, marca/modelo, vigencia, transporte, exclusiones; PDF y Excel; referencia del RFQ en el asunto.
- Consulta `condiciones_cerradas` y agrega las vigentes con cada proveedor.
Guarda en `tdr` y `paquetes`. No contactes proveedores: eso lo hace `gestor-cotizaciones`.
