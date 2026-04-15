-- This file is used for procedures/ triggers/ functions... testing.
-- Note that some may produce errors for demonstration. You would like to run only the part you want to test.

USE GRAB;

-- Test procedure 1
--  Xem xe của Tài xế 8
CALL GET_DRIVER_VEHICLE_LIST(8, NULL, NULL, 'CAPACITY_DESC');

--  Lọc riêng xe máy của Tài xế 8, xếp theo tên hãng (Make) A-Z
CALL GET_DRIVER_VEHICLE_LIST(8, 'Bike', NULL, 'MAKE');

--  Lọc car của Tài xế 8, capacity >= 4
CALL GET_DRIVER_VEHICLE_LIST(8, 'Car', 4, 'CAPACITY_ASC');
