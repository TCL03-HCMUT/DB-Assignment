INSERT INTO user_account
(NAME, PHONE_NUMBER, EMAIL, ACCOUNT_PASSWORD, GENDER, AVATAR) VALUES
('Đặng Quí', '0474213546', 'dangqui@example.com', 'dangqui', 'Male', NULL),
('Vương Anh Tuấn', '036988860', 'vuonganhtuan@example.com', 'vuonganhtuan', 'Male', NULL),
('Lạc Toàn Quân', '0119094843', 'lactoanquan@example.com', 'lactoanquan', 'Male', NULL),
('Chu Minh Thức', '0276301993', 'chuminhthuc@example.com', 'chuminhthuc', 'Male', NULL),
('Phan Ngọc Giác', '0257991897', 'phanngocgiac@example.com', 'phanngocgiac', 'Male', NULL),
('Vương Kim', '0880550902', 'vuongkim@example.com', 'vuongkim', 'Female', NULL),
('Trương Thị Vy', '0393012273', 'truongthivy@example.com', 'truongthivy', 'Female', NULL),
('Ngô Tham', '0438911414', 'ngotham@example.com', 'ngotham', 'Male', NULL),
('Đào Bình Viện', '0478471276', 'daobinhvien@example.com', 'daobinhvien', 'Male', NULL),
('Trương Trúc Nam', '0772619483', 'truongtrucnam@example.com', 'truongtrucnam', 'Female', NULL);

INSERT INTO user_notification
(TITLE, CONTENT,TIME) VALUES
('Deal sốc năm mới','Từ 1/1/2026 đến ngày 3/1/2026, giảm 30% cho cuốc đi xe ôtô.','2026-01-01 09:30:00'),
('Khao trọn ngày cá tháng tư','Trong ngày 1/4/2026, giảm 15% nếu thanh toán bằng thẻ tín dụng OCB','2026-04-01 09:00:00'),
('Ưu đãi từ BIDV','Từ hôm nay đến ngày 31/12/2026, BIDV có ưu đãi dành cho chủ thẻ BIDV, giảm 10.000 cho các cuốc >= 30.000, giảm 30.000 cho cuốc từ 90.000','2026-02-02 09:30:00'),
('Liên kết ví Momo, trao deal liền tay!','Đến 1/6/2026, liên kết ví Momo để nhận ngay ưu đãi giảm 20% cho cuốc đi xe ôtô.','2026-02-13 09:30:00'),
('Ưu đãi đặc biệt từ Vietcombank','Từ hôm nay đến ngày 1/5/2026, Vietcombank có ưu đãi dành cho chủ thẻ Vietcombank, giảm 15.000 cho các cuốc >= 45.000, giảm 50.000 cho cuốc từ 150.000','2026-02-14 09:30:00');

INSERT INTO TRANSPORT_MODE
(TYPE, SEAT_CAPACITY, SERVICE_LEVEL) VALUES
('Bike', 1, 'Standard'),
('Bike', 1, 'Saver'),
('Car', 4, 'Standard'),
('Car', 4, 'Saver'),
('Car', 4, 'Electric'),
('Car', 6, 'Standard');

INSERT INTO DISCOUNT
(MAX_USAGE,VALID_UNTIL_DATE,DISCOUNT_TYPE,PERCENTAGE_DISCOUNT,AMOUNT_DISCOUNT) VALUES
(5, '2026-01-01 23:59:59', 'Percentage', 0.30, NULL),
(5, '2026-04-01 23:59:59', 'Percentage', 0.15, NULL),
(5, '2026-12-31 23:59:59', 'Amount', NULL, 10000),
(5, '2026-12-31 23:59:59', 'Amount', NULL, 30000),
(5, '2026-06-01 23:59:59', 'Percentage', 0.20, NULL),
(5, '2026-05-01 23:59:59', 'Amount', NULL, 15000),
(5, '2026-05-01 23:59:59', 'Amount', NULL, 50000);

INSERT INTO ACCOUNT_COMMUNICATION
(ACCOUNT_ID, COMMUNICATION_TYPE) VALUES
(1, 'Email'),(1, 'SMS'),(1, 'Push Notification'),
(2, 'Email'),(2, 'SMS'),(2, 'Push Notification'),
(3, 'Email'),(3, 'SMS'),(3, 'Push Notification'),
(4, 'Email'),(4, 'SMS'),(4, 'Push Notification'),
(5, 'Email'),(5, 'SMS'),(5, 'Push Notification'),
(6, 'Email'),(6, 'SMS'),(6, 'Push Notification'),
(7, 'Email'),(7, 'SMS'),(7, 'Push Notification'),
(8, 'Email'),(8, 'SMS'),(8, 'Push Notification'),
(9, 'Email'),(9, 'SMS'),(9, 'Push Notification'),
(10, 'Email'),(10, 'SMS'),(10, 'Push Notification');

INSERT INTO PASSENGER
(ACCOUNT_ID, GRABCOINS) VALUES
(1,2002),
(2,1975),
(3,100),
(4,91),
(5,7);

INSERT INTO DRIVER
(ACCOUNT_ID, DRIVER_LICENSE_GRADE, CURRENT_BALANCE) VALUES
(6,'A1',1000000),
(7,'A1',1500000),
(8,'B2',750000),
(9,'A1',600000),
(10,'A2',2000000);

INSERT INTO REFERRAL
(DRIVER_ID, REFERRER_ID) VALUES
(6,10),
(7,6),
(8,6),
(9,6),
(10,6);

INSERT INTO bank_account
(BANK_NAME,ACCOUNT_NUMBER,DRIVER_ID) VALUES
('BIDV','179784021',6),
('BIDV','513661723',7),
('BIDV','551768767',8),
('Vietcombank','802767',9),
('Vietcombank','370610',10);

INSERT INTO SAVED_LOCATION
(PASSENGER_ID, SUGGESTIVE_NAME, ADDRESS, COORDINATE_Y, COORDINATE_X) VALUES
(1,'BK cs1','268 Đ. Lý Thường Kiệt, Phường Diên Hồng, Hồ Chí Minh',10.772011, 106.657882),
(2,'Cổng BK cs2','Khu phố Tân Lập, Phường Đông Hòa, TP.HCM',10.880458, 106.805564),
(3,'VP tuyển sinh quốc tế','Kiosk 98, 142A Tô Hiến Thành, Phường Diên Hồng, TP.HCM',10.773533, 106.661055),
(3,'Khoa CSE','268 Đ. Lý Thường Kiệt, Phường Diên Hồng, Hồ Chí Minh',10.773500, 106.660683),
(4,'Circle K cs1','268 Đ. Lý Thường Kiệt, Phường Diên Hồng, Hồ Chí Minh',10.772807, 106.658603),
(5,'Sân tập đá banh Phú thọ','1 Đ. Lữ Gia, Phường 15, Phú Thọ, Hồ Chí Minh',10.769086, 106.658159);

INSERT INTO VEHICLE
(PLATE_NUMBER,MAKE,MODEL,COLOR,CAPACITY,REGISTRANT_ID,USING_DRIVER_ID) VALUES
('50B-292.20','Honda','Lead 125','Vàng',1,6,6),            #driver số 6 loại 1 (xe máy standard)
('59CHX-228.03','Honda','SH Mode 125','Xanh dương',1,7,7), #driver số 7 loại 2 (xe máy saver)
('56CNN-856.86','Honda','Civic','Trắng',6,8,8),            #driver số 8 loại 6 (xe oto 6 chỗ standard)
('54AWJ-295.1','Honda','Wave RSX','Đen',1,9,9),            #driver số 9 loại 1 (xe máy standard)
('53MGC-597.04','Honda','CBR300R','Đỏ',1,10,10);           #driver số 10 loại 1 (xe máy standard)

INSERT INTO VEHICLE_CATEGORIZATION
(VEHICLE_ID, MODE_ID) VALUES
(1,1),
(2,2),
(3,6),
(4,1),
(5,1);

INSERT INTO TRIP
(TRIP_ID,
FROM_ADDRESS, FROM_Y, FROM_X,
TO_ADDRESS, TO_Y, TO_X,
BOOKING_TIME, STATUS, PICKUP_INFO, ESTIMATED_PRICE, USED_GRABCOINS, FINAL_PRICE,
PASSENGER_ID, MODE_ID, BOOKING_TYPE, REQUEST_TIME) VALUES
(1,
 'Sân bay Tân Sơn Nhất, Phường 2, Tân Bình, HCM', 10.818927, 106.665444,
 '268 Đ. Lý Thường Kiệt, Phường Diên Hồng, HCM', 10.772011, 106.657882,
 '2026-01-15 08:10:00', 'COMPLETED', 'Em đứng ở gate A13 ga Quốc nội, Anh Đặng Quí ơi', 42000, 0, 42000,
 1, 6, 'Standard', NULL),

(2,
 'Khu phố Tân Lập, Phường Đông Hòa, TP.HCM', 10.880458, 106.805564,
 'Bến xe Miền Đông, Bình Thạnh, HCM', 10.814300, 106.714500,
 '2026-01-20 14:30:00', 'COMPLETED', NULL, 100000, 0, 100000,
 3, 1, 'Standard', NULL),

(3,
 '1 Đ. Lữ Gia, Phường 15, Phú Thọ, HCM', 10.769086, 106.658159,
 'Chợ Bến Thành, Phường Bến Thành, Quận 1, HCM', 10.772300, 106.698200,
 '2026-02-03 09:45:00', 'COMPLETED', 'Em đứng ở cổng chính, gần sân câu lông ngoài trời, Anh Giác ơi', 35000, 0, 35000,
 5, 1, 'Standard', NULL),

(4,
 '268 Đ. Lý Thường Kiệt, Phường Diên Hồng, HCM', 10.772011, 106.657882,
 'Landmark 81, Vinhomes Central Park, Bình Thạnh, HCM', 10.794700, 106.722100,
 '2026-02-14 17:00:00', 'COMPLETED', 'Em đang ở cổng 2 ạ, anh Thức ơi', 55000, 0, 55000,
 4, 2, 'Standard', NULL),

(5,
 '268 Đ. Lý Thường Kiệt, Phường Diên Hồng, HCM', 10.772807, 106.658603,
 '10-12 Đinh Tiên Hoàng, Sài gòn', 10.785892, 106.702513,
 '2026-02-20 07:30:00', 'COMPLETED', NULL, 40000, 0, 40000,
 2, 2, 'Standard', NULL),

(6,
 '1 Đ. Lữ Gia, Phường 15, Phú Thọ, HCM', 10.769086, 106.658159,
 'Phố đi bộ Nguyễn Huệ, Quận 1, HCM', 10.773600, 106.703800,
 '2026-03-01 20:00:00', 'COMPLETED', NULL, 40000, 0, 40000,
 1, 1, 'Standard', NULL),

(7,
 'Chợ Bến Thành, Phường Bến Thành, Quận 1, HCM', 10.772300, 106.698200,
 'Sân bay Tân Sơn Nhất, Phường 2, Tân Bình, HCM', 10.818927, 106.665444,
 '2026-03-10 05:50:00', 'COMPLETED', NULL, 60000, 0, 60000,
 1, 1, 'Standard', NULL),

-- Scheduled trips (Đặt vào ngày 1/4/2024 để cho 3 ngày 1-3/4 dùng) (người passenger nữ Vương Kim đặt xe máy)
(8,
 '268 Đ. Lý Thường Kiệt, Phường Diên Hồng, HCM', 10.772807, 106.658603,
 '153 Nguyễn Chí Thanh, Street, An Đông, Hồ Chí Minh, Vietnam',10.759362, 106.666394,
 '2024-04-01 14:00:00', 'ONGOING', NULL, 90000, 0, 90000,
 5, 1, 'Scheduled', '2024-04-01 07:00:00'),

(9,
 '268 Đ. Lý Thường Kiệt, Phường Diên Hồng, HCM', 10.772807, 106.658603,
 '153 Nguyễn Chí Thanh, Street, An Đông, Hồ Chí Minh, Vietnam',10.759362, 106.666394,
 '2024-04-02 14:00:00', 'ONGOING', NULL, 60000, 0, 60000,
 5, 1, 'Scheduled', '2024-04-01 07:05:00'),

 (10,
 '268 Đ. Lý Thường Kiệt, Phường Diên Hồng, HCM', 10.772807, 106.658603,
 '153 Nguyễn Chí Thanh, Street, An Đông, Hồ Chí Minh, Vietnam',10.759362, 106.666394,
 '2024-04-03 14:00:00', 'ONGOING', NULL, 130000, 0, 130000,
 5, 1, 'Scheduled', '2024-04-01 07:11:00'),

-- 6 standard trips bị CANCELLED (lý do: sai địa điểm đến)
(11,
'268 Đ. Lý Thường Kiệt, Phường Diên Hồng, HCM', 10.772807, 106.658603,
'86 Đ. Số 23, Tân Mỹ, Hồ Chí Minh 70000, Vietnam',10.714079, 106.728499,
'2019-03-20 14:00:00', 'CANCELLED', NULL, 60000, 0, 60000,
4, 1, 'Standard', NULL
),
(12,
'268 Đ. Lý Thường Kiệt, Phường Diên Hồng, HCM', 10.772807, 106.658603,
'86 Đ. Số 23, Tân Mỹ, Hồ Chí Minh 70000, Vietnam',10.714079, 106.728499,
'2019-03-05 14:00:00', 'CANCELLED', NULL, 60000, 0, 60000,
4, 1, 'Standard', NULL
),
(13,
'268 Đ. Lý Thường Kiệt, Phường Diên Hồng, HCM', 10.772807, 106.658603,
'86 Đ. Số 23, Tân Mỹ, Hồ Chí Minh 70000, Vietnam',10.714079, 106.728499,
'2019-02-02 14:00:00', 'CANCELLED', NULL, 60000, 0, 60000,
4, 1, 'Standard', NULL
),
(14,
'268 Đ. Lý Thường Kiệt, Phường Diên Hồng, HCM', 10.772807, 106.658603,
'86 Đ. Số 23, Tân Mỹ, Hồ Chí Minh 70000, Vietnam',10.714079, 106.728499,
'2019-01-19 14:00:00', 'CANCELLED', NULL, 60000, 0, 60000,
4, 1, 'Standard', NULL
),
(15,
'268 Đ. Lý Thường Kiệt, Phường Diên Hồng, HCM', 10.772807, 106.658603,
'86 Đ. Số 23, Tân Mỹ, Hồ Chí Minh 70000, Vietnam',10.714079, 106.728499,
'2019-09-19 14:00:00', 'CANCELLED', NULL, 60000, 0, 60000,
4, 1, 'Standard', NULL
),
(16,
'268 Đ. Lý Thường Kiệt, Phường Diên Hồng, HCM', 10.772807, 106.658603,
'86 Đ. Số 23, Tân Mỹ, Hồ Chí Minh 70000, Vietnam',10.714079, 106.728499,
'2019-12-01 14:00:00', 'CANCELLED', NULL, 60000, 0, 60000,
4, 1, 'Standard', NULL
);

INSERT INTO ASSIGNED_TRIP 
(TRIP_ID, FROM_TIME, DRIVER_ID) VALUES
(1,'2026-01-15 08:15:00',8),
(2,'2026-01-20 14:35:00',9),
(3,'2026-02-03 09:50:00',9),
(4,'2026-02-14 17:05:00',7),
(5,'2026-02-20 07:35:00',7),
(6,'2026-03-01 20:05:00',6),
(7,'2026-03-10 05:55:00',6),
(8,'2024-04-01 14:02:00',10),
(9,'2024-04-01 14:01:00',10),
(10,'2024-04-01 14:07:00',10);

INSERT INTO COMPLETED_TRIP
(TRIP_ID, TO_TIME, OBTAINED_GRABCOIN, RATING_STARS, FEEDBACK, DRIVER_PAY) VALUES
(1,'2026-01-15 08:30:00',0,1,'Chuyển đi 1 sao',42000),
(2,'2026-01-20 15:03:00',0,2,'Chuyển đi 2 sao',100000),
(3,'2026-02-03 10:04:00',0,3,'Chuyển đi 3 sao',35000),
(4,'2026-02-14 17:29:00',0,4,'Chuyển đi 4 sao',55000),
(5,'2026-02-20 07:55:00',0,5,'Chuyển đi 5 sao',40000),
(6,'2026-03-01 20:22:00',0,5,'Chuyển đi 5 sao',40000),
(7,'2026-03-10 06:11:00',0,5,'Chuyển đi 5 sao',60000);

INSERT INTO PAYMENT_METHOD
(PAYMENT_METHOD_ID, TYPE, ACCOUNT_IDENTIFIER, PASSENGER_ID) VALUES
(1,'Card','505354',1),
(2,'Card','259284',2),
(3,'Card','595454',3),
(4,'Card','380503',4),
(5,'Card','260890',5),
(6,'E-Wallet','461510',5);

INSERT INTO PAYMENT_TRANSACTION
(TRANSACTION_ID, PAYMENT_AMOUNT, DATE_TIME, PAID_BY_CASH, TIP, TRIP_ID, PAYMENT_METHOD_ID) VALUES
-- Trip 1: Passenger 1 (Đặng Quí)
(1, 42000, '2026-01-15 08:30:00', FALSE,0,  1, 1),

-- Trip 2: Passenger 3 (Lạc Toàn Quân)
(2, 100000, '2026-01-20 15:03:00', FALSE,0, 2, 2),

-- Trip 3: Passenger 5 (Phan Ngọc Giác)
(3, 35000, '2026-02-03 10:04:00', FALSE,0,  3, 5),

-- Trip 4: Passenger 4 (Chu Minh Thức)
(4, 55000, '2026-02-14 17:29:00', FALSE, 0, 4, 4),

-- Trip 5: Passenger 2 (Vương Anh Tuấn)
(5, 40000, '2026-02-20 07:55:00', FALSE, 0, 5, 2),

-- Trip 6: Passenger 1 (Đặng Quí)
(6, 40000, '2026-03-01 20:22:00', FALSE, 0, 6, 1),

-- Trip 7: Passenger 1 (Đặng Quí)
(7, 60000, '2026-03-10 06:11:00', FALSE, 0, 7, 1);  

INSERT INTO DISCOUNT
(MAX_USAGE,VALID_UNTIL_DATE,DISCOUNT_TYPE,PERCENTAGE_DISCOUNT,AMOUNT_DISCOUNT) VALUES
(5, '2026-01-01 23:59:59', 'Percentage', 0.30, NULL),
(5, '2026-04-01 23:59:59', 'Percentage', 0.15, NULL),
(5, '2026-12-31 23:59:59', 'Amount', NULL, 10000),
(5, '2026-12-31 23:59:59', 'Amount', NULL, 30000),
(5, '2026-06-01 23:59:59', 'Percentage', 0.20, NULL),
(5, '2026-05-01 23:59:59', 'Amount', NULL, 15000),
(5, '2026-05-01 23:59:59', 'Amount', NULL, 50000);