-- Active: 1775981929461@@localhost@3306@GRAB
DELIMITER //


-- p_mode_ids_list: vehicle category for this vehicle. for exapmle: command-separated '1,2', respectively standard bike and saver bike
-- p- prefix stands for 'parameter'
CREATE PROCEDURE INSERT_VEHICLE (
    IN p_plate_number VARCHAR(20),
    IN p_make VARCHAR(20),
    IN p_model VARCHAR(20),
    IN p_color VARCHAR(10),
    IN p_capacity INT,
    IN p_registrant_id INT,
    IN p_using_driver_id INT,
    IN p_mode_ids_list TEXT,
    OUT p_vehicle_id INT
)
BEGIN
    DECLARE v_vehicle_id INT;
    DECLARE v_mode_id_str VARCHAR(255);
    DECLARE v_pos INT DEFAULT 1;

    -- PLATE NUMBER validation
    IF p_plate_number NOT REGEXP '^[0-9]{2}[A-Z]{1,3}-[0-9]{3}\\.[0-9]{2}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid plate number. The format must be: [2 digits][1 to 3 capital letters][-][3 digits][.][2 digits]';
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
    SET p_vehicle_id = v_vehicle_id;

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
END //

CREATE PROCEDURE SWITCH_VEHICLE(
    IN p_registrant_id INT,
    IN p_vehicle_id INT
)
BEGIN
    -- Nullify all vehicles of this registrant
    UPDATE VEHICLE
    SET USING_DRIVER_ID = NULL
    WHERE REGISTRANT_ID = p_registrant_id;

    -- Set the chosen vehicle
    UPDATE VEHICLE
    SET USING_DRIVER_ID = p_registrant_id
    WHERE VEHICLE_ID = p_vehicle_id
      AND REGISTRANT_ID = p_registrant_id;
END //

CREATE PROCEDURE DELETE_VEHICLE(
    IN p_vehicle_id INT
)
BEGIN
    DELETE FROM VEHICLE
    WHERE VEHICLE_ID = p_vehicle_id;
END //

-- Procedure 1: Lấy danh sách Vehicle của Driver 

CREATE PROCEDURE GET_DRIVER_VEHICLE_LIST(
    IN p_driver_id INT,             -- Required: ID của tài xế
    IN p_mode_type VARCHAR(20),     -- Optional: 'Bike'/ 'Car' (NULL: tất cả)
    IN p_min_capacity INT,          -- Optional: Sức chứa tối thiểu (NULL: tất cả)
    IN p_sort_option VARCHAR(20)    -- Required: 'CAPACITY_DESC'/ 'CAPACITY_ASC'/ 'MAKE'
)
BEGIN
    SELECT 
        V.VEHICLE_ID, V.PLATE_NUMBER, V.MAKE, V.MODEL, V.CAPACITY,

        -- Trường hợp nhiều mode (VD: "Bike, Car")
        GROUP_CONCAT(TM.TYPE SEPARATOR ', ') AS MODE,
        
        CASE 
            WHEN V.USING_DRIVER_ID = p_driver_id THEN 'ACTIVE'
            ELSE 'IDLE'
        END AS CURRENT_STATUS

    FROM VEHICLE V
    JOIN VEHICLE_CATEGORIZATION VC ON V.VEHICLE_ID = VC.VEHICLE_ID
    JOIN TRANSPORT_MODE TM ON VC.MODE_ID = TM.MODE_ID
    
    WHERE 
        V.REGISTRANT_ID = p_driver_id
        AND (p_mode_type IS NULL OR TM.TYPE = p_mode_type)
        AND (p_min_capacity IS NULL OR V.CAPACITY >= p_min_capacity)
        
    GROUP BY
        V.VEHICLE_ID 
        
    ORDER BY 
        CASE WHEN p_sort_option = 'CAPACITY_DESC' THEN V.CAPACITY END DESC,
        CASE WHEN p_sort_option = 'CAPACITY_ASC' THEN V.CAPACITY END ASC,
        CASE WHEN p_sort_option = 'MAKE' THEN V.MAKE END ASC,
        V.VEHICLE_ID ASC;
END //

DELIMITER ;

-- Procedure 2: Báo cáo số lượng chuyến đi đã hoàn thành theo tháng trong khoảng thời gian nhất định
DELIMITER //

CREATE PROCEDURE GET_PASSENGER_MONTHLY_REPORT(
    IN p_passenger_id INT,
    IN p_months_back INT
)
BEGIN
    SELECT 
        DATE_FORMAT(C.TO_TIME, '%Y-%m') AS Month, 
        COUNT(T.TRIP_ID) AS Total_Completed_Trips
    FROM TRIP T
    JOIN COMPLETED_TRIP C ON T.TRIP_ID = C.TRIP_ID
    WHERE 
        T.PASSENGER_ID = p_passenger_id AND
        C.TO_TIME >= DATE_SUB(CURRENT_DATE, INTERVAL p_months_back MONTH) 
    GROUP BY Month
    HAVING 
        Total_Completed_Trips > 0
    ORDER BY Month ASC;
END //

DELIMITER ;