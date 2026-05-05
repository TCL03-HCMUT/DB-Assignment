-- TODO: create demonstrations for the presentation

-- Test Derived attribute: Driver_star
USE GRAB;

-- 1. Check the initial driver star rating for Driver 8 (Currently has Trip 1 and 4, both 5 stars -> Average: 5.00)
SELECT ACCOUNT_ID, DRIVER_STAR FROM DRIVER WHERE ACCOUNT_ID = 8;

-- 2. Test UPDATE Trigger: Change the rating of Trip 4 from 5 to 3
UPDATE COMPLETED_TRIP SET RATING_STARS = 3 WHERE TRIP_ID = 4;

-- Check star rating after update (Expected: (5 + 3) / 2 = 4.00)
SELECT ACCOUNT_ID, DRIVER_STAR FROM DRIVER WHERE ACCOUNT_ID = 8;

-- 3. Test DELETE Trigger: Remove the completed trip completely
DELETE FROM COMPLETED_TRIP WHERE TRIP_ID = 1;

-- Check star rating after deletion (Expected: 3.00, as only Trip 4 with 3 stars remains)
SELECT ACCOUNT_ID, DRIVER_STAR FROM DRIVER WHERE ACCOUNT_ID = 8;

-- 4. Test INSERT Trigger: Re-insert Trip 1 with a 1-star rating
INSERT INTO
    COMPLETED_TRIP (
        TRIP_ID,
        TO_TIME,
        OBTAINED_GRABCOIN,
        RATING_STARS,
        FEEDBACK,
        DRIVER_PAY
    )
VALUES (
        1,
        '2026-01-03 08:30:00',
        21,
        1,
        'Very bad ride',
        42000
    );

-- Check the driver star rating after insertion (Expected: (3 + 1) / 2 = 2.00)
SELECT ACCOUNT_ID, DRIVER_STAR FROM DRIVER WHERE ACCOUNT_ID = 8;




-- Test Procedure: GET_PASSENGER_MONTHLY_REPORT
-- Assuming current date is May 5, 2026.
-- The procedure calculates the cut-off date by subtracting months from LAST_DAY(CURRENT_DATE) (May 31, 2026).

-- ---------------------------------------------------------
-- TEST CASE 1: Passenger 1 (Activity in Jan and Mar 2026)
-- Passenger 1 has completed trips on 2026-01-03, 2026-03-01, and 2026-03-10.
-- ---------------------------------------------------------
SELECT '--- TEST 1: Passenger 1 (4-month lookback) ---' AS Scenario;

-- Looking back 4 months from May 31 gives a cut-off of Jan 31.
-- Expected: Returns ONLY the March trips. The Jan 3 trip is filtered out.
CALL GET_PASSENGER_MONTHLY_REPORT (1, 4);

-- ---------------------------------------------------------
-- TEST CASE 2: Passenger 2 (Single trip in Feb 2026)
-- Passenger 2 has one completed trip on 2026-02-20.
-- ---------------------------------------------------------
SELECT '--- TEST 2: Passenger 2 (Short-range vs Long-range) ---' AS Scenario;

-- Looking back 1 month from May 31 gives a cut-off of April 30.
SELECT 'Results for 1-month lookback (Expected: Empty):' AS Sub_Test;
CALL GET_PASSENGER_MONTHLY_REPORT (2, 1);

-- Looking back 4 months from May 31 gives a cut-off of Jan 31.
SELECT 'Results for 4-month lookback (Expected: 1 trip in Feb):' AS Sub_Test;
CALL GET_PASSENGER_MONTHLY_REPORT (2, 4);



-- Test Function: GRAB_COIN_BONUS
-- Calculates end-of-month loyalty bonus coins for a passenger.


-- Test case 1: Passenger 3, April 2026.
-- Has one completed trip, paid cashless, with a 5-star rating.
-- Expected bonus: 5 (cashless) + 10 (rating) = 15.
SELECT GRAB_COIN_BONUS (3, 4, 2026) AS 'Passenger 3, Apr 2026 Bonus';

-- Test case 2: Passenger with no completed trips in the given month.
-- Expected: 0
SELECT GRAB_COIN_BONUS (1, 2, 2026) AS 'Passenger 1, Feb 2026 Bonus';







-- Test Function: CALCULATE_DRIVER_BONUS_FEE
-- Calculates a monthly bonus for drivers based on completed trips.

-- Test case 1: Driver 6, March 2026.
-- Has two completed trips (Trip 6, Trip 7) with payment.
-- Both have 5-star ratings (+2000 each) and transport mode seat capacity < 6. Base bonus (+5000 each).
-- Expected bonus: (5000 + 2000) * 2 = 14000.
SELECT CALCULATE_DRIVER_BONUS_FEE (6, 3, 2026) AS 'Driver 6, Mar 2026 Bonus';

-- Test case 2: Driver 8, February 2026.
-- Has one completed trip (Trip 4). 
-- Its rating was updated to 3 stars earlier in this file (+0). Transport mode seat capacity >= 6 (+1500). Base bonus (+5000).
-- Expected bonus: 5000 + 0 + 1500 = 6500.
SELECT CALCULATE_DRIVER_BONUS_FEE (8, 2, 2026) AS 'Driver 8, Feb 2026 Bonus';

-- Test case 3: Driver 8, January 2026.
-- Has one completed trip (Trip 1). But its payment transaction was deleted earlier (due to CASCADE DELETE).
-- Re-inserted trip doesn't have a payment transaction.
-- Expected bonus: 0.
SELECT CALCULATE_DRIVER_BONUS_FEE (8, 1, 2026) AS 'Driver 8, Jan 2026 Bonus (No Payment)';

-- Test case 4: Driver 10, January 2026.
-- No completed trips in this month.
-- Expected bonus: 0.
SELECT CALCULATE_DRIVER_BONUS_FEE (10, 1, 2026) AS 'Driver 10, Jan 2026 Bonus (No Trips)';
-- CONSTRAINT 8: Valid License Vehicle Registration
-- Test that drivers can only register vehicle types compatible with their license

-- Setup: Display vehicles of each driver
SELECT 
    D.ACCOUNT_ID as driver_id,
    D.DRIVER_LICENSE_GRADE as license,
    V.VEHICLE_ID,
    V.CAPACITY
FROM DRIVER D
LEFT JOIN VEHICLE V ON D.ACCOUNT_ID = V.REGISTRANT_ID
ORDER BY D.ACCOUNT_ID, V.VEHICLE_ID;

-- Test Case 8.1: Driver with A1 license trying to register a Bike (should PASS)
-- Driver 6 has A1 license, Mode 1 is Bike Standard (SEAT_CAPACITY = 1)
-- Vehicle 4 of Driver 6 is a bike with CAPACITY = 2
-- SHOULD SUCCEED
CALL ADD_VEHICLE_CATEGORIZATION(4, 1);

-- Test Case 8.2: Driver with B2 license trying to register a Car (should PASS)
-- Driver 8 has B2 license, Mode 6 is Car 6-seater Standard (SEAT_CAPACITY = 6)
-- Vehicle 3 is a car with CAPACITY = 7
-- SHOULD SUCCEED
CALL ADD_VEHICLE_CATEGORIZATION(3, 6);

-- Test Case 8.3: Driver with A1 license trying to register a Car (should FAIL)
-- Driver 1 has A1 license, trying to add Mode 3 (Car) to Vehicle 1 (Bike with CAPACITY = 2)
-- This should violate Constraint 8 - A1 license can only drive bikes
-- Expected error: "Semantic constraint violated: Driver license must be B2, C, D, E, or F to register a car"
CALL ADD_VEHICLE_CATEGORIZATION(1, 3);


-- CONSTRAINT 10: Matching Vehicle and Service Types
-- Test that assigned drivers' vehicles match the requested trip mode

-- Setup: Verify current assignments and vehicle modes
-- Looking at data:
-- Trip 1: MODE_ID = 6 (Car 6-seat), assigned to Driver 8 using Vehicle 2 (Xpander, has MODE 6) - MATCH ✓
-- Trip 2: MODE_ID = 1 (Bike), assigned to Driver 9 using Vehicle 8 (CBR500R, has MODE 1) - MATCH ✓
-- Trip 3: MODE_ID = 1 (Bike), assigned to Driver 9 using Vehicle 8 (CBR500R, has MODE 1) - MATCH ✓
-- Trip 4: MODE_ID = 6 (Car 6-seat), assigned to Driver 8 using Vehicle 2 (Xpander, has MODE 6) - MATCH ✓

-- Test Case 10.1: Verify valid assignments exist (PASS)
-- Check assignments that should match
SELECT 
    T.TRIP_ID,
    T.MODE_ID,
    AT.DRIVER_ID,
    V.VEHICLE_ID,
    V.USING_DRIVER_ID,
    GROUP_CONCAT(VC.MODE_ID) as vehicle_modes
FROM TRIP T
LEFT JOIN ASSIGNED_TRIP AT ON T.TRIP_ID = AT.TRIP_ID
LEFT JOIN VEHICLE V ON V.VEHICLE_ID = (
    SELECT VEHICLE_ID FROM VEHICLE WHERE USING_DRIVER_ID = AT.DRIVER_ID LIMIT 1
)
LEFT JOIN VEHICLE_CATEGORIZATION VC ON V.VEHICLE_ID = VC.VEHICLE_ID
WHERE T.TRIP_ID IN (1, 2, 3, 4)
GROUP BY T.TRIP_ID, V.VEHICLE_ID
ORDER BY T.TRIP_ID;

-- Test Case 10.2: Create a new trip that would violate constraint if assigned to wrong driver
-- Create a new bike trip (MODE_ID = 1)
INSERT INTO TRIP
(FROM_ADDRESS, FROM_Y, FROM_X, TO_ADDRESS, TO_Y, TO_X, BOOKING_TIME, STATUS, 
 PICKUP_INFO, ESTIMATED_PRICE, USED_GRABCOINS, FINAL_PRICE, PASSENGER_ID, MODE_ID, BOOKING_TYPE, REQUEST_TIME)
VALUES
('268 Đ. Lý Thường Kiệt', 10.772807, 106.658603,
 '86 Đ. Số 23, Tân Mỹ, HCM', 10.714079, 106.728499,
 '2026-03-20 10:00:00', 'PENDING', NULL, 50000, 0, 50000,
 2, 1, 'Standard', NULL);

-- Now try to assign this BIKE trip (MODE_ID = 1) to Driver 8 who is using Vehicle 2 (Xpander, CAR with MODE 6)
-- This SHOULD FAIL - vehicle doesn't support the trip mode
-- Vehicle 2 modes: Car 6-seat (MODE 6 only)
-- Trip needs MODE 1 (Bike Standard) but Vehicle 2 doesn't have Bike modes
INSERT INTO ASSIGNED_TRIP (TRIP_ID, FROM_TIME, DRIVER_ID)
VALUES (18, '2026-03-20 10:05:00', 8);


-- Test getting paginated list of driver's vehicles with various filters
-- Data summary:
-- Driver 6: owns vehicles 4, 5 (bikes with CAPACITY=2)
-- Driver 7: owns vehicles 6, 7 (bikes with CAPACITY=2)
-- Driver 8: owns vehicles 1, 2, 3 (cars with CAPACITY=7)
-- Driver 9: owns vehicles 8, 9 (bikes with CAPACITY=2)
-- Driver 10: owns vehicle 10 (bike with CAPACITY=2)


-- Test Case 1.1: Get vehicles filtered by capacity = 7 and service = 'Standard' for Driver 8
-- Expected: Returns only vehicles with capacity 7 and standard service (all 3 cars: vehicles 1, 2, 3)
CALL GET_DRIVER_VEHICLE_LIST(
    8,              -- p_driver_id: Driver 8
    'Standard',     -- p_service_level: filter by Standard service
    7,              -- p_capacity: capacity must be exactly 7
    'CAPACITY_DESC',-- p_sort_option
    NULL,           -- p_plate_number: no filter
    10,             -- p_limit
    0               -- p_offset
);


-- Test Case 1.2: Get vehicles filtered by plate number pattern for Driver 8
-- Expected: Returns vehicles matching the plate pattern (1 vehicle)
CALL GET_DRIVER_VEHICLE_LIST(
    8,              -- p_driver_id: Driver 8
    NULL,           -- p_service_level: no filter
    NULL,           -- p_capacity: no filter
    'CAPACITY_DESC',-- p_sort_option
    'E',            -- p_plate_number: search for plates containing 'E' (52E-556, 57A-987 contains E)
    10,             -- p_limit
    0               -- p_offset
);

-- Test Case 1.3: Get vehicles sorted by capacity ascending for Driver 6
-- Expected: Returns vehicles 4, 5 (both have capacity 2) sorted by capacity
CALL GET_DRIVER_VEHICLE_LIST(
    6,              -- p_driver_id: Driver 6 (bike owner)
    NULL,           -- p_service_level: no filter
    NULL,           -- p_capacity: no filter
    'CAPACITY_ASC', -- p_sort_option: sort by capacity ascending
    NULL,           -- p_plate_number: no filter
    10,             -- p_limit
    0               -- p_offset
);

-- Test Case 1.6: Get vehicles sorted by MAKE for Driver 8
-- Expected: Returns all 3 vehicles of Driver 8 sorted by vehicle make (Ford, Mitsubishi, Toyota)
CALL GET_DRIVER_VEHICLE_LIST(
    8,              -- p_driver_id: Driver 8
    NULL,           -- p_service_level: no filter
    NULL,           -- p_capacity: no filter
    'MAKE',         -- p_sort_option: sort by make
    NULL,           -- p_plate_number: no filter
    10,             -- p_limit
    0               -- p_offset
);

-- insert vehicle, switch vehicle, delete vehicle test 
SET @registrant_id = 8;
SET @plate_number = '50W-776.74';
SET @make = 'Toyota';
SET @model = 'Camry';
SET @color = 'Tim';
SET @capacity = 5;
SET @mode_list = '3';
SET @using_driver_id = NULL;

CALL INSERT_VEHICLE(
    @plate_number,
    @make,
    @model,
    @color,
    @capacity,
    @registrant_id,
    @using_driver_id,
    @mode_list,
    @new_vehicle_id
);

SELECT @new_vehicle_id;

CALL SWITCH_VEHICLE(
    @registrant_id,
     @new_vehicle_id
     );

CALL DELETE_VEHICLE(
@new_vehicle_id
     );