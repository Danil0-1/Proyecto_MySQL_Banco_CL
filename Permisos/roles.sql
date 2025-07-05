

CREATE USER 'admin'@'%' IDENTIFIED BY 'adds-dev-diosmioyanopuedomas';
GRANT ALL PRIVILEGES ON banco_cl.* TO 'admin'@'%';



CREATE USER 'operador_pagos'@'%' IDENTIFIED BY 'historial123';
GRANT SELECT, INSERT, UPDATE ON banco_cl.Pagos TO 'operador_pagos'@'%';
GRANT SELECT ON banco_cl.Historial_de_pagos TO 'operador_pagos'@'%';


CREATE USER 'gerente'@'%' IDENTIFIED BY 'mrgerente123';
GRANT SELECT ON banco_cl.Clientes TO 'gerente'@'%';
GRANT SELECT ON banco_cl.Tarjetas TO 'gerente'@'%';
GRANT SELECT ON banco_cl.Cuotas_de_manejo TO 'gerente'@'%';
GRANT SELECT ON banco_cl.Pagos TO 'gerente'@'%';
GRANT SELECT ON banco_cl.Intereses_tarjetas TO 'gerente'@'%';
GRANT SELECT ON banco_cl.Movimientos_tarjeta TO 'gerente'@'%';
GRANT SELECT ON banco_cl.Cuotas_credito TO 'gerente'@'%';



CREATE USER 'consultor_tarjetas'@'%' IDENTIFIED BY 'holii123';
GRANT SELECT ON banco_cl.Tarjetas TO 'consultor_tarjetas'@'%';
GRANT SELECT ON banco_cl.Cuotas_de_manejo TO 'consultor_tarjetas'@'%';



CREATE USER 'auditor'@'%' IDENTIFIED BY 'auditor123';
GRANT SELECT ON banco_cl.Cuotas_de_manejo TO 'auditor'@'%';
GRANT SELECT ON banco_cl.Pagos TO 'auditor'@'%';
GRANT SELECT ON banco_cl.Intereses_tarjetas TO 'auditor'@'%';
GRANT SELECT ON banco_cl.Movimientos TO 'auditor'@'%';
GRANT SELECT ON banco_cl.Movimientos_tarjeta TO 'auditor'@'%';


FLUSH PRIVILEGES;


SHOW GRANTS FOR 'admin'@'%';
SHOW GRANTS FOR 'operador_pagos'@'%';
SHOW GRANTS FOR 'gerente'@'%';
SHOW GRANTS FOR 'consultor_tarjetas'@'%';
SHOW GRANTS FOR 'auditor'@'%';


-- Procedimientos

GRANT EXECUTE ON PROCEDURE banco_cl.ps_procesar_pago TO 'operador_pagos'@'%';
GRANT EXECUTE ON PROCEDURE banco_cl.ps_clientes_tarjetas_vencidas_sin_pago TO 'operador_pagos'@'%';
GRANT EXECUTE ON PROCEDURE banco_cl.ps_aumentar_limite_credito TO 'operador_pagos'@'%';
GRANT EXECUTE ON PROCEDURE banco_cl.ps_resumen_pagos_cliente TO 'operador_pagos'@'%';


GRANT EXECUTE ON PROCEDURE banco_cl.ps_reporte_cuotas_mensual TO 'gerente'@'%';
GRANT EXECUTE ON PROCEDURE banco_cl.ps_bloquear_tarjetas_vencidas TO 'gerente'@'%';
GRANT EXECUTE ON PROCEDURE banco_cl.ps_resumen_financiero_cliente TO 'gerente'@'%';
GRANT EXECUTE ON PROCEDURE banco_cl.ps_clientes_tarjetas_vencidas_sin_pago TO 'gerente'@'%';
GRANT EXECUTE ON PROCEDURE banco_cl.ps_reporte_intereses_mensual TO 'gerente'@'%';


GRANT EXECUTE ON PROCEDURE banco_cl.ps_resumen_financiero_cliente TO 'consultor_tarjetas'@'%';
GRANT EXECUTE ON PROCEDURE banco_cl.ps_clientes_tarjetas_vencidas_sin_pago TO 'consultor_tarjetas'@'%';
GRANT EXECUTE ON PROCEDURE banco_cl.ps_reporte_intereses_mensual TO 'consultor_tarjetas'@'%';
GRANT EXECUTE ON PROCEDURE banco_cl.ps_reporte_cuotas_mensual TO 'consultor_tarjetas'@'%';


-- Funciones

GRANT EXECUTE ON FUNCTION banco_cl.fn_saldo_pendiente TO 'operador_pagos'@'%';
GRANT EXECUTE ON FUNCTION banco_cl.fn_total_pagos_por_tipo TO 'operador_pagos'@'%';
GRANT EXECUTE ON FUNCTION banco_cl.fn_promedio_pagos_credito TO 'operador_pagos'@'%';
GRANT EXECUTE ON FUNCTION banco_cl.fn_cuotas_pagadas TO 'operador_pagos'@'%';
GRANT EXECUTE ON FUNCTION banco_cl.fn_total_credito_pendiente_cliente TO 'operador_pagos'@'%';

GRANT EXECUTE ON FUNCTION banco_cl.fn_calcular_cuota_manejo TO 'gerente'@'%';
GRANT EXECUTE ON FUNCTION banco_cl.fn_total_pagos_por_tipo TO 'gerente'@'%';
GRANT EXECUTE ON FUNCTION banco_cl.fn_cantidad_tarjetas TO 'gerente'@'%';
GRANT EXECUTE ON FUNCTION banco_cl.fn_interes_tarjeta TO 'gerente'@'%';
GRANT EXECUTE ON FUNCTION banco_cl.fn_tarjetas_bloqueadas_cliente TO 'gerente'@'%';
GRANT EXECUTE ON FUNCTION banco_cl.fn_fecha_ultima_compra TO 'gerente'@'%';
GRANT EXECUTE ON FUNCTION banco_cl.fn_promedio_interes_mensual TO 'gerente'@'%';
GRANT EXECUTE ON FUNCTION banco_cl.fn_saldo_tarjetas_vencidas TO 'gerente'@'%';
GRANT EXECUTE ON FUNCTION banco_cl.fn_calcular_cuota_manejo TO 'gerente'@'%';


GRANT EXECUTE ON FUNCTION banco_cl.fn_calcular_cuota_manejo TO 'consultor_tarjetas'@'%';
GRANT EXECUTE ON FUNCTION banco_cl.fn_total_pagos_por_tipo TO 'consultor_tarjetas'@'%';
GRANT EXECUTE ON FUNCTION banco_cl.fn_cantidad_tarjetas TO 'consultor_tarjetas'@'%';
GRANT EXECUTE ON FUNCTION banco_cl.fn_interes_tarjeta TO 'consultor_tarjetas'@'%';
GRANT EXECUTE ON FUNCTION banco_cl.fn_tarjetas_bloqueadas_cliente TO 'consultor_tarjetas'@'%';
GRANT EXECUTE ON FUNCTION banco_cl.fn_fecha_ultima_compra TO 'consultor_tarjetas'@'%';
GRANT EXECUTE ON FUNCTION banco_cl.fn_promedio_interes_mensual TO 'consultor_tarjetas'@'%';
GRANT EXECUTE ON FUNCTION banco_cl.fn_saldo_tarjetas_vencidas TO 'consultor_tarjetas'@'%';
GRANT EXECUTE ON FUNCTION banco_cl.fn_calcular_cuota_manejo TO 'consultor_tarjetas'@'%';


USE banco_cl;

CREATE ROLE IF NOT EXISTS admin_cl;
GRANT ALL PRIVILEGES ON banco_cl.* TO admin_cl;
GRANT EXECUTE ON *.* TO admin_cl;

CREATE USER IF NOT EXISTS 'admin'@'%' IDENTIFIED BY 'adds-dev-diosmioyanopuedomas';
GRANT admin_cl TO 'admin'@'%';
SET DEFAULT ROLE admin_cl TO 'admin'@'%';


CREATE ROLE IF NOT EXISTS operador_pagos_cl;
GRANT SELECT, INSERT, UPDATE ON banco_cl.Pagos TO operador_pagos_cl;
GRANT SELECT ON banco_cl.Historial_de_pagos TO operador_pagos_cl;

-- Procedimientos
GRANT EXECUTE ON PROCEDURE banco_cl.ps_procesar_pago TO operador_pagos_cl;
GRANT EXECUTE ON PROCEDURE banco_cl.ps_clientes_tarjetas_vencidas_sin_pago TO operador_pagos_cl;
GRANT EXECUTE ON PROCEDURE banco_cl.ps_aumentar_limite_credito TO operador_pagos_cl;
GRANT EXECUTE ON PROCEDURE banco_cl.ps_resumen_pagos_cliente TO operador_pagos_cl;

-- Funciones
GRANT EXECUTE ON FUNCTION banco_cl.fn_saldo_pendiente TO operador_pagos_cl;
GRANT EXECUTE ON FUNCTION banco_cl.fn_total_pagos_por_tipo TO operador_pagos_cl;
GRANT EXECUTE ON FUNCTION banco_cl.fn_promedio_pagos_credito TO operador_pagos_cl;
GRANT EXECUTE ON FUNCTION banco_cl.fn_cuotas_pagadas TO operador_pagos_cl;
GRANT EXECUTE ON FUNCTION banco_cl.fn_total_credito_pendiente_cliente TO operador_pagos_cl;

CREATE USER IF NOT EXISTS 'operador_pagos'@'%' IDENTIFIED BY 'historial123';
GRANT operador_pagos_cl TO 'operador_pagos'@'%';
SET DEFAULT ROLE operador_pagos_cl TO 'operador_pagos'@'%';


CREATE ROLE IF NOT EXISTS gerente_cl;
GRANT SELECT ON banco_cl.Clientes, banco_cl.Tarjetas, banco_cl.Cuotas_de_manejo,
                 banco_cl.Pagos, banco_cl.Intereses_tarjetas,
                 banco_cl.Movimientos_tarjeta, banco_cl.Cuotas_credito TO gerente_cl;

-- Procedimientos
GRANT EXECUTE ON PROCEDURE banco_cl.ps_reporte_cuotas_mensual TO gerente_cl;
GRANT EXECUTE ON PROCEDURE banco_cl.ps_bloquear_tarjetas_vencidas TO gerente_cl;
GRANT EXECUTE ON PROCEDURE banco_cl.ps_resumen_financiero_cliente TO gerente_cl;
GRANT EXECUTE ON PROCEDURE banco_cl.ps_clientes_tarjetas_vencidas_sin_pago TO gerente_cl;
GRANT EXECUTE ON PROCEDURE banco_cl.ps_reporte_intereses_mensual TO gerente_cl;

-- Funciones
GRANT EXECUTE ON FUNCTION banco_cl.fn_calcular_cuota_manejo TO gerente_cl;
GRANT EXECUTE ON FUNCTION banco_cl.fn_total_pagos_por_tipo TO gerente_cl;
GRANT EXECUTE ON FUNCTION banco_cl.fn_cantidad_tarjetas TO gerente_cl;
GRANT EXECUTE ON FUNCTION banco_cl.fn_interes_tarjeta TO gerente_cl;
GRANT EXECUTE ON FUNCTION banco_cl.fn_tarjetas_bloqueadas_cliente TO gerente_cl;
GRANT EXECUTE ON FUNCTION banco_cl.fn_fecha_ultima_compra TO gerente_cl;
GRANT EXECUTE ON FUNCTION banco_cl.fn_promedio_interes_mensual TO gerente_cl;
GRANT EXECUTE ON FUNCTION banco_cl.fn_saldo_tarjetas_vencidas TO gerente_cl;

CREATE USER IF NOT EXISTS 'gerente'@'%' IDENTIFIED BY 'mrgerente123';
GRANT gerente_cl TO 'gerente'@'%';
SET DEFAULT ROLE gerente_cl TO 'gerente'@'%';

CREATE ROLE IF NOT EXISTS consultor_tarjetas_cl;
GRANT SELECT ON banco_cl.Tarjetas, banco_cl.Cuotas_de_manejo TO consultor_tarjetas_cl;

-- Procedimientos
GRANT EXECUTE ON PROCEDURE banco_cl.ps_resumen_financiero_cliente TO consultor_tarjetas_cl;
GRANT EXECUTE ON PROCEDURE banco_cl.ps_clientes_tarjetas_vencidas_sin_pago TO consultor_tarjetas_cl;
GRANT EXECUTE ON PROCEDURE banco_cl.ps_reporte_intereses_mensual TO consultor_tarjetas_cl;
GRANT EXECUTE ON PROCEDURE banco_cl.ps_reporte_cuotas_mensual TO consultor_tarjetas_cl;

-- Funciones
GRANT EXECUTE ON FUNCTION banco_cl.fn_calcular_cuota_manejo TO consultor_tarjetas_cl;
GRANT EXECUTE ON FUNCTION banco_cl.fn_total_pagos_por_tipo TO consultor_tarjetas_cl;
GRANT EXECUTE ON FUNCTION banco_cl.fn_cantidad_tarjetas TO consultor_tarjetas_cl;
GRANT EXECUTE ON FUNCTION banco_cl.fn_interes_tarjeta TO consultor_tarjetas_cl;
GRANT EXECUTE ON FUNCTION banco_cl.fn_tarjetas_bloqueadas_cliente TO consultor_tarjetas_cl;
GRANT EXECUTE ON FUNCTION banco_cl.fn_fecha_ultima_compra TO consultor_tarjetas_cl;
GRANT EXECUTE ON FUNCTION banco_cl.fn_promedio_interes_mensual TO consultor_tarjetas_cl;
GRANT EXECUTE ON FUNCTION banco_cl.fn_saldo_tarjetas_vencidas TO consultor_tarjetas_cl;

CREATE USER IF NOT EXISTS 'consultor_tarjetas'@'%' IDENTIFIED BY 'holii123';
GRANT consultor_tarjetas_cl TO 'consultor_tarjetas'@'%';
SET DEFAULT ROLE consultor_tarjetas_cl TO 'consultor_tarjetas'@'%';


CREATE ROLE IF NOT EXISTS auditor_cl;
GRANT SELECT ON banco_cl.Cuotas_de_manejo, banco_cl.Pagos, banco_cl.Intereses_tarjetas,
               banco_cl.Movimientos, banco_cl.Movimientos_tarjeta TO auditor_cl;

CREATE USER IF NOT EXISTS 'auditor'@'%' IDENTIFIED BY 'auditor123';
GRANT auditor_cl TO 'auditor'@'%';
SET DEFAULT ROLE auditor_cl TO 'auditor'@'%';

FLUSH PRIVILEGES;
