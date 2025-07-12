--- checking for null values----
SELECT *
FROM PatientRecords
WHERE 
    Name IS NULL OR
    Age IS NULL OR
    Gender IS NULL OR
    BloodType IS NULL OR
    MedicalCondition IS NULL OR
    DateOfAdmission IS NULL OR
    Doctor IS NULL OR
    Hospital IS NULL OR
    InsuranceProvider IS NULL OR
    BillingAmount IS NULL OR
    RoomNumber IS NULL OR
    AdmissionType IS NULL OR
    DischargeDate IS NULL OR
    Medication IS NULL OR
    TestResults IS NULL;
--- no row is empty acrosss all the columns---
--Normalise names so each name begins with a capital letter
UPDATE PatientRecords
SET Name = INITCAP(Name)
---------------------------PROBLEM QUESTIONS---------------------------
--Basic Retrieval Questions---
--List all patients admitted to the hospital.
SELECT COUNT(DISTINCT Name) FROM PatientRecords
--Retrieve names and ages of all male patients.
SELECT Gender, COUNT(DISTINCT Name) AS unique_patients
FROM PatientRecords
GROUP BY Gender;

---------Retrieve names and ages of all female patients.
SELECT 
	COUNT(DISTINCT Name) AS FemalePatientCount
FROM 
	PatientRecords
WHERE 
	gender = 'Female';

--Aggregate & Statistical Questions-------
---What is the total billing amount for all patients?
SELECT 
	SUM(billingamount) 
FROM 
	PatientRecords
---How many patients are currently admitted?
SELECT 
	COUNT(*)
FROM 	
	PatientRecords
WHERE 
	dischargedate IS NULL
---- What is the average age of patients per blood type?
SELECT 
	ROUND(AVG(Age), 0) as Avg_age, bloodtype
FROM 
	PatientRecords
GROUP BY 
	bloodtype
ORDER BY 
	Avg_age
--- Hospital Operations Questions--------
---Which doctor has the highest number of patients?
SELECT 
	doctor, 
	COUNT(*) AS PatientCount
FROM 
	PatientRecords
GROUP BY 
	doctor
ORDER BY 
	PatientCount DESC
LIMIT 1
----List all distinct medical conditions.
SELECT 
	distinct(medicalcondition)from PatientRecords
Group BY 
	medicalcondition
--Number of patients per admission type?
SELECT 
	COUNT(*), 
	Admissiontype
FROM 
	PatientRecords
GROUP BY 
	Admissiontype
ORDER BY 
	COUNT(*) DESC
--🧾 Billing & Insurance Questions
---Which insurance provider has covered the most patients?
SELECT
	COUNT(*), 
	InsuranceProvider
FROM 
	PatientRecords
GROUP BY 
	InsuranceProvider
ORDER BY
	COUNT DESC
----List patients without insurance provider information.
SELECT 
	Name
FROM 
	PatientRecords
WHERE 
	InsuranceProvider IS NULL --- null all the patients are insured
---🏨 Room & Admission Management
-------What is the room number of the patient with the highest bill?
SELECT Name,
	roomnumber, 
	MAX(billingamount) 
FROM 
	PatientRecords 
GROUP BY 
	Name,roomnumber
ORDER BY 
	MAX DESC
LIMIT 1
------Which room has had the most patients over time?
SELECT 
	COUNT(*) as roomcount,
	roomnumber
FROM 
	PatientRecords
GROUP BY 
	roomnumber
ORDER BY 
	roomcount DESC
LIMIT 20
---List the number of times a room has been used
SELECT  
    p1.RoomNumber,
    COUNT(*) AS Timeused
FROM 
    PatientRecords p1
INNER JOIN 
    PatientRecords p2 
    ON p1.RoomNumber = p2.RoomNumber
    AND p1.Name < p2.Name
GROUP BY 
    p1.RoomNumber
ORDER BY 
	Timeused DESC
LIMIT 10;
---Which rooms had the most patients admitted through emergency?
SELECT 
	COUNT(*),
	roomnumber
FROM PatientRecords
WHERE Admissiontype = 'Emergency'
GROUP BY 
	roomnumber
ORDER BY
	COUNT DESC
LIMIT 5
----Which admission type results in the longest hospital stay?
SELECT 
    admissiontype,
    ROUND(AVG(dischargedate - dateofadmission),0) AS stay_duration
FROM 
    PatientRecords
GROUP BY admissiontype
ORDER BY 
    stay_duration DESC
--What is the distribution of room usage per admission type?
SELECT 
    admissiontype,
    roomnumber,
    COUNT(*) AS usage_count
FROM 
    PatientRecords
GROUP BY 
    admissiontype, roomnumber
ORDER BY 
    admissiontype, usage_count DESC;
---- Medical and Diagnostic Insights
-------List patients prescribed a medication containing 'Ibuprofen'.
select * from PatientRecords
-- CTE to get the total patients per blood type
WITH BloodTypeTotals AS (
    SELECT 
        BloodType,
        COUNT(*) AS TotalPatients
    FROM 
        PatientRecords
    GROUP BY 
        BloodType
),

-- CTE to count each medical condition per blood type
ConditionCounts AS (
    SELECT 
        BloodType,
        MedicalCondition,
        COUNT(*) AS ConditionCount
    FROM 
        PatientRecords
    GROUP BY 
        BloodType, MedicalCondition
),

-- Joining the two cte's and calculate percentages
ConditionPercents AS (
    SELECT 
        cc.MedicalCondition,
        cc.BloodType,
        cc.ConditionCount,
        bt.TotalPatients,
        ROUND((cc.ConditionCount * 100.0) / bt.TotalPatients, 2) AS Percentage
    FROM 
        ConditionCounts cc
    JOIN 
        BloodTypeTotals bt ON cc.BloodType = bt.BloodType
)
--highest percentage per medical condition
SELECT 
    MedicalCondition,
    BloodType,
    ConditionCount,
    TotalPatients,
    Percentage
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY MedicalCondition ORDER BY Percentage DESC) AS rn
    FROM ConditionPercents
) ranked
WHERE rn = 1
ORDER BY Percentage DESC;
-------What is the average age of patients for each medical condition?
SELECT
	ROUND(AVG(Age),0) as avgage,
	medicalcondition
FROM 
	PatientRecords
GROUP BY 
	medicalcondition
ORDER BY 
	avgage DESC;
----How many male vs female patients are diagnosed with hypertension/diabetes/etc.?
SELECT 
	gender,
	medicalcondition,
	COUNT(DISTINCT Name) AS gendercount
FROM PatientRecords
GROUP BY gender, medicalcondition
ORDER BY gendercount DESC;

----Diagnosis Trends
------Most diverse range of medical conditions handled by a doctor ?
WITH Doctorconditionscounts AS (
    SELECT 
        DISTINCT(Doctor),
        COUNT(DISTINCT MedicalCondition) AS Uniqueconditions
    FROM 
        PatientRecords
    GROUP BY 
        Doctor
)
SELECT 
    DISTINCT(Doctor),
    Uniqueconditions
FROM 
    Doctorconditionscounts
ORDER BY 
    Uniqueconditions DESC ----- 6
-------What is the distribution of medical conditions across different hospitals?
WITH hospitalcount AS (
    SELECT 
        Hospital,
        COUNT(DISTINCT MedicalCondition) AS uniqueconditions
    FROM 
        PatientRecords
    GROUP BY
        Hospital
)
SELECT 
    Hospital,
    uniqueconditions
FROM 
    hospitalcount
ORDER BY 
    uniqueconditions DESC;
----💉 Medication & Treatment Patterns
---What are the most frequently prescribed medications for each medical condition?
WITH RankedMedications AS (
   SELECT 
   		COUNT(*) as countingprescribtion,
		medicalcondition,
		medication,
		ROW_NUMBER() OVER(PARTITION BY medicalcondition ORDER BY COUNT(*) DESC) AS rn
	FROM PatientRecords
	GROUP BY 
		medicalcondition,
		medication
)
SELECT 
	medicalcondition,
	medication,
	countingprescribtion
FROM RankedMedications
WHERE rn = 1
------Lab/Test Analysis
---What are the most common test result outcomes for diabetic patients?
SELECT 
	COUNT(*),
	testresults
FROM 
	PatientRecords
WHERE 
	medicalcondition = 'Diabetes'
GROUP BY 
	testresults
ORDER BY 
	COUNT DESC
---Hospital & Resource Utilization
------Which admission types lead to higher billing amounts.
SELECT 
    admissiontype,
    ROUND(SUM(billingamount),0) AS sumbilling
FROM 
    PatientRecords
GROUP BY 
    admissiontype
ORDER BY 
    sumbilling DESC;
---TIME-BASED QUERIES
---Count of people who spent less than 7 days in the hospital
SELECT 
    COUNT(*) AS short_stay_count
FROM 
    PatientRecords
WHERE 
    (dischargedate - dateofadmission) < 7;