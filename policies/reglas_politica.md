# Reglas de política verificables (implementar como SQL/código; el LLM solo las consulta)

| ID | Regla | Acción |
|----|-------|--------|
| P01 | Precio unitario > mejor precio histórico comparable (mismo ítem, ventana de fecha, volumen ajustado) + umbral % | Proponer correo de negociación |
| P02 | Oferta omite ítems/especificaciones del TdR | Estado `NO_HOMOLOGADA`; consulta al proveedor |
| P03 | Condición ofertada peor que `condiciones_cerradas` vigentes con ese proveedor | Alertar y proponer ajuste |
| P04 | Recomendación basada solo en precio con diferencias relevantes en plazo/garantía/alcance | Bloquear; exigir CBA |
| P05 | Monto adjudicado > presupuesto del paquete | Análisis de brechas obligatorio |
| P06 | Compras al mismo proveedor/rubro en ventana corta que evitan un umbral de aprobación | Alerta de fraccionamiento |
| P07 | Proveedor con alerta de seguridad alta sin liberar | Excluir de comparativos |
| P08 | Mismo usuario/agente propone y aprueba | Bloquear |
| P09 | Decision Record incompleto (sin evidencia o sin responsable) | No pasa a aprobación |
| P10 | Cotización solo `declarado`/`provisional` en un cierre | Exigir ratificación escrita antes de aprobar |
| P11 | Cambio sensible (banco, RUC, contacto) por WhatsApp/llamada/físico | Alerta alta + verificación por canal alterno por otra persona |
| P12 | Conflicto de cifras entre canales | Mostrar discrepancia; no elegir automáticamente |
