CREATE DATABASE HEALTHCARE_ANALYSIS;

USE HEALTHCARE_ANALYSIS;

SET sql_safe_updates=0;

SELECT * FROM appointment_table;

SELECT * FROM billing_table;

SELECT * FROM doctor_table ;

SELECT * FROM medical_procedure_table;

SELECT * FROM patient_table;

 
 
-- How many unique patients have scheduled appointments, and how many have never scheduled one?

SELECT
(SELECT count(DISTINCT patientID) FROM appointment_table) AS scheduled_appointment,
(SELECT count(*) FROM patient_table WHERE patientID NOT IN (SELECT DISTINCT patientID FROM appointment_table)) AS NA_appointments ;


-- Retrieve the full name and email of patients who have undergone the most medical procedures.

SELECT P.patientID, P.firstname, P.lastname, P.email, COUNT(M.procedureID) AS procedure_count
FROM patient_table P
JOIN appointment_table A ON P.patientID = A.patientID
JOIN medical_procedure_table M ON A.appointmentID = M.appointmentID
GROUP BY P.patientID, P.firstname, P.lastname, P.email
ORDER BY procedure_count DESC
LIMIT 1;


-- Identify patients who have multiple unpaid bills by checking for duplicate PatientID in the Billing dataset.

SELECT P.patientID, P.firstname, P.lastname, count(*)  AS unpaid_bills
FROM   patient_table P
LEFT JOIN  billing_table B
ON P.patientID = B.PatientID
WHERE B.amount IS NULL 
GROUP BY P.patientID, P.firstname, P.lastname
ORDER BY P.firstname;


-- Find the top 5 doctors with the highest number of appointments scheduled.

SELECT D.doctorname, count(A.AppointmentID) AS Highest_No_of_Appointments
FROM doctor_table D 
join appointment_table A 
on D.DoctorID = A.DoctorID
group by D.doctorname
order by Highest_No_of_Appointments desc
limit 5 ; 


-- List all appointments where a patient has consulted more than one doctor on the same day.

SELECT A1.AppointmentID, A1.patientID, A1.Date, A1.DoctorID AS Doctor1, A2.DoctorID AS Doctor2 
FROM appointment_table A1
JOIN appointment_table A2
ON A1.patientID = A2.patientID 
AND A1.Date = A2.Date
AND A1.DoctorID <> A2.DoctorID 
ORDER BY  A1.patientID, A1.Date;
 
 
-- Determine which specialization has the highest patient visit count based on appointment records.

SELECT D.specialization, count(A.AppointmentID) AS count_of_Visits
FROM doctor_table D
JOIN appointment_table A 
ON D.DoctorID = A.DoctorID 
GROUP BY D.specialization
ORDER BY count_of_Visits DESC;



-- Calculate the total revenue generated from all patient bills, categorized by month and identify the "highest revenue-generating month."


SELECT monthname(A.Date) AS Month, month(A.Date) AS Month_Number, sum(B.amount) AS Total_Revenue
FROM appointment_table A 
JOIN billing_table B 
ON A.patientID = B.patientID
GROUP BY Month, Month_Number 
ORDER BY  Total_Revenue DESC
LIMIT 1;


-- Identify the top 3 highest billed items in the Billing table and count how many times each has been billed.


SELECT Items, SUM(Amount) AS Total_Amount, COUNT(*) AS Billing_count
FROM billing_table
GROUP BY Items
ORDER BY Total_Amount DESC
LIMIT 3;



-- Generate a monthly revenue trend from medical billings to analyze financial performance.


SELECT  year(A.Date) AS Year, monthname(A.Date) AS Month, month(A.Date) AS Month_Number, sum(B.amount) AS Total_Revenue
FROM appointment_table A 
JOIN billing_table B 
ON A.patientID = B.patientID
WHERE A.Date IS NOT NULL
GROUP BY Month, Month_Number, Year
ORDER BY  Year,Month_Number ;


-- Identify patients who have frequently missed their appointments by checking duplicate PatientID values without corresponding billing records.

SELECT A.patientID , count(A.appointmentID) AS Missed_appointment FROM appointment_table A 
LEFT JOIN billing_table B
ON A.patientID = B.patientID
WHERE B.InvoiceID IS NULL
GROUP BY A.patientID
HAVING count(A.appointmentID) > 1
ORDER BY Missed_appointment DESC;



-- Retrieve a list of all patients who have undergone a procedure but have no billing record for it.

SELECT distinct P.patientID, P.firstname, P.lastname  
FROM patient_table P 
JOIN appointment_table A 
ON P.patientID = A.patientID 
JOIN medical_procedure_table M 
ON A.appointmentID = M.appointmentID 
LEFT JOIN billing_table B 
ON P.patientID = B.patientID
WHERE B.InvoiceID IS NULL;



-- Identify the doctor who has performed the highest number of unique medical procedures.

SELECT D.doctorname, M.procedurename, count(DISTINCT M.procedureID) AS unique_Procedures
FROM doctor_table D 
JOIN appointment_table A 
ON A.DoctorID = D.DoctorID 
JOIN medical_procedure_table M 
ON M.AppointmentID = A.AppointmentID
GROUP BY D.doctorname, M.procedurename 
ORDER BY unique_Procedures DESC
LIMIT 1;


-- Generate a summary report showing the total number of procedures performed by each doctor along with their total billed amount.

WITH ProcedureCount AS (
    SELECT A.DoctorID, COUNT(M.ProcedureID) AS TotalProcedures
    FROM appointment_table A
    JOIN medical_procedure_table M  ON A.appointmentID = M.appointmentID
    GROUP BY A.DoctorID
),
BilledAmount AS (
    SELECT A.DoctorID, SUM(B.amount) AS TotalBilledAmount
    FROM appointment_table A
    LEFT JOIN billing_table B ON A.PatientID = B.PatientID
    GROUP BY A.DoctorID
)
SELECT D.DoctorID, D.DoctorName, 
       PC.TotalProcedures AS TotalProcedures, 
       BA.TotalBilledAmount AS TotalBilledAmount
FROM doctor_table  D 
LEFT JOIN ProcedureCount PC ON D.DoctorID = PC.DoctorID
LEFT JOIN BilledAmount BA  ON D.DoctorID = BA.DoctorID
ORDER BY TotalProcedures DESC;





