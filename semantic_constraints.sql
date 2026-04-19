-- Active: 1775061495821@@127.0.0.1@3306@grab
USE GRAB;
DELIMITER //

-- constriant 8
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
	
-- constraint 9
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

-- constraint 10
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

-- Constraint 12: Grab coin check
CREATE TRIGGER GRABCOIN_ACCUMULATION
BEFORE INSERT ON COMPLETED_TRIP
FOR EACH ROW 
BEGIN
    DECLARE trip_final_price INT;
    DECLARE obtained_coins INT;
    DECLARE T_ID INT;
    SET T_ID = NEW.TRIP_ID;
    SELECT FINAL_PRICE INTO trip_final_price FROM TRIP WHERE TRIP.TRIP_ID = T_ID;

    SET obtained_coins = trip_final_price DIV 2000;

    -- UPDATE COMPLETED_TRIP
    -- SET OBTAINED_GRABCOIN = trip_final_price
    -- WHERE TRIP_ID = T_ID;

    IF NEW.OBTAINED_GRABCOIN <> obtained_coins THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Semantic constraint violated: Incorrect calculation for Obtained_Grabcoin';
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

    SET error = CONCAT('Semantic constraint violated: PAYMENT_AMOUNT must equal FINAL_PRICE.', NEW.TRIP_ID);
    IF NEW.PAYMENT_AMOUNT <> v_final_price THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = error;
        -- SET MESSAGE_TEXT = 'Semantic constraint violated: PAYMENT_AMOUNT must equal FINAL_PRICE.';
    END IF;
END//

-- Constraint 6: Single Ongoing Trip per Driver
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
DELIMITER ;

-- Constraint 9: Final price
DELIMITER //

CREATE TRIGGER VALIDATE_FINAL_PRICE_CALCULATION
BEFORE INSERT ON TRIP
FOR EACH ROW
BEGIN
    DECLARE total_percentage DECIMAL(10, 4) DEFAULT 0.0;
    DECLARE total_amount_discount INT DEFAULT 0;
    DECLARE grabcoin_discount_value DECIMAL(10, 2) DEFAULT 0.0;
    DECLARE calculated_final_price INT DEFAULT 0;
    
    SELECT 
        COALESCE(SUM(D.PERCENTAGE_DISCOUNT), 0), 
        COALESCE(SUM(D.AMOUNT_DISCOUNT), 0)
    INTO total_percentage, total_amount_discount
    FROM TRIP_DISCOUNT TD
    JOIN DISCOUNT D ON TD.DISCOUNT_ID = D.DISCOUNT_ID
    WHERE TD.TRIP_ID = NEW.TRIP_ID;

    SET grabcoin_discount_value = (NEW.USED_GRABCOINS / 150.0) * 5000;

    SET calculated_final_price = ROUND(
        NEW.ESTIMATED_PRICE * (1 - total_percentage) 
        - total_amount_discount 
        - grabcoin_discount_value
    );
    IF calculated_final_price < 0 THEN
        SET calculated_final_price = 0;
    END IF;

    IF NEW.FINAL_PRICE <> calculated_final_price THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Semantic constraint violated: Final_price calculation is incorrect';
    END IF;
END //

DELIMITER ;