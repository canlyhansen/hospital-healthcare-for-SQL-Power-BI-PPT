USE PP2;
SELECT * FROM health;

-- Data type check
ALTER TABLE health MODIFY `Date of Admission` DATE;
ALTER TABLE health MODIFY `Discharge Date` DATE;

-- Feature relevance check
-- Skipping this, because information might be shown in visualization, but personally I would delete Name and Room Number

-- Missing value check
SELECT * FROM health 
WHERE Age = '' 
   OR Gender = '' 
   OR `Blood Type` = '' 
   OR `Medical Condition` = '' 
   OR `Insurance Provider` = '' 
   OR `Billing Amount` = ''
   OR `Date of Admission` IS NULL 
   OR `Discharge Date` IS NULL;

-- Duplicate value check
SELECT Name, COUNT(*) AS occurrences
FROM health
GROUP BY Name
HAVING COUNT(*) > 1;

-- Delete duplicates
-- WITH RowNumbered AS (
-- SELECT
-- 	Name,
-- 	ROW_NUMBER() OVER(PARTITION BY Name ORDER BY (SELECT NULL))
--     AS row_num
-- FROM health
-- )
-- DELETE FROM RowNumbered
-- WHERE row_num > 1;

-- Adding a unique ID column and pkan to use self-join to keep the row with the same Name and delete any subsequent rows that share that same Name:
-- ALTER TABLE health ADD COLUMN id INT AUTO_INCREMENT PRIMARY KEY FIRST;
-- DELETE t1 FROM health t1
-- JOIN health t2 
--     ON t1.Name = t2.Name 
--     AND t1.id > t2.id;
-- Temporary Table approach
-- CREATE TEMPORARY TABLE keep_ids AS
-- SELECT MIN(id) AS id
-- FROM health
-- GROUP BY Name;
-- DELETE FROM health 
-- WHERE id NOT IN (SELECT id FROM keep_ids);
-- DROP TEMPORARY TABLE keep_ids;

-- ANALYSIS

-- 1. Seeing the correlation between Age Group and Medical Condition
WITH CategorizedHealth AS (
    SELECT 
        *,
        CASE 
            WHEN Age BETWEEN 0 AND 17 THEN '0-17 (Pediatric)'
            WHEN Age BETWEEN 18 AND 30 THEN '18-30 (Young Adult)'
            WHEN Age BETWEEN 31 AND 50 THEN '31-50 (Adult)'
            WHEN Age BETWEEN 51 AND 65 THEN '51-65 (Middle-Aged)'
            ELSE '65+ (Senior)'
        END AS Age_Group
    FROM health
)
SELECT 
    Age_Group,
    `Medical Condition`,
    COUNT(*) AS Patients_With_Condition,
    SUM(COUNT(*)) OVER (PARTITION BY Age_Group) AS Total_Age_Group_Patients
FROM CategorizedHealth
GROUP BY Age_Group, `Medical Condition`
ORDER BY Age_Group, Patients_With_Condition DESC;

-- 2. Seeing the correlation between Gender and Medical Condition
SELECT
    Gender,
    COALESCE(`Medical Condition`, '--- Total for this Gender ---') AS `Medical Condition`,
    COUNT(*) AS Total_Patients
FROM health
GROUP BY Gender, `Medical Condition` WITH ROLLUP;

-- 3. Seeing the correlation between Blood type and Medical Condition
SELECT
	`Blood Type`,
    `Medical Condition`,
    COUNT(*) AS Total_Patients,
	SUM(COUNT(*)) OVER (PARTITION BY `Blood Type`) AS Total_Blood_Type_Patients
FROM health
GROUP BY `Blood Type`, `Medical Condition`
ORDER BY `Blood Type`, Total_Patients DESC;

-- 4. Seeing the correlation between Insurance Provider and Medical Condition
SELECT
	`Insurance Provider`,
    `Medical Condition`,
    COUNT(*) AS Total_Patients,
	SUM(COUNT(*)) OVER (PARTITION BY `Insurance Provider`) AS Total_Insurance_Provider_Patients
FROM health
GROUP BY `Insurance Provider`, `Medical Condition`
ORDER BY `Insurance Provider`, Total_Patients DESC;

-- 5. Seeing the sum of Billing Amount for every Medical Condition
SELECT
    `Medical Condition`,
    ROUND(SUM(`Billing Amount`), 0) AS Total_Billing_Amount
FROM health
GROUP BY `Medical Condition` WITH ROLLUP;

-- 6. Seeing the Billing Amount for every Insurance Provider
SELECT
    `Insurance Provider`,
    ROUND(SUM(`Billing Amount`), 0) AS Total_Billing_Amount
FROM health
GROUP BY `Insurance Provider` WITH ROLLUP;

-- 7. Seeing the length of stay for every medical condition
SELECT
    AVG(DATEDIFF(`Discharge Date`, `Date of Admission`)) AS Length_of_stay,
    `Medical Condition`
FROM health
GROUP BY `Medical Condition`
ORDER BY Length_of_stay DESC;





