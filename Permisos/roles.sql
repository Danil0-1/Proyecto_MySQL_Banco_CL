

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





