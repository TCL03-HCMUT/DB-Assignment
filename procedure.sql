DELIMITER $$


-- p_mode_ids_list: vehicle category for this vehicle. for exapmle: command-separated '1,2', respectively standard bike and saver bike
CREATE PROCEDURE INSERT_VEHICLE_WITH_MODES (
    IN p_plate_number VARCHAR(20),
    IN p_make VARCHAR(20),
    IN p_model VARCHAR(20),
    IN p_color VARCHAR(10),
    IN p_capacity INT,
    IN p_registrant_id INT,
    IN p_using_driver_id INT,
    IN p_mode_ids_list TEXT -- 
)
BEGIN
    DECLARE v_vehicle_id INT;
    DECLARE v_mode_id_str VARCHAR(255);
    DECLARE v_pos INT DEFAULT 1;

    -- PLATE NUMBER validation
    IF p_plate_number NOT REGEXP '^[0-9]{2}[A-Z]{1,3}-[0-9]{3}\\.[0-9]{2}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid plate number format';
    END IF;

    -- Insert into VEHICLE
    INSERT INTO VEHICLE (
        PLATE_NUMBER, MAKE, MODEL, COLOR, 
        CAPACITY, REGISTRANT_ID, USING_DRIVER_ID
    )
    VALUES (
        p_plate_number, p_make, p_model, p_color, 
        p_capacity, p_registrant_id, p_using_driver_id
    );

    -- Insert into VEHICLE_CATEGORIZATION
    SET v_vehicle_id = LAST_INSERT_ID();
    WHILE CHAR_LENGTH(p_mode_ids_list) > 0 AND v_pos > 0 DO
        SET v_pos = LOCATE(',', p_mode_ids_list);
        
        IF v_pos > 0 THEN
            SET v_mode_id_str = LEFT(p_mode_ids_list, v_pos - 1);
            SET p_mode_ids_list = SUBSTRING(p_mode_ids_list, v_pos + 1);
        ELSE
            SET v_mode_id_str = p_mode_ids_list;
            SET p_mode_ids_list = '';
        END IF;

        IF v_mode_id_str <> '' THEN
            INSERT INTO VEHICLE_CATEGORIZATION (VEHICLE_ID, MODE_ID)
            VALUES (v_vehicle_id, CAST(v_mode_id_str AS UNSIGNED));
        END IF;
    END WHILE;

END$$

DELIMITER ;