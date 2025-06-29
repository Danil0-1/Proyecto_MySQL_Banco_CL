
USE banco_cl;

-- Al insertar un nuevo pago, actualizar automáticamente el estado de la cuota de manejo.

DELIMITER //

DROP TRIGGER IF EXISTS tr_actualizar_estado_cuota_manejo;
CREATE TRIGGER tr_actualizar_estado_cuota_manejo
AFTER INSERT ON Pagos
FOR EACH ROW
BEGIN
    DECLARE _total_pago DECIMAL(10,2);
    DECLARE _monto_total DECIMAL(10,2);

    SELECT SUM(total_pago) INTO _total_pago
    FROM Pagos 
    WHERE cuota_id = NEW.cuota_id;

    SELECT monto_total INTO _monto_total
    FROM Cuotas_de_manejo 
    WHERE id = NEW.cuota_id;

    IF _total_pago >= _monto_total THEN
        UPDATE Cuotas_de_manejo
        SET estado = 'Pago'
        WHERE id = NEW.cuota_id;
    END IF;
END //
DELIMITER ;

SELECT * FROM Cuotas_de_manejo;

INSERT INTO Pagos (
    cuota_id,
    fecha_pago,
    total_pago,
    metodo_pago,
    estado
) VALUES (
    4, CURDATE(), 47500.00, 'Transferencia', 'Completado'
);

-- Al modificar el monto de apertura de una tarjeta, recalcular la cuota de manejo correspondiente.

DELIMITER //
DROP TRIGGER IF EXISTS tr_recalcular_cuota_manejo;
CREATE TRIGGER tr_recalcular_cuota_manejo
AFTER UPDATE ON Tarjetas
FOR EACH ROW
BEGIN
    IF OLD.monto_apertura <> NEW.monto_apertura THEN
        UPDATE Cuotas_de_manejo
        SET monto_total = NEW.monto_apertura - (NEW.monto_apertura * (
            SELECT descuento 
            FROM Tipo_tarjetas 
            WHERE id = NEW.tipo_tarjeta_id
        ) / 100)
        WHERE tarjeta_id = NEW.id;
    END IF;
END //
DELIMITER ;

SELECT * FROM Cuotas_de_manejo;

UPDATE Tarjetas 
SET monto_apertura = 200000
WHERE id = 1;


-- Al eliminar una tarjeta, eliminar todas las cuotas de manejo asociadas a esa tarjeta.

DELIMITER //

DROP TRIGGER IF EXISTS tr_eliminar_cuotas_manejo;
CREATE TRIGGER tr_eliminar_cuotas_manejo
BEFORE DELETE ON Tarjetas
FOR EACH ROW
BEGIN
    DELETE FROM Cuotas_de_manejo WHERE tarjeta_id = OLD.id;
END //

DELIMITER ;

SELECT * FROM Tarjetas t LEFT JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id; 

DELETE FROM Tarjetas WHERE id = 1;

-- Al actualizar los descuentos, recalcular las cuotas de manejo de las tarjetas afectadas.

DELIMITER //

DROP TRIGGER IF EXISTS tr_recalcular_cuotas_manejo_descuento;
CREATE TRIGGER tr_recalcular_cuotas_manejo_descuento
AFTER UPDATE ON Tipo_tarjetas
FOR EACH ROW
BEGIN
    IF OLD.descuento <> NEW.descuento THEN
        UPDATE Cuotas_de_manejo cm
        JOIN Tarjetas t ON t.id = cm.tarjeta_id
        SET cm.monto_total = t.monto_apertura - (t.monto_apertura * NEW.descuento / 100)
        WHERE t.tipo_tarjeta_id = NEW.id;
    END IF;
END //

DELIMITER ;

UPDATE Tipo_tarjetas
SET descuento = 3.0
WHERE id = 1;

SELECT * FROM Cuotas_de_manejo;

-- Actualizar estado de cuota de manejo cuando se registre un pago

DELIMITER //
DROP TRIGGER IF EXISTS tr_actualizar_estado_cuota_manejo;
CREATE TRIGGER tr_actualizar_estado_cuota_manejo
AFTER INSERT ON Pagos
FOR EACH ROW
BEGIN
    DECLARE _total_pago DECIMAL(10,2);
    DECLARE _monto_total DECIMAL(10,2);

    SELECT SUM(total_pago) INTO _total_pago 
    FROM Pagos 
    WHERE cuota_id = NEW.cuota_id;

    SELECT monto_total INTO _monto_total 
    FROM Cuotas_de_manejo 
    WHERE id = NEW.cuota_id;

    IF _total_pago >= _monto_total THEN
        UPDATE Cuotas_de_manejo 
        SET estado = 'Pago' 
        WHERE id = NEW.cuota_id;
    END IF;

END //
DELIMITER ;

SELECT * FROM Cuotas_de_manejo;

INSERT INTO Pagos(
    cuota_id,
    fecha_pago,
    total_pago,
    metodo_pago,
    estado
) VALUES(
    47, CURDATE(), 47500.00, 'Tarjeta', 'Completado'
);


-- Al registrar un nuevo movimiento de tarjeta, actualizar el saldo de la tarjeta.

DELIMITER //

DROP TRIGGER IF EXISTS tr_actualizar_saldo_tarjeta;
CREATE TRIGGER tr_actualizar_saldo_tarjeta
AFTER INSERT ON Movimientos_tarjeta
FOR EACH ROW
BEGIN
    DECLARE _saldo_actual DECIMAL(10,2);

    SELECT saldo INTO _saldo_actual
    FROM Tarjetas
    WHERE id = NEW.tarjeta_id;

    IF NEW.tipo_movimiento_tarjeta IN (1, 2) THEN
        IF _saldo_actual >= NEW.monto THEN
            UPDATE Tarjetas
            SET saldo = _saldo_actual - NEW.monto
            WHERE id = NEW.tarjeta_id;
        ELSE
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Saldo insuficiente para realizar esta operación.';
        END IF;
    
    ELSEIF NEW.tipo_movimiento_tarjeta IN (3, 4) THEN
        UPDATE Tarjetas
        SET saldo = _saldo_actual + NEW.monto
        WHERE id = NEW.tarjeta_id;
    END IF;
END //

DELIMITER ;

SELECT * FROM Tarjetas;

INSERT INTO Movimientos_tarjeta(
    tipo_movimiento_tarjeta,
    tarjeta_id,
    fecha,
    monto,
    cuotas
) VALUES
(2, 2, CURDATE(), 50000, 1);


-- Actualizar estado de cuota de credito cuando se registre un pago

DELIMITER //

DROP TRIGGER IF EXISTS tr_actualizar_estado_cuota_credito;
CREATE TRIGGER tr_actualizar_estado_cuota_credito
AFTER INSERT ON Pagos_tarjeta
FOR EACH ROW
BEGIN
    DECLARE _monto_total_pago DECIMAL(10,2) DEFAULT 0.00;
    DECLARE _valor_cuota DECIMAL(10,2) DEFAULT 0.00;

    SELECT SUM(monto) INTO _monto_total_pago
    FROM Pagos_tarjeta
    WHERE cuota_credito_id = NEW.cuota_credito_id;

    SELECT valor_cuota INTO _valor_cuota
    FROM Cuotas_credito
    WHERE id = NEW.cuota_credito_id;

    IF _monto_total_pago >= _valor_cuota THEN
        UPDATE Cuotas_credito
        SET estado = 'Pagada'
        WHERE id = NEW.cuota_credito_id;
    END IF;

END;
//

DELIMITER ;

SELECT * FROM Cuotas_credito;

INSERT INTO Pagos_tarjeta(
    cuota_credito_id,
    fecha_pago,
    monto
) VALUES 
(9, CURDATE(),  30000);


-- Bloquear tarjeta automáticamente al registrar 7 retiros consecutivos por tarjeta en menos de 1 dia

DELIMITER //

DROP TRIGGER IF EXISTS tr_bloquear_tarjeta_retiros_rapidos;
CREATE TRIGGER tr_bloquear_tarjeta_retiros_rapidos
AFTER INSERT ON Movimientos_tarjeta
FOR EACH ROW
BEGIN
    DECLARE _cantidad_movimiento INT;

    SELECT COUNT(*) INTO _cantidad_movimiento
    FROM Movimientos_tarjeta
    WHERE tarjeta_id = NEW.tarjeta_id AND tipo_movimiento_tarjeta = 2 AND fecha >= NOW() - INTERVAL 1 DAY;

    IF NEW.tipo_movimiento_tarjeta = 2 THEN
        IF _cantidad_movimiento >= 7 THEN
            UPDATE Tarjetas SET estado = 'Bloqueada'
            WHERE id = NEW.tarjeta_id;
        END IF;
    END IF;
END //
DELIMITER ;

SELECT * FROM Tarjetas WHERE id = 3;

INSERT INTO Movimientos_tarjeta (tipo_movimiento_tarjeta, tarjeta_id, monto, cuotas)
VALUES 
(2, 3, 10, 1),
(2, 3, 20, 1),
(2, 3, 30, 1),
(2, 3, 40, 1),
(2, 3, 50, 1),
(2, 3, 60, 1),
(2, 3, 70, 1);

-- Bloquear movimientos en tarjetas inactivas, bloqueadas o vencidas

DELIMITER //

DROP TRIGGER IF EXISTS tr_evitar_movimiento_tarjeta_inactiva;
CREATE TRIGGER tr_evitar_movimiento_tarjeta_inactiva
BEFORE INSERT ON Movimientos_tarjeta
FOR EACH ROW
BEGIN
    DECLARE _estado_tarjeta ENUM('Activa', 'Inactiva', 'Bloqueada', 'Vencida');

    SELECT estado INTO _estado_tarjeta
    FROM Tarjetas
    WHERE id = NEW.tarjeta_id;

    IF _estado_tarjeta <> 'Activa' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se permiten movimientos en tarjetas que no estén activas.';
    END IF;
END //

DELIMITER ;

-- Asignar una tarjeta automaticamente al crear una cuenta

DELIMITER //

DROP TRIGGER IF EXISTS tr_tarjeta_inactiva_nueva_cuenta;
CREATE TRIGGER tr_tarjeta_inactiva_nueva_cuenta
AFTER INSERT ON Cuentas
FOR EACH ROW
BEGIN
    IF NEW.saldo = 0 THEN
        INSERT INTO Tarjetas (
            tipo_tarjeta_id, 
            categoria_tarjeta_id, 
            cuenta_id,
            monto_apertura, 
            saldo, 
            estado, 
            numero_tarjeta,
            fecha_expiracion
        )
        VALUES (
            1, 
            2, 
            NEW.id, 
            0, 
            0, 
            'Inactiva',
            CONCAT('0000', NEW.id, FLOOR(RAND()*10000)),
            CURDATE() + INTERVAL 3 YEAR
        );
    END IF;
END //
DELIMITER ;

SELECT * 
FROM Cuentas
INNER JOIN Tarjetas ON Cuentas.id = Tarjetas.cuenta_id;

INSERT INTO Cuentas(
    tipo_cuenta_id,
    cliente_id,
    saldo,
    fecha_creacion
) VALUES
(1, 1, 0.00, CURDATE())

-- Actualizar el historial de pagos al cambiar un pago

DELIMITER //

DROP TRIGGER IF EXISTS tr_historial_estado_pago;
CREATE TRIGGER tr_historial_estado_pago
BEFORE UPDATE ON Pagos
FOR EACH ROW
BEGIN
    IF OLD.estado <> NEW.estado THEN
        INSERT INTO Historial_de_pagos (
            pago_id,
            fecha_cambio,
            estado_anterior,
            nuevo_estado
        ) VALUES (
            OLD.id,
            CURDATE(),
            OLD.estado,
            NEW.estado
        );
    END IF;
END //

DELIMITER ;

SELECT * 
FROM Historial_de_pagos 
WHERE pago_id = 4;


UPDATE Pagos 
SET estado = 'Completado' 
WHERE id = 4;


-- Registrar automáticamente una cuenta al insertar un cliente

DELIMITER //
CREATE TRIGGER tr_crear_cuenta_con_cliente
AFTER INSERT ON Clientes
FOR EACH ROW
BEGIN
    INSERT INTO Cuentas (
        tipo_cuenta_id, 
        cliente_id, 
        saldo, 
        fecha_creacion
    )VALUES (
        1, NEW.id, 0, CURDATE()
        ); 
END //
DELIMITER ;

INSERT INTO Clientes(
    nombre,
    documento,
    correo,
    fecha_registro,
    telefono
) VALUES
('Prueba cuenta', '9847598174', 'pruebacuenta@gmail.com', CURDATE(), '+57 312475825');

SELECT *
FROM Cuentas
WHERE cliente_id = LAST_INSERT_ID();

-- Al insertar una tarjeta, generar automáticamente su PIN

DELIMITER //
DROP TRIGGER IF EXISTS tr_generar_pin_tarjeta;
CREATE TRIGGER tr_generar_pin_tarjeta
AFTER INSERT ON Tarjetas
FOR EACH ROW
BEGIN
    INSERT INTO Seguridad_tarjetas (tarjeta_id, pin)
    VALUES (NEW.id, LPAD(FLOOR(RAND() * 10000), 4, '0'));
END //
DELIMITER ;

INSERT INTO Tarjetas(
    tipo_tarjeta_id,
    categoria_tarjeta_id,
    cuenta_id,
    monto_apertura,
    saldo,
    estado,
    numero_tarjeta,
    fecha_expiracion
) VALUES(
    1, 1, 1, 100000, 10000000, 'Activa', '1263871647124748', DATE_ADD(CURDATE(), INTERVAL 3 YEAR)
)

SELECT * FROM Seguridad_tarjetas WHERE tarjeta_id = LAST_INSERT_ID();

-- Si el tipo de tarjeta es 'Joven', limitar el saldo máximo

DELIMITER //

DROP TRIGGER IF EXISTS tr_limitar_saldo_joven;
CREATE TRIGGER tr_limitar_saldo_joven
BEFORE INSERT ON Tarjetas
FOR EACH ROW
BEGIN
    DECLARE _tipo_nombre VARCHAR(20);

    SELECT nombre INTO _tipo_nombre 
    FROM Tipo_tarjetas 
    WHERE id = NEW.tipo_tarjeta_id;
    
    IF _tipo_nombre = 'Joven' AND NEW.saldo > 500000 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Las tarjetas tipo Joven no pueden tener saldo mayor a 500000.';
    END IF;
END //
DELIMITER ;


INSERT INTO Tarjetas(
    tipo_tarjeta_id,
    categoria_tarjeta_id,
    cuenta_id,
    monto_apertura,
    saldo,
    estado,
    numero_tarjeta,
    fecha_expiracion
) VALUES(
    1, 1, 1, 100000, 10000000, 'Activa', '1263871647124748', DATE_ADD(CURDATE(), INTERVAL 3 YEAR)
)


--  Si se elimina una cuota de manejo, eliminar pagos asociados

DELIMITER //

DROP TRIGGER IF EXISTS tr_borrar_pagos_con_cuota;
CREATE TRIGGER tr_borrar_pagos_con_cuota
BEFORE DELETE ON Cuotas_de_manejo
FOR EACH ROW
BEGIN
    DELETE FROM Pagos 
    WHERE cuota_id = OLD.id;
END //
DELIMITER ;

SELECT * 
FROM Cuotas_de_manejo cm 
INNER JOIN Pagos p ON cm.id = p.cuota_id
WHERE cm.id = 5;

SELECT * FROM Pagos WHERE cuota_id = 5;

DELETE FROM Cuotas_de_manejo
WHERE id = 5


--  Si se crea un pago_tarjeta mayor al valor de la cuota, rechazarlo

DELIMITER //

DROP TRIGGER IF EXISTS tr_rechazar_pago_excesivo;
CREATE TRIGGER tr_rechazar_pago_excesivo
BEFORE INSERT ON Pagos_tarjeta
FOR EACH ROW
BEGIN
    DECLARE _valor DECIMAL(10,2);
    SELECT valor_cuota INTO _valor FROM Cuotas_credito WHERE id = NEW.cuota_credito_id;

    IF NEW.monto > _valor THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se permite pagar más de lo que vale la cuota.';
    END IF;
END //
DELIMITER ;


INSERT INTO Pagos_tarjeta (cuota_credito_id, fecha_pago, monto)
VALUES (7, CURDATE(), 120000); 

SELECT * FROM Cuotas_credito;