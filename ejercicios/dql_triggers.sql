
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