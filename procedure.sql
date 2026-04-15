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
END$$

DELIMITER ;