DELIMITER $$

CREATE PROCEDURE INSERT_VEHICLE_CHECK_PLATE (
    IN p_plate_number VARCHAR(20),
    IN p_make VARCHAR(20),
    IN p_model VARCHAR(20),
    IN p_color VARCHAR(10),
    IN p_capacity INT,
    IN p_registrant_id INT,
    IN p_using_driver_id INT
)
BEGIN
    -- Check plate format
    IF p_plate_number NOT REGEXP '^[0-9]{2}[A-Z]{1,3}-[0-9]{3}\\.[0-9]{2}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid plate number format';
    END IF;

    -- Insert
    INSERT INTO VEHICLE (
        PLATE_NUMBER,
        MAKE,
        MODEL,
        COLOR,
        CAPACITY,
        REGISTRANT_ID,
        USING_DRIVER_ID
    )
    VALUES (
        p_plate_number,
        p_make,
        p_model,
        p_color,
        p_capacity,
        p_registrant_id,
        p_using_driver_id
    );

END$$

DELIMITER ;