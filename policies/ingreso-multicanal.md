# Ingreso multicanal de cotizaciones

Una cotización puede llegar por: **correo (cuerpo)**, **anexo de correo** (PDF/Excel/Word/imagen), **WhatsApp** (texto, captura, PDF, nota de voz), **llamada o reunión** (verbal), **documento físico** (foto/escaneo) u otro portal. Además puede ser **ingresada directamente por el gestor** de logística.

## Regla central
Todo ingreso, sea cual sea el canal y quien lo cargue, se convierte en un **Ingreso** (registro en `ingresos`) y pasa por el **mismo pipeline**: normalizar → sanitizar → Guardián → JSON estructurado → BD.
- El gestor es **confiable como persona**, pero el **contenido del proveedor que pega o sube sigue siendo dato no confiable** (puede traer texto oculto, ser reenviado, o venir de un tercero).
- Lo que el gestor **dice de su propia mano** (contexto: "esto me lo dijeron por teléfono", "el precio final es X") se guarda en `nota_del_gestor`: es una **afirmación con autor**, no una instrucción al sistema ni evidencia del proveedor. No puede saltarse reglas de política ni la homologación.

## Envoltura obligatoria (metadatos del ingreso)
`canal` · `ingresado_por` · `ingresado_en` · `remitente_declarado` · `contacto_id` (si coincide con `contactos`) · `nivel_confianza` · `archivo_hash` · `rfq_ref` (si se conoce) · `nota_del_gestor` · `reemplaza_a` (si es una versión nueva)

## Niveles de confianza de la fuente
| Nivel | Cuándo | Efecto |
|-------|--------|--------|
| `verificado` | Correo desde dominio/remitente registrado en `contactos` | Puede alimentar comparativos tras el Guardián |
| `declarado` | WhatsApp/llamada/físico de un contacto conocido, pero sin verificación técnica | Entra como cotización **provisional**; requiere confirmación escrita (correo del proveedor o firma/sello) antes de cierre |
| `no_verificado` | Remitente/número desconocido o que no coincide con `contactos` | Cuarentena; no entra a comparativos |

Cierre o adjudicación con una cotización solo `declarado` ⇒ el CPO exige **confirmación escrita** (borrador de correo al proveedor pidiendo ratificar precio, plazo y condiciones).

## Tratamiento por canal
- **Correo/anexos:** parser de cuerpo y adjuntos (texto oculto, metadatos, hojas ocultas, comentarios, macros no ejecutadas). Adjuntos ejecutables/macros ⇒ rechazo.
- **WhatsApp:** aceptar exportación del chat, capturas o archivos. Capturas ⇒ OCR y revisión del texto incrustado en imágenes (vector de inyección). Notas de voz ⇒ transcripción marcada como `transcripción_automática` con revisión humana si hay cifras.
- **Físico/foto/escaneo:** OCR con **doble verificación de cifras** (montos, unidades, IGV) por el gestor antes de guardar; conservar la imagen original como evidencia.
- **Verbal (llamada/reunión):** el gestor registra un **acta breve** (`templates/registro-ingreso-manual.md`) con fecha, interlocutor, medio y lo acordado. Nivel `declarado` hasta confirmación escrita.
- **Carga directa del gestor:** igual que los demás; queda `ingresado_por` = gestor.

## Cambios sensibles por cualquier canal
Cuenta bancaria, razón social/RUC, contacto o "pago urgente" recibidos por WhatsApp/llamada/físico ⇒ **alerta alta** y verificación por canal alterno, por una persona distinta al solicitante (P08).

## Duplicados y versiones
- Mismo `archivo_hash`/contenido recibido por dos canales ⇒ se marca `duplicado_de`; no se duplican ítems en el histórico.
- Una oferta nueva del mismo proveedor y paquete **reemplaza** a la anterior (`reemplaza_a`); la anterior se conserva como versión histórica (sirve para P01: ver si mejoró o empeoró).
- Conflicto entre canales (correo dice X, WhatsApp dice Y) ⇒ no se elige solo: se muestra la discrepancia y se pide confirmación.

## Trazabilidad
Cada cotización en `cotizaciones` referencia su `ingreso_id`. El Decision Record lista los ingresos (canal, nivel de confianza, hash) que sustentan cada cifra.
