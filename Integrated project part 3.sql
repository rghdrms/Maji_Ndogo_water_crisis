-- Task 1
-- Uderstanding the database structure
-- Ensuring that all relations assigned well
-- Converting the relationship between the visits and water_quality tables from one-to-many to one-to-one

-- Task 2 Integrating the Auditor's report
-- Adding the auditor report to our database
DROP TABLE IF EXISTS auditor_report;
CREATE TABLE auditor_report (
				location_id VARCHAR(32),
				type_of_water_source VARCHAR(64),
				true_water_source_score int DEFAULT NULL,
				statements VARCHAR(255)
				);
                
/*
We need to tackle a couple of questions here.
1. Is there a difference in the scores?
2. If so, are there patterns?
*/
-- 1. Is there a difference in the scores?
-- First, grab the location_id and true_water_source_score columns from auditor_report

SELECT
	location_id,
    true_water_source_score
FROM
	auditor_report;

-- Then join the visits table to the auditor_report table
SELECT
	auditor_report.location_id AS audit_location,
    true_water_source_score,
    record_id,
    visits.location_id AS visit_location
FROM
	auditor_report
JOIN 
	visits
ON
	visits.location_id = auditor_report.location_id;


-/* 
we have the record_id for each location, our next step is to retrieve the corresponding scores from the water_quality table.
We are particularly interested in the subjective_quality_score.
To do this, we'll JOIN the visits table and the water_quality table, using the
record_id as the connecting key.
*/

SELECT
	auditor_report.location_id,
    auditor_report.true_water_source_score AS auditor_score,
    visits.record_id,
    water_quality.subjective_quality_score AS employee_score
FROM
	auditor_report
JOIN 
	visits
ON
	visits.location_id = auditor_report.location_id
JOIN
	water_quality
ON
	visits.record_id = water_quality.record_id;

/* 
check if the auditor's and exployees' scores agree. There are many ways to do it. 
We can have a WHERE clause and check if surveyor_score = auditor_score,
 or we can subtract the two scores and check if the result is 0.
 */

SELECT
	auditor_report.location_id,
    auditor_report.true_water_source_score AS auditor_score,
    visits.record_id,
    water_quality.subjective_quality_score AS employee_score
FROM
	auditor_report
JOIN 
	visits
ON
	visits.location_id = auditor_report.location_id
JOIN
	water_quality
ON
	visits.record_id = water_quality.record_id
WHERE 
	auditor_report.true_water_source_score = water_quality.subjective_quality_score;

/* Some of the locations were visited multiple times, so these records are duplicated here.
To fix it, we set visits.visit_count = 1 in the WHERE clause */

SELECT
	auditor_report.location_id,
    auditor_report.true_water_source_score AS auditor_score,
    visits.record_id,
    water_quality.subjective_quality_score AS employee_score
FROM
	auditor_report
JOIN 
	visits
ON
	visits.location_id = auditor_report.location_id
JOIN
	water_quality
ON
	visits.record_id = water_quality.record_id
WHERE 
	auditor_report.true_water_source_score = water_quality.subjective_quality_score
AND
	visits.visit_count = 1;
/* 
What does this mean considering the auditor visited 1620 sites?
1518/1620 = 94% of the records the auditor checked were correct
this is an excellent result
But that means that 102 records are incorrect
*/
-- Check for incorrect records
SELECT
	auditor_report.location_id,
    auditor_report.true_water_source_score AS auditor_score,
    visits.record_id,
    water_quality.subjective_quality_score AS employee_score
FROM
	auditor_report
JOIN 
	visits
ON
	visits.location_id = auditor_report.location_id
JOIN
	water_quality
ON
	visits.record_id = water_quality.record_id
WHERE 
	auditor_report.true_water_source_score != water_quality.subjective_quality_score
AND
	visits.visit_count = 1;
    
/* 
we need to make sure those results are still valid, now we know some of them are incorrect. 
We didn't use the scores that much, but we relied a lot on the type_of_water_source, 
so let's check if there are any errors there.
*/

SELECT
	auditor_report.location_id,
    auditor_report.true_water_source_score AS auditor_score,
    visits.record_id,
    water_quality.subjective_quality_score AS employee_score,
    water_source.type_of_water_source AS survey_source,
    auditor_report.type_of_water_source AS audit_source
FROM
	auditor_report
JOIN 
	visits
ON
	visits.location_id = auditor_report.location_id
JOIN
	water_quality
ON
	visits.record_id = water_quality.record_id
JOIN
	water_source
ON
	visits.source_id = water_source.source_id
WHERE 
	auditor_report.true_water_source_score = water_quality.subjective_quality_score
AND
	visits.visit_count = 1;
-- the types of sources look the same! So even though the scores are wrong,
-- the integrity of the type_of_water_source data we analysed last time is not affected.
-- remove the columns and JOIN statement for water_sources again from the above query

-- Task 3 Linking records to employees

/*
let's look at where these errors may have come from. At some of the locations, employees assigned scores incorrectly, 
and those records ended up in this results set.
there are two reasons this can happen.
1. These workers are all humans and make mistakes so this is expected.
2. Unfortunately, the alternative is that someone assigned scores incorrectly on purpose!
--> Join the employee_name column from employee table, we can see which employees made these incorrect records.
*/

SELECT
	auditor_report.location_id,
    visits.record_id,
    employee_name,
    auditor_report.true_water_source_score AS auditor_score,
    water_quality.subjective_quality_score AS employee_score
FROM
	auditor_report
JOIN 
	visits
ON
	visits.location_id = auditor_report.location_id
JOIN
	water_quality
ON
	visits.record_id = water_quality.record_id
JOIN
	employee
ON
	visits.assigned_employee_id = employee.assigned_employee_id
WHERE 
	auditor_report.true_water_source_score != water_quality.subjective_quality_score
AND
	visits.visit_count = 1;
    
-- This query is massive and complex, so maybe it is a good idea to save this as a CTE, so when we do more analysis

CREATE TABLE incorrect_records AS (
				SELECT
					auditor_report.location_id,
					visits.record_id,
					employee_name,
					auditor_report.true_water_source_score AS auditor_score,
					water_quality.subjective_quality_score AS employee_score
				FROM
					auditor_report
				JOIN 
					visits
				ON
					visits.location_id = auditor_report.location_id
				JOIN
					water_quality
				ON
					visits.record_id = water_quality.record_id
				JOIN
					employee
				ON
					visits.assigned_employee_id = employee.assigned_employee_id
				WHERE 
					auditor_report.true_water_source_score != water_quality.subjective_quality_score
				AND
					visits.visit_count = 1
                    );

-- Check if it works well
SELECT * FROM incorrect_records; -- Done

-- Let's first get a unique list of employees from this table.

SELECT 
	COUNT(DISTINCT employee_name) AS numder_of_employee
FROM
	incorrect_records;
-- 17 employees
/*
Let's try to calculate how many mistakes each employee made. 
So basically we want to count how many times their name is in Incorrect_records list
*/

SELECT
	employee_name,
	COUNT(employee_name) AS numder_of_mistakes
FROM
	incorrect_records
GROUP BY
	employee_name
ORDER BY 
	numder_of_mistakes DESC;
-- It looks like some of surveyors are making a lot of "mistakes" while many of the other surveyors are only making a few.

-- Task 4 Gathering some evidence
-- Find all of the employees who have an above-average number of mistakes
-- calculate the average number of mistakes employees made
DROP table error_count;
CREATE TABLE error_count AS(
						SELECT
							employee_name,
							COUNT(employee_name) AS number_of_mistakes
						FROM
							incorrect_records
						GROUP BY
							employee_name
						ORDER BY 
							number_of_mistakes DESC);
SELECT
	AVG(number_of_mistakes) AS avg_error_count_per_empl
FROM
	error_count;

-- Compare each employee's error_count with avg_error_count_per_empl.
-- We will call this results set our suspect_list.
SELECT
employee_name,
number_of_mistakes
FROM
error_count
WHERE
number_of_mistakes > (SELECT AVG(number_of_mistakes) FROM error_count);

/*
Let's start by cleaning up our previous code a bit:
First, Incorrect_records is a result we'll be using for the rest of the analysis, but it makes the
query a bit less readable. So, let's convert it to a VIEW. We can then use it as if it was a table.
It will make our code much simpler to read, but, it comes at a cost. We can add comments to CTEs in our code, 
so if we return to that query a year later, we can read those comments and quickly understand 
what Incorrect_records represents.
If we save it as a VIEW, it is not as obvious. So we should add comments in places where we
use Incorrect_records.
*/
-- Replacing CTE with CREATE VIEW

CREATE VIEW incorrect_records AS (
				SELECT
					auditor_report.location_id,
					visits.record_id,
					employee_name,
					auditor_report.true_water_source_score AS auditor_score,
					water_quality.subjective_quality_score AS employee_score,
                    auditor_report.statements AS statements
				FROM
					auditor_report
				JOIN 
					visits
				ON
					visits.location_id = auditor_report.location_id
				JOIN
					water_quality
				ON
					visits.record_id = water_quality.record_id
				JOIN
					employee
				ON
					visits.assigned_employee_id = employee.assigned_employee_id
				WHERE 
					auditor_report.true_water_source_score != water_quality.subjective_quality_score
				AND
					visits.visit_count = 1
                    );

-- Calling SELECT * FROM Incorrect_records gives us the same result as the CTE did.
SELECT employee_name, AVG(COUNT(employee_name)) FROM Incorrect_records GROUP BY employee_name;

/*
Next, we convert the query error_count, we made earlier, into a CTE. 
Test it to make sure it gives the same result again, using SELECT * FROM Incorrect_records. 
On large queries like this, it is better to build the query, and test each step,
because fixing errors becomes harder as the query grows.
*/
WITH error_count AS ( -- This CTE calculates the number of mistakes each employee made
SELECT
	employee_name,
	COUNT(employee_name) AS number_of_mistakes
FROM
	Incorrect_records
/* 
Incorrect_records is a view that joins the audit report to the database
for records where the auditor and
employees scores are different
*/
GROUP BY
	employee_name)
-- Query
SELECT * FROM error_count order by number_of_mistakes DESC;

-- Calculate the average of the number_of_mistakes in error_count
SELECT
	AVG(number_of_mistakes) AS avg_mistakes_per_employee
FROM
	error_count;
    
/*
To find the employees who made more mistakes than the average person,
we need the employee's names, the number of mistakes each one
made, and filter the employees with an above-average number of mistakes.
*/

SELECT
	employee_name,
    number_of_mistakes 
FROM
	error_count
WHERE
	number_of_mistakes > (SELECT AVG(number_of_mistakes) FROM error_count);
    
/*
We should look at the Incorrect_records table again, and isolate all of the records these four employees gathered. 
We should also look at the statements for these records to look for patterns.
*/
-- convert the suspect_list to a CTE

CREATE TABLE suspect_list AS( -- This CTE SELECTS the employees with above−average mistakes
		SELECT
			employee_name,
			number_of_mistakes 
		FROM
			error_count
		WHERE
			number_of_mistakes > (SELECT AVG(number_of_mistakes) FROM error_count)
		);
SELECT * FROM suspect_list;

-- filter that Incorrect_records CTE to identify all of the records associated with the four employees we identified
-- This query filters all of the records where the "corrupt" employees gathered data
SELECT
	employee_name,
    location_id, 
    statements
FROM
	incorrect_records
WHERE
	employee_name in (SELECT employee_name from suspect_list);

SELECT
	employee_name,
    location_id, 
    statements
FROM
	incorrect_records
WHERE
	employee_name in (SELECT employee_name from suspect_list)
AND 
	statements LIKE '%cash%';
    
/*
Check if there are any employees in the Incorrect_records table with statements mentioning "cash"
 that are not in our suspect list. This should be as simple as adding one word.
*/
SELECT
	employee_name,
    location_id, 
    statements
FROM
	incorrect_records
WHERE
	employee_name  not in (SELECT employee_name from suspect_list)
AND 
	statements LIKE '%cash%';
-- we got an empty result, so no one, except the four suspects, has these allegations of bribery

/*
So we can sum up the evidence we have for Zuriel Matembo, Malachi Mavuso, Bello Azibo and Lalitha Kaburi:
1. They all made more mistakes than their peers on average.
2. They all have incriminating statements made against them, and only them.
Keep in mind, that this is not decisive proof, but it is concerning enough that we should flag it.
*/





CREATE TABLE suspect_list1 AS (
    SELECT ec1.employee_name, ec1.number_of_mistakes
    FROM error_count ec1
    WHERE ec1.number_of_mistakes >= (
        SELECT AVG(ec2.number_of_mistakes)
        FROM error_count ec2
        WHERE ec2.employee_name = ec1.employee_name));


SELECT * FROM suspect_list1;

-- Q8: Which employee just avoided our classification of having an above-average number of mistakes? 
-- Hint: Use one of the queries we used to aggregate data from Incorrect_records.

SELECT
	employee_name,
    COUNT(employee_name)
FROM
	incorrect_records
GROUP BY 
	employee_name;

-- Q10:
SELECT
	auditorRep.location_id,
	visitsTbl.record_id,
	auditorRep.true_water_source_score AS auditor_score,
	wq.subjective_quality_score AS employee_score,
	wq.subjective_quality_score - auditorRep.true_water_source_score  AS score_diff
FROM auditor_report AS auditorRep
JOIN visits AS visitsTbl
ON auditorRep.location_id = visitsTbl.location_id
JOIN water_quality AS wq
ON visitsTbl.record_id = wq.record_id
WHERE (wq.subjective_quality_score - auditorRep.true_water_source_score) > 9; 















