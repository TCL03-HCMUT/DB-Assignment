-- Active: 1775981929461@@localhost@3306@GRAB
-- 2.3: HAVING, WHERE, ORDER BY, JOIN + aggregate
-- Dates of trips in nearest month, and its count
SELECT 
    DATE_FORMAT(C.TO_TIME, '%Y-%m') AS Month, 
    COUNT(T.TRIP_ID) AS Total_Completed_Trips
FROM TRIP T
JOIN COMPLETED_TRIP C ON T.TRIP_ID = C.TRIP_ID
WHERE 
    C.TO_TIME >= DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH) 
GROUP BY Month
HAVING 
    Total_Completed_Trips > 0
ORDER BY Month ASC;