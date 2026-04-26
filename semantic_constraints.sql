-- Active: 1775061495821@@127.0.0.1@3306@grab
USE GRAB;

DELIMITER //

-- Constraint 1: BOOKING_TIME < FROM_TIME < TO_TIME

CREATE TRIGGER ASSIGNED_TRIP_BEFORE_INSERT_TIME_CHECK
BEFORE INSERT ON ASSIGNED_TRIP
FOR EACH ROW
BEGIN
    DECLARE v_booking_time DATETIME;

    IF NEW.FROM_TIME IS NOT NULL THEN
        SET v_booking_time = (SELECT BOOKING_TIME FROM TRIP WHERE TRIP_ID = NEW.TRIP_ID);
        
        IF v_booking_time IS NOT NULL AND NEW.FROM_TIME <= v_booking_time THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Semantic constraint violated: FROM_TIME must be strictly after BOOKING_TIME.';
        END IF;
    END IF;
END//

CREATE TRIGGER ASSIGNED_TRIP_BEFORE_UPDATE_TIME_CHECK
BEFORE UPDATE ON ASSIGNED_TRIP
FOR EACH ROW
BEGIN
    DECLARE v_booking_time DATETIME;
    DECLARE v_to_time DATETIME;

    IF NEW.FROM_TIME IS NOT NULL THEN
        SET v_booking_time = (SELECT BOOKING_TIME FROM TRIP WHERE TRIP_ID = NEW.TRIP_ID);
        IF v_booking_time IS NOT NULL AND NEW.FROM_TIME <= v_booking_time THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Semantic constraint violated: FROM_TIME must be strictly after BOOKING_TIME.';
        END IF;
    
        SET v_to_time = (SELECT TO_TIME FROM COMPLETED_TRIP WHERE TRIP_ID = NEW.TRIP_ID);
        IF v_to_time IS NOT NULL AND NEW.FROM_TIME >= v_to_time THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Semantic constraint violated: FROM_TIME must be strictly before TO_TIME.';
        END IF;
    END IF;
END//

CREATE TRIGGER COMPLETED_TRIP_BEFORE_INSERT_TIME_CHECK
BEFORE INSERT ON COMPLETED_TRIP
FOR EACH ROW
BEGIN
    DECLARE v_from_time DATETIME;
    DECLARE v_booking_time DATETIME;

    IF NEW.TO_TIME IS NOT NULL THEN
        SET v_from_time = (SELECT FROM_TIME FROM ASSIGNED_TRIP WHERE TRIP_ID = NEW.TRIP_ID);
        IF v_from_time IS NOT NULL AND NEW.TO_TIME <= v_from_time THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Semantic constraint violated: TO_TIME must be strictly after FROM_TIME.';
        END IF;

        SET v_booking_time = (SELECT BOOKING_TIME FROM TRIP WHERE TRIP_ID = NEW.TRIP_ID);
        IF v_booking_time IS NOT NULL AND NEW.TO_TIME <= v_booking_time THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Semantic constraint violated: TO_TIME must be strictly after BOOKING_TIME.';
        END IF;
    END IF;
END//

CREATE TRIGGER COMPLETED_TRIP_BEFORE_UPDATE_TIME_CHECK
BEFORE UPDATE ON COMPLETED_TRIP
FOR EACH ROW
BEGIN
    DECLARE v_from_time DATETIME;
    DECLARE v_booking_time DATETIME;

    IF NEW.TO_TIME IS NOT NULL THEN
        SET v_from_time = (SELECT FROM_TIME FROM ASSIGNED_TRIP WHERE TRIP_ID = NEW.TRIP_ID);
        IF v_from_time IS NOT NULL AND NEW.TO_TIME <= v_from_time THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Semantic constraint violated: TO_TIME must be strictly after FROM_TIME.';
        END IF;

        SET v_booking_time = (SELECT BOOKING_TIME FROM TRIP WHERE TRIP_ID = NEW.TRIP_ID);
        IF v_booking_time IS NOT NULL AND NEW.TO_TIME <= v_booking_time THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Semantic constraint violated: TO_TIME must be strictly after BOOKING_TIME.';
        END IF;
    END IF;
END//

-- Constraint 2 & 3: Discount validity and usage limit
CREATE TRIGGER TRIP_DISCOUNT_BEFORE_INSERT
BEFORE INSERT ON TRIP_DISCOUNT
FOR EACH ROW
BEGIN
    DECLARE booking_time DATETIME;
    DECLARE valid_until DATETIME;
    DECLARE current_usage INT;
    DECLARE max_usage INT;

    SELECT BOOKING_TIME INTO booking_time FROM TRIP WHERE TRIP_ID = NEW.TRIP_ID;
    SELECT VALID_UNTIL_DATE, MAX_USAGE INTO valid_until, max_usage
    FROM DISCOUNT
    WHERE DISCOUNT_ID = NEW.DISCOUNT_ID;

    IF valid_until <= booking_time THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Semantic constraint violated: Discount expired before trip booking time.';
    END IF;

    SELECT COUNT(*) INTO current_usage FROM TRIP_DISCOUNT WHERE DISCOUNT_ID = NEW.DISCOUNT_ID;

    IF max_usage IS NOT NULL AND current_usage + 1 > max_usage THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Semantic constraint violated: Discount maximum usage limit exceeded.';
    END IF;
END//

CREATE TRIGGER TRIP_DISCOUNT_BEFORE_UPDATE
BEFORE UPDATE ON TRIP_DISCOUNT
FOR EACH ROW
BEGIN
    DECLARE booking_time DATETIME;
    DECLARE valid_until DATETIME;
    DECLARE current_usage INT;
    DECLARE max_usage INT;

    SELECT BOOKING_TIME INTO booking_time FROM TRIP WHERE TRIP_ID = NEW.TRIP_ID;
    SELECT VALID_UNTIL_DATE, MAX_USAGE INTO valid_until, max_usage
    FROM DISCOUNT
    WHERE DISCOUNT_ID = NEW.DISCOUNT_ID;

    IF valid_until <= booking_time THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Semantic constraint violated: Discount expired before trip booking time.';
    END IF;

    SELECT COUNT(*) INTO current_usage FROM TRIP_DISCOUNT WHERE DISCOUNT_ID = NEW.DISCOUNT_ID;

    IF NEW.DISCOUNT_ID = OLD.DISCOUNT_ID THEN
        IF max_usage IS NOT NULL AND current_usage > max_usage THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Semantic constraint violated: Discount maximum usage limit exceeded.';
        END IF;
    ELSE
        IF max_usage IS NOT NULL AND current_usage + 1 > max_usage THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Semantic constraint violated: Discount maximum usage limit exceeded.';
        END IF;
    END IF;
END//

CREATE TRIGGER TRIP_BEFORE_UPDATE_DISCOUNT_VALIDITY
BEFORE UPDATE ON TRIP
FOR EACH ROW
BEGIN
    DECLARE invalid_count INT;

    IF OLD.BOOKING_TIME <> NEW.BOOKING_TIME THEN
        SELECT COUNT(*) INTO invalid_count
        FROM TRIP_DISCOUNT td
        JOIN DISCOUNT d ON td.DISCOUNT_ID = d.DISCOUNT_ID
        WHERE td.TRIP_ID = NEW.TRIP_ID
          AND d.VALID_UNTIL_DATE <= NEW.BOOKING_TIME;

        IF invalid_count > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Semantic constraint violated: Trip booking time is after discount expiration.';
        END IF;
    END IF;
END//

CREATE TRIGGER DISCOUNT_BEFORE_UPDATE_USAGE_AND_VALIDITY
BEFORE UPDATE ON DISCOUNT
FOR EACH ROW
BEGIN
    DECLARE invalid_count INT;
    DECLARE applied_count INT;

    IF OLD.VALID_UNTIL_DATE <> NEW.VALID_UNTIL_DATE THEN
        SELECT COUNT(*) INTO invalid_count
        FROM TRIP_DISCOUNT td
        JOIN TRIP t ON td.TRIP_ID = t.TRIP_ID
        WHERE td.DISCOUNT_ID = NEW.DISCOUNT_ID
          AND t.BOOKING_TIME >= NEW.VALID_UNTIL_DATE;

        IF invalid_count > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Semantic constraint violated: Discount valid_until_date is earlier than a booked trip.''s booking time.';
        END IF;
    END IF;

    IF OLD.MAX_USAGE <> NEW.MAX_USAGE AND NEW.MAX_USAGE IS NOT NULL THEN
        SELECT COUNT(*) INTO applied_count FROM TRIP_DISCOUNT WHERE DISCOUNT_ID = NEW.DISCOUNT_ID;

        IF applied_count > NEW.MAX_USAGE THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Semantic constraint violated: Discount maximum usage limit is less than current usage.';
        END IF;
    END IF;
END//

-- Constraint 4: Transaction date must be no earlier than completed trip end time
CREATE TRIGGER PAYMENT_TRANSACTION_BEFORE_INSERT
BEFORE INSERT ON PAYMENT_TRANSACTION
FOR EACH ROW
BEGIN
    DECLARE trip_to_time DATETIME;

    SELECT TO_TIME INTO trip_to_time FROM COMPLETED_TRIP WHERE TRIP_ID = NEW.TRIP_ID;

    IF NEW.DATE_TIME < trip_to_time THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Semantic constraint violated: Payment date is before trip completion time.';
    END IF;
END//

CREATE TRIGGER PAYMENT_TRANSACTION_BEFORE_UPDATE
BEFORE UPDATE ON PAYMENT_TRANSACTION
FOR EACH ROW
BEGIN
    DECLARE trip_to_time DATETIME;

    SELECT TO_TIME INTO trip_to_time FROM COMPLETED_TRIP WHERE TRIP_ID = NEW.TRIP_ID;

    IF NEW.DATE_TIME < trip_to_time THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Semantic constraint violated: Payment date is before trip completion time.';
    END IF;
END//

CREATE TRIGGER COMPLETED_TRIP_BEFORE_UPDATE_PAYMENT_TIME
BEFORE UPDATE ON COMPLETED_TRIP
FOR EACH ROW
BEGIN
    DECLARE invalid_payment_count INT;

    IF OLD.TO_TIME <> NEW.TO_TIME THEN
        SELECT COUNT(*) INTO invalid_payment_count
        FROM PAYMENT_TRANSACTION
        WHERE TRIP_ID = NEW.TRIP_ID
          AND DATE_TIME < NEW.TO_TIME;

        IF invalid_payment_count > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Semantic constraint violated: Completed trip end time is after an existing payment transaction date.';
        END IF;
    END IF;
END//

-- Constraint 5: Exact Fare Payment Matching
CREATE TRIGGER FARE_PAYMENT_MATCHING
BEFORE INSERT ON PAYMENT_TRANSACTION
FOR EACH ROW
BEGIN
    DECLARE v_final_price INT;
    DECLARE error VARCHAR(1000);

    SELECT FINAL_PRICE INTO v_final_price
    FROM TRIP
    WHERE TRIP_ID = NEW.TRIP_ID;

    -- SET error = CONCAT('Semantic constraint violated: PAYMENT_AMOUNT must equal FINAL_PRICE.', NEW.TRIP_ID);
    -- IF NEW.PAYMENT_AMOUNT <> v_final_price THEN
    --     SIGNAL SQLSTATE '45000'
    --     SET MESSAGE_TEXT = error;
    --     -- SET MESSAGE_TEXT = 'Semantic constraint violated: PAYMENT_AMOUNT must equal FINAL_PRICE.';
    -- END IF;
    SET NEW.PAYMENT_AMOUNT = v_final_price;
END//


-- Constraint 6: Single Ongoing Trip per Driver

CREATE TRIGGER DRIVER_ACTIVE_TRIP_CHECK
BEFORE UPDATE ON TRIP
FOR EACH ROW
BEGIN
    DECLARE driver_id INT;
    DECLARE other_active_trip INT DEFAULT 0;
    IF NEW.STATUS IN ('ASSIGNED', 'DRIVER_ARRIVED', 'ONGOING') THEN

        SELECT DRIVER_ID INTO driver_id FROM ASSIGNED_TRIP
        WHERE TRIP_ID = NEW.TRIP_ID
        LIMIT 1;

        IF driver_id IS NOT NULL THEN
            SELECT COUNT(*) INTO other_active_trip FROM TRIP
            JOIN ASSIGNED_TRIP ON TRIP.TRIP_ID = ASSIGNED_TRIP.TRIP_ID
            WHERE ASSIGNED_TRIP.DRIVER_ID = driver_id
                AND TRIP.STATUS IN ('ASSIGNED', 'DRIVER_ARRIVED', 'ONGOING')
                AND TRIP.TRIP_ID <> NEW.TRIP_ID;

            IF other_active_trip > 0 THEN
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'The driver already has at least one another active trip. Active trips are trips of status: ASSIGNED, DRIVER_ASSIGNED, ONGOING';
            END IF;
        END IF;
    END IF;
END//

CREATE TRIGGER DRIVER_ONGOING_CHECK
BEFORE INSERT ON ASSIGNED_TRIP
FOR EACH ROW
BEGIN
    DECLARE v_ongoing_count INT;
    DECLARE error VARCHAR(1000);

    SELECT COUNT(*) INTO v_ongoing_count
    FROM ASSIGNED_TRIP assign
    JOIN TRIP trip ON assign.TRIP_ID = trip.TRIP_ID
    WHERE assign.DRIVER_ID = NEW.DRIVER_ID
        AND trip.STATUS = 'ONGOING';

    SET error = CONCAT('Semantic constraint violated: Driver ', NEW.DRIVER_ID,' already has an ongoing trip');
    IF v_ongoing_count >= 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = error;
    END IF;
END//

-- Constraint 7: Single Ongoing Trip per Passenger
CREATE TRIGGER PASSENGER_ACTIVE_TRIP_CHECK
BEFORE UPDATE ON TRIP
FOR EACH ROW
BEGIN
    DECLARE other_active_trip INT DEFAULT 0;
    IF NEW.STATUS = 'ONGOING' THEN
        SELECT COUNT(*) INTO other_active_trip FROM TRIP
        WHERE TRIP.PASSENGER_ID = NEW.PASSENGER_ID
            AND TRIP.STATUS = 'ONGOING'
            AND TRIP.TRIP_ID <> NEW.TRIP_ID;

        IF other_active_trip > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'The passenger already has at least one another active trip. Active trips are trips of status: ONGOING';
        end if;
    END IF;
END//

CREATE TRIGGER PASSENGER_ONGOING_CHECK
BEFORE INSERT ON ASSIGNED_TRIP
FOR EACH ROW
BEGIN
    DECLARE v_ongoing_count INT;
    DECLARE v_passenger_id INT;
    DECLARE error VARCHAR(1000);

    SELECT PASSENGER_ID INTO v_passenger_id
    FROM TRIP
    WHERE TRIP_ID = NEW.TRIP_ID;

    SELECT COUNT(*) INTO v_ongoing_count
    FROM ASSIGNED_TRIP at
    JOIN TRIP t ON at.TRIP_ID = t.TRIP_ID
    WHERE t.PASSENGER_ID = v_passenger_id
      AND t.STATUS = 'ONGOING';


    SET error = CONCAT(
    'Semantic constraint violated: Passenger ', v_passenger_id,
    ' already in an ongoing trip');
    IF v_ongoing_count >= 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = error;
    END IF;
END//

-- constraint 8: Valid license registration
CREATE TRIGGER VALID_LICENSE_VEHICLE_REGISTRATION
BEFORE INSERT ON VEHICLE_CATEGORIZATION
FOR EACH ROW
BEGIN
	DECLARE v_type ENUM('Bike', 'Car');
    DECLARE d_license VARCHAR(2);
    
    SELECT TYPE INTO v_type
    FROM TRANSPORT_MODE
    WHERE MODE_ID = NEW.MODE_ID;
    
    SELECT D.DRIVER_LICENSE_GRADE INTO d_license
    FROM DRIVER D
    JOIN VEHICLE V ON D.ACCOUNT_ID = V.REGISTRANT_ID
    WHERE V.VEHICLE_ID = NEW.VEHICLE_ID;
    
    IF v_type = 'Bike' AND d_license NOT IN ('A1', 'A2') THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Semantic constraint violated: Driver license must be A1 or A2 to register a bike';
    END IF;
    
    IF v_type = 'Car' AND d_license NOT IN ('B2', 'C', 'D', 'E', 'F') THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Semantic constraint violated: Driver license must be B2, C, D, E, or F to register a car';
    END IF;
END//

-- constraint 9: Trip status ordering
CREATE TRIGGER TRIP_STATUS_ORDER
BEFORE UPDATE ON TRIP
FOR EACH ROW
BEGIN
    DECLARE old_status ENUM(
        'PENDING',
        'ASSIGNED',
        'DRIVER_ARRIVED',
        'ONGOING',
        'COMPLETED',
        'CANCELLED'
    );

    DECLARE is_valid BOOL;

    SET old_status = OLD.STATUS;
    SET is_valid = TRUE;

    CASE
        WHEN old_status = 'PENDING' THEN
            IF NEW.STATUS <> 'ASSIGNED' AND NEW.STATUS <> 'CANCELLED' THEN
                SET is_valid = FALSE;
            END IF;
        WHEN old_status = 'ASSIGNED' THEN
            IF NEW.STATUS <> 'DRIVER_ARRIVED' THEN
                SET is_valid = FALSE;
            END IF;
        WHEN old_status = 'DRIVER_ARRIVED' THEN
            IF NEW.STATUS <> 'ONGOING' THEN
                SET is_valid = FALSE;
            END IF;
        WHEN old_status = 'ONGOING' THEN
            IF NEW.STATUS <> 'COMPLETED' THEN
                SET is_valid = FALSE;
            END IF;
        WHEN old_status = 'COMPLETED' THEN
            -- prevent changing to anything other than completed
            IF NEW.STATUS <> 'COMPLETED' THEN
                SET is_valid = FALSE;
            END IF;
        ELSE
            IF NEW.STATUS <> 'CANCELLED' THEN
                SET is_valid = FALSE;
            END IF;
    END CASE;

    IF is_valid = FALSE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Semantic constraint violated: Trip status is out of order';
    END IF;
END//

-- constraint 10: Matching vehicle and service types
CREATE TRIGGER TRIP_ASSIGNMENT_MODE
BEFORE INSERT ON ASSIGNED_TRIP
FOR EACH ROW
BEGIN
	DECLARE trip_mode_id INT;
    DECLARE current_vehicle_id INT;
    
    SELECT MODE_ID into trip_mode_id
    FROM TRIP
    WHERE TRIP_ID = NEW.TRIP_ID;
    
    SELECT VEHICLE_ID into current_vehicle_id
    FROM VEHICLE 
    WHERE USING_DRIVER_ID = NEW.DRIVER_ID;
    
    IF current_vehicle_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Semantic constraint violated: The assigned driver is offline (not currently using any vehicle)';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 
        FROM VEHICLE_CATEGORIZATION 
        WHERE VEHICLE_ID = current_vehicle_id AND MODE_ID = trip_mode_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Semantic constraint violated: The driver''s current vehicle does not match requested trip mode';
    END IF;
    
END//

-- Constraint 11: Final price

CREATE PROCEDURE REFRESH_TRIP_FINAL_PRICE(IN p_trip_id INT)
BEGIN
    DECLARE v_total_p DECIMAL(10,4);
    DECLARE v_total_a INT;
    DECLARE v_est_price INT;
    DECLARE v_coins INT;

    -- Fetch base trip data
    SELECT ESTIMATED_PRICE, USED_GRABCOINS 
    INTO v_est_price, v_coins 
    FROM TRIP WHERE TRIP_ID = p_trip_id;

    -- Aggregate all linked discounts (Handling the M:N relationship)
    SELECT COALESCE(SUM(PERCENTAGE_DISCOUNT), 0), COALESCE(SUM(AMOUNT_DISCOUNT), 0)
    INTO v_total_p, v_total_a
    FROM TRIP_DISCOUNT TD
    JOIN DISCOUNT D ON TD.DISCOUNT_ID = D.DISCOUNT_ID
    WHERE TD.TRIP_ID = p_trip_id;

    -- Apply the Formula: Max( Estimated * (1 - ΣPi) - ΣAj - (Coins/150 * 5000), 0 )
    UPDATE TRIP 
    SET FINAL_PRICE = ROUND(GREATEST ((v_est_price * (1 - v_total_p)) - v_total_a - ((v_coins / 150.0) * 5000), 0) / 1000) * 1000
    WHERE TRIP_ID = p_trip_id;
END//

CREATE TRIGGER INITIALIZE_TRIP_PRICE
BEFORE INSERT ON TRIP
FOR EACH ROW
BEGIN
    -- Initial price calculation (Estimated - GrabCoins)
    SET NEW.FINAL_PRICE = ROUND(GREATEST(NEW.ESTIMATED_PRICE - ((NEW.USED_GRABCOINS / 150.0) * 5000), 0) / 1000) * 1000;
END//

CREATE TRIGGER RECALCULATE_PRICE_ON_DISCOUNT_LINK
AFTER INSERT ON TRIP_DISCOUNT
FOR EACH ROW
BEGIN
    -- Call the combined function to update the stored derived attribute
    CALL REFRESH_TRIP_FINAL_PRICE(NEW.TRIP_ID);
END//

-- Constraint 12: Grab coin accumulation

CREATE TRIGGER GRABCOIN_ACCUMULATION
BEFORE INSERT ON COMPLETED_TRIP
FOR EACH ROW 
BEGIN
    DECLARE trip_final_price INT;

    SELECT FINAL_PRICE 
    INTO trip_final_price 
    FROM TRIP 
    WHERE TRIP_ID = NEW.TRIP_ID;

    SET NEW.OBTAINED_GRABCOIN = trip_final_price DIV 2000;
END//

CREATE TRIGGER GRABCOIN_UPDATE
BEFORE UPDATE ON TRIP
FOR EACH ROW
BEGIN
    DECLARE trip_final_price INT;

    SELECT FINAL_PRICE 
    INTO trip_final_price 
    FROM TRIP 
    WHERE TRIP_ID = NEW.TRIP_ID;

    -- SET NEW.OBTAINED_GRABCOIN = trip_final_price DIV 2000;
    UPDATE COMPLETED_TRIP
    SET OBTAINED_GRABCOIN = trip_final_price DIV 2000
    WHERE TRIP_ID = NEW.TRIP_ID;
END//

-- Constraint xx: Vehicle capacity and transport mode compatibility
CREATE TRIGGER VALIDATE_VEHICLE_MODE_CATEGORIZATION
BEFORE INSERT ON VEHICLE_CATEGORIZATION
FOR EACH ROW
BEGIN
    DECLARE v_capacity INT;
    DECLARE m_type ENUM('Bike', 'Car');
    DECLARE m_seat_capacity INT;

    -- Get vehicle capacity
    SELECT CAPACITY INTO v_capacity
    FROM VEHICLE
    WHERE VEHICLE_ID = NEW.VEHICLE_ID;

    -- Get transport mode details
    SELECT TYPE, SEAT_CAPACITY INTO m_type, m_seat_capacity
    FROM TRANSPORT_MODE
    WHERE MODE_ID = NEW.MODE_ID;

    -- Check for valid combinations of vehicle capacity and transport mode
    IF NOT ((v_capacity = 2 AND m_type = 'Bike' AND m_seat_capacity = 1) OR (v_capacity = 5 AND m_type = 'Car' AND m_seat_capacity = 4) OR (v_capacity = 7 AND m_type = 'Car' AND m_seat_capacity = 6)) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Semantic constraint violated: The vehicle capacity does not match the transport mode type or seat capacity.';
    END IF;
END//

DELIMITER ;