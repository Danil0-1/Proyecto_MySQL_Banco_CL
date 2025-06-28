
USE banco_cl;

-- Calcular la cuota de manejo para un cliente según su tipo de tarjeta y monto de apertura.

DELIMITER //

DROP FUNCTION IF EXISTS fn_calcular_cuota_manejo;
CREATE FUNCTION fn_calcular_cuota_manejo(p_cliente_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE _cuota_manejo DECIMAL(10,2);
    DECLARE _descuento_tarjeta DECIMAL(5,2);
    DECLARE _monto_apertura DECIMAL(10,2);

    SELECT tt.descuento INTO _descuento_tarjeta
    FROM Clientes cl
    INNER JOIN Cuentas cu ON cu.cliente_id = cl.id
    INNER JOIN Tarjetas t ON t.cuenta_id = cu.id
    INNER JOIN Tipo_tarjetas tt ON tt.id = t.tipo_tarjeta_id
    WHERE cl.id = p_cliente_id;

    SELECT t.monto_apertura INTO _monto_apertura
    FROM Clientes cl
    INNER JOIN Cuentas cu ON cu.cliente_id = cl.id
    INNER JOIN Tarjetas t ON t.cuenta_id = cu.id
    WHERE cl.id = p_cliente_id;

    SET _cuota_manejo = _monto_apertura - (_monto_apertura * _descuento_tarjeta / 100);

    RETURN _cuota_manejo;

END //

DELIMITER ;

SELECT fn_calcular_cuota_manejo(1) AS Total_a_pagar;

-- Calcular el total pendiente de cuota de manejo de pago de un cliente.

DELIMITER //

DROP FUNCTION IF EXISTS fn_saldo_pendiente;
CREATE FUNCTION fn_saldo_pendiente(p_cliente_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE _total_cuota DECIMAL(10,2);
    DECLARE _id_cuota INT;
    DECLARE _total_restante DECIMAL(10,2);
    DECLARE _pagos_clientes DECIMAL(10,2) DEFAULT 0.00;
    DECLARE _pago_individual DECIMAL(10,2);

    DECLARE cur CURSOR FOR
        SELECT IFNULL(p.total_pago, 0)
        FROM Clientes cl
        INNER JOIN Cuentas cu ON cu.cliente_id = cl.id
        INNER JOIN Tarjetas t ON t.cuenta_id = cu.id
        LEFT JOIN Cuotas_de_manejo cm ON cm.tarjeta_id = t.id
        LEFT JOIN Pagos p ON p.cuota_id = cm.id
        WHERE cl.id = p_cliente_id;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    SELECT IFNULL(SUM(cm.monto_total), 0) INTO _total_cuota
    FROM Clientes cl
    INNER JOIN Cuentas cu ON cu.cliente_id = cl.id
    INNER JOIN Tarjetas t ON t.cuenta_id = cu.id
    LEFT JOIN Cuotas_de_manejo cm ON cm.tarjeta_id = t.id
    WHERE cl.id = p_cliente_id;

    IF _total_cuota = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El cliente no paga cuota de manejo';
    END IF;

    OPEN cur;
        read_loop: LOOP
            FETCH cur INTO _pago_individual;
            IF done THEN
                LEAVE read_loop;
            END IF;
            SET _pagos_clientes = _pagos_clientes + IFNULL(_pago_individual, 0);
        END LOOP;

        SET _total_restante = _total_cuota - _pagos_clientes;
    CLOSE cur;

    IF _total_restante < 0 THEN
        SET _total_restante = 0;
    END IF;

    RETURN _total_restante;


END //
DELIMITER ;

SELECT fn_saldo_pendiente(1) AS Total_pendiente;


-- Calcular el total pendiente de las cuotas de credito de un cliente.

DELIMITER //

DROP FUNCTION IF EXISTS fn_cuotas_credito;
CREATE FUNCTION fn_cuotas_credito(p_cliente_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE _total_deuda DECIMAL(10,2) DEFAULT 0;

    SELECT IFNULL(SUM(cc.valor_cuota), 0) INTO _total_deuda
    FROM Clientes cl
    INNER JOIN Cuentas cu ON cu.cliente_id = cl.id
    INNER JOIN Tarjetas t ON t.cuenta_id = cu.id
    INNER JOIN Movimientos_tarjeta mt ON mt.tarjeta_id = t.id
    LEFT JOIN Cuotas_credito cc ON cc.movimiento_id = mt.id
    WHERE cl.id = p_cliente_id AND cc.estado = 'Pendiente';

    RETURN _total_deuda;
END //

DELIMITER ;

SELECT fn_cuotas_credito(1) AS Total_deuda;

-- Estimar el total de pagos realizados por tipo de tarjeta durante un período determinado.

DELIMITER //

DROP FUNCTION IF EXISTS fn_total_pagos_por_tipo;
CREATE FUNCTION fn_total_pagos_por_tipo(p_tipo_tarjeta_id INT, p_fecha_inicio DATE, p_fecha_fin DATE)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE _total DECIMAL(10,2) DEFAULT 0;

    SELECT IFNULL(SUM(pt.monto), 0) INTO _total
    FROM Pagos_tarjeta pt
    INNER JOIN Cuotas_credito cc ON pt.cuota_credito_id = cc.id
    INNER JOIN Movimientos_tarjeta mt ON cc.movimiento_id = mt.id
    INNER JOIN Tarjetas t ON mt.tarjeta_id = t.id
    WHERE t.tipo_tarjeta_id = p_tipo_tarjeta_id AND pt.fecha_pago BETWEEN p_fecha_inicio AND p_fecha_fin;

    RETURN _total;
END //

DELIMITER ;

SELECT fn_total_pagos_por_tipo(1, '2020-01-01', '2026-01-01')

-- Calcular el monto total de las cuotas de manejo para todos los clientes de un mes.

DELIMITER //

DROP FUNCTION IF EXISTS fn_total_cuotas_manejo_mes;
CREATE FUNCTION fn_total_cuotas_manejo_mes(p_mes INT, p_anio INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE _total DECIMAL(10,2) DEFAULT 0;

    SELECT SUM(monto_total) INTO _total
    FROM Cuotas_de_manejo
    WHERE MONTH(vencimiento_cuota) = p_mes AND YEAR(vencimiento_cuota) = p_anio;

    RETURN _total;
END //

DELIMITER ;

SELECT fn_total_cuotas_manejo_mes(6, 2025);


-- Calcular el promedio de pagos realizados por un cliente en sus tarjetas de crédito.

DELIMITER //

DROP FUNCTION IF EXISTS fn_promedio_pagos_credito;
CREATE FUNCTION fn_promedio_pagos_credito(p_cliente_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE _promedio INT DEFAULT 0;

    SELECT AVG(pt.monto) INTO _promedio
    FROM Clientes cl
    INNER JOIN Cuentas cu ON cu.cliente_id = cl.id
    INNER JOIN Tarjetas t ON t.cuenta_id = cu.id
    INNER JOIN Movimientos_tarjeta mt ON mt.tarjeta_id = t.id
    INNER JOIN Cuotas_credito cc ON cc.movimiento_id = mt.id
    INNER JOIN Pagos_tarjeta pt ON pt.cuota_credito_id = cc.id
    WHERE t.categoria_tarjeta_id = 1 AND cl.id = p_cliente_id;

    RETURN _promedio;
END //
DELIMITER ;

SELECT fn_promedio_pagos_credito(1) AS Promedio;


-- Determinar cuántas tarjetas activas tiene un cliente según su ID.

DELIMITER //

DROP FUNCTION IF EXISTS fn_cantidad_tarjetas;
CREATE FUNCTION fn_cantidad_tarjetas(p_cliente_id INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE _cantidad_tarjetas INT DEFAULT 0;

    SELECT COUNT(DISTINCT t.id) INTO _cantidad_tarjetas
    FROM Clientes cl
    INNER JOIN Cuentas cu ON cu.cliente_id = cl.id
    INNER JOIN Tarjetas t ON t.cuenta_id = cu.id
    WHERE cl.id = p_cliente_id;

    RETURN _cantidad_tarjetas;
END //

DELIMITER ;

SELECT fn_cantidad_tarjetas(1) AS Cantidad;

-- Calcular el total de intereses historicos generados por una tarjeta específica.

DELIMITER //

DROP FUNCTION IF EXISTS fn_interes_tarjeta;
CREATE FUNCTION fn_interes_tarjeta(p_tarjeta_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE _interes_historico DECIMAL(10,2);

    SELECT SUM(it.monto_interes) INTO _interes_historico
    FROM Tarjetas t
    INNER JOIN Intereses_tarjetas it ON it.tarjeta_id = t.id
    WHERE t.id = p_tarjeta_id;

    RETURN IFNULL(_interes_historico, 0);

END //

DELIMITER ;

SELECT fn_interes_tarjeta(2);


-- Calcular el total de dinero retirado por un cliente en un mes específico.

DELIMITER //

DROP FUNCTION IF EXISTS fn_total_retiros_mes;
CREATE FUNCTION fn_total_retiros_mes(p_cliente_id INT, p_mes INT, p_anio INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE _total_retiros DECIMAL(10,2) DEFAULT 0;

    SELECT IFNULL(SUM(m.monto), 0) INTO _total_retiros
    FROM Movimientos m
    INNER JOIN Cuentas c ON m.cuenta_id = c.id
    INNER JOIN Tipo_movimiento_cuenta tmc ON m.tipo_movimiento = tmc.id
    WHERE c.cliente_id = p_cliente_id AND tmc.nombre = 'Retiro' AND MONTH(m.fecha) = p_mes AND YEAR(m.fecha) = p_anio;

    RETURN _total_retiros;
END //

DELIMITER ;

SELECT fn_total_retiros_mes(1, 1, 2023) AS Total_retiros;


-- Contar cuántas tarjetas de un cliente están actualmente en estado bloqueada.

DELIMITER //

DROP FUNCTION IF EXISTS fn_tarjetas_bloqueadas_cliente;
CREATE FUNCTION fn_tarjetas_bloqueadas_cliente(p_cliente_id INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE _total_bloqueadas INT DEFAULT 0;

    SELECT COUNT(t.id) INTO _total_bloqueadas
    FROM Tarjetas t
    INNER JOIN Cuentas c ON t.cuenta_id = c.id
    WHERE c.cliente_id = p_cliente_id AND t.estado = 'Bloqueada';

    RETURN _total_bloqueadas;
END //

DELIMITER ;

SELECT fn_tarjetas_bloqueadas_cliente(7) AS Tarhetas_bloqueadas;

-- Calcular cuánto crédito disponible tiene un cliente

DELIMITER //
DROP FUNCTION IF EXISTS fn_limite_credito_disponible;
CREATE FUNCTION fn_limite_credito_disponible(p_cliente_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE _disponible DECIMAL(10,2);

    SELECT SUM(t.limite_credito - t.saldo ) INTO _disponible
    FROM Tarjetas t
    INNER JOIN Cuentas c ON t.cuenta_id = c.id
    WHERE c.cliente_id = p_cliente_id AND t.categoria_tarjeta_id = 1;

    RETURN _disponible;
END //
DELIMITER ;

SELECT fn_limite_credito_disponible(2) AS Credito_disponible;

--  Determinar cuántas cuotas de crédito ha pagado un cliente en total

DELIMITER //
DROP FUNCTION IF EXISTS fn_cuotas_pagadas;
CREATE FUNCTION fn_cuotas_pagadas(p_cliente_id INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE _cuotas INT;

    SELECT COUNT(*) INTO _cuotas
    FROM Cuotas_credito cc
    INNER JOIN Movimientos_tarjeta mt ON cc.movimiento_id = mt.id
    INNER JOIN Tarjetas t ON mt.tarjeta_id = t.id
    INNER JOIN Cuentas c ON t.cuenta_id = c.id
    WHERE c.cliente_id = p_cliente_id AND cc.estado = 'Pagada';

    RETURN _cuotas;
END //
DELIMITER ;

SELECT fn_cuotas_pagadas(1) AS Cuotas_pagadas;

-- Obtener la fecha de la última compra hechas con alguna tarjeta por un cliente


DELIMITER //
DROP FUNCTION IF EXISTS fn_fecha_ultima_compra;
CREATE FUNCTION fn_fecha_ultima_compra(p_cliente_id INT)
RETURNS DATE
DETERMINISTIC
BEGIN
    DECLARE _fecha DATE;

    SELECT MAX(mt.fecha) INTO _fecha
    FROM Movimientos_tarjeta mt
    INNER JOIN Tarjetas t ON mt.tarjeta_id = t.id
    INNER JOIN Cuentas c ON t.cuenta_id = c.id
    WHERE c.cliente_id = p_cliente_id AND mt.tipo_movimiento_tarjeta = 1;

    IF _fecha IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El usuario no tiene compras';
    END IF;

    RETURN _fecha;
END //
DELIMITER ;

SELECT fn_fecha_ultima_compra(4) AS Ultima_Compra;


-- Calcular el promedio mensual de intereses generados por una tarjeta durante el último año

DELIMITER //
DROP FUNCTION IF EXISTS fn_promedio_interes_mensual;
CREATE FUNCTION fn_promedio_interes_mensual(p_tarjeta_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE _promedio DECIMAL(10,2);

    SELECT AVG(monto_interes) INTO _promedio
    FROM Intereses_tarjetas
    WHERE tarjeta_id = p_tarjeta_id AND fecha_generacion >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH);

    IF _promedio IS NULL THEN
        SET _promedio = 0;
    END IF;

    RETURN _promedio;
END //
DELIMITER ;

SELECT fn_promedio_interes_mensual(1) AS Promedio_tarjeta;


-- Calcular cuánto dinero se ha descontado a un cliente en todas sus cuentas

DELIMITER //
DROP FUNCTION IF EXISTS fn_total_descuentos_aplicados;
CREATE FUNCTION fn_total_descuentos_aplicados(p_cliente_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE _descuento_total DECIMAL(10,2);

    SELECT SUM(cm.monto_base * tt.descuento / 100) INTO _descuento_total
    FROM Tarjetas t
    INNER JOIN Tipo_tarjetas tt ON t.tipo_tarjeta_id = tt.id
    INNER JOIN Cuentas c ON t.cuenta_id = c.id
    INNER JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id
    WHERE c.cliente_id = p_cliente_id;

    IF _descuento_total IS NULL THEN
        SET _descuento_total = 0;
    END IF;

    RETURN _descuento_total;
END //
DELIMITER ;

SELECT fn_total_descuentos_aplicados(1) AS Total_con_descuentos;


--  Calcular cuánto le falta por pagar a un cliente en cuotas de crédito

DELIMITER //

DROP FUNCTION IF EXISTS fn_total_credito_pendiente_cliente;
CREATE FUNCTION fn_total_credito_pendiente_cliente(p_cliente_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE _total_credito DECIMAL(10,2) DEFAULT 0.00;
    DECLARE _pagado DECIMAL(10,2) DEFAULT 0.00;
    DECLARE _pendiente DECIMAL(10,2);

    SELECT IFNULL(SUM(cc.valor_cuota), 0) INTO _total_credito
    FROM Clientes cl
    JOIN Cuentas cu ON cu.cliente_id = cl.id
    JOIN Tarjetas t ON t.cuenta_id = cu.id
    JOIN Movimientos_tarjeta mt ON mt.tarjeta_id = t.id
    JOIN Cuotas_credito cc ON cc.movimiento_id = mt.id
    WHERE cl.id = p_cliente_id AND cc.estado = 'Pendiente';

    SELECT IFNULL(SUM(pt.monto), 0) INTO _pagado
    FROM Clientes cl
    JOIN Cuentas cu ON cu.cliente_id = cl.id
    JOIN Tarjetas t ON t.cuenta_id = cu.id
    JOIN Movimientos_tarjeta mt ON mt.tarjeta_id = t.id
    JOIN Cuotas_credito cc ON cc.movimiento_id = mt.id
    JOIN Pagos_tarjeta pt ON pt.cuota_credito_id = cc.id
    WHERE cl.id = p_cliente_id AND cc.estado = 'Pendiente';

    SET _pendiente = _total_credito - _pagado;

    IF _pendiente < 0 THEN
        SET _pendiente = 0;
    END IF;

    RETURN _pendiente;
END //

DELIMITER ;
