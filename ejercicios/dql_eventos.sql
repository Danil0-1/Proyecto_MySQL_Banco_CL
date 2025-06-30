
USE banco_cl;

SET GLOBAL event_scheduler = ON;


-- Evento para actualizar el estado de las tarjetas vencidas

DELIMITER //

CREATE EVENT IF NOT EXISTS ev_actualizar_tarjetas_vencidas
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    UPDATE Tarjetas
    SET estado = 'Vencida'
    WHERE fecha_expiracion < CURDATE() AND estado != 'Vencida';
END //

DELIMITER ;
