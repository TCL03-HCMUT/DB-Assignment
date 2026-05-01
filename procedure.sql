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
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_vehicle_id = -1;
        ROLLBACK;
    END;

    -- PLATE NUMBER validation
    IF p_plate_number NOT REGEXP '^[0-9]{2}[A-Z]{1,3}-[0-9]{3}\\.[0-9]{2}$' THEN
        SET p_vehicle_id = -1;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid plate number. The format must be: [2 digits][1 to 3 capital letters][-][3 digits][.][2 digits]';
    END IF;

    -- Start transaction
    START TRANSACTION;

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

    -- Commit transaction if all steps succeed
    COMMIT;
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

CREATE PROCEDURE CHANGE_VEHICLE_PLATE(
    IN p_vehicle_id INT,
    IN p_plate_number VARCHAR(20)
)
BEGIN
    IF p_plate_number NOT REGEXP '^[0-9]{2}[A-Z]{1,3}-[0-9]{3}\\.[0-9]{2}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid plate number. The format must be: [2 digits][1 to 3 capital letters][-][3 digits][.][2 digits]';
    END IF;

    UPDATE VEHICLE
    SET PLATE_NUMBER = p_plate_number
    WHERE VEHICLE_ID = p_vehicle_id;
END//

CREATE PROCEDURE CHANGE_VEHICLE_COLOR(
    IN p_vehicle_id INT,
    IN p_color VARCHAR(20)
)
BEGIN
    UPDATE VEHICLE
    SET COLOR = p_color
    WHERE VEHICLE_ID = p_vehicle_id;
END//

-- Thêm 1 categorization mới cho xe
CREATE PROCEDURE ADD_VEHICLE_CATEGORIZATION(
    IN p_vehicle_id INT,
    IN p_mode_id INT
)
BEGIN
    -- Check if this categorization already exists
    IF NOT EXISTS (
        SELECT 1 FROM VEHICLE_CATEGORIZATION 
        WHERE VEHICLE_ID = p_vehicle_id AND MODE_ID = p_mode_id
    ) THEN
        INSERT INTO VEHICLE_CATEGORIZATION (VEHICLE_ID, MODE_ID)
        VALUES (p_vehicle_id, p_mode_id);
    END IF;
END//

-- Xóa 1 categorization của xe (không cho xóa nếu nó là mode cuối cùng)
CREATE PROCEDURE REMOVE_VEHICLE_CATEGORIZATION(
    IN p_vehicle_id INT,
    IN p_mode_id INT
)
BEGIN
    -- Delete the categorization
    DELETE FROM VEHICLE_CATEGORIZATION
    WHERE VEHICLE_ID = p_vehicle_id AND MODE_ID = p_mode_id;
END//

-- Procedure 1: Lấy danh sách Vehicle của Driver

CREATE PROCEDURE GET_DRIVER_VEHICLE_LIST(
    IN p_driver_id INT,             -- Required: ID của tài xế
    IN p_service_level VARCHAR(20), -- Optional: 'Standard'/ 'Saver'/ 'Electric' (NULL: tất cả)
    IN p_capacity INT,              -- Optional: Sức chứa chính xác (2/5/7, NULL: tất cả)
    IN p_sort_option VARCHAR(20),   -- Required: 'CAPACITY_DESC'/ 'CAPACITY_ASC'/ 'MAKE'
    IN p_plate_number VARCHAR(20),  -- Optional: Biển số xe (NULL: tất cả)
    IN p_limit INT,                 -- Optional: Số lượng bản ghi mỗi trang (default: 10)
    IN p_offset INT                 -- Optional: Vị trí bắt đầu (default: 0)
)
BEGIN
    -- Input validation for pagination
    IF p_limit IS NULL OR p_limit <= 0 THEN
        SET p_limit = 10;
    END IF;
    IF p_offset IS NULL OR p_offset < 0 THEN
        SET p_offset = 0;
    END IF;

    SELECT 
        V.VEHICLE_ID, V.PLATE_NUMBER, V.MAKE, V.MODEL, V.CAPACITY, V.COLOR,

        -- Trường hợp nhiều mode (VD: "Standard, Saver")
        GROUP_CONCAT(TM.SERVICE_LEVEL SEPARATOR ', ') AS SERVICE_TYPE,
        
        CASE 
            WHEN V.USING_DRIVER_ID = p_driver_id THEN 'ACTIVE'
            ELSE 'IDLE'
        END AS CURRENT_STATUS

    FROM VEHICLE V
    JOIN VEHICLE_CATEGORIZATION VC ON V.VEHICLE_ID = VC.VEHICLE_ID
    JOIN TRANSPORT_MODE TM ON VC.MODE_ID = TM.MODE_ID
    
    WHERE 
        V.REGISTRANT_ID = p_driver_id
        AND (p_service_level IS NULL OR TM.SERVICE_LEVEL = p_service_level)
        AND (p_capacity IS NULL OR V.CAPACITY = p_capacity)
        AND (p_plate_number IS NULL OR V.PLATE_NUMBER LIKE CONCAT('%', p_plate_number, '%'))
        
    GROUP BY
        V.VEHICLE_ID 
        
    ORDER BY 
        CASE WHEN p_sort_option = 'CAPACITY_DESC' THEN V.CAPACITY END DESC,
        CASE WHEN p_sort_option = 'CAPACITY_ASC' THEN V.CAPACITY END ASC,
        CASE WHEN p_sort_option = 'MAKE' THEN V.MAKE END ASC,
        V.VEHICLE_ID ASC
    LIMIT p_limit OFFSET p_offset;
END //


-- Procedure: Đếm tổng số Vehicle của Driver theo bộ lọc
CREATE PROCEDURE COUNT_DRIVER_VEHICLES(
    IN p_driver_id INT,             -- Required: ID của tài xế
    IN p_service_level VARCHAR(20), -- Optional: 'Standard'/ 'Saver'/ 'Electric' (NULL: tất cả)
    IN p_capacity INT,              -- Optional: Sức chứa chính xác (2/5/7, NULL: tất cả)
    IN p_plate_number VARCHAR(20)   -- Optional: Biển số xe (NULL: tất cả)
)
BEGIN
    SELECT COUNT(DISTINCT V.VEHICLE_ID) AS total_count
    FROM VEHICLE V
    JOIN VEHICLE_CATEGORIZATION VC ON V.VEHICLE_ID = VC.VEHICLE_ID
    JOIN TRANSPORT_MODE TM ON VC.MODE_ID = TM.MODE_ID
    
    WHERE 
        V.REGISTRANT_ID = p_driver_id
        AND (p_service_level IS NULL OR TM.SERVICE_LEVEL = p_service_level)
        AND (p_capacity IS NULL OR V.CAPACITY = p_capacity)
        AND (p_plate_number IS NULL OR V.PLATE_NUMBER LIKE CONCAT('%', p_plate_number, '%'));
END //


-- Procedure 2: Báo cáo số lượng chuyến đi đã hoàn thành theo tháng trong khoảng thời gian nhất định

-- Too simple?
-- CREATE PROCEDURE GET_PASSENGER_MONTHLY_REPORT(
--     IN p_passenger_id INT,
--     IN p_months_back INT
-- )
-- BEGIN
--     SELECT 
--         DATE_FORMAT(C.TO_TIME, '%Y-%m') AS Month, 
--         COUNT(T.TRIP_ID) AS Total_Completed_Trips
--     FROM TRIP T
--     JOIN COMPLETED_TRIP C ON T.TRIP_ID = C.TRIP_ID
--     WHERE 
--         T.PASSENGER_ID = p_passenger_id AND
--         C.TO_TIME >= DATE_SUB(CURRENT_DATE, INTERVAL p_months_back MONTH) 
--     GROUP BY Month
--     HAVING 
--         Total_Completed_Trips > 0
--     ORDER BY Month ASC;
-- END //


CREATE PROCEDURE GET_PASSENGER_MONTHLY_REPORT(
    IN p_passenger_id INT,
    IN p_months_back INT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM PASSENGER WHERE ACCOUNT_ID = p_passenger_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Passenger ID does not exist.';
    END IF;

    SELECT 
        DATE_FORMAT(C.TO_TIME, '%Y-%m') AS Reporting_Month,
        
        COUNT(T.TRIP_ID) AS Total_Trips,
        
        -- Service Tier
        SUM(CASE WHEN M.SERVICE_LEVEL = 'Electric' THEN 1 ELSE 0 END) AS Electric_Rides,
        SUM(CASE WHEN M.SERVICE_LEVEL = 'Saver' THEN 1 ELSE 0 END) AS Saver_Rides,
        
        -- Financial Analysis
        SUM(T.ESTIMATED_PRICE) AS Gross_Estimate,
        SUM(T.FINAL_PRICE) AS Actual_Spent,
        SUM(T.ESTIMATED_PRICE - T.FINAL_PRICE) AS Total_Saved,
        
        -- Loyalty
        SUM(C.OBTAINED_GRABCOIN) AS Standard_Coins_Earned,
        
        -- Super duper advanced
        GRAB_COIN_BONUS(p_passenger_id, MONTH(MAX(C.TO_TIME)), YEAR(MAX(C.TO_TIME))) AS Loyalty_Bonus_Earned

    FROM TRIP T
    JOIN COMPLETED_TRIP C ON T.TRIP_ID = C.TRIP_ID
    JOIN TRANSPORT_MODE M ON T.MODE_ID = M.MODE_ID
    WHERE 
        T.PASSENGER_ID = p_passenger_id AND
        C.TO_TIME >= DATE_SUB(LAST_DAY(CURRENT_DATE), INTERVAL p_months_back MONTH) 
    GROUP BY 
        Reporting_Month
    HAVING
        Total_Trips > 0
    ORDER BY 
        Reporting_Month DESC;
END //


-- Procedure 3: Passenger Trip History
-- A complex user-facing query that retrieves a detailed, paginated history of a passenger's trips,
-- joining across multiple tables to include driver, vehicle, and feedback details.

CREATE PROCEDURE GET_PASSENGER_TRIP_HISTORY(
    IN p_passenger_id INT,
    IN p_limit INT,
    IN p_offset INT
)
BEGIN
    -- Input validation for pagination
    IF p_limit IS NULL OR p_limit <= 0 THEN
        SET p_limit = 10;
    END IF;
    IF p_offset IS NULL OR p_offset < 0 THEN
        SET p_offset = 0;
    END IF;

    SELECT 
        T.TRIP_ID,
        T.STATUS,
        T.BOOKING_TIME,
        T.FROM_ADDRESS,
        T.TO_ADDRESS,
        T.FINAL_PRICE,
        T.USED_GRABCOINS,
        TM.TYPE AS Vehicle_Type,
        TM.SERVICE_LEVEL,
        U.NAME AS Driver_Name,
        CT.RATING_STARS,
        CT.FEEDBACK,
        AT.FROM_TIME AS Start_Time,
        CT.TO_TIME AS Completion_Time
    FROM TRIP T
    JOIN TRANSPORT_MODE TM ON T.MODE_ID = TM.MODE_ID
    LEFT JOIN ASSIGNED_TRIP AT ON T.TRIP_ID = AT.TRIP_ID
    LEFT JOIN USER_ACCOUNT U ON AT.DRIVER_ID = U.ACCOUNT_ID
    LEFT JOIN COMPLETED_TRIP CT ON T.TRIP_ID = CT.TRIP_ID
    WHERE T.PASSENGER_ID = p_passenger_id
    ORDER BY T.BOOKING_TIME DESC
    LIMIT p_limit OFFSET p_offset;
END //


-- Procedure 4: Driver Trip History
-- Retrieves a detailed, paginated history of a driver's completed trips,
-- joining across multiple tables to include passenger, vehicle, and trip details.

CREATE PROCEDURE GET_DRIVER_TRIP_HISTORY(
    IN p_driver_id INT,
    IN p_limit INT,
    IN p_offset INT
)
BEGIN
    -- Input validation for pagination
    IF p_limit IS NULL OR p_limit <= 0 THEN
        SET p_limit = 10;
    END IF;
    IF p_offset IS NULL OR p_offset < 0 THEN
        SET p_offset = 0;
    END IF;

    SELECT 
        T.TRIP_ID,
        T.STATUS,
        T.BOOKING_TIME,
        T.FROM_ADDRESS,
        T.TO_ADDRESS,
        T.FINAL_PRICE,
        TM.TYPE AS Vehicle_Type,
        TM.SERVICE_LEVEL,
        U.NAME AS Passenger_Name,
        CT.RATING_STARS,
        CT.FEEDBACK,
        AT.FROM_TIME AS Start_Time,
        CT.TO_TIME AS Completion_Time
    FROM TRIP T
    JOIN TRANSPORT_MODE TM ON T.MODE_ID = TM.MODE_ID
    JOIN ASSIGNED_TRIP AT ON T.TRIP_ID = AT.TRIP_ID
    JOIN USER_ACCOUNT U ON T.PASSENGER_ID = U.ACCOUNT_ID
    LEFT JOIN COMPLETED_TRIP CT ON T.TRIP_ID = CT.TRIP_ID
    WHERE AT.DRIVER_ID = p_driver_id
    ORDER BY T.BOOKING_TIME DESC
    LIMIT p_limit OFFSET p_offset;
END //


-- SIGN_UP_PASSENGER
-- Parameters:
--   p_name: Full name of the passenger
--   p_phone_number: Phone number (must be 10 digits starting with 0)
--   p_email: Email address
--   p_password: Password
--   p_gender: Gender ('Male' or 'Female', optional)
-- Returns:
--   p_account_id: The created account ID, or -1 if error
CREATE PROCEDURE SIGN_UP_PASSENGER(
    IN p_name VARCHAR(30),
    IN p_phone_number VARCHAR(10),
    IN p_email VARCHAR(50),
    IN p_password TEXT,
    IN p_gender ENUM('Male', 'Female'),
    OUT p_account_id INT
)
BEGIN
    DECLARE v_existing_count INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_account_id = -1;
        ROLLBACK;
    END;

    -- Validate inputs
    IF p_name IS NULL OR CHAR_LENGTH(TRIM(p_name)) = 0 THEN
        SET p_account_id = -1;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Name cannot be empty';
    END IF;

    IF p_phone_number IS NULL OR p_phone_number NOT REGEXP '^0[0-9]{9}$' THEN
        SET p_account_id = -1;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid phone number format. Must be 10 digits starting with 0';
    END IF;

    IF p_email IS NULL OR p_email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        SET p_account_id = -1;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid email format';
    END IF;

    IF p_password IS NULL OR CHAR_LENGTH(p_password) < 6 THEN
        SET p_account_id = -1;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Password must be at least 6 characters';
    END IF;

    -- Check for duplicates
    SELECT COUNT(*) INTO v_existing_count 
    FROM USER_ACCOUNT 
    WHERE EMAIL = p_email OR PHONE_NUMBER = p_phone_number;

    IF v_existing_count > 0 THEN
        SET p_account_id = -1;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Email or phone number already exists';
    END IF;

    -- Start transaction
    START TRANSACTION;

    -- Insert into USER_ACCOUNT
    INSERT INTO USER_ACCOUNT (NAME, PHONE_NUMBER, EMAIL, ACCOUNT_PASSWORD, GENDER)
    VALUES (p_name, p_phone_number, p_email, p_password, p_gender);

    -- Get the inserted ID
    SET p_account_id = LAST_INSERT_ID();

    -- Insert into PASSENGER
    INSERT INTO PASSENGER (ACCOUNT_ID, GRABCOINS)
    VALUES (p_account_id, 0);

    -- Commit transaction
    COMMIT;
END //

-- SIGN_UP_DRIVER
-- Parameters:
--   p_name: Full name of the driver
--   p_phone_number: Phone number (must be 10 digits starting with 0)
--   p_email: Email address
--   p_password: Password
--   p_gender: Gender ('Male' or 'Female', optional)
--   p_driver_license_grade: Driver license grade (A1, A2, B2, C, D, E, F)
-- Returns:
--   p_account_id: The created account ID, or -1 if error
CREATE PROCEDURE SIGN_UP_DRIVER(
    IN p_name VARCHAR(30),
    IN p_phone_number VARCHAR(10),
    IN p_email VARCHAR(50),
    IN p_password TEXT,
    IN p_gender ENUM('Male', 'Female'),
    IN p_driver_license_grade ENUM('A1', 'A2', 'B2', 'C', 'D', 'E', 'F'),
    OUT p_account_id INT
)
BEGIN
    DECLARE v_existing_count INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_account_id = -1;
        ROLLBACK;
    END;

    -- Validate inputs
    IF p_name IS NULL OR CHAR_LENGTH(TRIM(p_name)) = 0 THEN
        SET p_account_id = -1;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Name cannot be empty';
    END IF;

    IF p_phone_number IS NULL OR p_phone_number NOT REGEXP '^0[0-9]{9}$' THEN
        SET p_account_id = -1;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid phone number format. Must be 10 digits starting with 0';
    END IF;

    IF p_email IS NULL OR p_email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        SET p_account_id = -1;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid email format';
    END IF;

    IF p_password IS NULL OR CHAR_LENGTH(p_password) < 6 THEN
        SET p_account_id = -1;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Password must be at least 6 characters';
    END IF;

    IF p_driver_license_grade IS NULL THEN
        SET p_account_id = -1;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Driver license grade is required';
    END IF;

    -- Check for duplicates
    SELECT COUNT(*) INTO v_existing_count 
    FROM USER_ACCOUNT 
    WHERE EMAIL = p_email OR PHONE_NUMBER = p_phone_number;

    IF v_existing_count > 0 THEN
        SET p_account_id = -1;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Email or phone number already exists';
    END IF;

    -- Start transaction
    START TRANSACTION;

    -- Insert into USER_ACCOUNT
    INSERT INTO USER_ACCOUNT (NAME, PHONE_NUMBER, EMAIL, ACCOUNT_PASSWORD, GENDER)
    VALUES (p_name, p_phone_number, p_email, p_password, p_gender);

    -- Get the inserted ID
    SET p_account_id = LAST_INSERT_ID();

    -- Insert into DRIVER
    INSERT INTO DRIVER (ACCOUNT_ID, DRIVER_LICENSE_GRADE, CURRENT_BALANCE)
    VALUES (p_account_id, p_driver_license_grade, 0);

    -- Commit transaction
    COMMIT;
END //

-- Procedure: GET_USER_INFO
-- Purpose: Retrieve complete user information (works for both passenger and driver)
-- Parameters:
--   p_account_id: Account ID to retrieve
-- Returns:
--   User details including account type (passenger/driver) and relevant fields
CREATE PROCEDURE GET_USER_INFO(
    IN p_account_id INT
)
BEGIN
    SELECT 
        u.ACCOUNT_ID,
        u.NAME,
        u.EMAIL,
        u.PHONE_NUMBER,
        u.GENDER,
        u.AVATAR,
        CASE 
            WHEN p.ACCOUNT_ID IS NOT NULL THEN 'Passenger'
            WHEN d.ACCOUNT_ID IS NOT NULL THEN 'Driver'
            ELSE 'Unknown'
        END AS USER_TYPE,
        p.GRABCOINS,
        d.DRIVER_LICENSE_GRADE,
        d.CURRENT_BALANCE,
        COALESCE(ROUND(AVG(ct.RATING_STARS), 2), 0) AS AVERAGE_RATING
    FROM USER_ACCOUNT u
    LEFT JOIN PASSENGER p ON u.ACCOUNT_ID = p.ACCOUNT_ID
    LEFT JOIN DRIVER d ON u.ACCOUNT_ID = d.ACCOUNT_ID
    LEFT JOIN ASSIGNED_TRIP at ON d.ACCOUNT_ID = at.DRIVER_ID
    LEFT JOIN COMPLETED_TRIP ct ON at.TRIP_ID = ct.TRIP_ID
    WHERE u.ACCOUNT_ID = p_account_id
    GROUP BY u.ACCOUNT_ID;
END //

DELIMITER ;
