-- Active: 1775061495821@@127.0.0.1@3306@grab
-- Function 1: GrabCoins bonus for passengers
-- A function that calculates a special end-of-month "GrabCoin" loyalty bonus for a passenger.
-- Instead of a flat earn rate, the rewards are dynamic.
-- The function evaluates each trip row-by-row, granting bonus multipliers
-- based on the luxury level of the ride and
-- the passenger's engagement (whether they left a rating).
USE GRAB;

DELIMITER //

CREATE FUNCTION GRAB_COIN_BONUS(
    P_PASSENGER_ID INT,
    P_TARGET_MONTH INT,
    P_TARGET_YEAR INT
)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE V_TOTAL_EXTRA_COINS INT DEFAULT 0;
    DECLARE V_TRIP_EXTRA_COINS DECIMAL(10, 2) DEFAULT 0;
    DECLARE V_BASE_COINS INT;
    DECLARE V_SERVICE_LEVEL ENUM(
        'Standard',
        'Saver',
        'Electric'
    );
    DECLARE V_RATING_STARS INT;
    DECLARE V_BOOKING_HOUR INT;
    DECLARE V_PAID_BY_CASH BOOLEAN;
    DECLARE V_TRIP_COUNTER INT DEFAULT 0;
    DECLARE V_PASSENGER_EXISTS INT;
    DECLARE DONE BOOLEAN DEFAULT FALSE;


    -- Declare cursor
    DECLARE TRIP_CURSOR CURSOR FOR
        SELECT C.OBTAINED_GRABCOIN, M.SERVICE_LEVEL, C.RATING_STARS,
                HOUR(T.BOOKING_TIME), TX.PAID_BY_CASH
        FROM TRIP T
        JOIN COMPLETED_TRIP C ON T.TRIP_ID = C.TRIP_ID
        JOIN TRANSPORT_MODE M ON T.MODE_ID = M.MODE_ID
        LEFT JOIN PAYMENT_TRANSACTION TX ON C.TRIP_ID = TX.TRIP_ID
        WHERE T.PASSENGER_ID = P_PASSENGER_ID
            AND MONTH(C.TO_TIME) = P_TARGET_MONTH
            AND YEAR(C.TO_TIME) = P_TARGET_YEAR
        ORDER BY C.TO_TIME ASC;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET DONE = TRUE;

    -- Input validation
    IF P_TARGET_MONTH NOT BETWEEN 1 AND 12 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid month';
    END IF;

    SELECT COUNT(*) INTO V_PASSENGER_EXISTS
    FROM PASSENGER WHERE ACCOUNT_ID = P_PASSENGER_ID;

    IF V_PASSENGER_EXISTS = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Passenger does not exist';
    END IF;

    OPEN TRIP_CURSOR;

    REWARD_LOOP: LOOP
        FETCH TRIP_CURSOR INTO V_BASE_COINS, V_SERVICE_LEVEL, V_RATING_STARS, V_BOOKING_HOUR, V_PAID_BY_CASH;

        IF DONE THEN
            LEAVE REWARD_LOOP;
        END IF;

        SET V_TRIP_COUNTER = V_TRIP_COUNTER + 1;
        SET V_TRIP_EXTRA_COINS = 0;

        -- Bonus for green energy
        IF V_SERVICE_LEVEL = 'Electric' THEN
            SET V_TRIP_EXTRA_COINS = V_TRIP_EXTRA_COINS + V_BASE_COINS;
        END IF;

        -- Rush hour bonus (7-8 AM and 5-6 PM)
        IF V_BOOKING_HOUR IN (7, 8, 17, 18) THEN
            SET V_TRIP_EXTRA_COINS = V_TRIP_EXTRA_COINS + (V_BASE_COINS * 0.5);
        END IF;

        -- Cashless bonus
        IF V_PAID_BY_CASH = FALSE THEN
            SET V_TRIP_EXTRA_COINS = V_TRIP_EXTRA_COINS + 5;
        END IF;

        -- Engagement bonus
        IF V_RATING_STARS = 5 THEN
            SET V_TRIP_EXTRA_COINS = V_TRIP_EXTRA_COINS + 10;
        END IF;

        -- Bonus for every 5th trip of the month
        IF V_TRIP_COUNTER % 5 = 0 THEN
            SET V_TRIP_EXTRA_COINS = V_TRIP_EXTRA_COINS + 100;
        END IF;

        SET V_TOTAL_EXTRA_COINS = V_TOTAL_EXTRA_COINS + ROUND(V_TRIP_EXTRA_COINS);
    
    END LOOP;

    CLOSE TRIP_CURSOR;
        
    RETURN V_TOTAL_EXTRA_COINS;

END//


-- Function 2: Driver Bonus Calculation
-- A function that calculates a monthly bonus for drivers based on their completed trips.
-- The bonus is influenced by multiple factors, including the average rating of their trips,
-- the type of vehicle they used, and whether they completed any trips during peak hours.

CREATE FUNCTION CALCULATE_DRIVER_BONUS_FEE(
    p_driver_id INT,
    p_month INT,
    p_year INT
) 
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    -- Variables for calculation
    DECLARE v_total_bonus DECIMAL(10,2) DEFAULT 0.0;
    DECLARE v_trip_rating INT;
    DECLARE v_seat_capacity INT;
    DECLARE v_has_payment INT;
    DECLARE v_driver_exists INT;
    DECLARE done INT DEFAULT FALSE;

    

    -- 2. Cursor to fetch details for each trip
    DECLARE trip_cursor CURSOR FOR 
        SELECT CT.RATING_STARS, TM.SEAT_CAPACITY, T.TRIP_ID
        FROM COMPLETED_TRIP CT
        JOIN ASSIGNED_TRIP AT ON CT.TRIP_ID = AT.TRIP_ID
        JOIN TRIP T ON AT.TRIP_ID = T.TRIP_ID
        JOIN TRANSPORT_MODE TM ON T.MODE_ID = TM.MODE_ID
        WHERE AT.DRIVER_ID = p_driver_id 
          AND MONTH(CT.TO_TIME) = p_month 
          AND YEAR(CT.TO_TIME) = p_year;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- 1. Input Validation
    IF p_month < 1 OR p_month > 12 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid month input.';
    END IF;

    -- Check if driver exists
    SELECT COUNT(*) INTO v_driver_exists
    FROM DRIVER WHERE ACCOUNT_ID = p_driver_id;

    IF v_driver_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Driver does not exist';
    END IF;
    
    OPEN trip_cursor;

    -- 3. Loop through data
    calc_loop: LOOP
        FETCH trip_cursor INTO v_trip_rating, v_seat_capacity, v_has_payment;
        IF done THEN
            LEAVE calc_loop;
        END IF;

        -- 4. Query Validation: Check if payment exists for this trip
        SELECT COUNT(*) INTO v_has_payment FROM PAYMENT_TRANSACTION 
        WHERE TRIP_ID = v_has_payment;

        IF v_has_payment > 0 THEN
            -- Start with a base bonus of 5000 VNĐ
            SET v_total_bonus = v_total_bonus + 5000;

            -- Complex IF Logic: Rating-based multiplier
            IF v_trip_rating = 5 THEN
                SET v_total_bonus = v_total_bonus + 2000;
            ELSEIF v_trip_rating >= 4 THEN
                SET v_total_bonus = v_total_bonus + 500;
            END IF;

            -- Capacity incentive
            IF v_seat_capacity >= 6 THEN
                SET v_total_bonus = v_total_bonus + 1500;
            END IF;
        END IF;

    END LOOP;

    CLOSE trip_cursor;

    RETURN v_total_bonus;
END //


-- SIGN_IN
-- Purpose: Authenticate user and get their information
-- Parameters:
--   p_email: Email address
--   p_password: Password
-- Returns:
--   Account ID if successful, -1 if authentication fails
CREATE FUNCTION SIGN_IN(
    p_email VARCHAR(50),
    p_password TEXT
)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_account_id INT DEFAULT -1;
    DECLARE v_stored_password TEXT;

    -- Get the account ID and password
    SELECT ACCOUNT_ID, ACCOUNT_PASSWORD 
    INTO v_account_id, v_stored_password
    FROM USER_ACCOUNT 
    WHERE EMAIL = p_email 
    LIMIT 1;

    -- Check if user exists
    IF v_account_id IS NULL THEN
        RETURN -1;
    END IF;

    -- Check if password matches
    IF v_stored_password = p_password THEN
        RETURN v_account_id;
    ELSE
        RETURN -1;
    END IF;
END //

DELIMITER ;