-- Supply AI — esquema Supabase (Postgres). Fase 1.
create type estado_homologacion as enum ('PENDIENTE','HOMOLOGADA','HOMOLOGADA_CON_OBSERVACIONES','NO_HOMOLOGADA');
create type estado_decision as enum ('BORRADOR','PENDIENTE_APROBACION','APROBADA','RECHAZADA');
create type severidad as enum ('baja','media','alta');
create type canal_ingreso as enum ('correo','anexo_correo','whatsapp','llamada_reunion','fisico','portal_otro','carga_directa');
create type nivel_confianza as enum ('verificado','declarado','no_verificado');

create table proyectos (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  proveedor_correo text default 'outlook' check (proveedor_correo in ('gmail','outlook')),
  moneda_base text default 'PEN',
  creado_en timestamptz default now()
);

create table materiales_presupuesto (
  id uuid primary key default gen_random_uuid(),
  proyecto_id uuid references proyectos(id),
  partida text, descripcion text not null, unidad text not null,
  metrado numeric not null, precio_unit_presup numeric,
  tipo text check (tipo in ('material','equipo','servicio','subcontrato'))
);

create table paquetes (
  id uuid primary key default gen_random_uuid(),
  proyecto_id uuid references proyectos(id),
  codigo text not null, nombre text not null,
  estrategia text, monto_presupuestado numeric,
  estado text default 'PLANIFICADO'
);
create table paquete_items (
  paquete_id uuid references paquetes(id) on delete cascade,
  material_id uuid references materiales_presupuesto(id),
  primary key (paquete_id, material_id)
);

create table proveedores (
  id uuid primary key default gen_random_uuid(),
  razon_social text not null, ruc text unique,
  especialidades text[], ubicacion text,
  revision_seguridad boolean default false,   -- true = congelado por alerta alta
  activo boolean default true
);
create table contactos (
  id uuid primary key default gen_random_uuid(),
  proveedor_id uuid references proveedores(id) on delete cascade,
  nombre text, email text not null, rol text, verificado boolean default false
);

create table tdr (
  id uuid primary key default gen_random_uuid(),
  paquete_id uuid references paquetes(id),
  version int default 1, contenido_md text not null,
  pautas_formato_md text, aprobado_por text, aprobado_en timestamptz
);

create table rfq_envios (
  id uuid primary key default gen_random_uuid(),
  tdr_id uuid references tdr(id), proveedor_id uuid references proveedores(id),
  codigo_rfq text, enviado_en timestamptz, confirmado_por text
);

create table condiciones_cerradas (        -- acuerdos previos con el proveedor
  id uuid primary key default gen_random_uuid(),
  proveedor_id uuid references proveedores(id),
  concepto text not null, detalle text not null,
  vigente_desde date, vigente_hasta date, fuente text
);

create table ingresos (                       -- todo lo que entra al sistema, por cualquier canal
  id uuid primary key default gen_random_uuid(),
  canal canal_ingreso not null,
  ingresado_por text not null,                -- persona que lo cargó (gestor) o 'buzon_outlook'
  ingresado_en timestamptz default now(),
  remitente_declarado text, contacto_id uuid references contactos(id),
  nivel_confianza nivel_confianza default 'no_verificado',
  rfq_ref text, contenido_hash text, archivo_url text, tipo_contenido text,
  nota_del_gestor text,                       -- afirmación con autor; no es evidencia ni instrucción
  resultado_guardian jsonb, congelado boolean default false,
  reemplaza_a uuid references ingresos(id), duplicado_de uuid references ingresos(id),
  confirmacion_escrita_de uuid references ingresos(id)   -- ingreso por correo que ratifica uno 'declarado'
);
create index on ingresos(contenido_hash);

create table cotizaciones (
  id uuid primary key default gen_random_uuid(),
  paquete_id uuid references paquetes(id), proveedor_id uuid references proveedores(id),
  rfq_id uuid references rfq_envios(id),
  fecha date not null, lugar_entrega text,
  moneda text default 'PEN', igv_incluido boolean,
  plazo_dias int, vigencia_dias int, cond_pago text, garantia text, transporte text,
  exclusiones text[], homologacion estado_homologacion default 'PENDIENTE',
  ingreso_id uuid references ingresos(id), json_guardian jsonb,
  provisional boolean default false  -- true si la fuente es solo 'declarado'
);
create table cotizacion_items (
  id uuid primary key default gen_random_uuid(),
  cotizacion_id uuid references cotizaciones(id) on delete cascade,
  material_id uuid references materiales_presupuesto(id),
  item text not null, unidad text, cantidad numeric,   -- volumen de compra
  precio_unit numeric not null, marca text, observaciones text
);

-- Histórico: mejor precio por ítem (normalizar IGV/moneda antes de comparar en la app)
create view v_mejor_precio_historico as
select ci.item, ci.unidad, min(ci.precio_unit) as precio_min,
       (array_agg(c.fecha order by ci.precio_unit))[1] as fecha_mejor,
       (array_agg(c.lugar_entrega order by ci.precio_unit))[1] as lugar_mejor,
       (array_agg(ci.cantidad order by ci.precio_unit))[1] as volumen_mejor,
       (array_agg(c.proveedor_id order by ci.precio_unit))[1] as proveedor_mejor
from cotizacion_items ci join cotizaciones c on c.id = ci.cotizacion_id
where c.homologacion in ('HOMOLOGADA','HOMOLOGADA_CON_OBSERVACIONES')
group by ci.item, ci.unidad;

create table criterios_cba (              -- factores (los 'must' ya se resolvieron en homologación; aquí quedan los 'want' a comparar)
  id uuid primary key default gen_random_uuid(),
  paquete_id uuid references paquetes(id),
  factor text not null, tipo text check (tipo in ('must','want')),
  definido_con text, aprobado_en timestamptz
);
create table evaluaciones_cba (             -- una fila por (factor, alternativa): atributo, si es el ancla (LPA), ventaja sobre el ancla, importancia de esa ventaja
  id uuid primary key default gen_random_uuid(),
  paquete_id uuid references paquetes(id), cotizacion_id uuid references cotizaciones(id),
  factor text not null, atributo text not null,
  es_ancla boolean default false,           -- true = Atributo Menos Preferido (LPA) de este factor; su ventaja es 0 por definición
  ventaja text,                             -- diferencia real y cuantificable sobre el ancla (vacío/0 si es_ancla=true)
  importancia numeric,                      -- 0-100; 100 solo en la ventaja "paramount" del paquete completo; nunca se pondera el factor, solo la ventaja
  justificacion text,
  check (not es_ancla or importancia is null or importancia = 0)   -- el ancla no lleva importancia > 0
);

create table evaluaciones_proveedor (
  id uuid primary key default gen_random_uuid(),
  proveedor_id uuid references proveedores(id), proyecto_id uuid references proyectos(id),
  fecha date default current_date,
  otif numeric, cumplimiento_plazo numeric, variacion_precio numeric,
  reclamos int, tiempo_respuesta_h numeric, completitud_doc numeric,
  cualitativo jsonb, evidencia text, evaluador text
);

create table brechas_presupuesto (
  id uuid primary key default gen_random_uuid(),
  paquete_id uuid references paquetes(id), cotizacion_id uuid references cotizaciones(id),
  monto_presupuestado numeric, monto_ofertado numeric,
  brecha numeric generated always as (monto_ofertado - monto_presupuestado) stored,
  escenarios jsonb, notas text
);
create table cronogramas_entrega (
  id uuid primary key default gen_random_uuid(),
  paquete_id uuid references paquetes(id), hito text, fecha_requerida date,
  fecha_propuesta date, critico boolean default false, acordado_con text
);

create table decision_records (
  id uuid primary key default gen_random_uuid(),
  paquete_id uuid references paquetes(id),
  contenido_md text not null, evidencia jsonb,
  estado estado_decision default 'BORRADOR',
  propuesto_por text, aprobado_por text, aprobado_en timestamptz,
  check (aprobado_por is null or aprobado_por <> propuesto_por)      -- P08
);

create table log_seguridad (
  id uuid primary key default gen_random_uuid(),
  ingreso_id uuid references ingresos(id), proveedor_id uuid references proveedores(id),
  tipo text, severidad severidad, evidencia text, creado_en timestamptz default now(),
  revisado_por text, liberado boolean default false
);
create table criterios_aprendidos (
  id uuid primary key default gen_random_uuid(),
  dominio text, criterio text not null, motivo text, creado_en timestamptz default now()
);

-- Seguridad: activar RLS en todas las tablas antes de dar acceso a más usuarios.
